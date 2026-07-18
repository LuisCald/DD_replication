# ─────────────────────────────────────────────────────────────────────────────
# Robustness run: remove all WEALTH microdata during the housing cycle
# (2004Q1–2009Q4) from every survey, then let the smoother impute it.
# Run with:   DD_EXAMPLE=no_housing_wealth julia run_estimation.jl
# Paper: the "Removing microdata from the housing cycle" panels of the
# reconstruction-robustness figure (SCF_wealth_*_excluding housing cycle
# wealth_*.pdf).
#
# Mechanics (set_measurements in ModelPrep.jl): with a Dict{String,QuarterlyDate}
# "begin"/"end" range AND a tag whose LAST WORD is a measure name, only that
# measure's rows are muted — the tag below ends in "wealth", so wealth rows are
# NaN'd for all datasets over the window. (The old recipe comment suggesting
# Dict("SCF" => muted_quarters_between(...)) does not match any code branch.)
# ─────────────────────────────────────────────────────────────────────────────
const model_options = ModelOptions(
    tag          = " excluding housing cycle wealth",
    data_to_mute = Dict("begin" => QuarterlyDate(2004, 1),
                        "end"   => QuarterlyDate(2009, 4)),
)
const obs_data = ObservedData()
