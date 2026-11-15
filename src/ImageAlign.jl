# Data from the paper "Least Squares Normalized Cross Correlation" (Woodford, 2018):
# https://arxiv.org/abs/1810.04320
# There are two categories of data:
#   - images: sets of images of planar scenes, for evaluating image alignment
#   - videos: image sequences, for evaluating planar tracking
# All image coordinates are 1-based (MATLAB convention), with x horizontal and y vertical.
import p7zip_jll, DelimitedFiles.readdlm
export loadimagealignimages, loadimagealignvideo, imagealignimages, imagealignvideos, ImageAlignScene, ImageAlignVideo

# Dataset => (Google Drive file id, sha256)
const imagealignimagedata = Dict(
    "graffiti2" => ("1w07UiATOPfU9GFut9p8ZgxyIg6GzgJ4B", "c682b34c49e286b303fa956145d50ed9641f89506b19bc4ab2eeb6aebcb120ca"),
    "rifle"     => ("1y_owhnanHygmQSFBIJyAWU4J-J3g5IdV", "6b69affa970674c1575de9e32f40087c2fa10cfcb12c5222a3bcb0efeeb86e63"),
)

# Dataset => (Google Drive file id, sha256, initial target corners in the first frame,
# clockwise from the top left, as a 2x4 matrix of x (row 1) and y (row 2) coordinates)
const imagealignvideodata = Dict(
    "book"      => ("1j0BTtRRYiglVGoLM1617NMwgyEKIG-Xp", "218365dca5076988d41e3b0857289a451fa7d094220fb20bd4eff7e40e6c329f", [114 586 680 116; 199 130 465 542]),
    "bear"      => ("1o9d7dcQ5PEK3e_MddPbOgGqyjMstYz0m", "71dae1a2397a76cdfd038395640ad1a7247113dbc3abb1f2f9cfce6bd5b93950", [221 618 624 244; 174 153 436 444]),
    "cat-plane" => ("13oyRZHjblz3xZK8gCDAwRx26vMTvZN7G", "93e29afafe7124329b37885f75220322422c92cf74f98acdd6968925e02f06ad", [198 457 458 207; 109 105 407 411]),
)

"""
    imagealignimages()

List the names of the image datasets from the Least Squares NCC paper.
"""
imagealignimages() = sort!(collect(keys(imagealignimagedata)))

"""
    imagealignvideos()

List the names of the video datasets from the Least Squares NCC paper.
"""
imagealignvideos() = sort!(collect(keys(imagealignvideodata)))

# Download and extract a dataset (once), returning the path to its folder
function imagealignpath(name::String, fid::String, sha256::String)
    root = joinpath(localpath(), "ImageAlign")
    outdir = joinpath(root, name)
    if !isdir(outdir)
        mkpath(root)
        fpath = joinpath(root, name * ".zip")
        download_verify("https://drive.usercontent.google.com/download?id=$fid&export=download&confirm=t", sha256, fpath)
        tmpdir = mktempdir(root)
        try
            run(pipeline(`$(p7zip_jll.p7zip()) x $fpath -o$tmpdir -y`; stdout=devnull))
            rm(joinpath(tmpdir, "__MACOSX"); recursive=true, force=true)
            # Some archives have a top level folder, others do not
            src = joinpath(tmpdir, name)
            if isdir(src)
                mv(src, outdir)
            else
                mv(tmpdir, outdir)
            end
        finally
            rm(tmpdir; recursive=true, force=true)
        end
        rm(fpath)
    end
    return outdir
end

listimages(dir) = filter(f -> endswith(lowercase(f), ".png"), readdir(dir; join=true))

######## Images ########

struct ImageAlignScene{T<:AbstractFloat}
    name::String
    images::Vector{String}                                     # Image file paths
    H::Union{Nothing, Matrix{SMatrix{3, 3, T, 9}}}             # H[i,j] maps points in image i to image j
    regions::Union{Nothing, Vector{Vector{SVector{4, Int}}}}   # regions[i][k]: (x1, y1, x2, y2) of the top left and
                                                               # bottom right corners of the kth 50x50 test region in image i
    offsets::Union{Nothing, Vector{SMatrix{2, 4, T, 8}}}       # offsets[k]: initialization offsets of the 4 corners of the kth
                                                               # region (clockwise from the top left), with mean length 1 pixel
end

function Base.show(io::IO, x::ImageAlignScene{T}) where T
    @printf(io, "ImageAlignScene{%s} %s: %d images, ground truth %s\n", T, x.name, length(x.images), isnothing(x.H) ? "unavailable" : "available")
end

function readscene(dir::String, T::Type)
    images = listimages(dir)
    N = length(images)
    isfile(joinpath(dir, "H11.txt")) || return ImageAlignScene{T}(basename(dir), images, nothing, nothing, nothing)
    H = [SMatrix{3, 3, T, 9}(readdlm(joinpath(dir, "H$i$j.txt"))) for i in 1:N, j in 1:N]
    # The region files store a 4xM matrix in column-major order, 4 values to a line
    regions = map(1:N) do i
        R = reshape(Int.(vec(permutedims(readdlm(joinpath(dir, "regions$i.txt"))))), :, 4)
        return [SVector{4, Int}(R[k, :]) for k in axes(R, 1)]
    end
    # Each line of the offsets file holds the 4 (x, y) corner offsets for a region
    O = readdlm(joinpath(dir, "offsets.txt"))
    offsets = [SMatrix{2, 4, T, 8}(O[k, :]) for k in axes(O, 1)]
    return ImageAlignScene{T}(basename(dir), images, H, regions, offsets)
end

"""
    loadimagealignimages(name, T=Float64)

Load an image dataset from the Least Squares NCC paper (see `imagealignimages`):
  - `"graffiti2"`: 7 planar scenes, each of 4 images (800x600) taken from roughly the same
    position under different natural lighting, with ground truth homographies between all
    pairs, 100 test regions per image and initialization offsets for those regions.
  - `"rifle"`: 7 images of a single planar scene, without ground truth.

The first call downloads the dataset (25 MB and 6 MB respectively).

Returns a vector of `ImageAlignScene`s.
"""
function loadimagealignimages(name::String, T::Type=Float64)
    haskey(imagealignimagedata, name) || throw(DomainError(name, "dataset not found. Available datasets: " * join(imagealignimages(), ", ")))
    dir = imagealignpath(name, imagealignimagedata[name]...)
    subdirs = filter(isdir, readdir(dir; join=true))
    isempty(subdirs) && return [readscene(dir, T)]
    return [readscene(d, T) for d in sort!(subdirs; by=d -> something(tryparse(Int, basename(d)), typemax(Int)))]
end

######## Videos ########

struct ImageAlignVideo
    name::String
    frames::Vector{String}  # Frame file paths, in order
    corners::Matrix{Int}    # Target corners in the first frame (clockwise from the top left): x in row 1, y in row 2
end

function Base.show(io::IO, x::ImageAlignVideo)
    @printf(io, "ImageAlignVideo %s: %d frames\n", x.name, length(x.frames))
end

"""
    loadimagealignvideo(name)

Load a video dataset from the Least Squares NCC paper (see `imagealignvideos`):
`"book"`, `"bear"` or `"cat-plane"`. Each is a sequence of frames of a planar target to
be tracked, along with the corners of that target in the first frame. There is no
ground truth. The first call downloads the dataset (67 MB, 336 MB and 332 MB
respectively).

Returns an `ImageAlignVideo`.
"""
function loadimagealignvideo(name::String)
    haskey(imagealignvideodata, name) || throw(DomainError(name, "dataset not found. Available datasets: " * join(imagealignvideos(), ", ")))
    fid, sha256, corners = imagealignvideodata[name]
    return ImageAlignVideo(name, listimages(imagealignpath(name, fid, sha256)), corners)
end
