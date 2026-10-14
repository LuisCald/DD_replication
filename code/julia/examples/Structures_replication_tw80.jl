# ─────────────────────────────────────────────────────────────────────────────
# REPLICATION variant: tw80
#
# MDD table, row "Γ all": Tall–Wide loadings at 80% (RobustProjection.jl).
#
# The replication spec (Structures_replication.jl, 8 distributional factors) with
# exactly this change. Run with (from the project root):
#   DD_EXAMPLE=replication_tw80 julia -t 32 --project=5_Code/code/julia/env 5_Code/code/julia/run_estimation.jl
# ─────────────────────────────────────────────────────────────────────────────

ENV["DD_TW"] = "0.8"

include(joinpath(@__DIR__, "Structures_replication.jl"))
