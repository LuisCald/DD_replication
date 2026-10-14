# ─────────────────────────────────────────────────────────────────────────────
# REPLICATION variant: no_housing_wealth
#
# Fig. recon_missing2 row 3 and tab. corr_outsample: wealth muted 2004Q1–2009Q4 in all surveys.
#
# The replication spec (Structures_replication.jl, 8 distributional factors) with
# exactly this change. Run with (from the project root):
#   DD_EXAMPLE=replication_no_housing_wealth julia -t 32 --project=5_Code/code/julia/env 5_Code/code/julia/run_estimation.jl
# ─────────────────────────────────────────────────────────────────────────────

ENV["DD_MUTE"] = "no_housing_wealth"

include(joinpath(@__DIR__, "Structures_replication.jl"))
