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
- `out_dir = nothing`: output directory (defaults to `<BASE_PATH>/data/synthetic`).
- `draws_file = nothing`: override the input JLD2 path.

Returns the path of the written CSV.
"""
function export_factor_draws(
    param_sizes, hyperpriors, Σ_ids, model_elements, model_options, time_params;
    n_draws::Int = 200, seed::Int = 12345, iteration::Symbol = :last,
    out_dir = nothing, draws_file = nothing,
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

    long = DataFrame()
    R = 0
    pb = Progress(n_draws, desc = "Smoothing posterior draws")
    for (s, id) in enumerate(draw_ids)
        θ = collect(pool[id, :])
        smoother_output, _, _ = likeli(model_elements, θ, param_sizes, hyperpriors,
                                       Σ_ids, model_options; smooth = true)
        @unpack x_smoothed = smoother_output          # (factor_count, T)
        R = size(x_smoothed, 1)
        df = DataFrame(Matrix(x_smoothed'), ["x$i" for i in 1:R])
        df[!, "time"] = collect(dts)
        df[!, "draw"] .= s
        append!(long, select(df, "draw", "time", :))
        next!(pb)
    end

    out_dir = out_dir === nothing ? _PD_SYNTH : out_dir
    mkpath(out_dir)
    out = joinpath(out_dir, "smoothed_factor_draws.csv")
    CSV.write(out, long)
    @info "Wrote $n_draws posterior factor draws ($R factors × $(length(dts)) quarters) → $out"
    return out
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
