# ─────────────────────────────────────────────────────────────────────────────
# aggregate_block_diagnostics.jl — why do the aggregate factors explain so little of the
# distributional factors, and would another aggregate block do better? (Oct 2026)
#
# Tier A (no model objects): from the estimated run's smoothed_factors.csv and the FRED-QD
# panel it (1) checks that select_aggregates reproduces the run's aggregate states,
# (2) builds distributional TARGETS — Real-Time Inequality, DFA, WIDq (external), quarterly
# CEX group means and the CEX coefficient block (the model's own quarterly survey), and the
# run's smoothed f_t (circular: diagnostic only) —, (3) builds CANDIDATE aggregate blocks
# (the published PCA top-11/3/30, one PC per FRED-QD group with Löwdin or Gram–Schmidt
# orthogonalisation, targeted PCA on screened / LASSO-selected series, PLS, forward stepwise
# PCs), (4) scores every candidate on every target: in-sample and purged blocked-CV R²
# (also with one lag of the target, the layout of the Role_Aggregates appendix),
# persistence, principal angles to the published span (the FEVD split only moves if the
# span moves), variance of the 201 series explained. Selections for the in-model runs
# (DD_AGG_MODE=targeted) are written to aggregate_blocks/targeted_<spec>.csv — chosen on
# the EXTERNAL targets only; the CEX targets are the held-out check.
# Tier B (DD_AGGDIAG_MODEL=1): loads the posterior mode and adds the FEVD sensitivity
# (horizon × ordering × identification) and posterior B vs OLS of f_t on [f_{t-1}, a_{t-1}].
#
# Run (Marvin: 5_Code/marvin/aggdiag.sbatch; the spec must match the estimated run):
#   DD_EXAMPLE=replication DD_TAG=" scf22" julia --project=5_Code/code/julia/env 5_Code/code/julia/aggregate_block_diagnostics.jl
# Output: 7_Results/aggregate_blocks/<tag>/ (new folder; nothing in the run folder is touched).
# ─────────────────────────────────────────────────────────────────────────────

include(joinpath(@__DIR__, "DistributionalDynamics.jl"))
using Statistics, LinearAlgebra

const TIER_B = get(ENV, "DD_AGGDIAG_MODEL", "0") == "1"
const DO_CEXCOEF = get(ENV, "DD_AGGDIAG_CEXCOEF", "1") == "1"
const NFOLD = parse(Int, get(ENV, "DD_AGGDIAG_NFOLD", "5"))
const PURGE = parse(Int, get(ENV, "DD_AGGDIAG_PURGE", "4"))
const MAXF = 8                                                # target factors kept (PCA 95%, capped)

const RUN = measures_folder(model_options.measures) * model_options.tag
const RUN_DIR = joinpath(RESULTS_DIR, RUN)
const OUT = joinpath(RESULTS_DIR, "aggregate_blocks", strip(model_options.tag))
mkpath(OUT); mkpath(AGG_BLOCKS_DIR)
@info "═══ aggregate-block diagnostics ═══" RUN OUT TIER_B

# ── helpers ───────────────────────────────────────────────────────────────────
function qdate(x)
    x isa QuarterlyDate && return x
    x isa Date && return QuarterlyDate(Dates.year(x), Dates.quarterofyear(x))
    s = strip(String(string(x)))
    m = match(r"^(\d{4})[-_ ]?[Qq](\d)$", s)
    m !== nothing && return QuarterlyDate(parse(Int, m[1]), parse(Int, m[2]))
    m = match(r"^(\d{4})-(\d{2})-(\d{2})", s)
    m !== nothing && return QuarterlyDate(Date(parse(Int, m[1]), parse(Int, m[2]), parse(Int, m[3])))
    error("cannot parse quarter: $x")
end
hp_cycle(x) = x .- HP(collect(Float64, x), 1600)
function deseason(x, q)                       # remove quarter means (keep the overall mean)
    y = copy(x)
    for k in 1:4
        ids = findall(==(k), q)
        isempty(ids) || (y[ids] .-= mean(x[ids]) - mean(x))
    end
    y
end
zcol(Y) = (Y .- mean(Y, dims = 1)) ./ std(Y, dims = 1)
"""PCA (95%, ≤ MAXF) of the standardised columns of Y (T × m) → T × k scores (unit variance)."""
function target_pca(Y; maxf = MAXF)
    Z = zcol(Y)
    M = MultivariateStats.fit(PCA, Matrix(Z'); pratio = 0.95, maxoutdim = maxf, method = :svd, mean = 0)
    S = MultivariateStats.transform(M, Matrix(Z'))
    return Matrix((S ./ sqrt.(principalvars(M)))'), principalratio(M)
end
"""align(dm, dt) → (im, it) indices of the common quarters, in date order"""
function align(dm, dt)
    lookup = Dict(d => i for (i, d) in enumerate(dm))
    it = [i for (i, d) in enumerate(dt) if haskey(lookup, d)]
    return [lookup[dt[i]] for i in it], it
end
# a target = (name, dates, Dict(variant => T × m matrix), note)
struct Target
    name::String
    dates::Vector{QuarterlyDate}
    series::Dict{String,Matrix{Float64}}   # "hp" / "raw" variants of the underlying series
    note::String
end
function finish_target(name, dates, raw::Matrix{Float64}, note; hp = true)
    keep = vec(all(isfinite, raw; dims = 2))
    dates = dates[keep]; raw = raw[keep, :]
    d = Dict("raw" => raw)
    hp && (d["hp"] = reduce(hcat, [hp_cycle(raw[:, j]) for j in 1:size(raw, 2)]))
    return Target(name, dates, d, note)
end

# ── 1. the run's smoothed states ─────────────────────────────────────────────
sf = CSV.read(joinpath(RUN_DIR, "from_mcmc", "data", "smoothed_factors.csv"), DataFrame)
const DATES = qdate.(sf.time)
const r_dist = hasproperty(model_options, :n_dist_factors) && model_options.factor_selection == :fixed ? model_options.n_dist_factors : 8
const q_agg = ncol(sf) - 1 - 4r_dist
q_agg >= 1 || error("smoothed_factors.csv has $(ncol(sf)-1) state columns; expected 4r + q with r = $r_dist")
const F_SM = Matrix{Float64}(sf[:, 2:1+r_dist])'                 # r × T
const A_SM = Matrix{Float64}(sf[:, 2+4r_dist:end])'               # q × T
@info "smoothed states: $(length(DATES)) quarters $(first(DATES))–$(last(DATES)); r = $r_dist, q = $q_agg"
tmin = Dict("year" => Dates.year(first(DATES)), "quarter" => Dates.quarterofyear(first(DATES)))
tmax = Dict("year" => Dates.year(last(DATES)), "quarter" => Dates.quarterofyear(last(DATES)))
const L = model_options.agg_lags

# ── 2. the published panel and the model's scores ────────────────────────────
super_aggs, fit_mask, series_names, dropped_ub, col_dates = build_super_aggs(obs_data.agg_data, tmin, tmax, L)
const T_M = size(super_aggs, 2) - dropped_ub
const MDATES = col_dates[1:T_M]
MDATES == DATES || error("panel dates $(first(MDATES))–$(last(MDATES)) ($(length(MDATES))) ≠ smoothed dates")
const N = length(series_names)
@info "panel: $N series × $(L+1) lags = $(size(super_aggs, 1)) rows, $(size(super_aggs, 2)) columns ($dropped_ub past tmax); fit mask excludes $(fit_mask === nothing ? 0 : count(!, fit_mask)) quarters"
X_ALL = Matrix(super_aggs[:, 1:T_M]')                              # T × N(L+1)
X_RAW = Matrix(super_aggs[[agg_row(i, 0, N, L) for i in 1:N], 1:T_M]')   # T × N contemporaneous

# the published top-30 scores, through the real select_aggregates (agg_mode :pca, count 30)
scores30 = let agg = copy(obs_data.agg_data)
    if !("year" in names(agg))
        agg[!, "time"] = QuarterlyDate.(agg[!, "time"]); agg[!, "year"] = Dates.year.(agg[!, "time"]); agg[!, "quarter"] = Dates.quarterofyear.(agg[!, "time"])
    end
    n0 = model_options.n_agg_factors; m0 = model_options.agg_mode
    model_options.n_agg_factors = 30; model_options.agg_mode = :pca
    _, s, _ = select_aggregates(agg, model_options.measures, T_M, tmin, tmax, L, model_options.tag, model_options.best_aggs)
    model_options.n_agg_factors = n0; model_options.agg_mode = m0
    s
end
size(scores30, 2) == T_M || error("select_aggregates returned $(size(scores30, 2)) columns, expected $T_M")
# byte-identity of the refactored :pca path against the published select_aggregates (archived copy)
let f = joinpath(AGG_BLOCKS_DIR, "select_aggregates_published.jl")
    if isfile(f)
        include(f)
        agg = copy(obs_data.agg_data)
        if !("year" in names(agg))
            agg[!, "time"] = QuarterlyDate.(agg[!, "time"]); agg[!, "year"] = Dates.year.(agg[!, "time"]); agg[!, "quarter"] = Dates.quarterofyear.(agg[!, "time"])
        end
        n0 = model_options.n_agg_factors; model_options.n_agg_factors = 30
        _, s_pub, _ = select_aggregates_published(agg, model_options.measures, T_M, tmin, tmax, L, model_options.tag, model_options.best_aggs)
        model_options.n_agg_factors = n0
        dev = maximum(abs, s_pub .- scores30)
        dev == 0 ? (@info "check: refactored :pca path is byte-identical to the published select_aggregates (30 scores)") :
                   (@warn "refactored :pca path differs from the published select_aggregates: max |diff| = $dev")
    end
end
# The aggregate states are observed with an estimated measurement error (tight prior, Model.jl ≈ L650) and follow
# AR(1)s with a persistence prior (κ₆ / ρ_Y): the smoother can treat a near-white observed PC largely as noise.
# This table says how much of each observed PC survives in the state the factors load on through B.
let obs = scores30[1:q_agg, :]
    tb = DataFrame(factor = 1:q_agg, rho1_observed = row_autocorr(obs, 1), rho1_state = row_autocorr(A_SM, 1),
                   sd_state = vec(std(A_SM; dims = 2)), corr_obs_state = [cor(obs[i, :], A_SM[i, :]) for i in 1:q_agg],
                   r2_state_on_obs = [cor(obs[i, :], A_SM[i, :])^2 for i in 1:q_agg], maxabsdiff = vec(maximum(abs, obs .- A_SM; dims = 2)))
    tb.noise_share_implied = 1 .- tb.sd_state .^ 2       # observed PCs have unit variance: 1 − var(state) ≈ share absorbed by measurement error
    CSV.write(joinpath(OUT, "observed_vs_smoothed_aggregates.csv"), tb)
    println("\n── observed aggregate PCs vs the run's smoothed aggregate states ──")
    show(stdout, tb; allrows = true, allcols = true); println()
    dev = maximum(tb.maxabsdiff)
    dev < 1e-6 ? (@info "check: the run's aggregate states equal the observed scores (max |diff| = $(round(dev; sigdigits = 3)))") :
                 (@info "the run's aggregate states are SMOOTHED versions of the observed PCs (max |diff| = $(round(dev; sigdigits = 3)); sd of the states $(round.(tb.sd_state; digits = 2)))")
end

# ── 3. targets ────────────────────────────────────────────────────────────────
targets = Target[]
# 3a Real-Time Inequality (Blanchet–Saez–Zucman): shares and per-unit levels relative to the total, asinh
let dir = joinpath(DATA_PROCESSING, "real_time_ineq")
    try
        inc = CSV.read(joinpath(dir, "Income  Data.csv"), DataFrame); wea = CSV.read(joinpath(dir, "Wealth Data.csv"), DataFrame)
        units = unique(skipmissing(inc.Unit)); "Households" in units && (inc = inc[coalesce.(inc.Unit .== "Households", false), :])
        groups = ["Bottom 50%", "Middle 40%", "Top 10%", "Top 1%"]
        toi(x) = x isa AbstractString ? parse(Int, x) : Int(x)
        tof(x) = x isa AbstractString ? parse(Float64, x) : Float64(x)
        cols = Matrix{Float64}[]; names_ = String[]; dlist = Vector{Vector{QuarterlyDate}}()
        for (df, lab, lvl, sh) in ((inc, "income", "Real Pretax Income Per Unit", "Real Pretax Income Share"),
                                   (wea, "wealth", "Real Wealth Per Unit", "Real Wealth Share"))
            tot = df[df.Group .== "Total", :]
            key = Dict((toi(y), toi(q)) => tof(v) for (y, q, v) in zip(tot.Year, tot.Quarter, tot[!, lvl]))
            for g in groups
                sub = df[df.Group .== g, :]
                push!(dlist, QuarterlyDate.(toi.(sub.Year), toi.(sub.Quarter)))
                lvlrel = asinh.(tof.(sub[!, lvl]) ./ [key[(toi(y), toi(q))] for (y, q) in zip(sub.Year, sub.Quarter)])
                push!(cols, hcat(lvlrel, tof.(sub[!, sh]))); append!(names_, ["$lab $g level", "$lab $g share"])
            end
        end
        all(==(dlist[1]), dlist) || error("RTI: unequal date vectors across groups")
        push!(targets, finish_target("RTI", dlist[1], reduce(hcat, cols), join(names_, "|")))
    catch e
        @warn "RTI target skipped" exception = (e, catch_backtrace())
    end
end
# 3b DFA: wealth shares and quantile levels by wealth group, wealth by income group (levels per household, shares)
let dir = joinpath(DATA_PROCESSING, "validation", "DFA")
    try
        sh = dropmissing(CSV.read(joinpath(dir, "wealth_shares_DFA.csv"), DataFrame), :time); qu = dropmissing(CSV.read(joinpath(dir, "wealth_quantiles_DFA.csv"), DataFrame), :time)
        wi = dropmissing(DataFrame(XLSX.readtable(joinpath(dir, "DFA.xlsx"), "wealth_by_income", header = true)), :time)
        d1 = qdate.(sh.time); d2 = qdate.(qu.time); d3 = qdate.(wi.time)
        d1 == d2 || error("DFA shares/quantiles dates differ")
        im, i3 = align(d1, d3)
        M = hcat(Float64.(Matrix(sh[im, [:bottom50, :next40, :top10]])),
                 asinh.(Float64.(Matrix(qu[im, [:bottom50, :next40, :top10]]))),
                 asinh.(Float64.(Matrix(wi[i3, ["quantile_bottom40", "quantile_next40", "quantile_top20"]]))),
                 Float64.(Matrix(wi[i3, ["sharebottom40", "sharenext40", "sharetop20"]])))
        push!(targets, finish_target("DFA", d1[im], M, "wealth shares b50/n40/t10 | asinh quantile levels | wealth-by-income asinh levels b40/n40/t20 | shares"))
    catch e
        @warn "DFA target skipped" exception = (e, catch_backtrace())
    end
end
# 3c WIDq: income and wealth group quantiles (log)
let dir = joinpath(DATA_PROCESSING, "WIDq")
    try
        inc = dropmissing(CSV.read(joinpath(dir, "income_quantiles_WIDq.csv"), DataFrame), :time); wea = dropmissing(CSV.read(joinpath(dir, "wealth_quantiles_WIDq.csv"), DataFrame), :time)
        d1 = qdate.(inc.time); d2 = qdate.(wea.time)
        im, iw = align(d1, d2)
        M = hcat(asinh.(Float64.(Matrix(inc[im, [:bottom50, :next40, :top10]]))), asinh.(Float64.(Matrix(wea[iw, [:bottom50, :next40, :top10]]))))   # asinh: bottom-50 wealth is negative
        push!(targets, finish_target("WIDq", d1[im], M, "asinh income quantiles b50/n40/t10 | asinh wealth quantiles"))
    catch e
        @warn "WIDq target skipped" exception = (e, catch_backtrace())
    end
end
# 3d CEX quarterly group means from the microdata: consumption and income by own rank (b50/n40/t10, rel. to mean),
#    consumption by income rank (b40/m40/t20); quarter means removed (the model's CEX inputs are X-13 adjusted)
let f = obs_data.files["CEX"]
    try
        cex = CSV.read(f, DataFrame; select = ["year", "quarter", "weight", "income", "consum"])
        function wgroups(x, w, cuts)
            o = sortperm(x); x = x[o]; w = w[o]
            cw = cumsum(w) ./ sum(w); rank = cw .- w ./ (2 * sum(w))
            g = [searchsortedlast(cuts, rk) + 1 for rk in rank]
            μ = sum(w .* x) / sum(w)
            [sum(w[g .== k] .* x[g .== k]) / sum(w[g .== k]) / μ for k in 1:length(cuts)+1]
        end
        function wcross(x, y, w, cuts)       # mean of y by rank of x
            o = sortperm(x); x = x[o]; y = y[o]; w = w[o]
            cw = cumsum(w) ./ sum(w); rank = cw .- w ./ (2 * sum(w))
            g = [searchsortedlast(cuts, rk) + 1 for rk in rank]
            μ = sum(w .* y) / sum(w)
            [sum(w[g .== k] .* y[g .== k]) / sum(w[g .== k]) / μ for k in 1:length(cuts)+1]
        end
        rows = Vector{Float64}[]; ds = QuarterlyDate[]
        for gdf in groupby(cex, [:year, :quarter]; sort = true)
            w = Float64.(coalesce.(gdf.weight, 0.0))
            c = Float64.(coalesce.(gdf.consum, NaN)); y = Float64.(coalesce.(gdf.income, NaN))
            mc = isfinite.(c) .& (w .> 0); my = isfinite.(y) .& (w .> 0); mb = mc .& my
            (sum(mc) < 100 || sum(my) < 100 || sum(mb) < 100) && continue
            push!(rows, vcat(wgroups(c[mc], w[mc], [0.5, 0.9]), wgroups(y[my], w[my], [0.5, 0.9]), wcross(y[mb], c[mb], w[mb], [0.4, 0.8])))
            push!(ds, QuarterlyDate(Int(first(gdf.year)), Int(first(gdf.quarter))))
        end
        M = log.(reduce(hcat, rows)')
        qs = Dates.quarterofyear.(ds)
        M = reduce(hcat, [deseason(M[:, j], qs) for j in 1:size(M, 2)])
        push!(targets, finish_target("CEXgroups", ds, Matrix(M), "log consum b50/n40/t10 rel. mean | log income b50/n40/t10 | log consum-by-income b40/m40/t20; quarter means removed"))
    catch e
        @warn "CEX group-means target skipped" exception = (e, catch_backtrace())
    end
end
# 3e CEX coefficient block: the raw Legendre/copula coefficients the estimation receives (data_constructor on the CEX file)
if DO_CEXCOEF
    try
        obs_sub = ObservedData(files = Dict("CEX" => obs_data.files["CEX"]), agg_data = obs_data.agg_data, gdp_series = copy(obs_data.gdp_series))
        dfs, _, _, time_dict, freq_type = data_constructor(obs_sub, model_options)
        X = dfs[1]
        ds = QuarterlyDate[]
        for y in sort(collect(keys(time_dict[1]))), p in sort(time_dict[1][y])
            push!(ds, freq_type[1] == "quarter" ? QuarterlyDate(Int(y), Int(round(p))) : QuarterlyDate(Int(y), 4))
        end
        length(ds) == size(X, 2) || error("CEX coefficients: $(length(ds)) dates vs $(size(X, 2)) columns")
        keep = vec(all(isfinite, X; dims = 2)) .& (vec(std(X; dims = 2)) .> 0)
        Xc = Matrix(X[keep, :]')
        qs = Dates.quarterofyear.(ds)
        Xc = reduce(hcat, [deseason(Xc[:, j], qs) for j in 1:size(Xc, 2)])
        push!(targets, finish_target("CEXcoefs", ds, Matrix(Xc), "$(count(keep)) complete coefficient rows of the CEX block, quarter means removed"))
    catch e
        @warn "CEX coefficient-block target skipped" exception = (e, catch_backtrace())
    end
end
# 3f the run's smoothed distributional factors (circular — built with the current aggregate block; diagnostic only)
push!(targets, Target("MODEL_f", DATES, Dict("raw" => Matrix(F_SM')), "smoothed f_t of the run (no HP: the model's factors are already detrended per coefficient)"))

# target factors: PCA (95 %, ≤ MAXF) per variant; MODEL_f is used as is
const TARGET_F = Dict{String,Dict{String,Matrix{Float64}}}()
for t in targets
    TARGET_F[t.name] = Dict{String,Matrix{Float64}}()
    for (v, Y) in t.series
        if t.name == "MODEL_f"
            TARGET_F[t.name][v] = Y
        else
            Fk, pr = target_pca(Y)
            TARGET_F[t.name][v] = Fk
            @info "target $(t.name)/$v: $(size(Y, 2)) series, $(length(t.dates)) quarters $(first(t.dates))–$(last(t.dates)) → $(size(Fk, 2)) factors ($(round(100pr; digits = 1))%)"
        end
        CSV.write(joinpath(OUT, "target_$(t.name)_$(v).csv"), hcat(DataFrame(time = string.(t.dates)), DataFrame(TARGET_F[t.name][v], ["f$i" for i in 1:size(TARGET_F[t.name][v], 2)])))
    end
end
open(joinpath(OUT, "targets_readme.txt"), "w") do io
    for t in targets; println(io, t.name, ": ", t.note); end
end
const EXTERNAL = [t.name for t in targets if t.name in ("RTI", "DFA", "WIDq")]
const HELDOUT = [t.name for t in targets if startswith(t.name, "CEX")]
tdict = Dict(t.name => t for t in targets)

# target matrices aligned to the master quarters: (X rows idx in 1:T_M, Y)
function aligned(tname, variant)
    t = tdict[tname]
    im, it = align(MDATES, t.dates)
    return im, TARGET_F[tname][variant][it, :]
end

# ── 4. candidates ─────────────────────────────────────────────────────────────
# name => (F (k × T_M), labels, selected_on)
candidates = Dict{String,Tuple{Matrix{Float64},Vector{String},String}}()
pcs_lab(k) = ["PC$i" for i in 1:k]
candidates["C0"]    = (scores30[1:q_agg, :], pcs_lab(q_agg), "")
candidates["C0-3"]  = (scores30[1:3, :], pcs_lab(3), "")
candidates["C0-30"] = (scores30[1:30, :], pcs_lab(30), "")
gmap = fredqd_group_map(series_names)
for (nm, spec) in (("B13", "b13"), ("B11", "b11"), ("B11-GS", "b11gs"), ("B2x-all", "b2x"), ("B5x2", "b5x2"), ("B6x2", "b6x2"))
    blocks, per_block, orth = parse_block_spec(spec)
    _, F, labels = block_factors(super_aggs, series_names, gmap, L; fit_mask, blocks, per_block, orth)
    candidates[nm] = (F[:, 1:T_M], labels, "")
end

# OOF R² of a candidate on a target (variant); withlag adds y_{t-1}
function score(F, tname, variant; withlag = false, nested = true)
    im, Y = aligned(tname, variant)
    X = Matrix(F[:, im]')
    if withlag
        X = hcat(X[2:end, :], Y[1:end-1, :]); Y = Y[2:end, :]
    end
    return oof_r2(X, Y; nfold = NFOLD, purge = PURGE, nested = nested), insample_r2(X, Y), size(Y, 1)
end
mean_ext(F; variant = "hp") = mean([mean(score(F, t, variant)[1]) for t in EXTERNAL])

# targeted: marginal screening on the external targets (rank-averaged series scores) → top-k series
if !isempty(EXTERNAL)
    ranks = zeros(N); colsc = zeros(size(X_ALL, 2))
    for t in EXTERNAL
        im, Y = aligned(t, "hp")
        ss, cs = screen_marginal(X_ALL[im, :], Y, N, L; nfold = NFOLD, purge = PURGE)
        ranks .+= invperm(sortperm(ss; rev = true)) ./ N; colsc .+= cs
    end
    ranks ./= length(EXTERNAL)
    order = sortperm(ranks)
    CSV.write(joinpath(OUT, "screening_series_scores.csv"), DataFrame(series = series_names[order], group = [get(FREDQD_GROUP_NAMES, gmap[s], "unmapped") for s in series_names[order]], mean_rank = ranks[order]))
    for k in (50, 100, 200)
        k > N && continue
        sel = series_names[order[1:k]]
        CSV.write(targeted_selection_file("t$k"), DataFrame(series = sel))
        _, F = targeted_factors(super_aggs, series_names, sel, L, q_agg; fit_mask)
        candidates["T$k"] = (F[:, 1:T_M], pcs_lab(q_agg), "external")
    end
    # LASSO per external target factor, union of the selected columns → series
    try
        selcols = Set{Int}()
        for t in EXTERNAL
            im, Y = aligned(t, "hp")
            union!(selcols, lasso_select(X_ALL[im, :], Y; nfold = NFOLD, purge = PURGE))
        end
        sel_series = sort(unique([series_names[mod1(c, N)] for c in selcols]))
        @info "LASSO: $(length(selcols)) columns → $(length(sel_series)) series"
        if length(sel_series) >= q_agg + 2
            CSV.write(targeted_selection_file("tl"), DataFrame(series = sel_series))
            _, F = targeted_factors(super_aggs, series_names, sel_series, L, q_agg; fit_mask)
            candidates["TL"] = (F[:, 1:T_M], pcs_lab(q_agg), "external")
        end
    catch e
        @warn "LASSO candidate skipped" exception = (e, catch_backtrace())
    end
    # PLS on the longest external target (RTI if present), 11 components, applied to every quarter
    try
        tp = "RTI" in EXTERNAL ? "RTI" : EXTERNAL[1]
        im, Y = aligned(tp, "hp")
        Wst = pls_weights(X_ALL[im, :], zcol(Y), q_agg)
        Fp = Matrix((X_ALL * Wst)')
        Fp = Fp ./ std(Fp; dims = 2)
        candidates["PLS"] = (Fp, ["PLS$i" for i in 1:q_agg], tp)
    catch e
        @warn "PLS candidate skipped" exception = (e, catch_backtrace())
    end
    # forward stepwise: 11 of the 30 published PCs by mean OOF R² on the external targets
    try
        chosen = Int[]
        for step in 1:q_agg
            best = -Inf; bj = 0
            for j in 1:30
                j in chosen && continue
                v = mean_ext(scores30[vcat(chosen, j), :])
                v > best && (best = v; bj = j)
            end
            push!(chosen, bj)
            @info "forward selection step $step: PC$bj (mean external OOF R² $(round(best; digits = 3)))"
        end
        CSV.write(joinpath(AGG_BLOCKS_DIR, "fs_pcs_$(strip(model_options.tag)).csv"), DataFrame(pc = chosen))
        candidates["FS"] = (scores30[chosen, :], ["PC$j" for j in chosen], "external")
    catch e
        @warn "forward-selection candidate skipped" exception = (e, catch_backtrace())
    end
    # B2x: keep 11 of the 15 two-PC block factors by the same forward selection
    try
        F15, lab15 = candidates["B2x-all"][1], candidates["B2x-all"][2]
        chosen = Int[]
        for step in 1:q_agg
            best = -Inf; bj = 0
            for j in 1:size(F15, 1)
                j in chosen && continue
                v = mean_ext(F15[vcat(chosen, j), :])
                v > best && (best = v; bj = j)
            end
            push!(chosen, bj)
        end
        candidates["B2x"] = (F15[chosen, :], lab15[chosen], "external")
        @info "B2x: kept " * join(lab15[chosen], "; ")
    catch e
        @warn "B2x selection skipped" exception = (e, catch_backtrace())
    end
end
for (nm, (F, labels, _)) in candidates
    CSV.write(joinpath(OUT, "candidate_$(nm).csv"), hcat(DataFrame(time = string.(MDATES)), DataFrame(Matrix(F'), labels)))
end

# ── 5. metrics ────────────────────────────────────────────────────────────────
metrics = DataFrame(candidate = String[], q = Int[], selected_on = String[], target = String[], variant = String[], withlag = Bool[],
                    n_obs = Int[], r2_is_mean = Float64[], r2_oof_mean = Float64[], r2_oof_min = Float64[], r2_oof = String[])
for (nm, (F, labels, selon)) in sort(collect(candidates); by = first), t in targets, v in sort(collect(keys(TARGET_F[t.name])))
    for wl in (false, true)
        try
            oof, is, n = score(F, t.name, v; withlag = wl, nested = size(F, 1) > 3)
            push!(metrics, (nm, size(F, 1), selon, t.name, v, wl, n, mean(is), mean(oof), minimum(oof), join(round.(oof; digits = 3), ";")))
        catch e
            @warn "metrics failed" nm t.name v wl exception = e
        end
    end
end
# raw series and the whole lagged panel as reference regressors (ridge)
for (nm, X) in (("RAW201", X_RAW), ("ALL1005", X_ALL)), t in targets, v in sort(collect(keys(TARGET_F[t.name])))
    try
        im, Y = aligned(t.name, v)
        oof = oof_r2(X[im, :], Y; nfold = NFOLD, purge = PURGE, λs = [1e-2, 1e-1, 1.0, 10.0, 100.0])
        push!(metrics, (nm, size(X, 2), "", t.name, v, false, size(Y, 1), NaN, mean(oof), minimum(oof), join(round.(oof; digits = 3), ";")))
    catch e
        @warn "reference metrics failed" nm t.name v exception = e
    end
end
CSV.write(joinpath(OUT, "metrics.csv"), metrics)

# persistence, principal angles vs the published span, variance of the 201 series explained, condition number
F0 = candidates["C0"][1]
diag_rows = DataFrame(candidate = String[], q = Int[], rho1_mean = Float64[], rho1_min = Float64[], n_rho1_below_0_2 = Int[], rho4_mean = Float64[],
                      angle_max_vs_C0 = Float64[], angle_median_vs_C0 = Float64[], n_angles_above_20 = Int[], var201_explained = Float64[], cond = Float64[])
for (nm, (F, labels, _)) in sort(collect(candidates); by = first)
    ρ1 = row_autocorr(F, 1); ρ4 = row_autocorr(F, 4)
    ang = principal_angles(F, F0)
    v201 = mean(insample_r2(Matrix(F'), X_RAW))
    push!(diag_rows, (nm, size(F, 1), mean(ρ1), minimum(ρ1), count(<(0.2), ρ1), mean(ρ4), maximum(ang), median(ang), count(>(20), ang), v201, cond(F * F' / size(F, 2))))
    CSV.write(joinpath(OUT, "persistence_$(nm).csv"), DataFrame(factor = labels, rho1 = ρ1, rho4 = ρ4))
end
ρf = row_autocorr(F_SM, 1)
CSV.write(joinpath(OUT, "persistence_MODEL_f.csv"), DataFrame(factor = ["f$i" for i in 1:r_dist], rho1 = ρf, rho4 = row_autocorr(F_SM, 4)))
CSV.write(joinpath(OUT, "candidate_diagnostics.csv"), diag_rows)

# summary table: mean OOF R² (hp variant, no lag) by candidate × target
let hp = metrics[(metrics.variant .== "hp") .& .!metrics.withlag, :]
    wide = unstack(hp, :candidate, :target, :r2_oof_mean)
    wide = leftjoin(wide, diag_rows[:, [:candidate, :q, :rho1_mean, :angle_max_vs_C0, :var201_explained]], on = :candidate)
    sort!(wide, :candidate)
    CSV.write(joinpath(OUT, "summary_oof_hp.csv"), wide)
    println("\n── mean out-of-fold R² on HP-cycle targets (no lag) ──")
    show(stdout, wide; allrows = true, allcols = true); println()
end
let mf = metrics[(metrics.target .== "MODEL_f") .& .!metrics.withlag, :]
    println("\n── the run's smoothed f_t on each candidate (OOF / in-sample, per factor) ──")
    show(stdout, mf[:, [:candidate, :r2_is_mean, :r2_oof_mean, :r2_oof]]; allrows = true, allcols = true); println()
end
println("\n── persistence and span ──")
show(stdout, diag_rows; allrows = true, allcols = true); println()

# ── 6. Tier B: the posterior mode ────────────────────────────────────────────
if TIER_B
    try
        @info "Tier B: estimation_prep + posterior mode"
        func_data, time_params, model_elements = estimation_prep(obs_data, model_options)
        param_vector, param_sizes, priors, meas_ind, Σ_ids = set_params(model_elements, time_params, model_options)
        par_final = get_param_vector(model_options.measures, :mcmc, "3D_$(model_options.case)", model_options.data_cutoffs, model_options.tag)
        length(par_final) == length(param_vector) || error("mode has $(length(par_final)) parameters, this spec $(length(param_vector))")
        A, B_mat, C, D, Ω_var, Ω_corr, Σ = matrisize(st_core_params(par_final, param_sizes), param_sizes)
        # the objective at the mode, split into prior and likelihood exactly as Model.likeli does
        try
            hyperpriors = st_hyperpriors(priors, param_sizes)
            n_hyper = param_sizes[end][1]
            hp_ = par_final[end-n_hyper+1:end]
            pri = get_priors(model_elements, model_options, hp_); push!(pri, hyperpriors...)
            log_P, alarmP = prioreval([[A..., B_mat..., C..., diag(D)...], copy(Ω_var), Ω_corr, Matrix(Σ), hp_], pri, param_sizes)
            logV, alarmV = likeli(model_elements, par_final, param_sizes, hyperpriors, Σ_ids, model_options)
            nΣ = length(diag(Matrix(Σ))); qq = size(B_mat, 2)
            lp_agg = sum(logpdf(pri[4+nΣ-qq+j], diag(Matrix(Σ))[nΣ-qq+j]) for j in 1:qq)
            # where do the tight aggregate priors sit in each list, and what does prioreval pair with the aggregate Σ entries?
            tight(d) = d isa Normal && d.μ < -5
            @info "Tier B: prior lists — runtime get_priors: $(length(pri)) entries, tight Normal(μ<-5) at $(findall(tight, pri)); set_params priors: $(length(priors)) entries, tight at $(findall(tight, priors)); nΣ = $nΣ, q = $qq, prioreval pairs Σ entry i with priors[4+i] ⇒ aggregate entries read priors $(4+nΣ-qq+1):$(4+nΣ); runtime entries there: $(unique(string.(typeof.(pri[4+nΣ-qq+1:4+nΣ])))) e.g. $(pri[4+nΣ-qq+1])"
            @info "Tier B: objective at the mode = $(round(logV; digits = 1)) (alarm $alarmV); prior part = $(round(log_P; digits = 1)) (alarm $alarmP), of which the $qq aggregate measurement-error entries contribute $(round(lp_agg; digits = 1)); likelihood part = $(round(logV - log_P; digits = 1))"
        catch e
            @warn "objective split failed" exception = (e, catch_backtrace())
        end
        Ω_var[diagind(Ω_var)] = log.(exp.(Ω_var[diagind(Ω_var)]) .+ 1)
        Ω = Ω_var * Matrix(Ω_corr) * Ω_var'
        r, q = size(B_mat)
        Φ_sub = [A B_mat; C D]
        try
            Σm = apply_measurement_criteria(Σ, Σ_ids, model_options, model_elements.agg_count)
            σagg = (Σm isa AbstractVector ? Σm : diag(Σm))[end-q+1:end]
            CSV.write(joinpath(OUT, "aggregate_measurement_error.csv"), DataFrame(factor = 1:q, sigma2_meas = σagg, sigma_innov = diag(Ω_var)[r+1:r+q], d = diag(D)))
            # raw φ (softplus → variance) and the prior actually evaluated on them (SelectPrior.prioreval: priors[4+i] ↔ diag(Σ)[i])
            nΣ = length(diag(Matrix(Σ)))
            pt = DataFrame(factor = 1:q, phi = σagg, sigma2 = log.(exp.(σagg) .+ 1),
                           prior = [string(priors[4+nΣ-q+j]) for j in 1:q],
                           logprior = [logpdf(priors[4+nΣ-q+j], σagg[j]) for j in 1:q])
            CSV.write(joinpath(OUT, "aggregate_measurement_error.csv"), pt)
            println("\n── aggregate measurement error at the mode: raw φ, variance softplus(φ), and the prior on φ ──")
            show(stdout, pt; allrows = true, allcols = true); println()
            @info "Tier B: aggregate measurement-error variances softplus(φ) = $(round.(pt.sigma2; sigdigits = 2)) (prior mean 1/2000); total log-prior of these $q entries = $(round(sum(pt.logprior); digits = 1))"
        catch e
            @warn "aggregate measurement error not extracted" exception = e
        end
        # (d) FEVD sensitivity
        fs = DataFrame(horizon = String[], shock_order = String[], type = String[], factor = Int[], agg_share = Float64[])
        for h in (1, 4, 8, 20, 40, Inf), so in (:agg_first, :dist_first), ty in (:block_cholesky, :generalized)
            sh = fevd_factor_shares(Φ_sub, Ω; r, q, horizon = h, shock_order = so, type = ty)
            for i in 1:r; push!(fs, (string(h), string(so), string(ty), i, sh[i])); end
        end
        CSV.write(joinpath(OUT, "fevd_sensitivity.csv"), fs)
        println("\n── FEVD aggregate share (%) per factor: block Cholesky, aggregates first ──")
        show(stdout, unstack(fs[(fs.type .== "block_cholesky") .& (fs.shock_order .== "agg_first"), :], :factor, :horizon, :agg_share); allrows = true, allcols = true); println()
        # h = 0 share from Ω alone: R² of the factor innovations on the aggregate innovations
        Ωff = Ω[1:r, 1:r]; Ωfy = Ω[1:r, r+1:r+q]; Ωyy = Ω[r+1:r+q, r+1:r+q]
        h0 = diag(Ωfy * (Ωyy \ Ωfy')) ./ diag(Ωff)
        # (c) OLS of f_t on [f_{t-1}, a_{t-1}] vs the posterior A, B (and the Minnesota prior sd of B)
        Yf = Matrix(F_SM[:, 2:end]'); Xf = hcat(Matrix(F_SM[:, 1:end-1]'), Matrix(A_SM[:, 1:end-1]'))
        β = (Xf' * Xf) \ (Xf' * Yf)                                   # (r+q) × r
        A_ols = Matrix(β[1:r, :]'); B_ols = Matrix(β[r+1:end, :]')
        resid = Yf - Xf * β
        share_B_ols = [var(Matrix(A_SM[:, 1:end-1]') * B_ols[i, :]) / var(Yf[:, i]) for i in 1:r]
        share_B_post = [var(Matrix(A_SM[:, 1:end-1]') * B_mat[i, :]) / var(Yf[:, i]) for i in 1:r]
        κ = model_options.prior.hyperparameters
        vF = VAR_fit(Matrix(F_SM'), 1); vY = VAR_fit(Matrix(A_SM'), 1)
        priorsd_B = [sqrt(κ[1] * κ[2] * vF[i] / vY[j]) for i in 1:r, j in 1:q]
        bt = DataFrame(factor = 1:r, h0_share_from_Omega = h0, var_share_Ba_ols = share_B_ols, var_share_Ba_post = share_B_post,
                       normB_ols = [norm(B_ols[i, :]) for i in 1:r], normB_post = [norm(B_mat[i, :]) for i in 1:r],
                       corr_B_ols_post = [cor(B_ols[i, :], B_mat[i, :]) for i in 1:r],
                       meanabs_B_post_over_priorsd = [mean(abs.(B_mat[i, :]) ./ priorsd_B[i, :]) for i in 1:r],
                       A_ols_diag = diag(A_ols), A_post_diag = diag(A), rho1_f = ρf)
        CSV.write(joinpath(OUT, "B_post_vs_ols.csv"), bt)
        CSV.write(joinpath(OUT, "B_post.csv"), DataFrame(B_mat, ["a$j" for j in 1:q])); CSV.write(joinpath(OUT, "B_ols.csv"), DataFrame(B_ols, ["a$j" for j in 1:q]))
        CSV.write(joinpath(OUT, "D_post.csv"), DataFrame(d = diag(D), rho1_a = row_autocorr(A_SM, 1)))
        println("\n── posterior B vs OLS of f_t on [f_{t-1}, a_{t-1}] ──")
        show(stdout, bt; allrows = true, allcols = true); println()
        @info "Tier B: max |eig A| = $(round(maximum(abs, eigvals(A)); digits = 3)), max |eig Φ| = $(round(maximum(abs, eigvals(Φ_sub)); digits = 3)), canonical corr(ε_f, ε_a) = $(round.(sqrt.(clamp.(eigvals(Symmetric(inv(Ωff) * Ωfy * (Ωyy \ Ωfy'))), 0, 1)); digits = 2))"
    catch e
        @warn "Tier B failed" exception = (e, catch_backtrace())
    end
end
@info "═══ aggregate-block diagnostics finished → $OUT ═══"
