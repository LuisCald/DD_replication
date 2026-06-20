# DFA balance-sheet component economy: HOME MORTGAGES.  Run: DD_EXAMPLE=mortgages julia run_estimation.jl
# Joint (income, wealth, hdebt). Micro: hdebt = housing debt (already in SCF.csv). Aggregate
# anchor: hdebt_per_hh (HHMSDODNS). Atom at 0 for renters / owners without a mortgage.
# Measure column is `hdebt` (the DFA "home mortgages" line). See doc/stocks_atom_design.md.
const model_options = ModelOptions(
    measures      = sort(["income", "wealth", "hdebt"]),
    atom_measures = ["hdebt"],
    tag           = " mortgages economy",
)
const obs_data = ObservedData()
