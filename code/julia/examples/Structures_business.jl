# DFA balance-sheet component economy: UNINCORPORATED BUSINESS.  Run: DD_EXAMPLE=business julia run_estimation.jl
# Joint (income, wealth, business). Micro: business = ffabus (SCF) at survey date like wealth.
# Aggregate anchor: business_per_hh (BOGZ1LM152090205Q, proprietors' equity in noncorporate
# business). Large atom (most households own no business). See doc/stocks_atom_design.md.
const model_options = ModelOptions(
    measures      = sort(["income", "wealth", "business"]),
    atom_measures = ["business"],
    tag           = " business economy",
)
const obs_data = ObservedData()
