# ─────────────────────────────────────────────────────────────
# PosteriorDraws.jl — export posterior draws of the smoothed factors
# ─────────────────────────────────────────────────────────────
#
# The DIME sampler (Stage 2) writes the full posterior of the parameter
# vector θ to
#
#     <BASE_PATH>/posterior_draws/<m_label>_<tag>.jld2      (key: d_chains)
#
# with `d_chains` shaped (iterations, chains, params). That file is large
# (hundreds of MB) and θ itself is not directly usable downstream — a user
# would have to re-run the Kalman smoother to turn a θ-draw into a
# distribution.
#
# `export_factor_draws` does exactly that, once, for a manageable sample of
# draws: for each sampled θ it runs the smoother and keeps `x_smoothed` (the
# latent factors, factor_count × T). The result is a compact, GitHub-friendly
# CSV — the same object as `smoothed_factors.csv`, but stacked over draws —
# that plugs straight into the `FactorMap` helper in `reconstruct.py` /
# `reconstruct.jl` to give posterior bands on any moment.
#
# This mirrors the sampling in `generate_microdata_implicates`
# (CreateTimeSeries.jl), which already draws from this same JLD2 to build the
# paper's confidence bands.
# ─────────────────────────────────────────────────────────────

using StatsBase: sample
using Random
using LinearAlgebra

# The repo's tracked synthetic-data folder (5_Code/data/synthetic), resolved
# from this file's location — robust to BASE_PATH pointing at the repo parent.
const _PD_SYNTH = joinpath(dirname(dirname(@__DIR__)), "data", "synthetic")

"""
    export_factor_draws(param_sizes, hyperpriors, Σ_ids, model_elements,
                        model_options, time_params; kwargs...)

Reconstruct the smoothed latent factors at a sample of posterior draws of θ
and write them to `data/synthetic/smoothed_factor_draws.csv` (long format:
`draw, time, x1 … xR`).

Keyword arguments
- `n_draws = 200`   : number of posterior draws to reconstruct.
- `seed = 12345`    : RNG seed for reproducible draw selection.
- `iteration = :last`: `:last` pools the final iteration of every chain
  (matches `generate_microdata_implicates`); `:all` pools every stored
  iteration × chain for more nearly-independent draws.
- `state_draws = :joint`: how the *state* is drawn around each θ-draw.
  `:joint` (default since Oct 2026) draws a whole path from p(x_{1:T} | y, θ) by
  forward-filtering backward-sampling (Carter–Kohn), so changes between dates
  within one draw carry the right uncertainty — needed for implicates.
  `:pointwise` draws x_t ~ N(x̂_{t|T}, Σ_{t|T}) independently per quarter (the
  pre-Oct-2026 behaviour; right for per-date bands only). `:none` keeps the
  smoothed mean paths (parameter uncertainty alone — bands ~0 in data-rich
  periods). `:joint` falls back to `:pointwise` for the :as_inputs and
  stochastic-trend specifications.
- `state_uncertainty = true`: legacy switch; `false` is the same as `state_draws = :none`.
- `filename = "smoothed_factor_draws.csv"`: output file name (handy for
  writing a comparison file without overwriting the default).
- `digits = 6`: decimal rounding of the written values — keeps the CSV
  GitHub-friendly (full 17-digit floats double the file size for noise far
  below posterior uncertainty). `nothing` disables rounding.
- `out_dir = nothing`: output directory (defaults to `<BASE_PATH>/data/synthetic`).
- `draws_file = nothing`: override the input JLD2 path.

Returns the path of the written CSV.
"""
function export_factor_draws(
    param_sizes, hyperpriors, Σ_ids, model_elements, model_options, time_params;
    n_draws::Int = 200, seed::Int = 12345, iteration::Symbol = :last,
    state_uncertainty::Bool = true, state_draws::Symbol = :joint, filename::String = "smoothed_factor_draws.csv",
    digits::Union{Int,Nothing} = 6, out_dir = nothing, draws_file = nothing,
)
    @unpack measures, tag = model_options
    m_label   = measures_folder(measures)
    init_path = BASE_PATH

    # ── locate and load the θ-draws ──────────────────────────────
    jld = draws_file === nothing ?
        joinpath(init_path, "posterior_draws", m_label * "_$tag.jld2") : draws_file
    isfile(jld) || error("Posterior-draws file not found: $jld\n" *
                         "Run Stage 2 (estimation) first — it writes this via DIMESampler.jl.")

    d_chains = jldopen(jld, "r") do io
        io["d_chains"]                      # (iterations, chains, params)
    end
    itr, ch, par = size(d_chains)

    # Pool of candidate draws (rows = draws, cols = params)
    pool = iteration === :all ? reshape(d_chains, itr * ch, par) : d_chains[end, :, :]
    npool = size(pool, 1)
    n_draws = min(n_draws, npool)

    Random.seed!(seed)
    draw_ids = sample(1:npool, n_draws; replace = false)

    # ── loop the smoother over draws, collect x_smoothed ─────────
    @unpack tmin, tmax = time_params
    dts = QuarterlyDate(tmin["year"], tmin["quarter"]):Quarter(1):QuarterlyDate(tmax["year"], tmax["quarter"])

    state_uncertainty || (state_draws = :none)
    state_draws in (:joint, :pointwise, :none) || error("state_draws = $(state_draws): use :joint, :pointwise or :none")
    if state_draws == :joint && !_ffbs_supported(model_options)
        @warn "state_draws = :joint is not wired for this specification (:as_inputs or stochastic trend); using :pointwise"
        state_draws = :pointwise
    end

    long = DataFrame()
    R = 0
    n_skipped = 0
    pb = Progress(n_draws, desc = "Smoothing posterior draws")
    for (s, id) in enumerate(draw_ids)
        θ = collect(pool[id, :])
        # one numerically degenerate draw (singular filter covariance) must not abort the whole export
        smoother_output = try
            likeli(model_elements, θ, param_sizes, hyperpriors, Σ_ids, model_options; smooth = true)[1]
        catch e
            e isa InterruptException && rethrow()
            n_skipped += 1
            @warn "posterior draw $id skipped: smoother failed ($(sprint(showerror, e)))" maxlog = 5
            next!(pb)
            continue
        end
        @unpack x_smoothed = smoother_output          # (factor_count, T)
        X = copy(x_smoothed)
        if state_draws == :joint
            L, r = _transition_matrix(θ, param_sizes, model_options)
            s == 1 && _ffbs_check(L, r, smoother_output)   # one-off sanity check in the log
            X = ffbs_draw(L, r, smoother_output)
        elseif state_draws == :pointwise
            # add the smoother's own state uncertainty: x_t ~ N(x̂_{t|T}, Σ_{t|T})
            @unpack sigma_smoothed = smoother_output
            for t in 1:size(X, 2)
                X[:, t] .+= _psd_sqrt(sigma_smoothed[t]) * randn(size(X, 1))
            end
        end
        R = size(X, 1)
        digits === nothing || (X = round.(X; digits = digits))
        df = DataFrame(Matrix(X'), ["x$i" for i in 1:R])
        df[!, "time"] = collect(dts)
        df[!, "draw"] .= s
        append!(long, select(df, "draw", "time", :))
        next!(pb)
    end

    out_dir = out_dir === nothing ? _PD_SYNTH : out_dir
    mkpath(out_dir)
    out = joinpath(out_dir, filename)
    CSV.write(out, long)
    unc = state_draws == :joint ? "θ + joint state paths" : state_draws == :pointwise ? "θ + pointwise state" : "θ only"
    n_skipped > 0 && @warn "$n_skipped of $n_draws posterior draws skipped (smoother failed); $(n_draws - n_skipped) written"
    @info "Wrote $(n_draws - n_skipped) posterior factor draws ($unc; $R factors × $(length(dts)) quarters) → $out"
    return out
end

_ffbs_supported(mo) = !(hasproperty(mo, :aggregate_rep) && mo.aggregate_rep == :as_inputs) &&
                      !(hasproperty(mo, :trend_spec) && mo.trend_spec == :stochastic)

# Companion transition of the :as_states filter (recurse_kalman_filter_smoother):
# state [f_t, f_{t-1}, f_{t-2}, f_{t-3}, Y_t], f_{t+1} = A f_t + B Y_t, Y_{t+1} = C f_t + D Y_t.
function _transition_matrix(θ, param_sizes, model_options)
    n_hyper = param_sizes[end][1]
    A, B, C, D = matrisize(θ[1:end-n_hyper], param_sizes)[1:4]
    r, q = size(B)
    L = zeros(eltype(A), 4r + q, 4r + q)
    L[1:r, 1:r] .= A;            L[1:r, 4r+1:end] .= B
    L[r+1:2r, 1:r] .= I(r);      L[2r+1:3r, r+1:2r] .= I(r);  L[3r+1:4r, 2r+1:3r] .= I(r)
    L[4r+1:end, 1:r] .= C;       L[4r+1:end, 4r+1:end] .= D
    return L, r
end

"""
    ffbs_draw(L, r, smoother_output; rng = Random.default_rng())

One draw of the whole state path from p(x_{1:T} | y, θ) — forward-filtering
backward-sampling (Carter and Kohn 1994; Frühwirth-Schnatter 1994). Uses the
filter output the smoother already returns: x_{t|t}, P_{t|t} (`x_updated`,
`sigma_updated`) and x_{t+1|t}, P_{t+1|t} (`x_filtered`, `sigma_filtered`).
x_T ~ N(x_{T|T}, P_{T|T}); then backwards
x_t | x_{t+1} ~ N(x_{t|t} + J_t (x_{t+1} - x_{t+1|t}), P_{t|t} - J_t L P_{t|t}),
J_t = P_{t|t} L' P_{t+1|t}^{-1}. The lag block of x_{t+1} pins f_t, f_{t-1},
f_{t-2} of x_t exactly; those rows are copied over so the path is consistent.
"""
function ffbs_draw(L, r, smoother_output; rng = Random.default_rng())
    @unpack x_filtered, sigma_filtered, x_updated, sigma_updated = smoother_output
    n, T = size(x_updated)
    X = zeros(n, T)
    X[:, T] = x_updated[:, T] .+ _psd_sqrt(sigma_updated[T]) * randn(rng, n)
    for t in (T-1):-1:1
        P = Matrix(sigma_updated[t])
        S = Symmetric(Matrix(sigma_filtered[t+1]))
        J = (pinv(S; rtol = 1e-12) * (L * P))'           # P L' S⁻¹
        m = x_updated[:, t] .+ J * (X[:, t+1] .- x_filtered[:, t+1])
        V = P .- J * L * P
        X[:, t] = m .+ _psd_sqrt((V .+ V') ./ 2) * randn(rng, n)
        X[1:3r, t] .= X[r+1:4r, t+1]                      # f_t, f_{t-1}, f_{t-2} are known exactly
    end
    return X
end

# Logged once per export: the mean of many joint draws should reproduce the
# smoothed mean, and their spread the smoothed SDs.
function _ffbs_check(L, r, smoother_output; n = 100)
    @unpack x_smoothed, sigma_smoothed = smoother_output
    rng = MersenneTwister(7)
    D = cat([ffbs_draw(L, r, smoother_output; rng = rng) for _ in 1:n]...; dims = 3)
    M = dropdims(mean(D; dims = 3); dims = 3); Sd = dropdims(std(D; dims = 3); dims = 3)
    sd_sm = reduce(hcat, [sqrt.(max.(diag(sigma_smoothed[t]), 0.0)) for t in axes(x_smoothed, 2)])
    k = 1:r
    rel_mean = maximum(abs.(M[k, :] .- x_smoothed[k, :])) / maximum(sd_sm[k, :])
    ratio = median(vec(Sd[k, 5:end] ./ sd_sm[k, 5:end]))
    @info "FFBS check ($n paths, first θ-draw): max |mean − smoothed| = $(round(rel_mean; digits = 3)) × max smoothed SD " *
          "(≈ 3/√$n expected); median draw SD / smoothed SD = $(round(ratio; digits = 2)) (≈ 1 expected)"
end

# Robust PSD square root: the smoothed state covariance can be numerically
# singular (stacked-lag rows), so plain cholesky is not safe.
function _psd_sqrt(S::AbstractMatrix)
    E = eigen(Symmetric(Matrix(S)))
    return E.vectors * Diagonal(sqrt.(max.(E.values, 0.0)))
end

"""
    summarize_factor_draws(; draws_csv=nothing, probs=(0.05, 0.5, 0.95), out_dir=nothing)

Collapse `smoothed_factor_draws.csv` into per-quarter posterior percentiles of
each factor and write `smoothed_factors_bands.csv` (columns
`time, x{i}_p05, x{i}_p50, x{i}_p95, …`). A quick sanity check; for bands on
economic *moments* rather than raw factors, use
`code/moments_from_coefficients/posterior_bands.py`.
"""
function summarize_factor_draws(; draws_csv = nothing, probs = (0.05, 0.5, 0.95), out_dir = nothing)
    draws_csv = draws_csv === nothing ?
        joinpath(_PD_SYNTH, "smoothed_factor_draws.csv") : draws_csv
    df = CSV.read(draws_csv, DataFrame)

    fac_cols = [c for c in names(df) if startswith(String(c), "x")]
    out = DataFrame(time = unique(df.time))
    for c in fac_cols
        for p in probs
            tag = "$(c)_p$(lpad(round(Int, 100p), 2, '0'))"
            g = combine(groupby(df, :time), c => (v -> quantile(v, p)) => tag)
            out = leftjoin(out, g, on = :time)
        end
    end
    sort!(out, :time)

    out_dir = out_dir === nothing ? _PD_SYNTH : out_dir
    mkpath(out_dir)
    dest = joinpath(out_dir, "smoothed_factors_bands.csv")
    CSV.write(dest, out)
    @info "Wrote factor bands → $dest"
    return dest
end
