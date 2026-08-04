# DFA balance-sheet component economy: REAL ESTATE.  Run: DD_EXAMPLE=real_estate julia run_estimation.jl
# Joint (income, wealth, real_estate). Micro: real_estate = house + oest (SCF) collected at
# survey date like wealth. Aggregate anchor: real_estate_per_hh (HNOREMV). Semicontinuous
# (renters/non-owners → atom at 0). See doc/stocks_atom_design.md. Defaults: see ModelOptions.
const model_options = ModelOptions(
    measures      = sort(["income", "wealth", "real_estate"]),
    atom_measures = ["real_estate"],
    factor_selection = :bai_ng,   # automatic count via Bai-Ng ICp2, clamped to <= 10 (MC-validated at T~33; see FactorSelectionSim.jl)
    tag           = " real_estate economy",
)
# Component columns live in the regenerated PSID_new/SCF_new files (canonical
# PSID.csv/SCF.csv predate the component export) -- swapped in as in new_data.
const obs_data = ObservedData(
    files = merge(retrieve_data_files(), Dict(
        "PSID" => joinpath(DATA_PROCESSING, "PSID_new.csv"),
        "SCF"  => joinpath(DATA_PROCESSING, "SCF_new.csv"),
    )),
)
