module VisualGeometryDatasets
import UserConfig

function  localpath()
return UserConfig.localpath("VisualGeometryDatasets data", isdir, true)
end

include("BALDatasets.jl")
end
