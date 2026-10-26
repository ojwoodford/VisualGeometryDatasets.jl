module VisualGeometryDatasets
import UserConfig

localpath() = UserConfig.localpath("VisualGeometryDatasets data", isdir, true)

include("BALDatasets.jl")
include("RANSAC2020.jl")
end
