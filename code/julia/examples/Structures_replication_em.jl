# ─────────────────────────────────────────────────────────────────────────────
# REPLICATION variant: em
#
# MDD table, EM row: loadings by EM completion instead of complete-case PCA.
#
# The replication spec (Structures_replication.jl, 8 distributional factors) with
# exactly this change. Run with (from the project root):
#   DD_EXAMPLE=replication_em julia -t 32 --project=5_Code/code/julia/env 5_Code/code/julia/run_estimation.jl
# ─────────────────────────────────────────────────────────────────────────────

ENV["DD_PCA"] = "em"

include(joinpath(@__DIR__, "Structures_replication.jl"))
