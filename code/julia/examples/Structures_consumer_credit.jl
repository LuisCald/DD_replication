# DFA balance-sheet component economy: CONSUMER CREDIT.  Run: DD_EXAMPLE=consumer_credit julia run_estimation.jl
# Joint (income, wealth, pdebt). Micro: pdebt = non-mortgage / unsecured debt (already in
# SCF.csv). Aggregate anchor: pdebt_per_hh (TOTALSL). Atom at 0 for households with no consumer
# credit. Measure column is `pdebt` (the DFA "consumer credit" line). See doc/stocks_atom_design.md.
const model_options = ModelOptions(
    measures      = sort(["income", "wealth", "pdebt"]),
    atom_measures = ["pdebt"],
    tag           = " consumer_credit economy",
)
const obs_data = ObservedData()
