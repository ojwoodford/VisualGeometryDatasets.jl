@isdefined(usetempdata) || include("setup.jl")
tempdata = usetempdata()

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
    @test sum(o -> sum(norm, eachcol(o)), s.offsets) / 400 ≈ 1
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

reverttempdata(tempdata)
