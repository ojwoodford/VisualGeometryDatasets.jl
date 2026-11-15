include("setup.jl")

# Each dataset's tests are in their own file, which can also be run alone, e.g.
# Pkg.test("VisualGeometryDatasets"; test_args=["imagealign"])
const testfiles = ["bal", "imagealign", "ransac2020"]

@testset "VisualGeometryDatasets.jl" begin
    for name in (isempty(ARGS) ? testfiles : ARGS)
        include(name * ".jl")
    end
end
