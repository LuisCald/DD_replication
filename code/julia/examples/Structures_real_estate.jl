# DFA balance-sheet component economy: REAL ESTATE.  Run: DD_EXAMPLE=real_estate julia run_estimation.jl
# Joint (income, wealth, real_estate). Micro: real_estate = house + oest (SCF) collected at
# survey date like wealth. Aggregate anchor: real_estate_per_hh (HNOREMV). Semicontinuous
# (renters/non-owners → atom at 0). See doc/stocks_atom_design.md. Defaults: see ModelOptions.
const model_options = ModelOptions(
    measures      = sort(["income", "wealth", "real_estate"]),
    atom_measures = ["real_estate"],
    tag           = " real_estate economy",
)
const obs_data = ObservedData()
