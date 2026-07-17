# Synthetic distributional data — moved to DD_data

The published data product (latent factors, posterior draws, coefficient
files, synthetic microdata, aggregate anchors) and the user-facing helper
scripts now live in their own repository:

**https://github.com/LuisCald/DD_data**

This folder remains as the **output directory of the estimation pipeline**:
`Reconstruction.jl`, `PosteriorDraws.jl` / `export_draws.jl` write regenerated
factor, draw, and coefficient files here. Regenerated outputs are not tracked
in this repo — after a new estimation run, copy the canonical file set into a
DD_data checkout and commit there (see `publish_to_DD_data.sh` in the repo
root).
