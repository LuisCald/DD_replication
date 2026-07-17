# ─────────────────────────────────────────────────────────────
# plot_factor_bands.jl — plot the smoothed factors with posterior bands.
#
# Reads
#   data/synthetic/smoothed_factor_draws.csv   (draws:  draw,time,x1..xR)
#   data/synthetic/smoothed_factors.csv         (point:  time,x1..xR)
# and draws each factor as a point-estimate line inside a shaded posterior
# band (default 5–95%). The draws file is produced by `export_factor_draws`
# (PosteriorDraws.jl).
#
# Usage:
#   julia --project=code/julia/env code/moments_from_coefficients/plot_factor_bands.jl
#   # optional: N_FACTORS=12 LO=0.10 HI=0.90 julia ... plot_factor_bands.jl
#
# Only deps: CSV, DataFrames, Statistics, Plots.
# ─────────────────────────────────────────────────────────────

using CSV, DataFrames, Statistics, Plots

const HERE  = @__DIR__
const REPO  = abspath(joinpath(HERE, "..", ".."))
const SYNTH = joinpath(REPO, "data", "synthetic")

quarter_to_num(s) = parse(Int, s[1:4]) + (parse(Int, s[7:7]) - 1) / 4

function plot_factor_bands(;
    draws_csv = joinpath(SYNTH, "smoothed_factor_draws.csv"),
    point_csv = joinpath(SYNTH, "smoothed_factors.csv"),
    n_factors::Int = parse(Int, get(ENV, "N_FACTORS", "8")),
    lo::Float64 = parse(Float64, get(ENV, "LO", "0.05")),
    hi::Float64 = parse(Float64, get(ENV, "HI", "0.95")),
    out = joinpath(HERE, "factor_posterior_bands.pdf"),
)
    isfile(draws_csv) || error("Draws file not found: $draws_csv\n" *
        "Generate it first with export_factor_draws (PosteriorDraws.jl).")

    draws = CSV.read(draws_csv, DataFrame)
    point = isfile(point_csv) ? CSV.read(point_csv, DataFrame) : nothing

    cols  = ["x$i" for i in 1:n_factors]
    setdiff(cols, names(draws)) |> m -> isempty(m) || error("Draws missing $m")

    # posterior percentiles per quarter
    g = groupby(draws, :time)
    summ = combine(g, [c => (v -> quantile(v, lo)) => "$(c)_lo" for c in cols]...,
                      [c => (v -> quantile(v, 0.5)) => "$(c)_md" for c in cols]...,
                      [c => (v -> quantile(v, hi)) => "$(c)_hi" for c in cols]...)
    sort!(summ, :time)
    x = quarter_to_num.(String.(summ.time))
    ndraws = length(unique(draws.draw))

    px = point === nothing ? nothing : quarter_to_num.(String.(point.time))

    plt = Plots.plot(layout = (cld(n_factors, 2), 2), size = (1000, 210 * cld(n_factors, 2)),
               legend = false, grid = false)
    for (k, c) in enumerate(cols)
        lob, hib, mdb = summ[!, "$(c)_lo"], summ[!, "$(c)_hi"], summ[!, "$(c)_md"]
        # shaded band via ribbon around the median
        Plots.plot!(plt, x, mdb; ribbon = (mdb .- lob, hib .- mdb), subplot = k,
              fillalpha = 0.25, color = :firebrick, lw = 1.0,
              title = "Factor $(k)", titlefontsize = 9)
        if point !== nothing && c in names(point)
            Plots.plot!(plt, px, point[!, c]; subplot = k, color = :black, lw = 1.0)
        end
        Plots.hline!(plt, [0.0]; subplot = k, color = :gray, lw = 0.4, alpha = 0.6)
    end
    Plots.plot!(plt, plot_title = "Smoothed distributional factors — posterior " *
          "$(round(Int,100lo))–$(round(Int,100hi))% bands ($ndraws draws)",
          plot_titlefontsize = 11)

    Plots.savefig(plt, out)
    png = replace(out, r"\.pdf$" => ".png")
    Plots.savefig(plt, png)
    @info "Wrote $out and $png"
    return out
end

if abspath(PROGRAM_FILE) == @__FILE__
    plot_factor_bands()
end
