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
    trend_spec    = :stochastic,
    factor_selection = :fixed,    # pratio saturates the rank-11 pool (12 PSID cols) -> singular priors;
    n_dist_factors   = 6,         # bai_ng ⇒ 10 on a flat spectrum (7.5/7.2/5.8/5.7/5.3/4.9 past factor 4) and
                                  # gave white-noise factors (see doc/stochastic_trend_design.md, S5)
    tag           = " stochastic trend PSID SCF",
)

# S5 smoke config: PSID + SCF only. Both are annual, so the per-draw X-13
# deseasoning loop (the 6-9h sigma grind on the quarterly surveys) is skipped
# almost entirely; consumption is then identified from PSID alone. Restore
# ObservedData() for the full-survey run once S5 passes.
const obs_data = ObservedData(
    files = Dict(
        "PSID" => joinpath(DATA_PROCESSING, "PSID.csv"),
        "SCF"  => joinpath(DATA_PROCESSING, "SCF.csv"),
    ),
)
