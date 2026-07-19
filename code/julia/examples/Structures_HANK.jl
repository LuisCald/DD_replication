# ─────────────────────────────────────────────────────────────────────────────
# Example experiment: HANK VALIDATION EXERCISE (survey replicas a–e)
#
# Run with:   DD_EXAMPLE=HANK HANK_ECON=1 julia run_estimation.jl
#
# Estimates the DD model on model-generated survey replicas from the
# BASEtoolbox HANK economy (examples/baseline_micro/generate_HANK_micro.jl),
# one economy per run:
#
#   HANK a N — PSID replica  (consum/income/wealth, stride 8)
#   HANK b N — CPS replica   (income, annual)
#   HANK c N — CEX replica   (consum/income, quarterly)
#   HANK d N — SCF replica   (income/wealth, triennial, wealth-stratified)
#   HANK e N — SIPP replica  (income quarterly, wealth Q4-only; single
#                             survey, no era split — sample E)
#
# The economy's shock series stand in for the aggregate data, and the truth
# per-household means replace the empirical aggregate correction series.
# HANK replicas are never seasonally adjusted (the model has no seasonal
# component) and their interval/noise caches are keyed by the dataset name
# (e.g. "HANK a 3"), so economies don't collide.
# ─────────────────────────────────────────────────────────────────────────────

const HANK_ECON = get(ENV, "HANK_ECON", "1")
@info "HANK exercise: economy $(HANK_ECON)"

const model_options = ModelOptions(
    tag = " HANK $(HANK_ECON)",
    number_of_dfs = 5,   # five replica datasets (a–e)
)

const obs_data = ObservedData(
    files = Dict(
        "HANK a $(HANK_ECON)" => joinpath(DATA_PROCESSING, "HANK_PSID_$(HANK_ECON).csv"),
        "HANK b $(HANK_ECON)" => joinpath(DATA_PROCESSING, "HANK_CPS_$(HANK_ECON).csv"),
        "HANK c $(HANK_ECON)" => joinpath(DATA_PROCESSING, "HANK_CEX_$(HANK_ECON).csv"),
        "HANK d $(HANK_ECON)" => joinpath(DATA_PROCESSING, "HANK_SCF_$(HANK_ECON).csv"),
        "HANK e $(HANK_ECON)" => joinpath(DATA_PROCESSING, "HANK_SIPP_$(HANK_ECON).csv"),
    ),
    agg_data = CSV.read(
        joinpath(DATA_PROCESSING, "HANK_shocks_economy_$(HANK_ECON).csv"),
        DataFrame,
    ),
    gdp_series = CSV.read(
        joinpath(DATA_PROCESSING, "HANK_truth_$(HANK_ECON).csv"),
        DataFrame,
    ),
)
