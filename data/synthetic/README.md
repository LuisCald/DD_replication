# Synthetic distributional data — moved to DD_data

The published data product (latent factors, posterior draws, coefficient
files, synthetic microdata, aggregate anchors) and the user-facing helper
scripts now live in their own repository:

**https://github.com/LuisCald/DD_data**

This folder remains as the **output directory of the estimation pipeline**:
`Reconstruction.jl`, `PosteriorDraws.jl` / `export_draws.jl` write regenerated
factor, draw, and coefficient files here. Regenerated outputs are not tracked
in this repo; they have the same layout as the files published in DD_data.
