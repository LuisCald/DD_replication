# ─────────────────────────────────────────────────────────────────────────────
# REPLICATION variant: cex_every_4_years
#
# Fig. recon_missing2 row 1 and tab. corr_outsample: CEX observed only every 4th year
# (1984–2021 waves muted except every 4th year).
#
# The replication spec (Structures_replication.jl, 8 distributional factors) with
# exactly this change. Run with (from the project root):
#   DD_EXAMPLE=replication_cex_every_4_years julia -t 32 --project=5_Code/code/julia/env 5_Code/code/julia/run_estimation.jl
# ─────────────────────────────────────────────────────────────────────────────

ENV["DD_MUTE"] = "cex_every_4_years"

include(joinpath(@__DIR__, "Structures_replication.jl"))
