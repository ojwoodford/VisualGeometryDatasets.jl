# VisualGeometryDatasets

[![Build Status](https://github.com/ojwoodford/VisualGeometryDatasets.jl/actions/workflows/CI.yml/badge.svg?branch=main)](https://github.com/ojwoodford/VisualGeometryDatasets.jl/actions/workflows/CI.yml?query=branch%3Amain)

Helper functions for caching and loading Visual Geometry datasets. Code for each dataset is stored in a separate file. Currently included datasets are:
- [Bundle Adjustment in the Large](https://grail.cs.washington.edu/projects/bal/): `bal = loadbaldataset("problem-XX-XXXXX")`
- [CVPR 2020 RANSAC tutorial](https://github.com/ducha-aiki/ransac-tutorial-2020-data) (Barath, Mishkin et al.) tentative correspondences, with ground truth and images:
  - Homographies (EVD and HPatchesSeq): `pairs = loadransac2020homography("EVD", :val)`
  - Fundamental and essential matrices (PhotoTourism scenes): `pairs = loadransac2020twoview("st_peters_square", :val)`. Use `ransac2020scenes(:val)` to list the scenes. The `:train` split is a 92 GB download.

Pull requests for supporting other datasets are welcomed.
