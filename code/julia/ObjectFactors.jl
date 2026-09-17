# ─────────────────────────────────────────────────────────────────────────────
# ObjectFactors.jl — shared + object-specific factors (doc/object_factors.tex).
#
#   ỷ_jt = H_jt ( Λ f_t + Σ_o Λ̄_o g_{o,t} ) + e_jt
#   g_{o,t} = Φ_o g_{o,t-1} + ζ_{o,t},   ζ ~ N(0, diag(ω_o²)),  independent of η_t
#
# An OBJECT is a block of coefficient rows with one set of dynamics: the 3D
# copula (all Legendre degrees ≥ 1), the three 2D copula slices (exactly one
# degree = 0), the three percentile functions. Λ̄_o is zero outside the
# object's rows. The specific blocks are block-diagonal AR(1)s alongside the
# untouched shared block — the restriction that separates "specific" from "a
# spare shared factor" (tex §5).
#
# Implementation follows the stochastic-trend augmentation: the core
# recursions are untouched; the state is augmented at the likelihood boundary
# ([f, τ, g] within each lag block), G gets extra columns (masked, lag-weighted,
# whitened exactly as the f-columns), and the smoother output is collapsed back
# to the baseline layout with the g path stashed for the reconstruction. The
# new parameters ride at the END of the trend block: θ_blk = [θ_τ (2r+1); θ_g],
# so every existing slice by st_ntrend(param_sizes) keeps working.
#
# v1 scope: trend_spec = :stochastic only (the :hp likelihood is not
# augmented); Kalman-EM driver refuses to run with object factors active.
# Downstream consumers that see only the COLLAPSED (f+τ, a) states — forecasts,
# FEVD's observable mapping, historical decomposition, factor-draw export, the
# anatomy shares — carry the shared block only; the reconstruction (and hence
# every HANK validation panel and cross-conditional cell) includes g.
# Priors on the appended block INCLUDE the transform Jacobians (unlike the trend
# block): with ω_g → 0 the designed outcome for a fully-shared object, a flat raw
# tail would let chains wander to −∞; the Jacobian makes the raw prior proper.
#
# Spec string (ModelOptions.object_factors): "3D:1@0.98,IW:1"
#   name  ∈ {3D, CI, CW, IW, C, I, W}  (letters = first letter of a measure)
#   :k    number of specific factors for that object
#   @φ    optional FIXED persistence (else estimated) — required in practice for
#         an object observed by one wave-frequency dataset (the 3D block, tex §5(iii))
# ─────────────────────────────────────────────────────────────────────────────

const OBJECT_FACTORS = Ref{Any}(nothing)    # set by compute_object_loadings! at prep
const OF_LAST_G      = Ref{Any}(nothing)    # smoothed g states (4·r_g × T), lag blocks in order
const _OF_G_CACHE    = Ref{Any}(nothing)    # (objectid(G), objectid(Λ̄), r_g) => Gg (whitened, masked, per t)
const _OF_GFULL_CACHE = Ref{Any}(nothing)   # (objectid(G), objectid(Λ̄), r, rτ, r_g) => G̃ with [f, τ, g] per lag block
const OF_PHI_MAX     = 0.995                # |φ| < OF_PHI_MAX via tanh
const OF_OMEGA_FLOOR = 1e-4                 # ω_g floor: exactly-zero innovation variance makes the smoother's backward pass singular

of_active() = OBJECT_FACTORS[] !== nothing && OBJECT_FACTORS[].r_g > 0
function of_clear_caches!()
    _OF_G_CACHE[] = nothing
    _OF_GFULL_CACHE[] = nothing
    return nothing
end
"Reset all object-factor state (call before the main perform_pca of a prep so proof-of-concept calls cannot leave stale loadings)."
function of_reset!()
    OBJECT_FACTORS[] = nothing
    OF_LAST_G[] = nothing
    of_clear_caches!()
end
of_rg() = of_active() ? OBJECT_FACTORS[].r_g : 0

# ── spec ─────────────────────────────────────────────────────────────────────
function parse_object_factor_spec(s::AbstractString)
    out = NamedTuple{(:name, :r, :phi_fixed), Tuple{Symbol, Int, Union{Nothing, Float64}}}[]
    for tok in split(strip(s), ',')
        isempty(strip(tok)) && continue
        m = match(r"^\s*([A-Za-z0-9]+)\s*:\s*(\d+)\s*(?:@\s*([0-9.]+))?\s*$", tok)
        m === nothing && error("object_factors: cannot parse '$(tok)' (expected e.g. 3D:1@0.98 or IW:1)")
        name = uppercase(m.captures[1])
        name = name == "3D" ? "cop3D" : join(sort(collect(name)))      # slices order-insensitive: "WI" → "IW"
        r    = parse(Int, m.captures[2])
        φ    = m.captures[3] === nothing ? nothing : parse(Float64, m.captures[3])
        φ !== nothing && !(0 <= φ < 1) && error("object_factors: fixed φ must be in [0,1), got $(φ) for $(name)")
        r > 0 && push!(out, (name = Symbol(name), r = r, phi_fixed = φ))
    end
    return out
end

measure_letter(m::AbstractString) = uppercase(string(first(m)))

# ── row sets: the partition of the coefficient vector by zero Legendre indices ──
"""
    object_row_sets(measures, estimator) -> Dict{Symbol, Vector{Int}}

Rows of the standardized coefficient vector belonging to each object. The
copula vector is `remove_immutable` applied to the K^D tensor in Julia
column-major order (DataConstructor.jl): entries with ≥ D-1 zero degrees are
dropped, the rest kept in order. A kept entry with NO zero degree is the 3D
block; with exactly one zero degree it belongs to the 2D slice of the other two
measures. Percentile-function rows follow the copula rows in `measures` order
(`id_dict` in set_measurements).
"""
function object_row_sets(measures, estimator)
    @unpack grid_pcf, grid_cop = estimator
    D = length(measures)
    K = grid_cop
    letters = [measure_letter(m) for m in measures]
    rows = Dict{Symbol, Vector{Int}}()
    row = 0
    for c in CartesianIndices(ntuple(_ -> K, D))
        nzero = count(==(1), c.I)                 # index 1 ↔ degree 0
        nzero >= D - 1 && continue                # immutable, not in the vector
        row += 1
        nz = findall(!=(1), c.I)                  # measures the entry varies with
        name = length(nz) == D ? :cop3D : Symbol(join(sort(letters[nz])))
        push!(get!(rows, name, Int[]), row)
    end
    cop_part, imm_part = retrieve_cop_and_imm_part(estimator, D)
    row == cop_part - imm_part || error("object_row_sets: enumerated $(row) copula rows, expected $(cop_part - imm_part)")
    for (i, m) in enumerate(measures)
        rows[Symbol(letters[i])] = collect(row + (i - 1) * grid_pcf + 1 : row + i * grid_pcf)
    end
    return rows
end

# ── loadings: PCA of each object's residual after the shared factors ──────────
"""
    compute_object_loadings!(pool, proj, measures, estimator, model_options)

For each object in the spec: take the pool columns (dataset-periods) at which
the object is fully observed, the least-squares shared scores on those columns
(from every observed row of the column), the residual on the object's rows,
and its leading r_o principal components with unit-variance scores. Stores the
result in OBJECT_FACTORS[]. `proj` is the FINAL shared loading matrix.
"""
function compute_object_loadings!(pool, proj, measures, estimator, model_options)
    spec_s = hasproperty(model_options, :object_factors) ? String(model_options.object_factors) : ""
    spec = parse_object_factor_spec(spec_s)
    if isempty(spec)
        OBJECT_FACTORS[] = nothing
        return nothing
    end
    hasproperty(model_options, :trend_spec) && model_options.trend_spec == :stochastic ||
        error("object_factors requires trend_spec = :stochastic in this version (the :hp likelihood is not augmented)")
    rows = object_row_sets(measures, estimator)
    n, r = size(proj)
    loadings = Matrix{Float64}[]
    names = Symbol[]; rs = Int[]; phis = Union{Nothing, Float64}[]
    for o in spec
        haskey(rows, o.name) || error("object_factors: unknown object $(o.name); known: $(sort(collect(keys(rows))))")
        R = rows[o.name]
        cols = findall(j -> all(!isnan, @view pool[R, j]), axes(pool, 2))
        length(cols) > o.r + 1 || error("object_factors: object $(o.name) is observed in only $(length(cols)) pool columns — cannot extract $(o.r) factor(s)")
        # shared scores on those columns, from every observed row of the column
        F̂ = zeros(r, length(cols))
        for (k, j) in enumerate(cols)
            obs = findall(!isnan, @view pool[:, j])
            Λo = proj[obs, :]
            F̂[:, k] = (Λo' * Λo + 1e-8 * I) \ (Λo' * pool[obs, j])
        end
        Rres = pool[R, cols] .- proj[R, :] * F̂
        Rres .-= mean(Rres; dims = 2)          # centre over the object's own columns (pooled across datasets)
        Fsv = svd(Rres)
        ro = min(o.r, length(Fsv.S) - 1)
        ncol = length(cols)
        Λ_o = Fsv.U[:, 1:ro] * Diagonal(Fsv.S[1:ro] ./ sqrt(ncol - 1))    # scores √(n-1)·V' have unit variance
        share = round(100 * sum(abs2, Fsv.S[1:ro]) / max(sum(abs2, Fsv.S), eps()); digits = 1)
        shared_share = round(100 * (1 - sum(abs2, Rres) / max(sum(abs2, pool[R, cols]), eps())); digits = 1)
        @info "Object factor $(o.name): $(length(R)) rows, observed in $(ncol) dataset-periods; shared factors explain " *
              "$(shared_share)% of the object's variance, $(ro) specific factor(s) explain $(share)% of the residual" *
              (o.phi_fixed === nothing ? "; φ estimated" : "; φ fixed at $(o.phi_fixed)")
        push!(loadings, Λ_o); push!(names, o.name); push!(rs, ro); push!(phis, o.phi_fixed)
    end
    r_g = sum(rs)
    # embedded loading matrix Λ̄ (n × r_g): zero outside each object's rows
    Λbar = zeros(n, r_g)
    col = 0
    for (k, nm) in enumerate(names)
        Λbar[rows[nm], col+1:col+rs[k]] .= loadings[k]
        col += rs[k]
    end
    OBJECT_FACTORS[] = (spec = spec, rows = rows, names = names, r = rs, phi_fixed = phis,
                        loadings = loadings, Λbar = Λbar, r_g = r_g, n_coef = n, Gj_g = nothing)
    of_clear_caches!()
    @info "Object factors active: $(r_g) specific state(s) [$(join(["$(names[k])×$(rs[k])" for k in eachindex(names)], ", "))]; " *
          "$(of_nparams()) parameters appended to the trend block"
    return OBJECT_FACTORS[]
end

# ── parameter block: [φ_raw (estimated ones) ; ω_raw] per object, in spec order ──
"Number of appended parameters: one ω per specific factor, plus one φ per factor whose φ is not fixed."
function of_nparams()
    of_active() || return 0
    O = OBJECT_FACTORS[]
    return sum(O.r) + sum(O.r[k] for k in eachindex(O.r) if O.phi_fixed[k] === nothing; init = 0)
end

of_sp(x)  = x > 35 ? x : log1p(exp(x))
of_isp(y) = y > 35 ? y : log(expm1(y))
of_phi(raw) = OF_PHI_MAX * tanh(raw)
of_phi_inv(φ) = atanh(clamp(φ / OF_PHI_MAX, -0.999999, 0.999999))

"Initial raw values (φ ≈ 0.9 where estimated; ω ≈ 0.05)."
function of_initials()
    of_active() || return Float64[]
    O = OBJECT_FACTORS[]
    θ = Float64[]
    for k in eachindex(O.names)
        O.phi_fixed[k] === nothing && append!(θ, fill(of_phi_inv(0.9), O.r[k]))
        append!(θ, fill(-3.0, O.r[k]))
    end
    return θ
end

"Placeholder priors for the sampler's init/step machinery (the block's log-prior is evaluated in of_logprior)."
function of_placeholder_priors()
    of_active() || return Distribution[]
    O = OBJECT_FACTORS[]
    p = Distribution[]
    for k in eachindex(O.names)
        O.phi_fixed[k] === nothing && append!(p, fill(Normal(of_phi_inv(0.9), 0.5), O.r[k]))
        append!(p, fill(truncated(Cauchy(0.0, 1.0), 0.0, Inf), O.r[k]))
    end
    return p
end

"Step ranges in raw coordinates."
function of_step_ranges()
    of_active() || return Tuple{Float64, Float64}[]
    O = OBJECT_FACTORS[]
    rg = Tuple{Float64, Float64}[]
    for k in eachindex(O.names)
        O.phi_fixed[k] === nothing && append!(rg, fill((-2.0, 3.0), O.r[k]))
        append!(rg, fill((-6.0, 0.5), O.r[k]))
    end
    return rg
end

"""
    of_unpack(θg) -> (Φ_g::Vector, ω_g::Vector, ok::Bool)

Transform the appended block into per-state persistence and innovation sd.
"""
function of_unpack(θg)
    O = OBJECT_FACTORS[]
    length(θg) == of_nparams() || return Float64[], Float64[], false
    Φ = Float64[]; ω = Float64[]
    i = 0
    for k in eachindex(O.names)
        if O.phi_fixed[k] === nothing
            append!(Φ, of_phi.(θg[i+1:i+O.r[k]])); i += O.r[k]
        else
            append!(Φ, fill(O.phi_fixed[k], O.r[k]))
        end
        append!(ω, max.(of_sp.(θg[i+1:i+O.r[k]]), OF_OMEGA_FLOOR)); i += O.r[k]
    end
    ok = i == length(θg) && all(isfinite, Φ) && all(x -> isfinite(x) && x > 0, ω)
    return Φ, ω, ok
end

"""
    of_logprior(Φ, ω, θg)

Log-prior of the appended block INCLUDING the transform Jacobians, so the prior
is proper in the raw coordinates the sampler moves in:
  ω = softplus(x):   log dω/dx = x − softplus(x)        (→ −|x| as x → −∞)
  φ = c·tanh(x):     log dφ/dx = log c + log(1 − tanh²x)  (→ −2|x| as |x| → ∞)
Without them a fully-shared object (ω_g → 0, the designed outcome) leaves a
flat raw tail the chains wander along.
"""
function of_logprior(Φ, ω, θg)
    O = OBJECT_FACTORS[]
    lp = 0.0
    i = 0; j = 0                                # i indexes Φ/ω, j indexes the raw block
    for k in eachindex(O.names)
        if O.phi_fixed[k] === nothing
            xφ = θg[j+1:j+O.r[k]]; j += O.r[k]
            lp += sum(logpdf.(Normal(0.9, 0.15), Φ[i+1:i+O.r[k]]))
            lp += sum(log(OF_PHI_MAX) .+ log.(max.(1 .- tanh.(xφ) .^ 2, 1e-300)))
        end
        xω = θg[j+1:j+O.r[k]]; j += O.r[k]
        lp += sum(logpdf.(Cauchy(0.0, 1.0), ω[i+1:i+O.r[k]])) + O.r[k] * log(2)
        lp += sum(xω .- of_sp.(xω))
        i += O.r[k]
    end
    return lp
end

# ── measurement columns for the g states ─────────────────────────────────────
"""
    of_build_Gg(model_elements, model_options) -> (Gg::Vector{Matrix}, Gj_g::Vector{Matrix})

Per-period measurement columns for the specific states (N × 4·r_g), built
exactly as the f-columns are: per-dataset lag weights read off Gⱼ (contemporaneous
or annual tent), masked by the raw observation pattern, then whitened with the
same pre_multiply_part! when pre_multiply is on. Gj_g (per dataset, n × 4·r_g,
raw) is kept for the reconstruction.
"""
function of_build_Gg(model_elements, model_options)
    O = OBJECT_FACTORS[]
    @unpack MV, Gⱼ, proj, y = model_elements
    r = size(proj, 2); n = size(proj, 1); n_dfs = length(Gⱼ); N_dist = n_dfs * n; T = size(y, 2)
    r_g = O.r_g
    size(O.Λbar, 1) == n || error("object factors: loadings have $(size(O.Λbar, 1)) rows, model has $(n)")
    # lag weights per stacked row, as in run_kalman_em.jl
    Gj_g = [zeros(n, 4r_g) for _ in 1:n_dfs]
    for j in 1:n_dfs, i in 1:n
        k = argmax(abs.(proj[i, :]))
        proj[i, k] == 0 && continue
        for lag in 0:3
            w = Gⱼ[j][i, lag * r + k] / proj[i, k]
            w == 0 && continue
            @views Gj_g[j][i, lag * r_g + 1 : (lag + 1) * r_g] .= w .* O.Λbar[i, :]
        end
    end
    proj_g = vcat(Gj_g...)                              # N_dist × 4r_g
    y_raw = Matrix{Float64}(vcat(MV...))
    y_full_raw = vcat(y_raw, y[N_dist+1:end, :])
    Gg_raw = [zeros(size(y, 1), 4r_g) for _ in 1:T]
    for t in 1:T
        mask = .!isnan.(@view y_raw[:, t])
        @views Gg_raw[t][1:N_dist, :] .= Diagonal(mask) * proj_g
    end
    premult = hasproperty(model_options, :pre_multiply) ? model_options.pre_multiply : true
    Gg = Gg_raw
    if premult
        Σ̂ = model_elements.boot_noise_processes
        size(Σ̂, 1) == N_dist || error("object factors: whitening matrix is $(size(Σ̂)), expected $(N_dist)×$(N_dist)")
        _, Gg = pre_multiply_part!(y_full_raw, Gg_raw, Σ̂, 4r_g)
    end
    return Gg, Gj_g
end

function of_Gg_cached(model_elements, model_options)
    key = (objectid(model_elements.G), objectid(OBJECT_FACTORS[].Λbar), of_rg())
    c = _OF_G_CACHE[]
    (c !== nothing && c[1] == key) && return c[2]
    Gg, Gj_g = of_build_Gg(model_elements, model_options)
    O = OBJECT_FACTORS[]
    OBJECT_FACTORS[] = merge(O, (Gj_g = Gj_g,))
    _OF_G_CACHE[] = (key, Gg)
    return Gg
end

"""
    of_augment_G(G, r, rτ, Gg) -> G̃

States per lag block go [f (r), τ (rτ), g (r_g)]; f and τ columns as in
st_augment_G, g columns from Gg (already masked and whitened).
"""
function of_augment_G(G::AbstractVector, r::Int, rτ::Int, Gg::AbstractVector)
    r_g = size(Gg[1], 2) ÷ 4
    r̃ = r + rτ + r_g
    map(eachindex(G)) do t
        Gt = G[t]
        n = size(Gt, 1)
        q = size(Gt, 2) - 4r
        G̃ = zeros(eltype(Gt), n, 4r̃ + q)
        for lag in 0:3
            src = lag * r .+ (1:r)
            G̃[:, lag * r̃ .+ (1:r)] .= @view Gt[:, src]
            G̃[:, lag * r̃ + r .+ (1:rτ)] .= @view Gt[:, src[1:rτ]]
            G̃[:, lag * r̃ + r + rτ .+ (1:r_g)] .= @view Gg[t][:, lag * r_g .+ (1:r_g)]
        end
        G̃[:, 4r̃+1:end] .= @view Gt[:, 4r+1:end]
        G̃
    end
end

"""
    of_augment_system(Ã, B̃, C̃, Ω̃_f, Φ_g, ω_g)

Append the independent AR(1) specific blocks to an (already trend-augmented)
system: block-diagonal in the transition and the innovation covariance, zero
rows/columns against the aggregates.
"""
function of_augment_system(Ã, B̃, C̃, Ω̃_f, Φ_g, ω_g)
    r̃ = size(Ã, 1); r_g = length(Φ_g); T = eltype(Ã)
    Ã2 = [Ã zeros(T, r̃, r_g); zeros(T, r_g, r̃) diagm(Φ_g)]
    B̃2 = [B̃; zeros(T, r_g, size(B̃, 2))]
    C̃2 = [C̃ zeros(T, size(C̃, 1), r_g)]
    Ω̃2 = [Ω̃_f zeros(T, r̃, r_g); zeros(T, r_g, r̃) diagm(ω_g .^ 2)]
    return Ã2, B̃2, C̃2, Ω̃2
end

"Full augmented measurement matrices [f, τ, g]; cached like st_G_cached."
function of_G_full_cached(model_elements, model_options, r::Int, rτ::Int)
    key = (objectid(model_elements.G), objectid(OBJECT_FACTORS[].Λbar), r, rτ, of_rg())
    c = _OF_GFULL_CACHE[]
    (c !== nothing && c[1] == key) && return c[2]
    Gg = of_Gg_cached(model_elements, model_options)
    G̃ = of_augment_G(model_elements.G, r, rτ, Gg)
    _OF_GFULL_CACHE[] = (key, G̃)
    return G̃
end

# ── self-test ─────────────────────────────────────────────────────────────────
"""
    of_selftest(; r=3, rτ=2, rg=2, q=2, T=40, n=12, seed=7)

With ω_g = 0 the g states stay at zero and the augmented likelihood must equal
the trend-augmented one to machine precision; with ω_g > 0 it must differ.
"""
function of_selftest(; r = 3, rτ = r, rg = 2, q = 2, T = 40, n = 12, seed = 7)   # rτ = r: one trend per factor, as in st_likeli (the collapse assumes it)
    rng = Random.MersenneTwister(seed)
    A = 0.6 .* Matrix(Diagonal(rand(rng, r))) .+ 0.05 .* randn(rng, r, r)
    while maximum(abs.(eigvals(A))) >= 0.95; A .*= 0.9; end
    B = 0.1 .* randn(rng, r, q); C = 0.1 .* randn(rng, q, r); D = 0.5 .* Matrix(Diagonal(rand(rng, q)))
    Ω_f = let M = randn(rng, r, r); Matrix(Symmetric(M * M' ./ r + I)) end
    Ω_y = let M = randn(rng, q, q); Matrix(Symmetric(M * M' ./ q + I)) end
    Σ = 0.5 .* ones(n); y = randn(rng, n, T)
    G = [begin Gt = zeros(n, 4r + q); Gt[:, 1:r] .= randn(rng, n, r); Gt[:, 4r+1:end] .= 0.1 .* randn(rng, n, q); Gt end for _ in 1:T]
    Gg = [begin Gt = zeros(n, 4rg); Gt[:, 1:rg] .= randn(rng, n, rg); Gt end for _ in 1:T]
    ω_τ = 0.3 .* ones(rτ)
    Ã, B̃, C̃, Ω̃ = st_augment_system(A, B, C, Ω_f, ω_τ)
    G̃τ = st_augment_G(G, r, rτ)
    base, _ = recurse_kalman_filter_forward(Ã, B̃, C̃, D, Ω̃, Ω_y, Σ, G̃τ, y)
    G̃ = of_augment_G(G, r, rτ, Gg)
    Ã0, B̃0, C̃0, Ω̃0 = of_augment_system(Ã, B̃, C̃, Ω̃, 0.9 .* ones(rg), zeros(rg))
    aug0, _ = recurse_kalman_filter_forward(Ã0, B̃0, C̃0, D, Ω̃0, Ω_y, Σ, G̃, y)
    Ã1, B̃1, C̃1, Ω̃1 = of_augment_system(Ã, B̃, C̃, Ω̃, 0.9 .* ones(rg), 0.3 .* ones(rg))
    aug1, _ = recurse_kalman_filter_forward(Ã1, B̃1, C̃1, D, Ω̃1, Ω_y, Σ, G̃, y)
    ok_equal = isapprox(base, aug0; rtol = 1e-9)
    ok_moves = !isapprox(base, aug1; rtol = 1e-6)
    ok_equal || @warn "of_selftest: ω_g = 0 does NOT reproduce the trend-augmented likelihood ($base vs $aug0)"
    ok_moves || @warn "of_selftest: ω_g > 0 does not change the likelihood"
    # smoother leg: with ω_g ≈ 0 (1e-10, bypassing the floor — the floor's own
    # footprint is ~1e-6) the collapsed f must match the trend-only smoother, and
    # the stashed g block must have the right shape
    smτ, _, _ = recurse_kalman_filter_smoother(Ã, B̃, C̃, D, Ω̃, Ω_y, Σ, G̃τ, y)
    cτ = st_collapse_smoother(smτ, r, rτ)
    Ãs, B̃s, C̃s, Ω̃s = of_augment_system(Ã, B̃, C̃, Ω̃, 0.9 .* ones(rg), fill(1e-10, rg))
    smg, _, _ = recurse_kalman_filter_smoother(Ãs, B̃s, C̃s, D, Ω̃s, Ω_y, Σ, G̃, y)
    cg = st_collapse_smoother(smg, r, rτ, rg)
    ok_smooth = isapprox(cτ.x_smoothed, cg.x_smoothed; atol = 1e-8) && OF_LAST_G[] !== nothing && size(OF_LAST_G[]) == (4rg, T)
    ok_smooth || @warn "of_selftest: smoother leg failed (max |Δf| = $(maximum(abs, cτ.x_smoothed .- cg.x_smoothed)), OF_LAST_G $(OF_LAST_G[] === nothing ? "unset" : size(OF_LAST_G[])))"
    OF_LAST_G[] = nothing; ST_LAST_TAU[] = nothing
    return ok_equal && ok_moves && ok_smooth
end
