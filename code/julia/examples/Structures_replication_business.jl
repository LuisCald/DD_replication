# ─────────────────────────────────────────────────────────────────────────────
# REPLICATION variant: business — DFA-style balance-sheet product
#
# Joint distribution of (income, wealth, business) on the replication spec (8 distributional
# factors, HP trend, ridge 0.05, infl aggregates, COVID-robust aggregate PCA).
# Observed in: PSID, SCF; the other surveys enter with the item missing.
# Semicontinuous item: atom at zero (atom_measures), see doc/stocks_atom_design.md.
# Anchor: business_per_hh in inflation_corrected_correction_series.xlsx.
#
#   DD_EXAMPLE=replication_business julia -t 32 --project=5_Code/code/julia/env 5_Code/code/julia/run_estimation.jl
# ─────────────────────────────────────────────────────────────────────────────

ENV["DD_ITEM"] = "business"
ENV["DD_ATOM"] = "1"

include(joinpath(@__DIR__, "Structures_replication.jl"))
