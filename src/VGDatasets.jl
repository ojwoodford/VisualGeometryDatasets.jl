module VGDatasets
import UserConfig

function  localpath()
return UserConfig.localpath("VGDatasets data", isdir, true)
end

include("BALDatasets.jl")
end
