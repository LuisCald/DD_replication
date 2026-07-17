# Count micro observations per (dataset, year, quarter) for the data-timeline
# figure. Run on the server (local CSVs are Dropbox placeholders).
# Output: 2_Data_processing/obs_counts.csv with columns dataset,year,quarter,n
using Pkg
Pkg.activate(joinpath(@__DIR__, "env"))
using CSV, DataFrames

dir = normpath(joinpath(@__DIR__, "..", "..", "..", "2_Data_processing"))
files = [
    "CEX"   => "CEX.csv",
    "CPS"   => "CPS.csv",
    "CPS2"  => "CPS2.csv",
    "PSID"  => "PSID.csv",
    "SCF"   => "SCF.csv",
    "SIPP1" => "SIPP1.csv",
    "SIPP2" => "SIPP2.csv",
    "SIPP3" => "SIPP3.csv",
]

findcol(names, cands) = begin
    i = findfirst(n -> lowercase(String(n)) in cands, names)
    isnothing(i) ? nothing : names[i]
end

out = DataFrame(dataset=String[], year=Int[], quarter=Int[], n=Int[])
for (name, file) in files
    path = joinpath(dir, file)
    isfile(path) || (println("MISSING: ", path); continue)
    df = CSV.read(path, DataFrame)
    yc = findcol(names(df), ["year", "yr"])
    qc = findcol(names(df), ["quarter", "qtr", "q"])
    if isnothing(yc)
        println(name, ": no year column, headers are: ", join(names(df), ", "))
        continue
    end
    # count households per period; SCF-style files repeat rows per implicate
    impc = findcol(names(df), ["impnum", "implicate"])
    nimp = isnothing(impc) ? 1 : length(unique(df[!, impc]))
    g = isnothing(qc) ? combine(groupby(df, yc), nrow => :n) :
                        combine(groupby(df, [yc, qc]), nrow => :n)
    g.n = div.(g.n, nimp)
    for r in eachrow(g)
        push!(out, (name, Int(r[yc]), isnothing(qc) ? 0 : Int(r[qc]), r.n))
    end
    println(name, ": ", nrow(g), " periods, ",
            minimum(g.n), "-", maximum(g.n), " obs/period")
end
sort!(out, [:dataset, :year, :quarter])
CSV.write(joinpath(dir, "obs_counts.csv"), out)
println("wrote ", joinpath(dir, "obs_counts.csv"))
