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
    # HANK runs use QUINTILE integration grids (the replica moment targets are
    # quintile bin means; polynomial orders unchanged from the baseline) —
    # matches the historic HANK config and the grid_choice == 5 branch of the
    # interval series ("bottom40" / "next40" / "top20").
    estimator = SeriesEstimator(
        grid_pcf = 11 + 1,
        grid_cop = 11 + 1,
        integral_pcf_grid = 5,
        integral_cop_grid = 5,
    ),
)

# ── Aggregate inputs: realized shock-STATE paths, stationarized on load ──────
# The application feeds the model stationary aggregate transforms (FRED series
# through make_stationary; Data appendix: ADF at α = 0.05). The replica mirrors
# that information structure: the shocks CSV carries the persistent AR(1) state
# paths (BASE commit 6b8c9b2 — plain <sym> columns replaced the ε_<sym>
# innovation draws), and each series is differenced until an ADF test rejects a
# unit root (max 2). Near-unit-root shocks (Z, ρ=0.998) thus enter ≈ as their
# innovations while moderately persistent shocks (μ, μw, Rshock, ZI, Sshock)
# enter in levels — the same mixed outcome the empirical aggregates exhibit.
function _stationarize_states(df::DataFrame)
    out = copy(df)
    any(startswith.(names(out), "ε")) &&
        @warn "shocks CSV still holds innovation (ε_*) columns — regenerate with BASE ≥ 6b8c9b2 to get state paths"
    for c in names(out)
        c in ("date", "time", "year", "quarter") && continue
        x = Float64.(out[!, c])
        d = 0
        pv = NaN
        while d < 2
            pv = pvalue(ADFTest(x, :constant, 4))
            pv <= 0.05 && break
            x = vcat(0.0, diff(x))   # prepend 0 to preserve time alignment
            d += 1
        end
        out[!, c] = x
        @info "HANK aggregates: $(c) enters with $(d) difference(s) (ADF p = $(round(pv; digits = 3)))"
    end
    return out
end

const obs_data = ObservedData(
    files = Dict(
        "HANK a $(HANK_ECON)" => joinpath(DATA_PROCESSING, "HANK_PSID_$(HANK_ECON).csv"),
        "HANK b $(HANK_ECON)" => joinpath(DATA_PROCESSING, "HANK_CPS_$(HANK_ECON).csv"),
        "HANK c $(HANK_ECON)" => joinpath(DATA_PROCESSING, "HANK_CEX_$(HANK_ECON).csv"),
        "HANK d $(HANK_ECON)" => joinpath(DATA_PROCESSING, "HANK_SCF_$(HANK_ECON).csv"),
        "HANK e $(HANK_ECON)" => joinpath(DATA_PROCESSING, "HANK_SIPP_$(HANK_ECON).csv"),
    ),
    # agg_data = CSV.read(joinpath(DATA_PROCESSING, "HANK_shocks_economy_$(HANK_ECON).csv"), DataFrame),
    agg_data = _stationarize_states(
        CSV.read(
            joinpath(DATA_PROCESSING, "HANK_shocks_economy_$(HANK_ECON).csv"),
            DataFrame,
        ),
    ),
    gdp_series = CSV.read(
        joinpath(DATA_PROCESSING, "HANK_truth_$(HANK_ECON).csv"),
        DataFrame,
    ),
)
