# ─────────────────────────────────────────────────────────────────────────────
# Example experiment: THE TRANSFERRED MODEL on the paper's eight surveys
#
# Run with (from the project root):
#   DD_EXAMPLE=transfer julia -t 16 --project=5_Code/code/julia/env 5_Code/code/julia/run_estimation.jl
#
# This is the empirical counterpart of the HANK-validated specification
# (doc/transfer_old_vs_new.tex, doc/hank_campaign_overview.md):
#   • stochastic trend in factor space (trend_spec = :stochastic)
#   • per-factor persistence targets + joint stationarity cap (persistence_prior, stationarity_cap)
#   • loadings by EM completion with unit-variance scores (pca_method = :em, em_unit_scores)
#   • weighted (population) copula ranks — in DataConstructor.jl, always on
#   • cross-conditional cells at 40/40/20 (ModelOptions default), marginals at 50/40/10
#   • optional whitening ridge (DD_WRIDGE), to be set AFTER reading the
#     `whitening <survey>: cond(Σ̂)` lines of a prep-only pass (run_prep.jl)
#
# Environment switches (all optional):
#   DD_NDF     distributional factor count (default 5; HANK: 4 ≈ 5 on the cells the
#              basis carries, 8 over-fits observed dates — doc/hank_campaign_overview.md §8)
#   DD_WRIDGE  whitening ridge λ (default 0 = published whitening; 0.05 = HANK value)
#   DD_PCA     em | kalman_em | complete_cases (default em)
#   DD_TAG     extra tag suffix (default "")
#   DD_AGG_SHEET   aggregates sheet in aggregates_HHs_NPs.xlsx (default stationary_series_infl:
#                  FRED-QD published codes with prices as INFLATION, built by
#                  code/python/make_stationary_fredqd.py; "stationary_series" = the published
#                  sheet with prices as changes in inflation). Tag suffix " infl".
#   DD_AGG_XCOVID  1 (default) = fit the aggregate PCA loadings without 2020Q1–2021Q1 and
#                  project all quarters (ModelOptions.aggregate_pca_exclude); 0 = published
#                  behaviour. Tag suffix " xcovid".
#   Both address the near-white aggregate factors of run #1 (doc/aggregates_diagnostic.pdf).
#
# The tag encodes every switch so results never overwrite another spec's folder.
# Everything not set here falls back to the published baseline (Structures.jl).
# ─────────────────────────────────────────────────────────────────────────────

const TR_NDF    = parse(Int, get(ENV, "DD_NDF", "5"))
const TR_WRIDGE = parse(Float64, get(ENV, "DD_WRIDGE", "0"))
const TR_PCA    = Symbol(get(ENV, "DD_PCA", "em"))
TR_PCA in (:complete_cases, :em, :kalman_em) || error("DD_PCA must be 'complete_cases', 'em' or 'kalman_em'")
TR_NDF >= 1 || error("DD_NDF must be ≥ 1")

const TR_AGG_SHEET = get(ENV, "DD_AGG_SHEET", "stationary_series_infl")
const TR_XCOVID    = get(ENV, "DD_AGG_XCOVID", "1") == "1"
const TR_AGG_EXCL  = TR_XCOVID ? ["2020-Q1", "2020-Q2", "2020-Q3", "2020-Q4", "2021-Q1"] : String[]

const TR_TAG = " transfer stochastic trend $(TR_NDF) factors pf" *
               (TR_PCA == :em ? " em" : TR_PCA == :kalman_em ? " em kem" : "") *
               (TR_WRIDGE > 0 ? " wr$(TR_WRIDGE)" : "") *
               (TR_AGG_SHEET == "stationary_series_infl" ? " infl" : TR_AGG_SHEET == "stationary_series" ? "" : " $(TR_AGG_SHEET)") *
               (TR_XCOVID ? " xcovid" : "") *
               get(ENV, "DD_TAG", "")

@info "TRANSFER spec: $(TR_NDF) distributional factors, per-factor persistence, joint cap 0.995, stochastic trend, " *
      "pca $(TR_PCA), whitening ridge $(TR_WRIDGE)$(TR_WRIDGE == 0 ? " (published whitening — read cond(Σ̂) in the prep log before deciding)" : "")"
@info "  aggregates: sheet $(TR_AGG_SHEET); PCA loadings fit " * (TR_XCOVID ? "EXCLUDING 2020Q1–2021Q1 (all quarters projected)" : "on all quarters")
@info "  tag: $(repr(TR_TAG))"

const model_options = ModelOptions(
    trend_spec        = :stochastic,
    trend_lambda_scale = 0.1,
    persistence_prior = :per_factor,
    stationarity_cap  = 0.995,
    factor_selection  = :fixed,
    n_dist_factors    = TR_NDF,
    pca_method        = TR_PCA,
    em_unit_scores    = true,
    whitening_ridge   = TR_WRIDGE,
    aggregate_pca_exclude = TR_AGG_EXCL,
    # cross_conditional_shares = [0.4, 0.4, 0.2] is the ModelOptions default
    tag               = TR_TAG,
)

# The paper's data: all eight surveys (retrieve_data_files) and the per-household
# means (rgdp) are the defaults; the aggregates sheet is selectable (DD_AGG_SHEET).
const obs_data = ObservedData(agg_data = retrieve_aggregate_data(TR_AGG_SHEET))
