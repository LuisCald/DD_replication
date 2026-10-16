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
#   DD_TREND   stochastic (default) | hp — trend handling. hp = the per-coefficient HP
#              filter of the published model (removed before estimation, re-added at
#              reconstruction); the REPLICATION release uses hp (Structures_replication.jl).
#   DD_TAG     extra tag suffix (default "")
#   DD_AGG_SHEET   aggregates sheet in aggregates_HHs_NPs.xlsx (default stationary_series_infl:
#                  FRED-QD published codes with prices as INFLATION, built by
#                  code/python/make_stationary_fredqd.py; "stationary_series" = the published
#                  sheet with prices as changes in inflation). Tag suffix " infl".
#   DD_AGG_XCOVID  1 (default) = fit the aggregate PCA loadings without 2020Q1–2021Q1 and
#                  project all quarters (ModelOptions.aggregate_pca_exclude); 0 = published
#                  behaviour. Tag suffix " xcovid".
#   Both address the near-white aggregate factors of run #1 (doc/aggregates_diagnostic.pdf).
#   DD_NAF     aggregate factor count (default 0 = the pinned 11). Tag suffix " <k> af".
#   DD_TW      Tall–Wide loadings at this variance ratio (default 0 = PCA). Tag suffix " tw<r>".
#   DD_MUTE    cex_every_4_years | no_recent_20q | no_housing_wealth — the paper's data-removal
#              robustness runs (same muting as the old examples). Tag suffix " every 4 years" /
#              " excluding recent 20 quarters" / " excluding housing cycle wealth".
#   DD_ITEM    a balance-sheet item (stocks, real_estate, business, pension, hdebt, pdebt, liquid):
#              measures become (income, wealth, <item>), DFA-style; DD_ATOM=1 (default) treats the
#              item as semicontinuous (atom at zero, atom_measures). Tag suffix " <item> economy".
#   DD_MEASURES comma list overriding the measure set (e.g. income,wealth): used by
#              run_proof_of_concept.jl for the SCF (Y,W) and CEX (C,Y) proof-of-concept panels.
#   DD_COMPARE 1 = compare to the robustness runs in post-estimation (compare_to_other_est).
#   These serve the paper's robustness/MDD runs (examples/Structures_replication_*.jl).
#
# The tag encodes every switch so results never overwrite another spec's folder.
# Everything not set here falls back to the published baseline (Structures.jl).
# ─────────────────────────────────────────────────────────────────────────────

const TR_NDF    = parse(Int, get(ENV, "DD_NDF", "5"))
const TR_WRIDGE = parse(Float64, get(ENV, "DD_WRIDGE", "0"))
const TR_PCA    = Symbol(get(ENV, "DD_PCA", "em"))
const TR_TREND  = Symbol(get(ENV, "DD_TREND", "stochastic"))
TR_TREND in (:stochastic, :hp) || error("DD_TREND must be 'stochastic' or 'hp'")
TR_PCA in (:complete_cases, :em, :kalman_em) || error("DD_PCA must be 'complete_cases', 'em' or 'kalman_em'")
TR_NDF >= 1 || error("DD_NDF must be ≥ 1")

const TR_AGG_SHEET = get(ENV, "DD_AGG_SHEET", "stationary_series_infl")
const TR_XCOVID    = get(ENV, "DD_AGG_XCOVID", "1") == "1"
const TR_AGG_EXCL  = TR_XCOVID ? ["2020-Q1", "2020-Q2", "2020-Q3", "2020-Q4", "2021-Q1"] : String[]

const TR_NAF  = parse(Int, get(ENV, "DD_NAF", "0"))
const TR_TW   = parse(Float64, get(ENV, "DD_TW", "0"))
const TR_MUTE = get(ENV, "DD_MUTE", "")
# DD_PERS_AGG=1 (Oct 2026): persistence_prior = :per_factor_agg — one persistence target ρ_Y,k per AGGREGATE
#   factor as well (H block r+5 → r+q+4); tag " pfa" instead of " pf". Default 0 = the published :per_factor spec.
const TR_PERS_AGG = get(ENV, "DD_PERS_AGG", "0") == "1"
# DD_CONSENSUS=inv_me_sd: weight the cross-dataset consensus by inverse measurement-error SDs
#   (post-estimation only; default "equal" = the plain average).
const TR_CONSENSUS = get(ENV, "DD_CONSENSUS", "equal") == "inv_me_sd" ? :inv_me_sd : :equal
const TR_MUTE_SPEC = Dict(
    "" => ("", Dict("begin" => "", "end" => "")),
    "cex_every_4_years" => (" every 4 years",
        Dict("CEX" => muted_quarters_between(QuarterlyDate(1984, 1), QuarterlyDate(2021, 4)))),
    "no_recent_20q" => (" excluding recent 20 quarters",
        Dict("begin" => QuarterlyDate(2020, 1), "end" => QuarterlyDate(2024, 1))),
    "no_housing_wealth" => (" excluding housing cycle wealth",
        Dict("begin" => QuarterlyDate(2004, 1), "end" => QuarterlyDate(2009, 4))),
)
haskey(TR_MUTE_SPEC, TR_MUTE) || error("DD_MUTE must be one of $(join(filter(!isempty, collect(keys(TR_MUTE_SPEC))), ", "))")

const TR_ITEM = get(ENV, "DD_ITEM", "")
const TR_ATOM = get(ENV, "DD_ATOM", "1") == "1"
const TR_MEAS_ENV = get(ENV, "DD_MEASURES", "")   # e.g. "income,wealth" (SCF) or "consum,income" (CEX): proof-of-concept panels
const TR_MEASURES = !isempty(TR_ITEM) ? sort(["income", "wealth", TR_ITEM]) :
                    !isempty(TR_MEAS_ENV) ? sort(String.(strip.(split(TR_MEAS_ENV, ",")))) :
                    sort(["consum", "income", "wealth"])

const TR_TAG = " transfer" * (TR_TREND == :stochastic ? " stochastic trend" : " hp") * " $(TR_NDF) factors pf" * (TR_PERS_AGG ? "a" : "") *
               (TR_PCA == :em ? " em" : TR_PCA == :kalman_em ? " em kem" : "") *
               (TR_WRIDGE > 0 ? " wr$(TR_WRIDGE)" : "") *
               (TR_AGG_SHEET == "stationary_series_infl" ? " infl" : TR_AGG_SHEET == "stationary_series" ? "" : " $(TR_AGG_SHEET)") *
               (TR_XCOVID ? " xcovid" : "") *
               (TR_NAF > 0 ? " $(TR_NAF) af" : "") *
               (TR_TW > 0 ? " tw$(TR_TW)" : "") *
               TR_MUTE_SPEC[TR_MUTE][1] *
               (isempty(TR_ITEM) ? "" : " $(TR_ITEM) economy") *
               (isempty(TR_MEAS_ENV) || !isempty(TR_ITEM) ? "" : " " * join(TR_MEASURES, "_")) *
               get(ENV, "DD_TAG", "")

@info "TRANSFER spec: $(TR_NDF) distributional factors, per-factor persistence, joint cap 0.995, $(TR_TREND) trend, " *
      "pca $(TR_PCA), whitening ridge $(TR_WRIDGE)$(TR_WRIDGE == 0 ? " (published whitening — read cond(Σ̂) in the prep log before deciding)" : "")"
@info "  aggregates: sheet $(TR_AGG_SHEET); PCA loadings fit " * (TR_XCOVID ? "EXCLUDING 2020Q1–2021Q1 (all quarters projected)" : "on all quarters")
(TR_NAF > 0 || TR_TW > 0 || !isempty(TR_MUTE)) &&
    @info "  variant: aggregate factors $(TR_NAF > 0 ? TR_NAF : "pinned (11)"), Tall–Wide $(TR_TW > 0 ? TR_TW : "off"), muting $(isempty(TR_MUTE) ? "none" : TR_MUTE)"
@info "  tag: $(repr(TR_TAG))"

const model_options = ModelOptions(
    trend_spec        = TR_TREND,
    trend_lambda_scale = 0.1,
    persistence_prior = TR_PERS_AGG ? :per_factor_agg : :per_factor,
    consensus_weights = TR_CONSENSUS,
    stationarity_cap  = 0.995,
    factor_selection  = :fixed,
    n_dist_factors    = TR_NDF,
    pca_method        = TR_PCA,
    em_unit_scores    = true,
    whitening_ridge   = TR_WRIDGE,
    aggregate_pca_exclude = TR_AGG_EXCL,
    n_agg_factors     = TR_NAF,
    tw_ratio          = TR_TW,
    data_to_mute      = TR_MUTE_SPEC[TR_MUTE][2],
    measures          = TR_MEASURES,
    atom_measures     = (isempty(TR_ITEM) || !TR_ATOM) ? String[] : [TR_ITEM],
    compare_to_other_est = get(ENV, "DD_COMPARE", "0") == "1",   # post-estimation: compare to the robustness runs (recon_missing2, corr_outsample)
    # cross_conditional_shares = [0.4, 0.4, 0.2] is the ModelOptions default
    tag               = TR_TAG,
)

# The paper's data: all eight surveys (retrieve_data_files) and the per-household
# means (rgdp) are the defaults; the aggregates sheet is selectable (DD_AGG_SHEET).
const obs_data = ObservedData(agg_data = retrieve_aggregate_data(TR_AGG_SHEET))
