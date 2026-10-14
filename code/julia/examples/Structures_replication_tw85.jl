# ─────────────────────────────────────────────────────────────────────────────
# REPLICATION variant: tw85
#
# MDD table, row "Γ all 85": Tall–Wide loadings at 85%.
#
# The replication spec (Structures_replication.jl, 8 distributional factors) with
# exactly this change. Run with (from the project root):
#   DD_EXAMPLE=replication_tw85 julia -t 32 --project=5_Code/code/julia/env 5_Code/code/julia/run_estimation.jl
# ─────────────────────────────────────────────────────────────────────────────

ENV["DD_TW"] = "0.85"

include(joinpath(@__DIR__, "Structures_replication.jl"))
