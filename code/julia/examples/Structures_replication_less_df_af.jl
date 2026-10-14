# ─────────────────────────────────────────────────────────────────────────────
# REPLICATION variant: less_df_af
#
# MDD table, row "less DF and AF" (compact model): 3 distributional / 3 aggregate factors.
#
# The replication spec (Structures_replication.jl, 8 distributional factors) with
# exactly this change. Run with (from the project root):
#   DD_EXAMPLE=replication_less_df_af julia -t 32 --project=5_Code/code/julia/env 5_Code/code/julia/run_estimation.jl
# ─────────────────────────────────────────────────────────────────────────────

ENV["DD_NDF"] = "3"
ENV["DD_NAF"] = "3"

include(joinpath(@__DIR__, "Structures_replication.jl"))
