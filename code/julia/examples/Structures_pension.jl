# DFA balance-sheet component economy: PENSION ENTITLEMENTS.  Run: DD_EXAMPLE=pension julia run_estimation.jl
# Joint (income, wealth, pension). Micro: pension = pen (SCF) at survey date like wealth.
# Aggregate anchor: pension_per_hh (HNOPFAQ027S, total entitlements). NOTE: DB and DC are not
# separable here (no survey splits them), so this is combined entitlements. Atom at 0 for
# households with no pension wealth. See doc/stocks_atom_design.md.
const model_options = ModelOptions(
    measures      = sort(["income", "wealth", "pension"]),
    atom_measures = ["pension"],
    tag           = " pension economy",
)
const obs_data = ObservedData()
