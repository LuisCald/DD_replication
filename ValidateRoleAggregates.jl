# Trying to answer the referee comments
cd("/Users/lc/Dropbox/Distributional_Dynamics/5_Code")
include("DistributionalDynamics.jl")
using XGBoost
using Term
include("SupportExplainDist.jl")
include("FactorSelection.jl")

# import the datasets
income_df = CSV.read("/Users/lc/Dropbox/Distributional_Dynamics/2_Data_processing/real_time_ineq/Income  Data.csv", DataFrame)
wealth_df = CSV.read("/Users/lc/Dropbox/Distributional_Dynamics/2_Data_processing/real_time_ineq/Wealth Data.csv", DataFrame) # presence of negative shares

# Time parameters
start_year = 1980
end_year = 2018
end_q = 4
start_q = 1
n_lags_policy = 0
n_lags_aggs = 0
draws = 1000
agg_leads = 4
agg_lags = 4

# Measures dictionary
measures_dict = Dict("Income" => income_df, "Wealth" => wealth_df)

# Get distributional factors
factor_df = collect_dist_data(measures_dict; start_year=1980, end_year=2018, start_q=1, end_q=4)

# Importing aggregates
aggregate_data = DataFrame(XLSX.readtable(raw"/Users/lc/Dropbox/Distributional_Dynamics/2_Data_processing/aggregates_HHs_NPs.XLSX", "stationary_series", header=true,))

# Align aggregate data
agg_mat = generate_aggs(aggregate_data; leads=agg_leads, lags=agg_lags, start_year=start_year, end_year=end_year, start_q=start_q, end_q=end_q)

# Return R2 Dict
R2_dict = validate_role_of_aggs(agg_mat, factor_df, n_lags_policy, n_lags_aggs, draws; type_of_aggs=:best)
R2_dict2 = validate_role_of_aggs(agg_mat, factor_df, 1, n_lags_aggs, draws; type_of_aggs=:best)

# Store this vector of R2s
jldsave("/Users/lc/Dropbox/Distributional_Dynamics/7_Results/consum_and_income_and_wealth additional factors/other_results/R2_dict.jld2"; aggs=R2_dict["35"][4])


##################################################################
## Now with DFAs 
##################################################################
init_path = dirname(pwd())[end-7:end] == "Dynamics" ? dirname(pwd()) : pwd()
file_path = init_path * "/2_Data_processing/validation/DFA/DFA.xlsx"
fold_path = init_path * "/2_Data_processing/validation"

shares = CSV.read(fold_path * "/DFA/" * "wealth" * "_shares" * "_DFA.csv", DataFrame)
quantiles = CSV.read(fold_path * "/DFA/" * "wealth" * "_quantiles" * "_DFA.csv", DataFrame)
wealth_by_income = DataFrame(XLSX.readtable(file_path, "wealth_by_income", header=true,))

# Clean DFAs
factor_df = clean_DFA(shares, quantiles, wealth_by_income)

# Time parameters
yrs = year.(factor_df[!, :time])
start_year = minimum(yrs)
end_year = maximum(yrs)
start_q = 3
end_q = 4
n_lags_policy = 0
n_lags_aggs = 0
draws = 1000
agg_leads = 4
agg_lags = 4

# Return R2 Dict
agg_mat = generate_aggs(aggregate_data; leads=agg_leads, lags=agg_lags, start_year=start_year, end_year=end_year, start_q=start_q, end_q=end_q)
R2_dfa = validate_role_of_aggs(agg_mat, factor_df, n_lags_policy, n_lags_aggs, draws; type_of_aggs=:best)
R2_dfa2 = validate_role_of_aggs(agg_mat, factor_df, 1, n_lags_aggs, draws; type_of_aggs=:best)

intersect(R2_dfa2["35"][4], R2_dict["35"][4])
##################################################################
## Importing the CEX
##################################################################

# Unpack data + necessary options 
@unpack files, agg_data, df_vec, gdp_series = obs_data
@unpack estimator, number_of_dfs, measures, lags, freq, agg_freq, case, plot_proof, pca_perspective, rm_seasonality, equivalized, data_cutoffs, data_to_mute, tag, agg_lags = model_options

# Preliminairies
init_path = dirname(pwd())[end-7:end] == "Dynamics" ? dirname(pwd()) * "/2_Data_processing" : pwd()
dimension = length(measures)

@info("Extracting observations Tⱼ of the joint distributions, in alphabetical order of datasets' name.")
@info("Estimation selected: $tag")

# Collects data for all available years 
dfs, year_vec, time_dict, freq_type = data_constructor(obs_data, model_options)
time_p = define_timeframe(agg_data, year_vec, freq_type, time_dict, data_cutoffs) # TODO: time_dict needs to be filtered as well  
cutoff_bounds = align_data_with_timeframe!(dfs, year_vec, time_p, data_cutoffs)
_, dfs[1], _ = perform_detrending(dfs[1], time_p, year_vec[1], freq[1], freq_type[1], time_dict[1])
pool, means, stds = perform_standardization(dfs, estimator, dimension, measures)

# Generate a dates column from 'time_dict'
dates = []
for (yr, qtr) in time_dict[1]
    for q in qtr
        push!(dates, QuarterlyDate(yr, q))
    end
end
sort!(dates)

# Remove rows from pool where all values are NaN
pool_clean2, dates_clean = clean_data(year_vec, pool, dates) # removes covid obs

# Perform PCA
M = MultivariateStats.fit(PCA, pool_clean2, pratio=0.95, method=:svd, mean=0)
dist_pcs = MultivariateStats.transform(M, pool_clean2)

factor_df = DataFrame(time=dates_clean)
for i in axes(dist_pcs, 1)
    factor_df[!, "Factor $i"] = dist_pcs[i, :]
end

# Time parameters
yrs = year.(factor_df[!, :time])
start_year = minimum(yrs)
end_year = maximum(yrs)
start_q = 1
end_q = 4
n_lags_policy = 0
draws = 1000
agg_leads = 4
agg_lags = 4
agg_dates = collect(QuarterlyDate(start_year, start_q):Quarter(1):QuarterlyDate(end_year, end_q))

# Importing aggregates
aggregate_data = DataFrame(XLSX.readtable(raw"/Users/lc/Dropbox/Distributional_Dynamics/2_Data_processing/aggregates_HHs_NPs.XLSX", "stationary_series", header=true,))
agg_mat = generate_aggs(aggregate_data; leads=agg_leads, lags=agg_leads, start_year=start_year, end_year=end_year, start_q=start_q, end_q=end_q)

date_ids = findall(x -> x in dates_clean, agg_dates)
n_lags_aggs = 0
n_lags_policy = 0
R2_dict = validate_role_of_aggs(agg_mat, factor_df, n_lags_policy, n_lags_aggs, draws; type_of_aggs=:best, specific_aggs=date_ids)

using Printf

function generate_latex_table(dfa, dfa_withlag, realtime, realtime_withlag; kmax::Int=8)
    estimators = ["5", "10", "15", "20", "25"]#collect(keys(dfa))
    io = IOBuffer()

    println(io, raw"\begin{table}[htbp]")
    println(io, raw"  \centering")
    println(io, raw"  \begin{tabular}{@{}lcccc@{}}")
    println(io, raw"    \toprule")

    # Panel A: DFA
    println(io, raw"    \multicolumn{5}{c}{\textbf{Panel A: DFA}} \\\\")
    println(io, raw"    \cmidrule(lr){1-5}")

    est_string = raw"Factors &"
    for k in estimators
        est_string *= " \\textbf{$k} & "
        # println(io, raw"    \textbf{$k} & ")
    end
    println(io, est_string[1:end-2] * raw" \\\\")
    # println(io, raw"    Factors & BN & AO\_growth & AO\_ratio & FC \\\\")
    println(io, raw"    \midrule")
    nf = length(dfa["20"][2])
    for f in 1:nf
        row = @sprintf("    Factor %d", f)
        for est in estimators
            v_d = dfa[est][2][f]    # the R² for factor f in DFA
            v_r = dfa_withlag[est][2][f]    # the R² for factor f in dfa_withlag
            entry = @sprintf("%.2f / %.2f", v_d, v_r)
            row *= " & $entry"
        end
        println(io, row * raw" \\\\")
    end

    println(io, raw"    \midrule")

    # Panel B: dfa_withlag (we could repeat the same but label differently;
    #  since cells are already dfa/dfa_withlag, we still show the same numbers)
    println(io, raw"    \multicolumn{5}{c}{\textbf{Panel B: RTI}} \\\\")
    println(io, raw"    \cmidrule(lr){1-5}")
    println(io, est_string[1:end-2] * raw" \\\\")
    println(io, raw"    \midrule")

    nf = length(realtime["20"][2])

    for f in 1:nf
        row = @sprintf("    Factor %d", f)
        for est in estimators
            v_d = realtime[est][2][f]
            v_r = realtime_withlag[est][2][f]
            entry = @sprintf("%.2f / %.2f", v_d, v_r)
            row *= " & $entry"
        end
        println(io, row * raw" \\\\")
    end

    println(io, raw"    \bottomrule")
    println(io, raw"  \end{tabular}")
    println(io, raw"  \caption{Comparison of R² (DFA / RTI) by factor and estimator}")
    println(io, raw"\end{table}")

    return String(take!(io))
end


latex_str = generate_latex_table(R2_dfa, R2_dfa2, R2_dict, R2_dict2; kmax=11)
println(latex_str)
