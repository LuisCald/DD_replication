# run_mdd_table.jl — collect 7_Results/MDD/mdd_<tag>.jld2 of the paper's runs into
# 7_Results/MDD/mdd_table.tex (+ .csv). Needs no model; runs anywhere:
#   julia --project=5_Code/code/julia/env 5_Code/code/julia/run_mdd_table.jl
#
# Columns: harmonic mean and bridge sampler, raw and "comparable" (= raw + the log
# density of the aggregate scores s_{k+1..15} the model does not observe; see MDD.jl).
# Compare models on the comparable columns.

using JLD2, DataFrames, CSV, Printf

const BASE = normpath(joinpath(@__DIR__, "..", "..", ".."))
const MDD_DIR = joinpath(BASE, "7_Results", "MDD")
# Tag = core * variant * suffix. The suffix holds the switches every paper run shares (Oct 23 2026 re-run: tight
# aggregate measurement-error prior "aggtight", SCF/PSID income rows at Q4 "incq4", the 2022 SCF "scf22"); the
# variant words ("3 af", "tw0.8", …) sit between core and suffix, exactly where the Structures files put them.
# DD_MDD_SUFFIX="" rebuilds the table of the runs before Oct 2026.
const B0 = " transfer hp 8 factors pf wr0.05 infl xcovid"
const SUF = get(ENV, "DD_MDD_SUFFIX", " aggtight incq4 scf22")
const B = B0 * SUF
const ROWS = [   # (label, DF, AF, projection, tag)
    ("Baseline",            "8",  "11", "PCA",            B),
    ("6 DF",                "6",  "11", "PCA",            replace(B, "8 factors" => "6 factors")),
    ("7 DF",                "7",  "11", "PCA",            replace(B, "8 factors" => "7 factors")),
    ("Less AF",             "8",  "3",  "PCA",            B0 * " 3 af" * SUF),
    ("More AF",             "8",  "15", "PCA",            B0 * " 15 af" * SUF),
    ("Less DF and AF",      "3",  "3",  "PCA",            replace(B0, "8 factors" => "3 factors") * " 3 af" * SUF),
    ("\$\\Gamma\$ all",     "TW", "11", "Tall--Wide 80\\%", B0 * " tw0.8" * SUF),
    ("\$\\Gamma\$ all 85",  "TW", "11", "Tall--Wide 85\\%", B0 * " tw0.85" * SUF),
    ("EM loadings",         "8",  "11", "EM",             replace(B, "pf wr" => "pf em wr")),
]

df = DataFrame(model = String[], DF = String[], AF = String[], projection = String[], n_params = Int[],
               hm = Float64[], bs = Float64[], bs_split2 = Float64[], af_corr = Float64[],
               hm_comparable = Float64[], bs_comparable = Float64[])
for (lab, d, a, pr, tag) in ROWS
    f = joinpath(MDD_DIR, "mdd_$tag.jld2")
    if !isfile(f)
        @warn "missing: $f"; continue
    end
    r = load(f)
    bs = r["mdd_bs"] isa AbstractDict ? r["mdd_bs"]["logml"] : get(r["mdd_bs"], "logml", NaN)
    push!(df, (lab, d, a, pr, get(r, "n_params", 0), r["mdd_hm"], bs, get(r, "mdd_bs_split2", NaN),
               get(r, "af_corr", NaN), get(r, "mdd_hm_comparable", NaN), get(r, "mdd_bs_comparable", NaN)))
end
CSV.write(joinpath(MDD_DIR, "mdd_table.csv"), df)

fmt(x) = isfinite(x) ? @sprintf("%.1f", x) : "--"
open(joinpath(MDD_DIR, "mdd_table.tex"), "w") do io
    println(io, "\\begin{tabular}{lcccrrrr}\n\\toprule")
    println(io, "Model & DF & AF & Loadings & \\multicolumn{2}{c}{Harmonic mean} & \\multicolumn{2}{c}{Bridge sampler} \\\\")
    println(io, " & & & & raw & comparable & raw & comparable \\\\\n\\midrule")
    for r in eachrow(df)
        println(io, "$(r.model) & $(r.DF) & $(r.AF) & $(r.projection) & $(fmt(r.hm)) & $(fmt(r.hm_comparable)) & $(fmt(r.bs)) & $(fmt(r.bs_comparable)) \\\\")
    end
    println(io, "\\bottomrule\n\\end{tabular}")
    println(io, "% comparable = raw + log density of the aggregate scores s_{k+1..15} not observed by a k-AF model")
    println(io, "% (independent conjugate AR(1)s), so all rows are densities over the same data.")
    println(io, "% All rows: the stationarity cap truncates the prior without renormalisation (p(y)*Pr_prior(stationary)).")
end
println(df)
@info "MDD table written to $(joinpath(MDD_DIR, "mdd_table.tex"))"
