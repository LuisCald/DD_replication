# ─────────────────────────────────────────────────────────────────────────────
# Robustness run: 6 distributional factors (baseline keeps 8).
# Run with:   DD_EXAMPLE=6_factors julia run_estimation.jl
# Feeds the factor-count robustness / MDD comparison (Table: marginal data
# densities across factor counts, MDD.jl) together with 7_factors and the
# baseline. Everything else identical to the published baseline.
# ─────────────────────────────────────────────────────────────────────────────
const model_options = ModelOptions(
    number_of_dfs = 6,
    tag           = " 6 factors",
)
const obs_data = ObservedData()
