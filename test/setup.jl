# Shared setup for the dataset test files. Each file includes this, so it can be run alone.
using VisualGeometryDatasets, Test, LinearAlgebra
import UserConfig.localstorestring

# Run the code with the data folder pointed at a new temporary folder, then revert the data
# folder path and delete the temporary folder
macro withtempdata(ex)
    return quote
        local dname = mktempdir()
        local vgdir = localstorestring("VisualGeometryDatasets data")
        localstorestring("VisualGeometryDatasets data", dname)
        try
            $(esc(ex))
        finally
            localstorestring("VisualGeometryDatasets data", isempty(vgdir) ? "delete" : vgdir)
            rm(dname, recursive=true)
        end
    end
end
