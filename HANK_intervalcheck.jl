init_path = "/Users/lc/Dropbox/Distributional_Dynamics"
file_name = init_path * "/2_Data_processing/confidence_intervals/ci_draws_illiqd_and_income_and_liquid_deciles_series_HANK full_all.jld2"
raw_ci = jldopen(file_name, "r")["ci"]

# Find the bounds of each 
hank_year_vec = repeat([i for i in collect(2001:2024)], inner=4)
confidence_intervals = Dict("HANK" => Dict())
confidence_intervals["HANK"]["ci_u"], confidence_intervals["HANK"]["ci_l"] = construct_confidence_intervals(raw_ci, 0.025, 0.975, measures, hank_year_vec, estimator)
# Correct the confidence intervals to be in the same time frame as the estimation
hank_full_dts = QuarterlyDate(2001, 1):Quarter(1):QuarterlyDate(2024, 4)

# Estimation dates
dts = QuarterlyDate(smin["year"], smin["quarter"]):Quarter(1):QuarterlyDate(smax["year"], smax["quarter"])

# Find the indices of the estimation time frame in the HANK full time frame
hank_indices = findall(x -> x in dts, hank_full_dts)

for meas in measures
    for o in ["quantiles"]
        confidence_intervals["HANK"]["ci_u"][meas][o] = confidence_intervals["HANK"]["ci_u"][meas][o][:, hank_indices]
        confidence_intervals["HANK"]["ci_l"][meas][o] = confidence_intervals["HANK"]["ci_l"][meas][o][:, hank_indices]
    end
end

confidence_intervals["HANK"]["ci_u"]["copula"] = confidence_intervals["HANK"]["ci_u"]["copula"][:, hank_indices]
confidence_intervals["HANK"]["ci_l"]["copula"] = confidence_intervals["HANK"]["ci_l"]["copula"][:, hank_indices]

file_name = init_path * "/5_Code/ci_draws_illiqd_and_income_and_liquid_deciles_series_HANK_all.jld2"
raw_ci2 = jldopen(file_name, "r")["ci"]

# Find the bounds of each 
hank_year_vec = vcat([2002], repeat([i for i in collect(2003:2024)], inner=4))
confidence_intervals2 = Dict("HANK" => Dict())
confidence_intervals2["HANK"]["ci_u"], confidence_intervals2["HANK"]["ci_l"] = construct_confidence_intervals(raw_ci2, 0.025, 0.975, measures, hank_year_vec, estimator)

# Get indices of data from confidence intervals 2
years = collect(keys(time_dict[1]))
quarters = collect(values(time_dict[1]))

year_vec_data = []
for (i, yr) in enumerate(years)
    for q in quarters[i]
        for v in q
            push!(year_vec_data, QuarterlyDate(yr, v))
        end
    end
end

# Plot some random interval to see how it compares 
for m in measures
    for o in ["quantiles"]
        for i in 1:10
            println(m * " - " * o * " - " * string(i * 10) * "th percentile")
            Plots.plot(dts, confidence_intervals["HANK"]["ci_u"][m][o][i, :], label="HANK full", lw=2, ls=:dash, color=:blue)
            Plots.plot!(dts, confidence_intervals["HANK"]["ci_l"][m][o][i, :], label="", lw=2, ls=:dash, color=:blue)
            Plots.plot!(year_vec_data, confidence_intervals2["HANK"]["ci_u"][m][o][i, :], label="HANK", lw=2, ls=:solid, color=:red)
            Plots.plot!(year_vec_data, confidence_intervals2["HANK"]["ci_l"][m][o][i, :], label="", lw=2, ls=:solid, color=:red)
            Plots.savefig(init_path * "/5_Code/" * m * "_" * o * "_" * string(i * 10) * "th_percentile_HANK_vs_full.pdf")
        end
    end
end
