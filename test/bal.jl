@isdefined(var"@withtempdata") || include("setup.jl")

@withtempdata begin
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
end
