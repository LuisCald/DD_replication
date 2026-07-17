# ─────────────────────────────────────────────────────────────
# posterior_bands.jl — posterior bands on any moment, from the factor draws.
#
#   posterior factor draws  --(FactorMap)-->  coefficients  -->  moment
#
# FactorMap (code/julia/reconstruct.jl) learns the linear map factors ->
# coefficients from the published point-estimate files. Feeding each posterior
# factor draw through it yields a posterior distribution over any moment.
# Here we demo marginal deciles; swap in whatever moment you need.
#
# Usage:
#   julia --project=code/julia/env code/moments_from_coefficients/posterior_bands.jl
#   # optional: DATASET=PSID MEASURE=wealth DATE=2008-Q3 LO=0.05 HI=0.95 julia ...
#
# Needs the factor draws (data/synthetic/smoothed_factor_draws.csv), produced
# by export_factor_draws (PosteriorDraws.jl). Only deps: CSV, DataFrames,
# Statistics, Plots.
# ─────────────────────────────────────────────────────────────

const HERE  = @__DIR__
const REPO  = abspath(joinpath(HERE, "..", ".."))
const SYNTH = joinpath(REPO, "data", "synthetic")

include(joinpath(REPO, "code", "julia", "reconstruct.jl"))
using .DistributionalReconstruction
using CSV, DataFrames, Statistics, Plots

"4q-average of factors x1..xK ending at `date`, for one draw's sub-DataFrame."
function factors_4q_for_draw(sub::DataFrame, date::AbstractString, K::Int)
    sub = sort(sub, :time)
    times = String.(sub.time)
    j = findfirst(==(date), times)
    (j === nothing || j < 4) && return nothing
    M = Matrix(sub[j-3:j, ["x$i" for i in 1:K]])
    return vec(mean(M, dims = 1))
end

function main()
    dataset = get(ENV, "DATASET", "PSID")
    measure = Symbol(get(ENV, "MEASURE", "wealth"))
    date    = get(ENV, "DATE", "2008-Q3")
    lo      = parse(Float64, get(ENV, "LO", "0.05"))
    hi      = parse(Float64, get(ENV, "HI", "0.95"))
    draws_csv = joinpath(SYNTH, "smoothed_factor_draws.csv")
    isfile(draws_csv) || error("Draws file not found: $draws_csv\n" *
        "Run Stage 2 then the post-estimation export (export_factor_draws).")

    # FactorMap fit on the point estimate (average-trend variant → intercept
    # absorbs the constant trend, R² ≈ 1).
    fm = FactorMap(joinpath(SYNTH, "$(dataset)_coefficients_average.csv"),
                   joinpath(SYNTH, "smoothed_factors.csv"))
    K  = fm.n_factors
    u  = collect(0.1:0.1:0.9)

    q_point = quantile_at(fm, factors_at(fm, date), measure, u)

    per_draw = Vector{Vector{Float64}}()
    for sub in groupby(CSV.read(draws_csv, DataFrame), :draw)
        F = factors_4q_for_draw(DataFrame(sub), date, K)
        F === nothing && continue
        push!(per_draw, quantile_at(fm, F, measure, u))
    end
    isempty(per_draw) && error("No draw had 4 quarters of data ending at $date.")
    M = reduce(hcat, per_draw)'                     # (n_draws, 9)

    lob = [quantile(M[:, j], lo) for j in 1:length(u)]
    mdb = [quantile(M[:, j], 0.5) for j in 1:length(u)]
    hib = [quantile(M[:, j], hi) for j in 1:length(u)]

    out = DataFrame(decile = u, point = q_point, post_median = mdb,
                    lower = lob, upper = hib)
    dest = joinpath(HERE, "posterior_bands_output.csv")
    CSV.write(dest, out)
    println("$measure deciles at $date ($(size(M,1)) draws):")
    show(stdout, MIME("text/plain"), out); println("\nWrote $dest")

    plt = plot(u, mdb; ribbon = (mdb .- lob, hib .- mdb), fillalpha = 0.3,
               color = :firebrick, lw = 1.2,
               label = "$(round(Int,100lo))–$(round(Int,100hi))% posterior",
               xlabel = "Quantile u", ylabel = "$measure (relative to mean)",
               title = "$dataset $measure deciles — $date", legend = :topleft)
    plot!(plt, u, q_point; color = :black, ls = :dash, lw = 1.2, label = "point estimate")
    png = joinpath(HERE, "posterior_bands_output.png")
    savefig(plt, png); println("Wrote $png")
end

main()
