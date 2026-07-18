# ─────────────────────────────────────────────────────────────────────────────
# Example experiment: BASELINE MODEL ON THE REGENERATED SURVEY FILES
#
# Run with:   DD_EXAMPLE=new_data julia run_estimation.jl
#
# Identical specification to the published baseline (consum/income/wealth,
# 8 distributional factors, default estimator/priors) — only the PSID and SCF
# inputs are swapped for the regenerated files:
#
#   PSID_new.csv  — from PSID_nogrowth.xlsx via GrowthCorrection.jl
#                   (income/consumption grown to the wealth date; carries the
#                   balance-sheet components; trim applied to flows only)
#   SCF_new.csv   — from SCF_noForbes_nogrowth.xlsx via GrowthCorrection.jl +
#                   generateForbes400.py (2022 wave with components; refreshed
#                   Forbes 400 splice with the cached 2021–2024 scrape)
#
# The original PSID.csv / SCF.csv stay untouched, so results under this tag
# are directly comparable to the published baseline run. All other surveys
# (CEX, CPS, SIPP1–3) and the aggregate workbook are the baseline files.
#
# Outputs land under 7_Results/<measures> new data/ and the posterior draws
# under posterior_draws/<measures>_ new data.jld2.
# ─────────────────────────────────────────────────────────────────────────────

const model_options = ModelOptions(
    tag = " new data",
)

const obs_data = ObservedData(
    files = merge(retrieve_data_files(), Dict(
        "PSID" => joinpath(DATA_PROCESSING, "PSID_new.csv"),
        "SCF"  => joinpath(DATA_PROCESSING, "SCF_new.csv"),
    )),
)
