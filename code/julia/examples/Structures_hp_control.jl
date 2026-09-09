# ─────────────────────────────────────────────────────────────────────────────
# CONTROL for the stochastic-trend smoke run (S5).
#
# Run with:   DD_EXAMPLE=hp_control julia run_estimation.jl
#
# Identical to examples/Structures_stochastic_trend.jl in every respect
# (PSID + SCF only, Bai–Ng factor count, same tag family) EXCEPT the trend
# spec, which is the published baseline HP detrending. Purpose: the first
# :stochastic smoke produced white-noise-like distributional factors
# (Ω_f sd 0.6–1.85 vs 0.2–0.9 in the baseline mode; ±8σ swings around the
# 2020–21 waves). That can be the spec OR the smoke config (10 factors from a
# 12-column pool; no quarterly survey pins f_t between annual waves). This
# run isolates the spec: same config, HP trend. Compare
# from_mcmc/data/smoothed_factors.csv and the mode vector with
# st_posterior_summary.jl / the ad-hoc profile.
# ─────────────────────────────────────────────────────────────────────────────

const model_options = ModelOptions(
    trend_spec       = :hp,          # published baseline detrending
    factor_selection = :fixed,       # same retention as the :stochastic smoke
    n_dist_factors   = 6,
    tag              = " hp control PSID SCF",
)

const obs_data = ObservedData(
    files = Dict(
        "PSID" => joinpath(DATA_PROCESSING, "PSID.csv"),
        "SCF"  => joinpath(DATA_PROCESSING, "SCF.csv"),
    ),
)
