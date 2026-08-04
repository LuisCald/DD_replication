# DFA balance-sheet component economy: UNINCORPORATED BUSINESS.  Run: DD_EXAMPLE=business julia run_estimation.jl
# Joint (income, wealth, business). Micro: business = ffabus (SCF) at survey date like wealth.
# Aggregate anchor: business_per_hh (BOGZ1LM152090205Q, proprietors' equity in noncorporate
# business). Large atom (most households own no business). See doc/stocks_atom_design.md.
const model_options = ModelOptions(
    measures      = sort(["income", "wealth", "business"]),
    atom_measures = ["business"],
    factor_selection = :bai_ng,   # automatic count via Bai-Ng ICp2, clamped to <= 10 (MC-validated at T~33; see FactorSelectionSim.jl)
    tag           = " business economy",
)
# Component columns live in the regenerated PSID_new/SCF_new files (canonical
# PSID.csv/SCF.csv predate the component export) -- swapped in as in new_data.
const obs_data = ObservedData(
    files = merge(retrieve_data_files(), Dict(
        "PSID" => joinpath(DATA_PROCESSING, "PSID_new.csv"),
        "SCF"  => joinpath(DATA_PROCESSING, "SCF_new.csv"),
    )),
)
