# ─────────────────────────────────────────────────────────────────────────────
# Example experiment: STOCHASTIC TRENDS in the state space
#
# Run with:   DD_EXAMPLE=stochastic_trend julia run_estimation.jl
#
# Replaces the deterministic per-dataset HP trend (removed in ModelPrep,
# re-added at reconstruction with zero attributed uncertainty) with Ndim
# random-walk trend states filtered alongside the factors: trend gets
# uncertainty bands and enters the information decomposition. Motivation and
# full design: doc/stochastic_trend_design.md — the deterministic trend
# carries 58–100% of the recession-figure features and fabricated the Covid
# asset-rich/low-income climb (HP endpoint bias; contradicted by the raw
# 2019/2021 PSID waves).
#
# STATUS: S1 (this spec surface) landed; core wiring S2–S4 pending —
# estimation_prep errors with a pointer to the design doc until then, so this
# example cannot silently run as the baseline.
#
# Everything not set here falls back to the published baseline defaults in
# ModelOptions (see Structures.jl).
# ─────────────────────────────────────────────────────────────────────────────

const model_options = ModelOptions(
    trend_spec = :stochastic,
    tag        = " stochastic trend",
)

const obs_data = ObservedData()
