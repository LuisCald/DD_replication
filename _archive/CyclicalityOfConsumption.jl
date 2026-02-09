### Consumption patterns around recessions in the US
# The idea is the following:
# - we have dates on when the recessions occurred in the US
# - we have time series data on consumption patterns in the US for different income and wealth groups 
# - we want to see how consumption patterns change around recessions
# - we first want to see if the change in consumption patterns is different between recessions, Looking at only one group 
# - we then want to see if the change in consumption patterns is different between recessions, Looking at all groups together, so, a mean sort of 
# - we are gonna plot log average consumption for each group, and see how it changes around recessions

# - for one group, 	- plot consumption patterns for all recessions in one plot 
# - x-axis is t-2, t-1, t …  , where t is the recession time
# - 8 quarters before, 20 after 
# - recession time is zero 
# using Pkg
# Pkg.activate("env_dd_v19/")
# # using BAT 
# # using ValueShapes
# using DataFrames
# using CSV
# using StatsFuns
# using GR
# using Random
# GR.inline("pdf")

# # using GalacticOptim: AutoReverseDiff
# using Distributions
# using StatsPlots
# using Plots  
# using Dates 
# using PeriodicalDates

# using MultivariateStats
# using PlotlyJS
# using StatsBase
# using LaTeXStrings
# using LinearAlgebra
# using BenchmarkTools
# using TimerOutputs
# using Test
# using DelimitedFiles

# # using MCMCDiagnosticTools
# using JLD2
# using Latexify 
# Import recession dates 
init_path  = dirname(pwd())[end-7:end] == "Dynamics" ? dirname(pwd()) * "/2_Data_processing" : pwd()
nber_dates = CSV.read(init_path * "/nber_dates.csv", DataFrame)

# Drop row associated with 1980 recession 
filter!(x -> x.peak != "January 1980 (1980Q1)", nber_dates)
a = nber_dates[:, :peak][7]
filter!(x -> x.peak != a, nber_dates)

# From the first column, the current format is like this: December 1969 (1969Q4) --- we only want whats in the parentheses 
for point in ["peak", "trough"]
    nber_dates[!, point] = [x[end-6:end-1] for x in nber_dates[!, point]]

    # Add a hyphen in character 5
    nber_dates[!, point] = [x[1:4] * "-" * x[5:end] for x in nber_dates[!, point]]

    # Convert to dates, but just year quarter
    nber_dates[!, point] = QuarterlyDate.(nber_dates[!, point])
end

# Now I want to create a dictionary of dataframes, where each dataframe is a different recession 
nber_dates_dict  = Dict()
 
# Make a key for each group 
for (i, d) in enumerate(nber_dates[!, "peak"])
    nber_dates_dict[d] = DataFrame()
    
    # create a column of dates that is 8 quarters before and 20 quarters after
    nber_dates_dict[d][!, "date"] = d - Quarter(8) : Quarter(1) : d + Quarter(20)
end

pop!(nber_dates_dict, QuarterlyDate(1981, 3))
pop!(nber_dates_dict, QuarterlyDate(1969, 4))
pop!(nber_dates_dict, QuarterlyDate(1990, 3))
pop!(nber_dates_dict, QuarterlyDate(1973, 4))


# Identifying the different kinds of recessions 
demand_dates = [QuarterlyDate(1969, 4), QuarterlyDate(1981, 3), QuarterlyDate(2001, 1), QuarterlyDate(2007, 4)]
supply_dates = [QuarterlyDate(1973, 4), QuarterlyDate(1990, 3)] # QuarterlyDate(2019, 4)
both_dates   = [] #[QuarterlyDate(1980, 1)]
recession_types = Dict()

for d in nber_dates[!, "peak"]
    if d ∈ demand_dates
        recession_types[d] = "D"
    elseif d ∈ supply_dates
        recession_types[d] = "S"
    elseif d ∈ both_dates
        recession_types[d] = "B"
    end
end

# Create histogram of filter(x -> x < 0, micro_data[:,"cop_share"])
# Plots.barhist(filter(x -> x < 0, micro_data[:,"cop_share"]), bins=100)
# Plots.savefig("cop_share.pdf")

# Make a column which indicates whether it is a negative share or not
# micro_data[!, "cop_share_neg"] = [x < 0 ? 1 : 0 for x in micro_data[!, "cop_share"]]

# Now groupby year, summing over the cop_share_neg column
# micro_data[!, "year"] = Dates.year.(QuarterlyDate.(micro_data[!, "time"]))
# data_test = combine(groupby(micro_data, [:year]), :cop_share_neg => sum)

# Plot the data, where the x-axis is the year and the y-axis is the number of negative cop shares
# Plots.plot(data_test[!, "year"], data_test[!, "cop_share_neg_sum"], xticks=(1960:5:2020, [L"%$(f)" for f in 1960:5:2020]), xlabel=L"\textrm{year}", ylabel=L"\textrm{number of negative cop shares}")
# Plots.savefig("cop_share_neg.pdf")



# Now I want to add the consumption data to each dataframe, for some group
file_path = "/Users/lc/Dropbox/Distributional_Dynamics/7_Results/consum_and_income_and_wealth/from_optimization/data/PSID_micro_data_A non-diag_.csv"
micro_data = CSV.read(file_path, DataFrame)
micro_data[!, "time"] = QuarterlyDate.(micro_data[!, "time"])

# For cop_share, zero out the values that are less than 0 
micro_data[!, "cop_share"] = [x < 0 ? 0 : x for x in micro_data[!, "cop_share"]]

# Define groups, which are described by their grid points
groups  = Dict("overall" => [1:10, 1:10, 1:10], "low_income_low_wealth" => [1:10, 1:5, 1:5], "low_income_high_wealth" => [1:10, 1:5, 6:10], "high_income_low_wealth" => [1:10, 6:10, 1:5], "high_income_high_wealth" => [1:10, 6:10, 6:10]) # "low_income_top_wealth" => [1:10, 1:5, 10], "top_income_low_wealth" => [1:10, 10, 1:5], "top_income_top_wealth" => [1:10, 10, 10])
gr_labs = Dict("overall" => L"\textrm{Overall}", "low_income_low_wealth" => L"\textrm{Low\,\, Income,\,\, Low\,\, Wealth}", "low_income_high_wealth" => L"\textrm{Low\,\, Income,\,\, High\,\, Wealth}", "high_income_low_wealth" => L"\textrm{High\,\, Income,\,\, Low\,\, Wealth}", "high_income_high_wealth" => L"\textrm{High\,\, Income,\,\, High\,\, Wealth}")

# Now, merge my data with the nber_dates_dict
for (n, g) in groups
    merged_data_dict = Dict()

    println(n)
    # filter data based on the grid points
    s_micro_data = micro_data[findall(x -> x ∈ g[1], micro_data[!, "consumgrid"]), :]
    s_micro_data = s_micro_data[findall(x -> x ∈ g[2], s_micro_data[!, "incomegrid"]), :]
    s_micro_data = s_micro_data[findall(x -> x ∈ g[3], s_micro_data[!, "wealthgrid"]), :]
    
    s_micro_data     = combine(groupby(s_micro_data, [:time]), [:consum, :cop_share] => (x,y) -> mean(x, weights(y)))
    # combine(grouped_data, :consum => (x -> mean(x, weights(select(low_income_wealth_data, :weights))))
    rename!(s_micro_data, :consum_cop_share_function => :consum_mean)
    
    # Now log the values 
    s_micro_data[!, "log_consum_mean"] = log.(s_micro_data[!, "consum_mean"])
    # s_micro_data[!, "log_income_mean"] = log.(s_micro_data[!, "income_mean"])
    # symmetric log function to deal with negative values
    # s_micro_data[!, "log_wealth_mean"] = sign.(s_micro_data[!, "wealth_mean"]) .* log.(abs.(s_micro_data[!, "wealth_mean"]))

    for (i, d) in nber_dates_dict
        # Subset to the dates of interest, but keeping all columns
        ss_micro_data = filter(row -> row.time .<= maximum(d[!, "date"]), s_micro_data) # 
        ss_micro_data = filter(row -> row.time .>= minimum(d[!, "date"]), ss_micro_data)

        # s_micro_data = filter(x -> x ∈ d[!, "date"], s_micro_data[!, "time"])
        # Now make all the values relative to the peak date 
        consum_peak = ss_micro_data[:, "log_consum_mean"][ss_micro_data[:, "time"] .== i]
        ss_micro_data[!, "consum_rel"] = (ss_micro_data[:, "log_consum_mean"] .- consum_peak) .* 100 # in % terms
        
        # Now add the data to the dictionary, but first subset the dictionary dates to the dates permissible by the dataset 
        merged_data_dict[i] = nber_dates_dict[i][findall(x -> x ∈ ss_micro_data[:, "time"], nber_dates_dict[i][!, "date"]), :]
        merged_data_dict[i][!, n] = ss_micro_data[:, "consum_rel"]

        # correct dates for plotting, making the recession date zero
        merged_data_dict[i][!, "date"] = merged_data_dict[i][!, "date"] .- i
    end
    # Now, plot the data in one figure, with each recession a separate line and the x-axis being the quarters before and after the recession
    # For this second plot, label the lines at the end of each line vs. putting a legend and define the axis as the old plot does
    Plots.plot()
    for (i, d) in merged_data_dict
        Plots.plot!(d[!, "date"], d[!, n], label="", lw=2, title=gr_labs[n], xformatter=:latex, yformatter=:latex, ylabel=L"\textrm{Percent \,\, Change\,\, in\,\, Consumption}", xticks=(-8:4:20, [L"%$(f)" for f in -8:4:20]), xlabel=L"\textrm{quarters\,\, from \,\, peak}")
        Plots.annotate!(d[!, "date"][end], d[!, n][end], Plots.text(L"%$(i),\,\,%$(recession_types[i])", 5, :bottom))
    end
    Plots.savefig("$n.pdf")
end


# Create C(W,Y)
file_path = "/Users/lc/Dropbox/Distributional_Dynamics/7_Results/consum_and_income_and_wealth/from_optimization/data/PSID_micro_data_A non-diag_.csv"
micro_data = CSV.read(file_path, DataFrame)
micro_data[!, "time"] = QuarterlyDate.(micro_data[!, "time"])

# For cop_share, zero out the values that are less than 0 
micro_data[!, "cop_share"] = [x < 0 ? 0 : x for x in micro_data[!, "cop_share"]]

# # Define groups, which are described by their grid points
# groups  = Dict("overall" => [1:10, 1:10, 1:10], "low_income_low_wealth" => [1:10, 1:5, 1:5], "low_income_high_wealth" => [1:10, 1:5, 6:10], "high_income_low_wealth" => [1:10, 6:10, 1:5], "high_income_high_wealth" => [1:10, 6:10, 6:10]) # "low_income_top_wealth" => [1:10, 1:5, 10], "top_income_low_wealth" => [1:10, 10, 1:5], "top_income_top_wealth" => [1:10, 10, 10])
# gr_labs = Dict("overall" => L"\textrm{Overall}", "low_income_low_wealth" => L"\textrm{Low\,\, Income,\,\, Low\,\, Wealth}", "low_income_high_wealth" => L"\textrm{Low\,\, Income,\,\, High\,\, Wealth}", "high_income_low_wealth" => L"\textrm{High\,\, Income,\,\, Low\,\, Wealth}", "high_income_high_wealth" => L"\textrm{High\,\, Income,\,\, High\,\, Wealth}")

# Find wealth and income levels for the respective peak/trough dates 
C_WY_dict = Dict(
    "peak_allperiods" => DataFrame(),
    # "peak_fromhalfway" => DataFrame(),
    "trough_allperiods" => DataFrame(),
    # "trough_fromhalfway" => DataFrame()
    )


for (k,v) in C_WY_dict
    info = split(k, "_")

    peak   = nber_dates[!, "peak"]
    trough = nber_dates[!, "trough"]

    for (p_date, t_date) in zip(peak, trough) 
        # Subset to the dates of interest, but keeping all columns
        if k == "peak_allperiods"
            s_micro_data = filter(row -> row.time .<= p_date, micro_data) 
            s_micro_data = filter(row -> row.time .>= p_date - Quarter(3), s_micro_data) 
            # s_micro_data = filter(row -> row.time .== p_date, micro_data) 

        elseif k == "trough_allperiods"
            s_micro_data = filter(row -> row.time .<= t_date, micro_data) 
            s_micro_data = filter(row -> row.time .>= t_date - Quarter(3), s_micro_data) 
            # s_micro_data = filter(row -> row.time .== t_date, micro_data) 

        # elseif k == "peak_fromhalfway"
        #     s_micro_data = filter(row -> row.time .>= p_date, micro_data) 
        #     s_micro_data = filter(row -> row.time .< t_date, s_micro_data) 

        # elseif k == "trough_fromhalfway"

        end
        # Append to df 
        append!(C_WY_dict[k], s_micro_data)
    end

    function categorize_measure!(data, measure, grid_space)
        cutoffs                    = quantile(data[:, measure], weights(data.cop_share), grid_space)
        data[!, measure * "_category"] .= NaN 

        println(cutoffs)

        for (i, c) in enumerate(cutoffs)
            if i == 1
                cond = data[:, measure] .≤ c
                data[cond, measure * "_category"] .= c
            else 
                cond = data[:, measure] .> cutoffs[i-1] .&& data[:, measure] .≤ c
                data[cond, measure * "_category"] .= c
            end 
        end
    end

    # Apply the function to the income column
    for m in ["income", "wealth"]
        grid_space = m == "income" ? [.2, .5, .8, 1] : collect(0.1:0.1:1)
        categorize_measure!(C_WY_dict[k], m, grid_space)
    end

    # append!(unique_df, unique(C_WY_dict[k], [:income_category, :wealth_category, :consum]))
    C_WY_dict[k] = combine(groupby(C_WY_dict[k], [:income_category, :wealth_category]), [:consum, :cop_share] => ((x, y) -> mean(x, pweights(y))) => :weighted_mean)
    
    # x = 0:0.1:10
    # y = 0:0.1:10
    # f(x,y) = sin.(x) .+ cos.(y)
    # Plot the dataframes 
    # Identify inflexion points 
    infl_pts = find_change_indices(C_WY_dict[k][:, :income_category])


    gr()
    Plots.plot(
        C_WY_dict[k][:, :wealth_category] ./ 10000, # in tens-of-thousands 
        C_WY_dict[k][:, :income_category] ./ 10000, # in tens-of-thousands  
        C_WY_dict[k][:, :weighted_mean] ./ 10000, # in tens-of-thousands 
        st=:surface,
        xlabel = L"\textrm{Wealth \,\, (in\, 10k\, USD)}",
        ylabel = L"\textrm{Income \,\, (in\, 10k\, USD)}",
        zlabel = L"C(W, Y)", 
        # xticks = (infl_pts, [L"%$(g)" for g in ["low", "middle", "high", "top"]]), 
        xformatter=:latex, 
        yformatter=:latex, 
        zformatter=:latex, 
        legend=false, 
        camera = (40, 10), 
        size=(400,400),
        color=:winter, 
        # display_option=Plots.GR.OPTION_SHADED_MESH
        )
    Plots.pdf("/Users/lc/Dropbox/Distributional_Dynamics/7_Results/consumption_cyclicality/" * "at_$k" * ".pdf")


    # pyplot()
    # anim = Animation()

    # # Plots.gif(anim, "gr.gif", fps=24)
    # for i in range(0, stop = 180, step = 1)
    #     p = Plots.plot(
    #         C_WY_dict[k][:, :wealth_category] ./ 10000, # in tens-of-thousands  
    #         C_WY_dict[k][:, :income_category] ./ 10000, # in tens-of-thousands  
    #         C_WY_dict[k][:, :weighted_mean] ./ 10000, # in tens-of-thousands  
    #         st=:surface,
    #         xlabel = "Wealth",
    #         ylabel = "Income",
    #         zlabel = "C(W, Y)", 
    #         # xticks = (infl_pts, [L"%$(g)" for g in ["low", "middle", "high", "top"]]), 
    #         # xformatter=:latex, 
    #         # yformatter=:latex, 
    #         # zformatter=:latex, 
    #         legend=false, 
    #         camera = (i, 10), 
    #         size=(400,400),
    #         color=:winter, 
    #         fontfamily = "cmr10",
    #         # display_option=Plots.GR.OPTION_SHADED_MESH
    #         )
    #         Plots.frame(anim, p)
    # end
    # Plots.gif(anim, "/Users/lc/Dropbox/Distributional_Dynamics/7_Results/consumption_cyclicality/" * "$k" * ".gif", fps=8)
end


# Function to find indices of value changes
function find_change_indices(arr)
    # Include the first index by default
    change_indices = [1]
    
    # Iterate through the array
    for i in 2:length(arr)
        if arr[i] != arr[i - 1]
            push!(change_indices, i)
        end
    end

    return change_indices
end


# function create_interpolated_function(data)
#     # Assuming 'data' is a DataFrame with columns :W, :Y, and :C
#     unique_df = data[!, [:wealth, :income, :consum]]
#     # C_values = reshape(unique_df.consum, length(unique_df.wealth), length(unique_df.income))

#     # Create interpolation object
#     interp = interpolate(Matrix(unique_df), BSpline(Linear())) #Gridded(Linear()))

#     # Define the interpolated function C(W, Y)
#     function C(W, Y)
#         extrapolate(interp, Line())
#     end

#     return C
# end

# using DifferentialEquations
# using Plots
# using PyPlot

# V(x,A,t) = x .* ( A*x .- x'*A*x)
# RPS = [0 -1. 1; 1 0 -1; -1 1 0]
# tspan = (0, 50.0)
# x0 = [0.2, 0.2, 0.6]
# prob = ODEProblem(V, x0, tspan, RPS)
# sol = solve(prob);

# gr()
# anim = Animation()
# for i in range(0, stop = 90, step = 1)
#     p = Plots.plot(sol, vars=(1, 2, 3), camera=(i, i))
#     Plots.frame(anim, p)
# end
# Plots.gif(anim, "gr.gif", fps=24)

# pyplot()
# anim = Animation()
# for i in range(0, stop = 90, step = 1)
#     p = Plots.plot(sol, vars=(1, 2, 3), camera=(i, i*2))
#     Plots.frame(anim, p)
# end
# Plots.gif(anim, "gr.gif", fps=24)