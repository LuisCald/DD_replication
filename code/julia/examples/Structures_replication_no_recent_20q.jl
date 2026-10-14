# ─────────────────────────────────────────────────────────────────────────────
# REPLICATION variant: no_recent_20q
#
# Fig. recon_missing2 row 2 and tab. corr_outsample: all microdata muted 2020Q1–2024Q1.
#
# The replication spec (Structures_replication.jl, 8 distributional factors) with
# exactly this change. Run with (from the project root):
#   DD_EXAMPLE=replication_no_recent_20q julia -t 32 --project=5_Code/code/julia/env 5_Code/code/julia/run_estimation.jl
# ─────────────────────────────────────────────────────────────────────────────

ENV["DD_MUTE"] = "no_recent_20q"

include(joinpath(@__DIR__, "Structures_replication.jl"))
