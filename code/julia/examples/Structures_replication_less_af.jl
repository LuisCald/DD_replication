# ─────────────────────────────────────────────────────────────────────────────
# REPLICATION variant: less_af
#
# MDD table, row "less AF": 8 distributional / 3 aggregate factors.
# NB: fewer aggregate factors = fewer observed aggregate scores in y; compare MDDs only
# with the AF correction of run_mdd_table.jl (mdd_bs_comparable).
#
# The replication spec (Structures_replication.jl, 8 distributional factors) with
# exactly this change. Run with (from the project root):
#   DD_EXAMPLE=replication_less_af julia -t 32 --project=5_Code/code/julia/env 5_Code/code/julia/run_estimation.jl
# ─────────────────────────────────────────────────────────────────────────────

ENV["DD_NAF"] = "3"

include(joinpath(@__DIR__, "Structures_replication.jl"))
