# ─────────────────────────────────────────────────────────────────────────────
# REPLICATION variant: liquid — DFA-style balance-sheet product
#
# Joint distribution of (income, wealth, liquid) on the replication spec (8 distributional
# factors, HP trend, ridge 0.05, infl aggregates, COVID-robust aggregate PCA).
# Observed in: PSID, SCF, CEX; the other surveys enter with the item missing.
# Continuous item (can be negative): no atom.
# Anchor: liquid_per_hh in inflation_corrected_correction_series.xlsx.
#
#   DD_EXAMPLE=replication_liquid julia -t 32 --project=5_Code/code/julia/env 5_Code/code/julia/run_estimation.jl
# ─────────────────────────────────────────────────────────────────────────────

ENV["DD_ITEM"] = "liquid"
ENV["DD_ATOM"] = "0"

include(joinpath(@__DIR__, "Structures_replication.jl"))
