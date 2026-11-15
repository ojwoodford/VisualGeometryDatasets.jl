using VisualGeometryDatasets, Test, LinearAlgebra
import UserConfig.localstorestring

@testset "VisualGeometryDatasets.jl" begin
# Create a temporary data folder and store the path to it
dname = mktempdir()
vgdir = localstorestring("VisualGeometryDatasets data")
if isempty(vgdir)
    vgdir = "delete"
end
localstorestring("VisualGeometryDatasets data", dname)

@testset "BAL datasets" begin
    # Download a dataset and check some values
    data = loadbaldataset("problem-16-22106")
    @test length(data.measurements) == 83718
    @test data.measurements[1].camera == 1
    @test data.measurements[end].camera == 16
    @test data.measurements[1].landmark == 1
    @test data.measurements[end].landmark == 22106
    @test typeof(data.measurements[1].x) == Float64
    @test eltype(data.cameras[1]) == Float64
    @test eltype(data.landmarks[1]) == Float64
    @test data.measurements[end].x == -196.32

    # Check the storage type can be specified
    data = loadbaldataset("problem-16-22106", Float32)
    @test typeof(data.measurements[1].x) == Float32
    @test eltype(data.cameras[1]) == Float32
    @test eltype(data.landmarks[1]) == Float32
end

@testset "Image alignment images" begin
    @test imagealignimages() == ["graffiti2", "rifle"]
    scenes = loadimagealignimages("graffiti2")
    @test length(scenes) == 7
    s = scenes[1]
    @test length(s.images) == 4 && all(isfile, s.images)
    @test size(s.H) == (4, 4)
    @test s.H[1, 1] == one(s.H[1, 1])
    # Homographies are approximately consistent
    H = s.H[1, 2] * s.H[2, 1]
    @test H / H[3, 3] ≈ one(H) atol=0.5
    @test length(s.regions) == 4 && all(r -> length(r) == 100, s.regions)
    @test all(r -> r[3] - r[1] == 49 && r[4] - r[2] == 49, s.regions[1])
    @test length(s.offsets) == 100
    @test sum(o -> sum(c -> hypot(c...), eachcol(o)), s.offsets) / 400 ≈ 1
    @test eltype(loadimagealignimages("graffiti2", Float32)[1].offsets[1]) == Float32
    scenes = loadimagealignimages("rifle")
    @test length(scenes) == 1
    @test length(scenes[1].images) == 7
    @test isnothing(scenes[1].H)
end

# The video tests download about 750 MB, so only run them when asked
if get(ENV, "VGD_TEST_IMAGEALIGN_VIDEOS", "") == "1"
@testset "Image alignment videos" begin
    @test imagealignvideos() == ["bear", "book", "cat-plane"]
    for (name, n) in (("book", 284), ("bear", 1573), ("cat-plane", 899))
        v = loadimagealignvideo(name)
        @test length(v.frames) == n
        @test isfile(v.frames[1]) && isfile(v.frames[end])
        @test size(v.corners) == (2, 4)
    end
end
end

# The RANSAC 2020 tests download about 3 GB, so only run them when asked
if get(ENV, "VGD_TEST_RANSAC2020", "") == "1"
@testset "RANSAC 2020 homography" begin
    d = loadransac2020homography("EVD", :val)
    @test length(d) == 7
    @test length(loadransac2020homography("EVD", :test)) == 8
    d = loadransac2020homography("HPatchesSeq", :val)
    @test length(d) == 145
    p = d["v_artisans_1_2"]
    @test length(p.x1) == length(p.x2) == length(p.scores) == 1307
    @test p.H[1, 3] == 101.75
    @test isfile(p.image1) && isfile(p.image2)
    # A good share of the tentative matches agree with the ground truth
    err = [norm((p.H * [a; 1])[1:2] / (p.H * [a; 1])[3] - b) for (a, b) in zip(p.x1, p.x2)]
    @test count(<(3), err) > 0.2 * length(err)
    p = loadransac2020homography("HPatchesSeq", :test, Float32)[1]
    @test isnothing(p.H)
    @test eltype(p.x1[1]) == Float32
end

@testset "RANSAC 2020 two-view" begin
    @test "st_peters_square" in ransac2020scenes(:val)
    d = loadransac2020twoview("st_peters_square")
    @test length(d) == 4950
    p = d[1]
    @test length(p.x1) == 2650
    @test isfile(p.image1) && isfile(p.image2)
    # The ground truth is self consistent
    skew(t) = [0 -t[3] t[2]; t[3] 0 -t[1]; -t[2] t[1] 0]
    nrm(A) = A / A[end]
    @test nrm(p.E) ≈ nrm(p.K2' * p.F * p.K1)
    @test nrm(p.E) ≈ nrm(skew(p.t) * p.R)
    @test p.R' * p.R ≈ one(p.R)
    @test eltype(loadransac2020twoview("st_peters_square", :val, Float32)[1].F) == Float32
end
end

# Revert the database path and delete the temp directory
localstorestring("VisualGeometryDatasets data", vgdir)
rm(dname, recursive=true)
end
