# ─────────────────────────────────────────────────────────────────────────────
# AggregateBlocks.jl — alternative constructions of the aggregate block (Oct 2026)
#
# The published aggregate block is PCA on the 201 FRED-QD series and their 4 lags
# (select_aggregates → perform_pca(:aggs)): the 11 largest-VARIANCE directions of the
# macro panel, which need not be the directions that move the distribution (the FEVD
# credits them with 15–31% of the factors' variance; doc/aggregates_diagnostic.pdf
# finds factors 8–10 near white). This file adds two alternatives, selected by
# ModelOptions.agg_mode (DD_AGG_MODE / DD_AGG_SPEC in examples/Structures_transfer.jl):
#   :pca      — published path (byte-identical; perform_pca is untouched)
#   :blocks   — one (or a few) PCs per FRED-QD group ("named" factors: NIPA, employment,
#               prices, rates, credit, household balance sheets, …), each with its lags,
#               then orthogonalised. Löwdin symmetric (default) keeps each factor as close
#               as possible to its own block; :gs = Gram–Schmidt in spec order.
#   :targeted — PCA on a SUBSET of series screened for their predictive power for
#               distributional data (Bai–Ng 2008 "targeted predictors"); the list is
#               written by aggregate_block_diagnostics.jl to aggregate_blocks/targeted_<spec>.csv
# The FEVD's aggregate-vs-distributional split depends only on the SPAN of the block,
# not on rotations inside it, so a candidate can only change it by bringing in directions
# that PCA ranked below 11 (principal_angles makes that explicit before any run).
# Scores are always unit variance on the PCA fit sample (the Minnesota and shock priors
# are calibrated to that), and every fit respects aggregate_pca_exclude (fit_mask).
# ─────────────────────────────────────────────────────────────────────────────

const FREDQD_GROUP_NAMES = Dict(
    1 => "NIPA", 2 => "Industrial production", 3 => "Employment and unemployment", 4 => "Housing",
    5 => "Inventories, orders and sales", 6 => "Prices", 7 => "Earnings and productivity",
    8 => "Interest rates", 9 => "Money and credit", 10 => "Household balance sheets",
    11 => "Exchange rates", 12 => "Other", 13 => "Stock markets", 14 => "Non-household balance sheets")
# workbook names that are not FRED mnemonics (FRED-QD lists them as "S&P 500", "S&P div yield", "S&P PE ratio")
const FREDQD_MANUAL_GROUPS = Dict("sp500" => 13, "spdivyield" => 13, "spperatio" => 13)
const AGG_BLOCKS_DIR = joinpath(@__DIR__, "aggregate_blocks")
# block specs: comma list of blocks, "+" merges groups, "@n" takes n PCs of that block, ":gs" = Gram–Schmidt in order
const AGG_BLOCK_ALIASES = Dict(
    "b13"   => "1,2,3,4,5,6,7,8,9,10,11,13,14",                 # one PC per non-empty FRED-QD group
    "b11"   => "1+5,2,3,4,6,7,8+11,9,10,13,14",                 # orders → NIPA, FX → rates (q = 11, as the baseline)
    "b11gs" => "1+5,3,6,8+11,9,10,4,2,7,13,14:gs",              # same blocks, Gram–Schmidt: NIPA, employment, prices, rates, credit, HH balance sheets, …
    "b2x"   => "1+5@2,3@2,6@2,8+11@2,2,4,7,9,10,13,14",         # two PCs for the four big blocks (15 factors; the diagnostic picks 11)
)

agg_series_names(aggregates) = String.(setdiff(names(aggregates), ["date", "time", "year", "quarter"]))
agg_spec_slug(spec) = replace(lowercase(strip(String(spec))), "," => "_", "+" => "p", "@" => "x", ":" => "-")

# ── the published construction, factored out of select_aggregates ─────────────
"""Date filtering of select_aggregates (mutates `aggregates`); returns the rows past tmax/until."""
function filter_agg_dates!(aggregates, tmin, tmax, agg_lags; until=false)
    aggregates[:, "date"] = QuarterlyDate.(aggregates[:, "time"])

    # Calculate the quarter correction
    q_correction = tmin["quarter"] > agg_lags ? tmin["quarter"] - agg_lags : 4 - (agg_lags - tmin["quarter"]) % 4 # eg,

    # Calculate the year correction
    y_correction = tmin["quarter"] > agg_lags ? tmin["year"] : trunc(tmin["year"] - ((agg_lags + 3 - 1) / 4) + 1)

    filter!(row -> row.date >= QuarterlyDate(y_correction, q_correction), aggregates)

    local b
    if until != false
        b = filter(row -> row.date <= QuarterlyDate(until["year"], until["quarter"]), aggregates)
    else
        b = filter(row -> row.date <= QuarterlyDate(tmax["year"], tmax["quarter"]), aggregates)
    end
    return nrow(aggregates) - nrow(b)
end

"""Stack the series and their `agg_lags` lags (N(1+L) × T) and standardise each row (published)."""
function stack_lagged_aggs(data_only_aggs, agg_lags)
    super_aggs = data_only_aggs[:, 1:end-agg_lags] # N by T
    for i in 1:agg_lags
        super_aggs = vcat(super_aggs, data_only_aggs[:, i+1:end-agg_lags+i])
    end
    standardize_aggs!(super_aggs)
    return super_aggs
end

# Column j of super_aggs stacks dates j … j+agg_lags: block agg_lags (the last) is contemporaneous.
# Row of series i at lag ℓ (0 = contemporaneous):
agg_row(i, ℓ, N, agg_lags) = i + (agg_lags - ℓ) * N

"""Quarters in ModelOptions.aggregate_pca_exclude are kept out of every FIT (loadings); all quarters are projected."""
function agg_fit_mask(aggregates, agg_lags)
    excl = hasproperty(model_options, :aggregate_pca_exclude) ? Set(String.(model_options.aggregate_pca_exclude)) : Set{String}()
    isempty(excl) && return nothing
    col_dates = aggregates[!, "date"][agg_lags+1:end]
    return [!("$(Dates.year(d))-Q$(Dates.quarterofyear(d))" in excl) for d in col_dates]
end

"""The aggregate-factor count of perform_pca(:aggs): the tag/MDD pin (11; HANK 8) or n_agg_factors."""
function agg_factor_count(tag)
    Mdim = tag == " less AF" ? 3 : tag == " more AF" ? 15 : tag == " all AF" ? 30 : tag == " less DF and AF" ? 3 : occursin("HANK", tag) ? 8 : 11
    if hasproperty(model_options, :n_agg_factors) && model_options.n_agg_factors > 0
        Mdim = clamp(Int(model_options.n_agg_factors), 1, 30)
    end
    return Mdim
end

"""
    build_super_aggs(aggregates, tmin, tmax, agg_lags; until=false)

Diagnostics entry point: the published panel exactly as select_aggregates builds it.
Returns (super_aggs, fit_mask, series_names, dropped_rows_ub, col_dates); the model's
scores are columns 1:end-dropped_rows_ub, whose dates are col_dates[1:end-dropped_rows_ub].
"""
function build_super_aggs(aggregates, tmin, tmax, agg_lags; until=false)
    aggregates = copy(aggregates)
    if !("year" in names(aggregates))
        aggregates[!, "time"] = QuarterlyDate.(aggregates[!, "time"])
        aggregates[!, "year"] = Dates.year.(aggregates[!, "time"])
        aggregates[!, "quarter"] = Dates.quarterofyear.(aggregates[!, "time"])
    end
    dropped_rows_ub = filter_agg_dates!(aggregates, tmin, tmax, agg_lags; until = until)
    series_names = agg_series_names(aggregates)
    data_only_aggs = copy(transpose(Matrix{Float64}(select(aggregates, series_names))))
    super_aggs = stack_lagged_aggs(data_only_aggs, agg_lags)
    fit_mask = agg_fit_mask(aggregates, agg_lags)
    col_dates = aggregates[!, "date"][agg_lags+1:end]
    return super_aggs, fit_mask, series_names, dropped_rows_ub, col_dates
end

# ── FRED-QD groups ────────────────────────────────────────────────────────────
"""
    fredqd_group_map(series_names; appendix_csv) -> Dict(series => group id)

Workbook column → FRED-QD group (1–14) via lowercase(FRED MNEMONIC); the trailing "x" is part
of the mnemonic, so 198/201 match directly; the three S&P series are mapped by hand. Unmapped
series get 0 (excluded from block factors, still available to the targeted mode). Cached in
aggregate_blocks/group_map.csv (committed, so Marvin reads the same map).
"""
function fredqd_group_map(series_names; appendix_csv = joinpath(DATA_PROCESSING, "FRED-QD Appendix", "FRED-QD_updated_appendix.csv"))
    cache = joinpath(AGG_BLOCKS_DIR, "group_map.csv")
    if isfile(cache)
        g = CSV.read(cache, DataFrame)
        gm = Dict(String(r.series) => Int(r.group_id) for r in eachrow(g))
        missing_s = [s for s in series_names if !haskey(gm, s)]
        isempty(missing_s) && return gm
        @warn "group_map.csv lacks $(length(missing_s)) series; rebuilding from the appendix"
    end
    isfile(appendix_csv) || error("FRED-QD appendix not found: $appendix_csv")
    bytes = read(appendix_csv)                                   # latin-1: non-ASCII bytes only in descriptions
    ap = CSV.read(IOBuffer(String(map(b -> b > 0x7f ? UInt8('?') : b, bytes))), DataFrame)
    lookup = Dict(lowercase(strip(String(m))) => Int(g) for (m, g) in zip(ap[!, "FRED MNEMONIC"], ap[!, "Group"]) if !ismissing(m) && !ismissing(g))
    gmap = Dict{String,Int}(); src = Dict{String,String}()
    for s in series_names
        key = lowercase(s)
        if haskey(FREDQD_MANUAL_GROUPS, key)
            gmap[s] = FREDQD_MANUAL_GROUPS[key]; src[s] = "manual"
        elseif haskey(lookup, key)
            gmap[s] = lookup[key]; src[s] = "fred"
        elseif haskey(lookup, key * "x")
            gmap[s] = lookup[key*"x"]; src[s] = "fred+x"
        elseif endswith(key, "x") && haskey(lookup, chop(key))
            gmap[s] = lookup[chop(key)]; src[s] = "fred-x"
        else
            gmap[s] = 0; src[s] = "unmapped"
        end
    end
    unmapped = [s for s in series_names if gmap[s] == 0]
    isempty(unmapped) || @warn "FRED-QD group map: $(length(unmapped)) series unmapped (left out of block factors): $(join(unmapped, ", "))"
    mkpath(AGG_BLOCKS_DIR)
    CSV.write(cache, DataFrame(series = series_names, group_id = [gmap[s] for s in series_names],
                               group_name = [get(FREDQD_GROUP_NAMES, gmap[s], "unmapped") for s in series_names],
                               source = [src[s] for s in series_names]))
    @info "FRED-QD group map written: $cache"
    return gmap
end

function parse_block_spec(spec)
    s = String(strip(String(spec)))
    isempty(s) && (s = "b11")
    s = get(AGG_BLOCK_ALIASES, lowercase(s), s)
    orth = :lowdin
    if occursin(":", s)
        s, o = split(s, ":")
        orth = Symbol(lowercase(strip(o)))
    end
    orth in (:lowdin, :gs, :none) || error("block spec: orthogonalisation must be lowdin, gs or none (got $orth)")
    blocks = Vector{Vector{Int}}(); per_block = Dict{Int,Int}()
    for (b, tok) in enumerate(split(s, ","))
        t = String(strip(tok))
        if occursin("@", t)
            t, n = split(t, "@")
            per_block[b] = parse(Int, n)
        end
        push!(blocks, parse.(Int, split(t, "+")))
    end
    return blocks, per_block, orth
end
block_label(groups) = join([get(FREDQD_GROUP_NAMES, g, "g$g") for g in groups], " + ")

# ── PCA with the conventions of perform_pca(:aggs) ────────────────────────────
# rows = variables (standardised), columns = quarters; loadings fit on fit_mask, every quarter projected,
# scores scaled to unit variance on the fit sample; proj such that data ≈ proj · scores.
function _pca_scores(X, fit_mask, k)
    Xfit = fit_mask === nothing ? X : X[:, fit_mask]
    M = MultivariateStats.fit(PCA, Xfit; pratio = 1.0, maxoutdim = k, method = :svd, mean = 0)
    pcs = MultivariateStats.transform(M, X)
    λ = sqrt.(principalvars(M))
    kk = min(k, length(λ))
    scores = pcs[1:kk, :] ./ λ[1:kk]
    proj = projection(M)[:, 1:kk] * diagm(λ[1:kk])
    return proj, scores, M
end

"""Orthogonalise the stacked block scores F (k × T) on the fit sample: Löwdin (S^{-1/2}F, each factor
closest to its own block), Gram–Schmidt (L^{-1}F with S = LL': factor j mixes blocks 1..j only), or none."""
function orthogonalise(F, fit_mask, orth)
    Ff = fit_mask === nothing ? F : F[:, fit_mask]
    S = Symmetric(Ff * Ff' / size(Ff, 2))
    if orth == :lowdin
        E = eigen(S)
        return E.vectors * diagm(1 ./ sqrt.(E.values)) * E.vectors' * F
    elseif orth == :gs
        return cholesky(S).L \ F
    else
        return F
    end
end

"""
    block_factors(super_aggs, series_names, gmap, agg_lags; fit_mask, blocks, per_block, orth)
    -> (proj, scores, labels)

One PC per block (series of the listed FRED-QD groups and all their lags), sign fixed so the dominant
contemporaneous series loads positively, then orthogonalised. Unit-variance rows on the fit sample.
"""
function block_factors(super_aggs, series_names, gmap, agg_lags; fit_mask=nothing, blocks, per_block=Dict{Int,Int}(), orth=:lowdin)
    N = length(series_names); L = agg_lags
    F = Matrix{Float64}(undef, 0, size(super_aggs, 2)); labels = String[]
    for (b, groups) in enumerate(blocks)
        ids = [i for i in 1:N if get(gmap, series_names[i], 0) in groups]
        isempty(ids) && error("block $(groups) ($(block_label(groups))) has no series in the panel")
        rows = [agg_row(i, ℓ, N, L) for ℓ in 0:L for i in ids]       # the first length(ids) rows are contemporaneous
        k = get(per_block, b, 1)
        proj_b, s_b, _ = _pca_scores(super_aggs[rows, :], fit_mask, k)
        for j in 1:size(s_b, 1)
            c = proj_b[1:length(ids), j]
            c[argmax(abs.(c))] < 0 && (s_b[j, :] .*= -1)
        end
        F = vcat(F, s_b)
        append!(labels, [block_label(groups) * (k > 1 ? " ($j)" : "") for j in 1:k])
    end
    F_orth = orthogonalise(F, fit_mask, orth)
    proj = super_aggs * F_orth' ./ size(F_orth, 2)
    return proj, F_orth, labels
end

"""PCA on the rows of the selected series (all lags); top-K unit-variance scores; proj zero on unselected rows."""
function targeted_factors(super_aggs, series_names, selected, agg_lags, K; fit_mask=nothing)
    N = length(series_names); L = agg_lags
    sel = Set(String.(selected))
    ids = findall(s -> s in sel, series_names)
    length(ids) == length(sel) || @warn "targeted: $(length(sel) - length(ids)) selected series are not in the panel"
    isempty(ids) && error("targeted: no selected series found in the panel")
    rows = [agg_row(i, ℓ, N, L) for ℓ in 0:L for i in ids]
    proj_s, scores, _ = _pca_scores(super_aggs[rows, :], fit_mask, K)
    proj = zeros(size(super_aggs, 1), size(scores, 1))
    proj[rows, :] .= proj_s
    return proj, scores
end

"""Append residual PCs (orthogonal to `scores`) so a K-row panel has the model's scores as rows 1:k —
what MDD.af_correction needs from a non-PCA block."""
function complete_agg_panel(scores, super_aggs, K; fit_mask=nothing)
    k = size(scores, 1)
    K <= k && return scores, super_aggs * scores' ./ size(scores, 2)
    Bo = (super_aggs * scores') / (scores * scores')
    R = super_aggs - Bo * scores
    _, extra, _ = _pca_scores(R, fit_mask, K - k)
    S = vcat(scores, extra)
    return S, super_aggs * S' ./ size(S, 2)
end

targeted_selection_file(spec) = joinpath(AGG_BLOCKS_DIR, "targeted_" * lowercase(strip(String(spec))) * ".csv")

"""select_aggregates branch for agg_mode ∈ (:blocks, :targeted); K = the count perform_pca would keep."""
function alternative_agg_block(mode, super_aggs, series_names, agg_lags, K; fit_mask=nothing, spec="")
    if mode == :blocks
        blocks, per_block, orth = parse_block_spec(spec)
        gmap = fredqd_group_map(series_names)
        proj, scores, labels = block_factors(super_aggs, series_names, gmap, agg_lags; fit_mask, blocks, per_block, orth)
        k = size(scores, 1)
        @info "Aggregate block (:blocks, spec $(repr(spec)), $(orth)): $k factors — " * join(labels, "; ")
        if K < k
            @warn "agg_mode = :blocks: $k block factors but $K requested — keeping the first $K in spec order"
            scores = scores[1:K, :]; proj = proj[:, 1:K]
        elseif K > k
            @info "agg_mode = :blocks: $k block factors padded to $K with residual PCs (rows 1:$k unchanged — MDD af_correction)"
            scores, proj = complete_agg_panel(scores, super_aggs, K; fit_mask)
        end
    elseif mode == :targeted
        f = targeted_selection_file(spec)
        isfile(f) || error("agg_mode = :targeted: selection file not found: $f (run aggregate_block_diagnostics.jl)")
        selected = String.(CSV.read(f, DataFrame).series)
        proj, scores = targeted_factors(super_aggs, series_names, selected, agg_lags, K; fit_mask)
        @info "Aggregate block (:targeted, $(length(selected)) series from $(basename(f))): $(size(scores, 1)) factors"
    else
        error("agg_mode must be :pca, :blocks or :targeted (got $mode)")
    end
    @info "Aggregate block: keeping $(size(proj, 2)) factors (projection $(size(proj)))"
    return proj, scores
end

# ── evaluation helpers (aggregate_block_diagnostics.jl) ───────────────────────
"""Contiguous time folds with a `purge` gap on each side of the test block (the panel carries 4 lags)."""
function blocked_folds(T; nfold=5, purge=4)
    edges = round.(Int, range(0, T; length = nfold + 1))
    folds = Tuple{Vector{Int},Vector{Int}}[]
    for f in 1:nfold
        test = (edges[f]+1):edges[f+1]
        train = [t for t in 1:T if t < first(test) - purge || t > last(test) + purge]
        push!(folds, (train, collect(test)))
    end
    return folds
end

function ridge_fit(X, y, λ)
    μx = mean(X, dims = 1); μy = mean(y)
    Xc = X .- μx; yc = y .- μy
    T, p = size(Xc)
    λ = max(λ, 1e-8)
    β = p <= T ? (Xc'Xc + λ * I) \ (Xc'yc) : Xc' * ((Xc * Xc' + λ * I) \ yc)
    return β, μy - dot(vec(μx), β)
end

"""In-sample R² of each column of Y on X (OLS with a negligible ridge)."""
function insample_r2(X, Y)
    [begin
        β, b0 = ridge_fit(X, Y[:, j], 1e-8)
        1 - sum(abs2, Y[:, j] .- (X * β .+ b0)) / sum(abs2, Y[:, j] .- mean(Y[:, j]))
    end for j in 1:size(Y, 2)]
end

"""
    oof_r2(X, Y; nfold, purge, λs, nested) -> per-target out-of-fold R²

Purged blocked CV; SSE pooled over folds against the training mean (so a useless predictor
scores ≈ 0 and a harmful one < 0). λ (× n) is chosen per fold by an inner blocked CV on the
training block when `nested`; λs = [0] gives plain OLS.
"""
function oof_r2(X, Y; nfold=5, purge=4, λs=[0.0, 1e-3, 1e-2, 1e-1, 1.0, 10.0], nested=true)
    T, m = size(Y)
    folds = blocked_folds(T; nfold, purge)
    r2 = zeros(m)
    for j in 1:m
        y = Y[:, j]; sse = 0.0; sst = 0.0
        for (tr, te) in folds
            λbest = λs[1]
            if nested && length(λs) > 1
                best = -Inf
                inner = blocked_folds(length(tr); nfold = min(nfold, 4), purge)
                for λ in λs
                    s = 0.0; ss = 0.0
                    for (tr2, te2) in inner
                        β, b0 = ridge_fit(X[tr[tr2], :], y[tr[tr2]], λ * length(tr2))
                        s += sum(abs2, y[tr[te2]] .- (X[tr[te2], :] * β .+ b0))
                        ss += sum(abs2, y[tr[te2]] .- mean(y[tr[tr2]]))
                    end
                    sc = 1 - s / ss
                    sc > best && (best = sc; λbest = λ)
                end
            end
            β, b0 = ridge_fit(X[tr, :], y[tr], λbest * length(tr))
            sse += sum(abs2, y[te] .- (X[te, :] * β .+ b0))
            sst += sum(abs2, y[te] .- mean(y[tr]))
        end
        r2[j] = 1 - sse / sst
    end
    return r2
end

"""Marginal screening (Bai–Ng targeted predictors): OOF R² of every target on each column alone;
column score = mean over targets of max(R², 0); series score = best of its lags."""
function screen_marginal(X, Y, N, agg_lags; nfold=5, purge=4)
    P = size(X, 2)
    colscore = zeros(P)
    for jx in 1:P
        colscore[jx] = mean(max.(oof_r2(X[:, jx:jx], Y; nfold, purge, λs = [0.0], nested = false), 0.0))
    end
    sscore = [maximum(colscore[[agg_row(i, ℓ, N, agg_lags) for ℓ in 0:agg_lags]]) for i in 1:N]
    return sscore, colscore
end

"""LASSO by coordinate descent (X standardised columns, y centred)."""
function lasso_cd(X, y, λ; maxit=300, tol=1e-6, β0=nothing)
    T, p = size(X)
    β = β0 === nothing ? zeros(p) : copy(β0)
    r = y - X * β
    xx = vec(sum(abs2, X, dims = 1)) ./ T
    for _ in 1:maxit
        Δ = 0.0
        for j in 1:p
            xj = view(X, :, j)
            bj = β[j]
            ρ = dot(xj, r) / T + bj * xx[j]
            bn = sign(ρ) * max(abs(ρ) - λ, 0.0) / xx[j]
            if bn != bj
                r .-= xj .* (bn - bj); β[j] = bn
                Δ = max(Δ, abs(bn - bj))
            end
        end
        Δ < tol && break
    end
    return β
end

"""Per target: λ path, λ by purged blocked CV; returns the union of the selected columns."""
function lasso_select(X, Y; nfold=5, purge=4, nλ=15)
    Xs = (X .- mean(X, dims = 1)) ./ std(X, dims = 1)
    sel = Set{Int}()
    for j in 1:size(Y, 2)
        y = Y[:, j] .- mean(Y[:, j])
        λmax = maximum(abs.(Xs' * y)) / length(y)
        λs = λmax .* (10 .^ range(-0.1, -2; length = nλ))
        folds = blocked_folds(length(y); nfold, purge)
        best = -Inf; λbest = λs[1]
        for λ in λs
            sse = 0.0; sst = 0.0
            for (tr, te) in folds
                β = lasso_cd(Xs[tr, :], y[tr] .- mean(y[tr]), λ)
                sse += sum(abs2, y[te] .- (Xs[te, :] * β .+ mean(y[tr])))
                sst += sum(abs2, y[te] .- mean(y[tr]))
            end
            sc = 1 - sse / sst
            sc > best && (best = sc; λbest = λ)
        end
        β = lasso_cd(Xs, y, λbest)
        union!(sel, findall(!=(0.0), β))
    end
    return sort(collect(sel))
end

"""NIPALS PLS of Y on X (both T×·, columns standardised); returns the p×k weights W* that map RAW X to scores."""
function pls_weights(X, Y, k)
    Xr = copy(X); Yr = copy(Y)
    p = size(X, 2)
    W = zeros(p, k); P = zeros(p, k)
    for a in 1:k
        u = Yr[:, argmax(vec(var(Yr, dims = 1)))]
        w = Xr' * u; t = Xr * w
        for _ in 1:500
            w = Xr' * u; w ./= norm(w); t = Xr * w
            q = Yr' * t; q ./= norm(q)
            unew = Yr * q
            conv = norm(unew - u) / (norm(u) + eps())
            u = unew
            conv < 1e-9 && break
        end
        pa = Xr' * t / dot(t, t)
        Xr .-= t * pa'
        Yr .-= t * (Yr' * t / dot(t, t))'
        W[:, a] = w; P[:, a] = pa
    end
    return W * inv(P' * W)
end

"""Principal angles (degrees, largest first) between the row spaces of F1 and F2 (k × T)."""
function principal_angles(F1, F2)
    Q1 = Matrix(qr(Matrix(F1')).Q)[:, 1:size(F1, 1)]
    Q2 = Matrix(qr(Matrix(F2')).Q)[:, 1:size(F2, 1)]
    σ = svdvals(Q1' * Q2)
    return sort(acosd.(clamp.(σ, -1.0, 1.0)); rev = true)
end

"""First- and fourth-order autocorrelation of each row."""
function row_autocorr(F, lag)
    [cor(F[i, 1:end-lag], F[i, 1+lag:end]) for i in 1:size(F, 1)]
end

"""
    fevd_factor_shares(Φ_sub, Ω; r, q, horizon, shock_order, type) -> aggregate share (%) per factor

The factor-level part of FEVD.fevd_dist_vs_agg (ψ_s = JΦ^sB, squared responses summed to the
horizon), without the observable mapping and without writing files. `horizon = Inf` sums until
the increments vanish (unconditional variance). type = :block_cholesky (the paper) or
:generalized (Pesaran–Shin, no orthogonalisation; shares then need not add to 100).
"""
function fevd_factor_shares(Φ_sub, Ω; r, q, horizon=20, shock_order=:agg_first, type=:block_cholesky)
    n = size(Φ_sub, 1)
    J = zeros(r, n); J[:, 1:r] .= I(r)
    S_f = zeros(n, r); S_f[1:r, 1:r] .= I(r)
    S_y = zeros(n, q); S_y[r+1:r+q, 1:q] .= I(q)
    S = shock_order === :agg_first ? hcat(S_y, S_f) : hcat(S_f, S_y)
    agg_idx = shock_order === :agg_first ? (1:q) : (r+1:r+q)
    num_agg = zeros(r); denom = zeros(r)
    Φs = Matrix{Float64}(I, n, n)
    H = isfinite(horizon) ? Int(horizon) : 4000
    if type == :block_cholesky
        B = get_structural_mat(Ω, S, r, q; type = :block_cholesky, shock_order = shock_order)
        for s in 0:H-1
            ψ = J * Φs * B
            inc_a = sum(abs2, ψ[:, agg_idx]; dims = 2)[:]; inc = sum(abs2, ψ; dims = 2)[:]
            num_agg .+= inc_a; denom .+= inc
            Φs = Φs * Φ_sub
            !isfinite(horizon) && maximum(inc) < 1e-12 * maximum(denom) && break
        end
    else
        Ωs = Symmetric(S' * Ω * S); σ = diag(Ωs)
        for s in 0:H-1
            ψ = J * Φs * S                                   # r × (r+q) reduced-form responses
            G = ψ * Ωs                                       # r × (r+q)
            inc_a = vec(sum(G[:, agg_idx] .^ 2 ./ σ[agg_idx]'; dims = 2))
            inc = diag(ψ * Ωs * ψ')
            num_agg .+= inc_a; denom .+= inc
            Φs = Φs * Φ_sub
            !isfinite(horizon) && maximum(inc) < 1e-12 * maximum(denom) && break
        end
    end
    return 100 .* num_agg ./ denom
end
