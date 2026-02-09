# Take averages of all correlations across all objects
# jldsave(file_name * ".jld2"; correlations=corr_dict)


# Recursively average a vector of dicts that share the same nested structure,
# where leaves are Numbers.
function _avg_nested_dict(dicts::Vector{<:AbstractDict})
    out = Dict{Any,Any}()

    # union of keys
    ks = Set{Any}()
    for d in dicts
        union!(ks, keys(d))
    end

    for k in ks
        vals = [d[k] for d in dicts if haskey(d, k)]
        isempty(vals) && continue

        if all(v -> v isa AbstractDict, vals)
            out[k] = _avg_nested_dict(vals)
        else
            nums = Float64[v for v in vals if v isa Number]
            out[k] = isempty(nums) ? missing : mean(nums)
        end
    end

    return out
end

function average_correlations_HANK(tag, N; dfs=["a", "b", "c", "d"], folder="from_mcmc")
    correlations = Dict{Int,Dict{String,Any}}()

    m_label = measures_folder(measures)
    init_path = dirname(pwd())[end-7:end] == "Dynamics" ? dirname(pwd()) : pwd()

    for i in 1:N
        correlations[i] = Dict{String,Any}()
        new_tag = tag[1:end-1] * string(i)
        path = init_path * "/7_Results/$m_label" * "$new_tag" * "/$folder/plots/"
        i_new = i == 1 ? "" : " $(i)"   # your file naming convention

        for df in dfs
            file = path * "correlations/correlations_HANK $(df)$(i_new).jld2"
            correlations[i][df] = load(file, "correlations")   # auto-closes
        end
    end

    # average per dataset df across i=1..N
    avg_correlations = Dict{String,Any}()
    for df in dfs
        dicts = [correlations[i][df] for i in 1:N if haskey(correlations[i], df)]
        avg_correlations[df] = _avg_nested_dict(dicts)
    end

    return avg_correlations
end

using JLD2, Statistics

# ---- helpers ----
_mean_or_dash(v::Vector{<:Real}; digits::Int=2) = isempty(v) ? "-" : string(round(mean(v), digits=digits))

function mean_corr_cell(avg_correlations, df::AbstractString, obj::AbstractString, measure::AbstractString; digits::Int=2)
    if !haskey(avg_correlations, df) ||
       !haskey(avg_correlations[df], measure) ||
       !haskey(avg_correlations[df][measure], obj)
        return "-"
    end
    qdict = avg_correlations[df][measure][obj]
    vals = Float64[]
    for v in values(qdict)
        v isa Number && push!(vals, Float64(v))
    end
    return _mean_or_dash(vals; digits=digits)
end

# ---- exporter (matches your LaTeX layout) ----
function export_corr_table_hank_style(
    avg_correlations,
    objects;
    datasets=["a", "b", "c", "d"],
    dataset_titles=Dict("a" => "Dataset A", "b" => "Dataset B", "c" => "Dataset C", "d" => "Dataset D"),
    measures=["liquid", "illiqd", "income"],
    measure_labels=Dict("illiqd" => "Illiquid Assets", "income" => "Income", "liquid" => "Liquid Assets"),
    caption::String="Average Correlations: Full vs Incomplete HANK",
    label::String="tab:hank_avg_corr",
    notes::String=raw"\textit{Notes:} The table reports correlations between model estimates generated from using our methodology with 1 complete dataset vs. 4 incomplete samples of the HANK data. The complete dataset contains no missings across time and across measures and has 50000 observations per time period. Details on the run with incomplete samples is in the text above.",
    filename::String="avg_corr_hank.tex",
    digits::Int=2,
)
    # header names in the same order as `objects`
    colnames = objects

    lines = String[]
    push!(lines, "\\begin{table}[!ht]")
    push!(lines, "\\centering")
    push!(lines, "\\caption{$caption}\\label{$label}")
    push!(lines, "\\begin{tabular}{cccc}")
    push!(lines, "Time-series& " * join(colnames, " & ") * " \\\\")
    push!(lines, "\\toprule")
    push!(lines, "\\vspace{2mm}")

    for (idx, df) in enumerate(datasets)
        dtitle = get(dataset_titles, df, "Dataset $(uppercase(df))")
        push!(lines, " & \\multicolumn{3}{c}{\\textit{$dtitle}} \\\\ ")

        for m in measures
            mlabel = get(measure_labels, m, m)
            row = "$mlabel"
            for obj in objects
                row *= " & " * mean_corr_cell(avg_correlations, df, obj, m; digits=digits)
            end
            row *= " \\\\"
            push!(lines, row)
        end

        if idx < length(datasets)
            push!(lines, "\\\\")  # blank line between dataset blocks (as in your example)
            push!(lines, "")
        end
    end

    push!(lines, "\\bottomrule")
    push!(lines, "\\end{tabular}")
    push!(lines, "  \\captionsetup{font={footnotesize}, width={0.6\\textwidth}, justification=justified, skip=2pt}")
    push!(lines, "    \\caption*{\\footnotesize{$notes}}")
    push!(lines, "\\end{table}")

    open(filename, "w") do io
        write(io, join(lines, "\n"))
    end

    return filename
end

avg = average_correlations_HANK(tag, N)   # your function that averages across i=1..N
objects = label_qs(5)

export_corr_table_by_dataset(avg, objects;
    caption="Average correlations: full vs incomplete HANK",
    label="tab:hank_avg_corr",
    filename="avg_corr_hank.tex"
)

# Return by year number of observations, like value_counts in python

function year_obs_counts(df, year_col::Symbol)
    counts = Dict{Int,Int}()
    for row in eachrow(df)
        year = row[year_col]
        if isnan(year)
            continue
        end
        year_int = Int(year)
        counts[year_int] = get(counts, year_int, 0) + 1
    end
    return counts
end
for i in 1:4
    df = df_vec[1][i]
    counts = year_obs_counts(df, :year)
    println("Dataset $(i) year counts:", counts)
end
