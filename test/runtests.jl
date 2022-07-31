using VGDatasets
using Test
import UserConfig.localstorestring

@testset "VGDatasets.jl" begin
# Create a temporary data folder and store the path to it
dname = mktempdir()
vgdir = localstorestring("VGDatasets data")
if isempty(vgdir)
    vgdir = "delete"
end
localstorestring("VGDatasets data", dname)

@testset "BAL datasets" begin
    # Download a dataset and check some values
    data = loadbaldataset("problem-16-22106")
    @test size(data.measurementindices) == (2, 83718)
    @test vec(data.measurementindices[:,[1 end]]) == [1, 1, 16, 22106]
    @test size(data.measurements) == (2, 83718)
    @test typeof(data.measurements[1]) == Float64
    @test typeof(data.cameras[1]) == Float64
    @test typeof(data.landmarks[1]) == Float64
    @test data.measurements[1,end] == -196.32

    # Check the storage type can be specified
    data = loadbaldataset("problem-16-22106", Float32)
    @test typeof(data.measurements[1]) == Float32
    @test typeof(data.cameras[1]) == Float32
    @test typeof(data.landmarks[1]) == Float32
end

# Revert the database path and delete the temp directory
localstorestring("VGDatasets data", vgdir)
rm(dname, recursive=true)
end
