@isdefined(usetempdata) || include("setup.jl")

# The RANSAC 2020 tests download about 3 GB, so only run them when asked
if get(ENV, "VGD_TEST_RANSAC2020", "") == "1"
tempdata = usetempdata()

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

reverttempdata(tempdata)
end
