# Shared setup for the dataset test files. Each file includes this, so it can be run alone.
using VisualGeometryDatasets, Test, LinearAlgebra
import UserConfig.localstorestring

# Point the data folder at a new temporary folder, returning what is needed to revert it
function usetempdata()
    dname = mktempdir()
    vgdir = localstorestring("VisualGeometryDatasets data")
    localstorestring("VisualGeometryDatasets data", dname)
    return (dname, isempty(vgdir) ? "delete" : vgdir)
end

# Revert the data folder path and delete the temporary folder
function reverttempdata((dname, vgdir))
    localstorestring("VisualGeometryDatasets data", vgdir)
    rm(dname, recursive=true)
end
