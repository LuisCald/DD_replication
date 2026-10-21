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
#   DD_AGG_MEAS tight (default) | published — prior on the aggregate measurement error (see below).
#   DD_AGG_MODE pca | blocks | targeted, DD_AGG_SPEC — aggregate block construction (AggregateBlocks.jl).
#              Tag suffix " agg-<spec>".
#   DD_MUTE    cex_every_4_years | no_recent_20q | no_housing_wealth — the paper's data-removal
#              robustness runs (same muting as the old examples). Tag suffix " every 4 years" /
#              " excluding recent 20 quarters" / " excluding housing cycle wealth".
#   DD_ITEM    a balance-sheet item (stocks, real_estate, business, pension, hdebt, pdebt, liquid):
#              measures become (income, wealth, <item>), DFA-style; DD_ATOM=1 (default) treats the
#              item as semicontinuous (atom at zero, atom_measures). Tag suffix " <item> economy".
#   DD_MEASURES comma list overriding the measure set (e.g. income,wealth): used by
#              run_proof_of_concept.jl for the SCF (Y,W) and CEX (C,Y) proof-of-concept panels.
#   DD_LIQUIDITY 1 = the liquidity products (with DD_MEASURES): consumption × illiquid × liquid
#              (Structures_replication_liquidity.jl), consumption × income × liquid
#              (Structures_replication_liquidity_income.jl) and consumption × gross liquid × debt
#              (Structures_replication_liquidity_gross.jl): PSID/SCF/CEX *_liq.csv files and Z.1 anchors;
#              liquid anchored on its positive part (tag " pos"), debt with the atom treatment.
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
# DD_AGG_MODE / DD_AGG_SPEC (Oct 2026, AggregateBlocks.jl): how the aggregate block is built. pca = published
#   (variance-ranked PCA, default); blocks = one PC per FRED-QD group, orthogonalised (spec b11 / b13 / b11gs / b2x
#   or "1+5,2,…[:gs]"); targeted = PCA on series screened for predicting distributional data (spec = name of
#   aggregate_blocks/targeted_<spec>.csv). Tag suffix " agg-<spec>" (nothing under pca).
const TR_AGG_MODE = Symbol(lowercase(get(ENV, "DD_AGG_MODE", "pca")))
const TR_AGG_SPEC = get(ENV, "DD_AGG_SPEC", "")
# DD_AGG_MEAS (Oct 2026): prior on the aggregate rows' measurement error. tight (default) = the intended 1/2000 prior;
#   published = the prioreval pairing bug that left those entries on the loose survey prior (variance ≈ 1 on unit-variance
#   series), so the smoother absorbed most of the non-persistent aggregate PCs as noise (aggregate_block_diagnostics.jl).
#   Every run before 2026-10-21 is "published". Tag " aggtight" while the comparison is open.
const TR_AGG_MEAS = Symbol(lowercase(get(ENV, "DD_AGG_MEAS", "tight")))
TR_AGG_MEAS in (:published, :tight) || error("DD_AGG_MEAS must be published or tight")
TR_AGG_MODE in (:pca, :blocks, :targeted) || error("DD_AGG_MODE must be pca, blocks or targeted")
(TR_AGG_MODE == :pca || !isempty(TR_AGG_SPEC)) || error("DD_AGG_SPEC is required with DD_AGG_MODE=$(TR_AGG_MODE)")
const TR_AGG_TAG = TR_AGG_MODE == :pca ? "" :
                   " agg-" * replace(lowercase(strip(TR_AGG_SPEC)), "," => "_", "+" => "p", "@" => "x", ":" => "-")
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

# Liquidity products (DD_LIQUIDITY=1, see obs_data below). Net liquid wealth is anchored on its positive
# part (ModelOptions.positive_scale_measures; tag " pos"), consumer debt has a point mass at zero
# (32% of SCF, 55% of PSID households) and gets the atom treatment, with its share of zeros carried in the
# state (participation_in_state; tag " pis") so the model tracks it quarterly.
const TR_LIQUIDITY = get(ENV, "DD_LIQUIDITY", "0") == "1"
const TR_POSSCALE  = TR_LIQUIDITY && "liquid" in TR_MEASURES
const TR_DEBT_ATOM = TR_LIQUIDITY && "debt" in TR_MEASURES
# Illiquid wealth has a point mass at zero at the bottom too (8% of SCF, 13% of PSID households; almost no
# negatives), so it gets the atom treatment in consumption × illiquid × liquid (Oct 18). Liquid does not: its
# zeros sit inside the distribution (30–44% are negative), a flat stretch that rearrangement handles. One atom
# measure per model for now (DD_replication issue #1), so debt and illiquid never share a product.
# Debt products (Oct 18): total debt (29% of SCF, 37% of PSID households have none) and mortgage debt (60%, 62%)
# get the same treatment. Total assets have no atom: 4–7% exact zeros at the bottom, a flat stretch for rearrangement.
const TR_LIQ_ATOMS = TR_LIQUIDITY ? intersect(["debt", "illiquid", "totdebt", "mortdebt"], TR_MEASURES) : String[]
length(TR_LIQ_ATOMS) <= 1 || error("only one atom measure per model is supported (issue #1): $(TR_LIQ_ATOMS)")
# Known lower bound (Oct 19): gross liquid assets, total assets and illiquid wealth are >= 0, but without the atom
# treatment the smooth fit dips below zero in the bottom decile (2-19% of households at or near zero). Their quantile
# functions are cut at 0 in the reconstruction (ModelOptions.nonnegative_measures; no re-estimation needed).
const TR_NONNEG = TR_LIQUIDITY ? setdiff(intersect(["grossliq", "totassets", "illiquid"], TR_MEASURES), TR_LIQ_ATOMS) : String[]
# Zero share carried in the state (participation_in_state; tag " pis") for the atom measures of the liquidity and
# debt products and for the stocks item (re-estimated Oct 18). The other DFA items (real estate, mortgages,
# consumer credit, pensions) keep the published treatment (share interpolated between SCF waves outside the
# model) until they are re-estimated, so their configs reproduce DD_data. DD_PIS=0 / DD_PIS=1 override.
const TR_NEW_ITEM = !isempty(TR_ITEM) && TR_ATOM && TR_ITEM == "stocks"
const TR_PIS = get(ENV, "DD_PIS", (!isempty(TR_LIQ_ATOMS) || TR_NEW_ITEM) ? "1" : "0") == "1" &&
               (!isempty(TR_LIQ_ATOMS) || (!isempty(TR_ITEM) && TR_ATOM))

const TR_TAG = " transfer" * (TR_TREND == :stochastic ? " stochastic trend" : " hp") * " $(TR_NDF) factors pf" * (TR_PERS_AGG ? "a" : "") *
               (TR_PCA == :em ? " em" : TR_PCA == :kalman_em ? " em kem" : "") *
               (TR_WRIDGE > 0 ? " wr$(TR_WRIDGE)" : "") *
               (TR_AGG_SHEET == "stationary_series_infl" ? " infl" : TR_AGG_SHEET == "stationary_series" ? "" : " $(TR_AGG_SHEET)") *
               (TR_XCOVID ? " xcovid" : "") *
               (TR_NAF > 0 ? " $(TR_NAF) af" : "") *
               (TR_TW > 0 ? " tw$(TR_TW)" : "") *
               TR_AGG_TAG * (TR_AGG_MEAS == :tight ? " aggtight" : "") *
               TR_MUTE_SPEC[TR_MUTE][1] *
               (isempty(TR_ITEM) ? "" : " $(TR_ITEM) economy") *
               (isempty(TR_MEAS_ENV) || !isempty(TR_ITEM) ? "" : " " * join(TR_MEASURES, "_")) *
               (TR_POSSCALE ? " pos" : "") *
               (TR_PIS ? " pis" : "") *
               get(ENV, "DD_TAG", "")

@info "TRANSFER spec: $(TR_NDF) distributional factors, per-factor persistence, joint cap 0.995, $(TR_TREND) trend, " *
      "pca $(TR_PCA), whitening ridge $(TR_WRIDGE)$(TR_WRIDGE == 0 ? " (published whitening — read cond(Σ̂) in the prep log before deciding)" : "")"
@info "  aggregates: sheet $(TR_AGG_SHEET); PCA loadings fit " * (TR_XCOVID ? "EXCLUDING 2020Q1–2021Q1 (all quarters projected)" : "on all quarters")
(TR_NAF > 0 || TR_TW > 0 || !isempty(TR_MUTE) || TR_AGG_MODE != :pca) &&
    @info "  variant: aggregate factors $(TR_NAF > 0 ? TR_NAF : "pinned (11)"), Tall–Wide $(TR_TW > 0 ? TR_TW : "off"), muting $(isempty(TR_MUTE) ? "none" : TR_MUTE), aggregate block $(TR_AGG_MODE)$(TR_AGG_MODE == :pca ? "" : " " * repr(TR_AGG_SPEC))"
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
    agg_mode          = TR_AGG_MODE,
    agg_spec          = TR_AGG_SPEC,
    agg_meas_prior    = TR_AGG_MEAS,
    data_to_mute      = TR_MUTE_SPEC[TR_MUTE][2],
    measures          = TR_MEASURES,
    atom_measures     = !isempty(TR_LIQ_ATOMS) ? TR_LIQ_ATOMS : (isempty(TR_ITEM) || !TR_ATOM) ? String[] : [TR_ITEM],
    positive_scale_measures = TR_POSSCALE ? ["liquid"] : String[],
    nonnegative_measures    = TR_NONNEG,      # reconstruction only: quantile functions cut at 0
    rearrange_quantiles     = TR_LIQUIDITY || TR_NEW_ITEM,   # liquidity/debt products and the stocks item: rearrange non-monotone quantile functions (flat regions, zero mass); reconstruction only. Other items: published behavior
    participation_in_state  = TR_PIS,         # zero share observed and tracked quarterly by the model (tag " pis")
    compare_to_other_est = get(ENV, "DD_COMPARE", "0") == "1",   # post-estimation: compare to the robustness runs (recon_missing2, corr_outsample)
    # cross_conditional_shares = [0.4, 0.4, 0.2] is the ModelOptions default
    tag               = TR_TAG,
)

# The paper's data: all eight surveys (retrieve_data_files) and the per-household
# means (rgdp) are the defaults; the aggregates sheet is selectable (DD_AGG_SHEET).
# DD_LIQUIDITY=1 (Oct 2026; examples/Structures_replication_liquidity.jl): the second data product,
# consumption × illiquid × liquid. Surveys PSID, SCF, CEX from {SCF,PSID,CEX}_liq.csv
# (code/python/make_liquidity_data.py: liquid = net liquid + stocks/mutual funds, Kaplan–Violante
# style; illiquid = net real estate + bonds + life insurance + vehicles + business, no pensions).
# Anchors from the Z.1 series already in the workbook:
#   liquid_per_hh   = deposits + Treasury securities + equities/mutual funds − consumer credit
#   illiquid_per_hh = real estate − home mortgages + noncorporate business
#   grossliq_per_hh = deposits + Treasury securities + equities/mutual funds
#   debt_per_hh     = consumer credit
#   mortdebt_per_hh = home mortgages;   totdebt_per_hh = home mortgages + consumer credit
#   totassets_per_hh = net worth + totdebt_per_hh (so assets − debt matches the CIW wealth anchor)
function liquidity_anchors()
    a = retrieve_rgdp()
    a[!, "grossliq_per_hh"] = a.liquid_per_hh .+ a.stocks_per_hh
    a[!, "debt_per_hh"]     = a.pdebt_per_hh
    a[!, "liquid_per_hh"]   = a.liquid_per_hh .+ a.stocks_per_hh .- a.pdebt_per_hh
    a[!, "illiquid_per_hh"] = a.real_estate_per_hh .- a.hdebt_per_hh .+ a.business_per_hh
    a[!, "mortdebt_per_hh"] = a.hdebt_per_hh
    a[!, "totdebt_per_hh"]  = a.hdebt_per_hh .+ a.pdebt_per_hh
    a[!, "totassets_per_hh"] = a.wealth_per_hh .+ a.totdebt_per_hh   # assets − debt = the CIW wealth anchor
    return a
end
# With income in the measure set (consumption × income × liquid, Structures_replication_liquidity_income.jl)
# the income-only surveys CPS, CPS2 and SIPP1–3 enter as in the paper; otherwise only PSID, SCF, CEX.
function liquidity_files()
    f = retrieve_data_files()
    "income" in TR_MEASURES || filter!(kv -> kv.first in ("SCF", "PSID", "CEX"), f)
    for k in ("SCF", "PSID", "CEX")
        f[k] = joinpath(DATA_PROCESSING, "$(k)_liq.csv")
    end
    return f
end
const obs_data = TR_LIQUIDITY ?
    ObservedData(files = liquidity_files(), gdp_series = liquidity_anchors(), agg_data = retrieve_aggregate_data(TR_AGG_SHEET)) :
    ObservedData(agg_data = retrieve_aggregate_data(TR_AGG_SHEET))
