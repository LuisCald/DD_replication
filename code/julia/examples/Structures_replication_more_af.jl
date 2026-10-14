# ─────────────────────────────────────────────────────────────────────────────
# REPLICATION variant: more_af
#
# MDD table, row "more AF": 8 distributional / 15 aggregate factors.
#
# The replication spec (Structures_replication.jl, 8 distributional factors) with
# exactly this change. Run with (from the project root):
#   DD_EXAMPLE=replication_more_af julia -t 32 --project=5_Code/code/julia/env 5_Code/code/julia/run_estimation.jl
# ─────────────────────────────────────────────────────────────────────────────

ENV["DD_NAF"] = "15"

include(joinpath(@__DIR__, "Structures_replication.jl"))
