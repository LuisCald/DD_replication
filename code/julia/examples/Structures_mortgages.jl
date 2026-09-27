# DFA balance-sheet component economy: HOME MORTGAGES.  Run: DD_EXAMPLE=mortgages julia run_estimation.jl
# Joint (income, wealth, hdebt). Micro: hdebt = housing debt (already in SCF.csv). Aggregate
# anchor: hdebt_per_hh (HHMSDODNS). Atom at 0 for renters / owners without a mortgage.
# Measure column is `hdebt` (the DFA "home mortgages" line). See doc/stocks_atom_design.md.
const model_options = ModelOptions(
    measures      = sort(["income", "wealth", "hdebt"]),
    atom_measures = ["hdebt"],
    factor_selection = :bai_ng,   # automatic count via Bai-Ng ICp2, clamped to <= 10 (MC-validated at T~33; see FactorSelectionSim.jl)
    tag           = " mortgages economy",
)
# Component columns live in the canonical PSID.csv/SCF.csv (the regenerated
# files became the defaults on 2026-09-22; the " new data" vintage tag was retired).
const obs_data = ObservedData()
