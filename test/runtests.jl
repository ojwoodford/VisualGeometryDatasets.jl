include("setup.jl")

# Each dataset's tests are in their own file, which can also be run alone, e.g.
# Pkg.test("VisualGeometryDatasets"; test_args=["imagealign"])
runtest(name) = isempty(ARGS) || name in ARGS

@testset "VisualGeometryDatasets.jl" begin
    runtest("bal") && include("bal.jl")
    runtest("imagealign") && include("imagealign.jl")
    runtest("ransac2020") && include("ransac2020.jl")
end
