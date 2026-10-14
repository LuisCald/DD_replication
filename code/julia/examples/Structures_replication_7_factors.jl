# ─────────────────────────────────────────────────────────────────────────────
# REPLICATION variant: 7_factors
#
# MDD table: seven distributional factors.
#
# The replication spec (Structures_replication.jl, 8 distributional factors) with
# exactly this change. Run with (from the project root):
#   DD_EXAMPLE=replication_7_factors julia -t 32 --project=5_Code/code/julia/env 5_Code/code/julia/run_estimation.jl
# ─────────────────────────────────────────────────────────────────────────────

ENV["DD_NDF"] = "7"

include(joinpath(@__DIR__, "Structures_replication.jl"))
