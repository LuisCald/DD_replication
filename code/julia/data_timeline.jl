ENV["GKSwstype"] = "100"
using Pkg
Pkg.activate(joinpath(@__DIR__, "env"))
using Plots, LaTeXStrings, CSV, DataFrames, Statistics

out = "/Users/lc/Dropbox/Apps/Overleaf/Distributional Dynamics/Plots"
counts = CSV.read("/Users/lc/Dropbox/Distributional_Dynamics/2_Data_processing/obs_counts.csv", DataFrame)
counts = counts[counts.year .>= 1962, :]          # estimation sample starts 1962Q3
counts.t = counts.year .+ (counts.quarter .- 1) ./ 4

pick(ds...) = sort(reduce(vcat, [counts[counts.dataset .== d, :] for d in ds]), :t)

# vertical extent encodes sample size: height ∝ sqrt(n), calibrated to CPS max
NREF = 80_000
h(n) = 0.42 * sqrt(n / NREF) + 0.03
klabel(n) = latexstring("\\bar n \\approx ", string(round(Int, n / 1000)), "\\textrm{k}")

# publication lags in years (draft numbers, VERIFY)
LAG = Dict("SCF" => 1.75, "CPS" => 0.75, "PSID" => 1.7, "SIPP" => 1.5,
           "CEX" => 1.0, "Aggregates" => 0.15)

scf  = pick("SCF")
cps  = pick("CPS", "CPS2")
psid = pick("PSID")
sipp = [pick("SIPP1"), pick("SIPP2"), pick("SIPP3")]
cex  = pick("CEX")

lanes = [  # (y, label)
    (1, L"\textrm{Aggregates}"),
    (2, L"\textrm{SCF}\ (Y,\,W)"),
    (3, L"\textrm{CPS}\ (Y)"),
    (4, L"\textrm{PSID}"),
    (5, L"\textrm{SIPP}\ (Y,\,W)"),
    (6, L"\textrm{CEX}\ (C,\,Y)"),
]

plt = Plots.plot(; size=(1500, 640), legend=false, framestyle=:box,
    xlims=(1960.5, 2029.5), ylims=(0.4, 6.9),
    yticks=(first.(lanes), last.(lanes)),
    xticks=(1960:10:2020, [latexstring(string(v)) for v in 1960:10:2020]),
    guidefontsize=22, tickfontsize=20,
    bottom_margin=6Plots.mm, left_margin=10Plots.mm, right_margin=4Plots.mm,
    top_margin=2Plots.mm, grid=false)

nlab = Dict{Int,Int}()  # lane => mean n for right-margin label

# --- wave-based lanes: one vertical bar per wave, height = sample size ---
for (df, y, src) in ((scf, 2, "SCF"), (cps, 3, "CPS"), (psid, 4, "PSID"))
    color = Dict(2 => "#1baf7a", 3 => "#008300", 4 => "#2a78d6")[y]
    for r in eachrow(df)   # whiskers first, under the bars
        Plots.plot!(plt, [r.t, r.t + LAG[src]], [y, y]; color="#6a6a6a",
            linewidth=2, alpha=0.55)
    end
    for r in eachrow(df)
        hh = h(r.n)
        Plots.plot!(plt, [r.t, r.t], [y - hh, y + hh]; color=color, linewidth=4)
    end
    nlab[y] = round(Int, mean(df.n))
end

# --- SIPP: quarterly panels as variable-thickness bands (gaps preserved) ---
for seg in sipp
    isempty(seg) && continue
    xs = seg.t; hs = h.(seg.n)
    Plots.plot!(plt, [xs[end], xs[end] + LAG["SIPP"]], [5, 5];
        color="#6a6a6a", linewidth=3)
    Plots.plot!(plt, Plots.Shape([xs; reverse(xs)],
        [5 .- hs; reverse(5 .+ hs)]);
        fillcolor="#4a3aa7", fillalpha=0.85, linealpha=0)
end
nlab[5] = round(Int, mean(reduce(vcat, [s.n for s in sipp])))

# --- CEX: quarterly variable-thickness band from actual counts ---
let xs = cex.t, hs = h.(cex.n)
    Plots.plot!(plt, [xs[end], xs[end] + LAG["CEX"]], [6, 6];
        color="#6a6a6a", linewidth=3)
    Plots.plot!(plt, Plots.Shape([xs; reverse(xs)],
        [6 .- hs; reverse(6 .+ hs)]);
        fillcolor="#eda100", fillalpha=0.85, linealpha=0)
end
nlab[6] = round(Int, mean(cex.n))

# --- aggregates: thin band, not a survey (no sample-size meaning) ---
Plots.plot!(plt, [1962.5, 2024.0 + LAG["Aggregates"]], [1, 1];
    color="#e34948", linewidth=8, alpha=0.9)

for (y, n) in nlab
    Plots.annotate!(plt, 2025.6, y, Plots.text(klabel(n), 14, "#6a6a6a", :left))
end

# PSID coverage phases: income always, wealth from 1983, consumption from 1999
for x in (1983.0, 1999.0)
    Plots.plot!(plt, [x, x], [3.74, 4.28]; color="#9a9a9a", linewidth=1.5,
        linestyle=:dot)
end
Plots.annotate!(plt, 1975.5, 4.44, Plots.text(L"Y", 15, "#2a78d6", :center))
Plots.annotate!(plt, 1991.0, 4.44, Plots.text(L"Y,\,W", 15, "#2a78d6", :center))
Plots.annotate!(plt, 2010.5, 4.44, Plots.text(L"C,\,Y,\,W", 15, "#2a78d6", :center))

# "today" line at end of aggregate sample
Plots.vline!(plt, [2024.0]; color="#3a3935", linestyle=:dash, linewidth=2)
Plots.annotate!(plt, 2024.4, 6.68,
    Plots.text(L"\textrm{2024Q1}", 16, "#3a3935", :left))

# explanatory annotation for the whiskers
Plots.plot!(plt, [1993.2, 1996.0], [1.5, 1.5]; color="#6a6a6a", linewidth=2)
Plots.annotate!(plt, 1996.4, 1.5,
    Plots.text(L"\textrm{publication\ lag}", 16, "#6a6a6a", :left))

Plots.savefig(plt, joinpath(out, "data_timeline.png"))
Plots.savefig(plt, joinpath(out, "data_timeline.pdf"))
println("done")
