# ─────────────────────────────────────────────────────────────────────────────
# Robustness run: remove ALL microdata in the most recent 20 quarters
# (2020Q1–2024Q1) — the "real-time"/end-of-sample exercise: how do estimates
# look when the smoother must extrapolate the recent period from aggregates?
# Run with:   DD_EXAMPLE=no_recent_20q julia run_estimation.jl
# Paper: SCF_wealth_*_excluding recent 20 quarters_*.pdf panels.
# Tag contains no measure name → the general branch mutes ALL rows (all
# datasets, all objects) over the window.
# ─────────────────────────────────────────────────────────────────────────────
const model_options = ModelOptions(
    tag          = " excluding recent 20 quarters",
    data_to_mute = Dict("begin" => QuarterlyDate(2020, 1),
                        "end"   => QuarterlyDate(2024, 1)),
)
const obs_data = ObservedData()
