# Data from the CVPR 2020 RANSAC tutorial (Barath, Mishkin et al.):
# https://github.com/ducha-aiki/ransac-tutorial-2020-data
# The data is stored in HDF5 files, which JLD2 can read.
import Tar, CodecZlib.GzipDecompressorStream, JLD2
export loadransac2020homography, loadransac2020twoview, ransac2020scenes, HomographyPair, TwoViewPair

const ransac2020url = "https://cmp.felk.cvut.cz/~mishkdmy/CVPR-RANSAC-Tutorial-2020/"

# Archive => (file name, sha256 (nothing if not yet recorded), top folder inside the archive, path to the data within it)
const ransac2020archives = Dict(
    :homography => ("homography.tar.gz", "884f3db2c88c0fa9b1b7124e3644e846d454fd120af94618dcdbdb06c05b75d8", "homography", ""),
    :twoview_val => ("RANSAC-Tutorial-Data-ValOnly.tar", "dc0a57484fc74276d06e07ac3da2270394bfec7b14b7ae7b0371ccbae116d063", "RANSAC-Tutorial-Data-ValOnly", "val"),
    :twoview_test => ("RANSAC-Tutorial-Data-EF-Test.tar", nothing, "RANSAC-Tutorial-Data-Test", ""),
    :twoview_train => ("RANSAC-Tutorial-Data-EF.tar", nothing, "RANSAC-Tutorial-Data", "train"),
)

# Download and extract an archive (once), returning the path to its data
function ransac2020path(archive::Symbol)
    fname, sha256, folder, subpath = ransac2020archives[archive]
    root = joinpath(localpath(), "RANSAC2020")
    outdir = joinpath(root, folder)
    if !isdir(outdir)
        mkpath(root)
        fpath = joinpath(root, fname)
        download_verify(ransac2020url * fname, sha256, fpath)
        tmpdir = mktempdir(root)
        try
            open(fpath, "r") do fh
                Tar.extract(endswith(fname, ".gz") ? GzipDecompressorStream(fh) : fh, tmpdir)
            end
            mv(joinpath(tmpdir, folder), outdir)
        finally
            rm(tmpdir; recursive=true, force=true)
        end
        rm(fpath)
    end
    return joinpath(outdir, subpath)
end

# Convert a 4xN matrix of (x1, y1, x2, y2) columns into two point vectors
function splitmatches(M::AbstractMatrix, T::Type)
    x1 = [SVector{2, T}(M[1, i], M[2, i]) for i in axes(M, 2)]
    x2 = [SVector{2, T}(M[3, i], M[4, i]) for i in axes(M, 2)]
    return x1, x2
end

# Julia reads the row-major arrays written by Python with their dimensions reversed,
# so matrices need transposing
mat3(A, T) = SMatrix{3, 3, T, 9}(permutedims(A))
readmat3(file, key, T) = mat3(file[key], T)

# A lazily loaded collection of image pairs. Each HDF5 file holds one entry per pair (or per
# image, for R and T), keyed by name.
struct RANSAC2020Data{P} <: AbstractVector{P}
    dir::String
    pairnames::Vector{String}
    files::Dict{String, Any}
end

Base.size(d::RANSAC2020Data) = (length(d.pairnames),)
Base.getindex(d::RANSAC2020Data, i::Int) = d[d.pairnames[i]]

function opendata(P, dir, filenames, T)
    isdir(dir) || throw(DomainError(dir, "data folder not found"))
    files = Dict{String, Any}()
    for f in filenames
        fpath = joinpath(dir, string(f, ".h5"))
        isfile(fpath) && (files[f] = JLD2.jldopen(fpath, "r"))
    end
    names = sort!(collect(String, keys(files["matches"])))
    return RANSAC2020Data{P{T}}(dir, names, files)
end

function Base.show(io::IO, ::MIME"text/plain", d::RANSAC2020Data{P}) where P
    print(io, P, " collection: ", length(d), " pairs from ", d.dir)
end

######## Homography ########

struct HomographyPair{T<:AbstractFloat}
    name::String
    x1::Vector{SVector{2, T}}               # Points in image 1
    x2::Vector{SVector{2, T}}               # Tentatively matched points in image 2
    scores::Vector{T}                       # Matching score of each correspondence, as provided
    H::Union{Nothing, SMatrix{3, 3, T, 9}}  # Ground truth, mapping x1 to x2 (nothing for the test split)
    image1::String                          # Image file paths
    image2::String
end

function Base.show(io::IO, x::HomographyPair{T}) where T
    @printf(io, "HomographyPair{%s} %s: %d correspondences, ground truth %s\n", T, x.name, length(x.x1), isnothing(x.H) ? "unavailable" : "available")
end

"""
    loadransac2020homography(dataset, split=:val, T=Float64)

Load homography data from the CVPR 2020 RANSAC tutorial. `dataset` is `"EVD"` or
`"HPatchesSeq"`, and `split` is `:val` (with ground truth) or `:test` (without). The first call downloads and extracts an 800 MB archive.

Returns a lazily loaded vector of `HomographyPair`s, indexable by number or pair name.
"""
function loadransac2020homography(dataset::String, split::Symbol=:val, T::Type=Float64)
    dataset in ("EVD", "HPatchesSeq") || throw(DomainError(dataset, "dataset must be \"EVD\" or \"HPatchesSeq\""))
    split in (:val, :test) || throw(DomainError(split, "split must be :val or :test"))
    dir = joinpath(ransac2020path(:homography), dataset, string(split))
    return opendata(HomographyPair, dir, ("matches", "match_conf", "Hgt"), T)
end

function homographyimages(dir, name)
    if basename(dirname(dir)) == "EVD"
        # Key is the image name, e.g. "graf"
        return joinpath(dir, "imgs", "1", name * ".png"), joinpath(dir, "imgs", "2", name * ".png")
    end
    # Key is "<sequence>_<i>_<j>", e.g. "v_artisans_1_2"
    parts = rsplit(name, '_'; limit=3)
    return joinpath(dir, "imgs", parts[1], parts[2] * ".ppm"), joinpath(dir, "imgs", parts[1], parts[3] * ".ppm")
end

function Base.getindex(d::RANSAC2020Data{HomographyPair{T}}, name::String) where T
    x1, x2 = splitmatches(d.files["matches"][name], T)
    scores = vec(T.(d.files["match_conf"][name]))
    H = haskey(d.files, "Hgt") ? readmat3(d.files["Hgt"], name, T) : nothing
    return HomographyPair{T}(name, x1, x2, scores, H, homographyimages(d.dir, name)...)
end

######## Fundamental / essential matrix ########

const Mat3{T} = SMatrix{3, 3, T, 9}

struct TwoViewPair{T<:AbstractFloat}
    name::String
    x1::Vector{SVector{2, T}}         # Points in image 1 (pixels)
    x2::Vector{SVector{2, T}}         # Tentatively matched points in image 2
    scores::Vector{T}                 # Max of the two-way SNN ratios: 0 is a good match, ~1 a bad one
    K1::Union{Nothing, Mat3{T}}       # Calibration matrices
    K2::Union{Nothing, Mat3{T}}
    F::Union{Nothing, Mat3{T}}        # Ground truth fundamental matrix: x2' * F * x1 = 0
    E::Union{Nothing, Mat3{T}}        # Ground truth essential matrix: E = K2' * F * K1 = [t]x * R
    R::Union{Nothing, Mat3{T}}        # Ground truth relative pose, mapping camera 1 coordinates
    t::Union{Nothing, SVector{3, T}}  # to camera 2 as X2 = R * X1 + t (t has arbitrary scale)
    image1::String                    # Image file paths
    image2::String
end

function Base.show(io::IO, x::TwoViewPair{T}) where T
    @printf(io, "TwoViewPair{%s} %s: %d correspondences, ground truth %s\n", T, x.name, length(x.x1), isnothing(x.F) ? "unavailable" : "available")
end

twoviewarchive(split::Symbol) = split in (:val, :test, :train) ? Symbol(:twoview_, split) : throw(DomainError(split, "split must be :val, :test or :train"))

"""
    ransac2020scenes(split=:val)

List the scenes available for the fundamental/essential matrix data of the given split
(`:val`, `:test` or `:train`). Downloads the split's data if needed: 2.2 GB for `:val`,
4.1 GB for `:test` and 92 GB for `:train`.
"""
ransac2020scenes(split::Symbol=:val) = sort!(filter(isdir, readdir(ransac2020path(twoviewarchive(split)); join=true)) .|> basename)

"""
    loadransac2020twoview(scene, split=:val, T=Float64)

Load fundamental/essential matrix data from the CVPR 2020 RANSAC tutorial, for a single
PhotoTourism scene (see `ransac2020scenes`). `split` is `:val`, `:test` (no ground truth)
or `:train`. The first call for a split downloads and extracts its
archive: 2.2 GB for `:val`, 4.1 GB for `:test` and 92 GB for `:train`.

Returns a lazily loaded vector of `TwoViewPair`s, indexable by number or pair name.
"""
function loadransac2020twoview(scene::String, split::Symbol=:val, T::Type=Float64)
    dir = joinpath(ransac2020path(twoviewarchive(split)), scene)
    isdir(dir) || throw(DomainError(scene, "scene not found. Available scenes: " * join(ransac2020scenes(split), ", ")))
    return opendata(TwoViewPair, dir, ("matches", "match_conf", "K1_K2", "Fgt", "Egt", "R", "T"), T)
end

function Base.getindex(d::RANSAC2020Data{TwoViewPair{T}}, name::String) where T
    f = d.files
    x1, x2 = splitmatches(f["matches"][name], T)
    scores = vec(T.(f["match_conf"][name]))
    K1 = K2 = F = E = R = t = nothing
    if haskey(f, "K1_K2")
        K = f["K1_K2"][name]  # 3x3x2x1 once the dimensions are reversed
        K1, K2 = mat3(K[:, :, 1, 1], T), mat3(K[:, :, 2, 1], T)
    end
    haskey(f, "Fgt") && (F = readmat3(f["Fgt"], name, T))
    haskey(f, "Egt") && (E = readmat3(f["Egt"], name, T))
    # Key is "<image1>-<image2>"; R and T hold each image's world-to-camera pose
    im1, im2 = split(name, '-')
    if haskey(f, "R") && haskey(f, "T")
        R1, R2 = readmat3(f["R"], im1, T), readmat3(f["R"], im2, T)
        t1, t2 = SVector{3, T}(vec(f["T"][im1])), SVector{3, T}(vec(f["T"][im2]))
        R = R2 * R1'
        t = t2 - R * t1
    end
    imdir = joinpath(d.dir, "images")
    return TwoViewPair{T}(name, x1, x2, scores, K1, K2, F, E, R, t, joinpath(imdir, im1 * ".jpg"), joinpath(imdir, im2 * ".jpg"))
end
