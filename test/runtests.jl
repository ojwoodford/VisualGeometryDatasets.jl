include("setup.jl")

# Each dataset's tests are in their own file, which can also be run alone
@testset "VisualGeometryDatasets.jl" begin
    include("bal.jl")
    include("imagealign.jl")
    include("ransac2020.jl")
end
