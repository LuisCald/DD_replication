# ─────────────────────────────────────────────────────────────────────────────
# Example experiment: HANK VALIDATION EXERCISE (survey replicas a–e)
#
# Run with:   DD_EXAMPLE=HANK HANK_ECON=1 julia run_estimation.jl
#             DD_EXAMPLE=HANK HANK_ECON=1 HANK_TREND=stochastic julia run_estimation.jl
#             DD_EXAMPLE=HANK HANK_ECON=1 HANK_TREND=stochastic HANK_NDF=5 julia run_estimation.jl
#             DD_EXAMPLE=HANK HANK_ECON=1 HANK_TREND=stochastic HANK_NDF=5 HANK_PERS=per_factor julia run_estimation.jl
#
# HANK_PERS=per_factor estimates one factor-persistence target per factor
# (H block r+5; smooth default rho~0.9 where the data are silent) and
# suffixes the tag with " pf". Default: the baseline single shared target.
#
# HANK_NDF=k pins the distributional factor count to k (default: the HANK
# tag pin, 8, matching the empirical baseline) and suffixes the tag with
# " k factors". The aggregate count stays at the HANK pin (8).
#
# HANK_TREND=stochastic swaps the baseline HP detrending for the stochastic
# trend states (doc/stochastic_trend_design.md) and suffixes the tag. The
# truth has no operationalization drift, so the S5 expectation is that the
# ω_τ shrink toward zero and the truth-vs-estimate fit is at least as good as
# under HP — the "can the model represent the truth" test for the new spec.
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
const HANK_TREND = Symbol(get(ENV, "HANK_TREND", "hp"))
HANK_TREND in (:hp, :stochastic) || error("HANK_TREND must be 'hp' or 'stochastic', got $(HANK_TREND)")
const HANK_NDF = parse(Int, get(ENV, "HANK_NDF", "0"))   # 0 = HANK tag pin (8 factors)
0 <= HANK_NDF <= 10 || error("HANK_NDF must be in 1:10 (or 0 for the default pin), got $(HANK_NDF)")
const HANK_PERS = Symbol(get(ENV, "HANK_PERS", "common"))
HANK_PERS in (:common, :per_factor) || error("HANK_PERS must be 'common' or 'per_factor', got $(HANK_PERS)")
const HANK_TLS = parse(Float64, get(ENV, "HANK_TLS", "0.1"))   # trend λ prior scale (stochastic spec)
0 < HANK_TLS <= 1 || error("HANK_TLS must be in (0, 1], got $(HANK_TLS)")
const HANK_NAF = parse(Int, get(ENV, "HANK_NAF", "0"))   # 0 = HANK pin (8 aggregate factors)
0 <= HANK_NAF <= 9 || error("HANK_NAF must be in 1:9 (or 0 for the pin), got $(HANK_NAF)")
# ── copula-identification experiments (doc/copula_identification.tex) ────────
const HANK_COPERR = Symbol(get(ENV, "HANK_COPERR", "pooled"))   # Fix 1: :pooled | :communality
HANK_COPERR in (:pooled, :communality) || error("HANK_COPERR must be 'pooled' or 'communality'")
const HANK_PCA = Symbol(get(ENV, "HANK_PCA", "complete_cases")) # Fix 2: :complete_cases | :em
HANK_PCA in (:complete_cases, :em) || error("HANK_PCA must be 'complete_cases' or 'em'")
const HANK_NCF = parse(Int, get(ENV, "HANK_NCF", "0"))          # Fix 3: copula-specific factors
0 <= HANK_NCF <= 5 || error("HANK_NCF must be in 0:5, got $(HANK_NCF)")
const HANK_GRID = parse(Int, get(ENV, "HANK_GRID", "5"))        # Fix 4: integration grid (5 = quintile pin, 10 = empirical)
HANK_GRID in (5, 10) || error("HANK_GRID must be 5 or 10, got $(HANK_GRID)")
@info "HANK exercise: economy $(HANK_ECON), trend spec $(HANK_TREND), distributional factors $(HANK_NDF == 0 ? "8 (tag pin)" : string(HANK_NDF)), persistence $(HANK_PERS)"
@info "  copula experiments: error $(HANK_COPERR), pca $(HANK_PCA), copula factors $(HANK_NCF), integration grid $(HANK_GRID)"

const model_options = ModelOptions(
    tag = " HANK $(HANK_ECON)" * (HANK_TREND == :stochastic ? " stochastic trend" : "") *
          (HANK_NDF > 0 ? " $(HANK_NDF) factors" : "") * (HANK_PERS == :per_factor ? " pf" : "") *
          (HANK_TLS == 0.1 ? "" : " tls$(HANK_TLS)") * (HANK_NAF > 0 ? " naf$(HANK_NAF)" : "") *
          (HANK_COPERR == :communality ? " cw" : "") * (HANK_PCA == :em ? " em" : "") *
          (HANK_NCF > 0 ? " ncf$(HANK_NCF)" : "") * (HANK_GRID == 5 ? "" : " g$(HANK_GRID)"),
    trend_spec = HANK_TREND,
    persistence_prior = HANK_PERS,
    trend_lambda_scale = HANK_TLS,
    n_agg_factors = HANK_NAF,
    # pf's high ρ targets let A go explosive (|eig| 1.38, 5f pf run) — cap it.
    stationarity_cap = HANK_PERS == :per_factor ? 0.995 : Inf,
    factor_selection = HANK_NDF > 0 ? :fixed : :pratio,
    n_dist_factors   = HANK_NDF > 0 ? HANK_NDF : 8,
    # HANK runs use QUINTILE integration grids (the replica moment targets are
    # quintile bin means; polynomial orders unchanged from the baseline) —
    # matches the historic HANK config and the grid_choice == 5 branch of the
    # interval series ("bottom40" / "next40" / "top20").
    estimator = SeriesEstimator(
        grid_pcf = 11 + 1,
        grid_cop = 11 + 1,
        integral_pcf_grid = HANK_GRID,
        integral_cop_grid = HANK_GRID,
    ),
    copula_error    = HANK_COPERR,
    pca_method      = HANK_PCA,
    n_copula_factors = HANK_NCF,
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
