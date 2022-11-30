using VisualGeometryDatasets
using Test
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

# Revert the database path and delete the temp directory
localstorestring("VisualGeometryDatasets data", vgdir)
rm(dname, recursive=true)
end
