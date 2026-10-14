# run_dropwave_table.jl — collect SCF_dropwave_scores.csv of the paper's runs into
# 7_Results/MDD/dropwave_table.tex (+ .csv), next to the MDD table. No model needed:
#   julia --project=5_Code/code/julia/env 5_Code/code/julia/run_dropwave_table.jl
using CSV, DataFrames, Printf, Statistics

const BASE = normpath(joinpath(@__DIR__, "..", "..", ".."))
const B = " transfer hp 8 factors pf wr0.05 infl xcovid"
const ROWS = [("Baseline", B), ("6 DF", replace(B, "8 factors" => "6 factors")), ("7 DF", replace(B, "8 factors" => "7 factors")),
              ("Less AF", B * " 3 af"), ("More AF", B * " 15 af"), ("Less DF and AF", replace(B, "8 factors" => "3 factors") * " 3 af"),
              ("\$\\Gamma\$ all", B * " tw0.8"), ("\$\\Gamma\$ all 85", B * " tw0.85"), ("EM loadings", replace(B, "pf wr" => "pf em wr"))]

all_ = DataFrame()
for (lab, tag) in ROWS
    f = joinpath(BASE, "7_Results", "consum_and_income_and_wealth" * tag, "from_mcmc", "data", "SCF_dropwave_scores.csv")
    isfile(f) || (@warn "missing: $f"; continue)
    d = CSV.read(f, DataFrame); d[!, :model] .= lab
    append!(all_, d, cols = :union)
end
CSV.write(joinpath(BASE, "7_Results", "MDD", "dropwave_table.csv"), all_)

fmt(x) = isfinite(x) ? @sprintf("%.3f", x) : "--"
open(joinpath(BASE, "7_Results", "MDD", "dropwave_table.tex"), "w") do io
    for meas in unique(all_.measure)
        d = all_[all_.measure .== meas, :]
        println(io, "% $(meas): drop-one-SCF-wave prediction, relative to the average")
        println(io, "\\begin{tabular}{l" * "cc"^3 * "}\n\\toprule")
        println(io, "Model & \\multicolumn{2}{c}{Bottom 50} & \\multicolumn{2}{c}{50--90} & \\multicolumn{2}{c}{Top 10} \\\\")
        println(io, " & RMSE & cover & RMSE & cover & RMSE & cover \\\\\n\\midrule")
        for lab in unique(d.model)
            r(g) = d[(d.model .== lab) .& (d.group .== g), :]
            cells = String[]
            for g in ("bottom50", "next40", "top10")
                x = r(g); push!(cells, nrow(x) == 0 ? "-- & --" : "$(fmt(x.rmse[1])) & $(fmt(x.cover[1]))")
            end
            println(io, "$lab & " * join(cells, " & ") * " \\\\")
        end
        println(io, "\\bottomrule\n\\end{tabular}\n")
    end
    println(io, "% cover = share of dropped-wave predictions inside the survey's own 95% sampling interval.")
end
println(all_)
