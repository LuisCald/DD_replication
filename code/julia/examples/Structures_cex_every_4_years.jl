# ─────────────────────────────────────────────────────────────────────────────
# Robustness run: CEX enters only every 4th year (1984–2021) — the "less data"
# exercise showing the smoother imputing the muted CEX waves.
# Run with:   DD_EXAMPLE=cex_every_4_years julia run_estimation.jl
# Paper: the "less data" panels (a)–(f) of the reconstruction-robustness
# figure. Note: a smoother-side version of this exercise also exists in
# ForecastSSM.perform_forecast (postestimation, baseline parameters); this
# example is the full re-estimation variant matching the " every 4 years" tag.
# Tag contains no measure name → per-dataset branch: the listed CEX quarters
# are muted entirely.
# ─────────────────────────────────────────────────────────────────────────────
const model_options = ModelOptions(
    tag          = " every 4 years",
    data_to_mute = Dict("CEX" => muted_quarters_between(QuarterlyDate(1984, 1),
                                                        QuarterlyDate(2021, 4))),
)
const obs_data = ObservedData()
