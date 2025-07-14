# using CategoricalArrays
# using CSV 
# using Coverage
# using Random
# using GalacticOptim
# using DualNumbers
# using DataFramesMeta 
# using PyPlot
# using DataSets
# using MatrixEquations
# using SparseArrays
# using RecursiveArrayTools

# using StaticArrays
using Pkg
Pkg.activate("env_dd_v19/")
using ProgressMeter
using QuadGK
using Distributed
# using BAT 
# using ValueShapes
using Optimization 
using OptimizationOptimJL
using ReverseDiff
using ForwardDiff
using Optim
using DataFrames
using FreqTables
using DualNumbers
using AdvancedHMC
using CSV
using LineSearches
using Zygote 
# using DIMESampler 
using Printf
using ProgressBars
using StatsFuns
using Interpolations
using GR
using Random
using Polynomials
GR.inline("pdf")

# using GalacticOptim: AutoReverseDiff
using GenericLinearAlgebra: svd
using Distributions
using StatsPlots
using Plots  
using MCMCChains
using HypothesisTests
using GLM
using HPFilter

using ProgressBars
using LaTeXTabulars
using Dates 
using PeriodicalDates
# URL = "https://github.com/andreasKroepelin/KernelDensity.jl"
# Pkg.add(url=URL)
using KernelDensity
using Measures
using MultivariateStats
using PlotlyJS
using Parameters 
using FFTW
using XLSX
using StatsBase
using LaTeXStrings
using LinearAlgebra
using BenchmarkTools
using TimerOutputs
using Test
using DelimitedFiles
using PDMats
# using MCMCDiagnosticTools
using JLD2
using Trapz
using Combinatorics
using MatrixEquations
using FiniteDiff
using Latexify 
using BlackBoxOptim
using KissSmoothing
using RCall 
using NaNStatistics
using JuMP
using HiGHS
using ChebyshevApprox


# Import the inflation adjusted data, excel 
file_name = raw"/Users/lc/Dropbox/Distributional_Dynamics/2_Data_processing/inflation_corrected_correction_series.xlsx"
data = DataFrame(XLSX.readtable(file_name, "data", header=true,))

# Import the microdata csv 
file_name = raw"/Users/lc/Dropbox/Distributional_Dynamics/7_Results/consum_and_income_and_wealth/from_mcmc/data/SCF_micro_data_A non-diag_.csv"
micro_data = DataFrame(CSV.File(file_name))
filter!(x -> x.consumgrid == 1, micro_data) # in the SCF, only income or wealth


# convert time column to date column 
data[!, :time] = QuarterlyDate.(data[!, :time])
micro_data[!, :time] = QuarterlyDate.(micro_data[!, :time])

# Subset data to 1962Q3 onwards for 'data'
filter!(row -> row[:time] >= QuarterlyDate(1962, 3), data)

# Generate average wealth from micro data, which has columns 'time', 'wealth', 'consumption', 'income' and 'cop_share' which is the weight on the household
# in the micro data.
function generate_average(micro_data, measure)
    # Group by time and calculate the average wealth
    average_measure = combine(groupby(micro_data, :time), [measure, :cop_share] => (x,y) -> mean(x, weights(y)))
    # average_wealth     = combine(groupby(consum_df[ext], [:actual_time]), [:consum, :cop_share] => (x,y) -> mean(x, weights(y)))
    return average_measure
end

average_wealth_fred  = data[!, [:time, :wealth_per_hh]]
average_wealth_micro = generate_average(micro_data, :wealth)

# Plot the two series
Plots.plot(average_wealth_fred[!, :time], log.(average_wealth_fred[!, :wealth_per_hh]), xformatter=:latex, yformatter=:latex, xticks=(average_wealth_fred[1:20:end, :time], [L"%$(date)"[1:5] * "\$" for (_,date) in enumerate(average_wealth_fred[1:20:end, :time])]), ylabel=L"\textrm{Log \,\, Average \,\, Wealth}", lc=:blue, lw=3, label=L"\textrm{Fred}", legend=:topleft)
Plots.plot!(average_wealth_micro[!, :time], log.(average_wealth_micro[!, :wealth_cop_share_function]), xformatter=:latex, yformatter=:latex, lc=:red, lw=3, label=L"\textrm{Baseline}")
Plots.savefig("fred_vs_micro_wealth.pdf")

# Now for income
average_income_fred  = data[!, [:time, :income_per_hh]]
average_income_micro = generate_average(micro_data, :income)

# Plot the two series
Plots.plot(average_income_fred[!, :time], log.(average_income_fred[!, :income_per_hh]), xformatter=:latex, yformatter=:latex, xticks=(average_income_fred[1:20:end, :time], [L"%$(date)"[1:5] * "\$" for (_,date) in enumerate(average_income_fred[1:20:end, :time])]), ylabel=L"\textrm{Log \,\, Average \,\, Income}", lc=:blue, lw=3, label=L"\textrm{Fred}", legend=:topleft)
Plots.plot!(average_income_micro[!, :time], log.(average_income_micro[!, :income_cop_share_function]), xformatter=:latex, yformatter=:latex, lc=:red, lw=3, label=L"\textrm{Baseline}")
Plots.savefig("fred_vs_micro_income.pdf")

# Now for consumption
file_name = raw"/Users/lc/Dropbox/Distributional_Dynamics/7_Results/consum_and_income_and_wealth/from_mcmc/data/PSID_micro_data_A non-diag_.csv"
micro_data = DataFrame(CSV.File(file_name))
micro_data[!, :time] = QuarterlyDate.(micro_data[!, :time])

average_consum_fred  = data[!, [:time, :consum_per_hh]]
average_consum_micro = generate_average(micro_data, :consum)

# subset both series from 1998 onwards
filter!(row -> row[:time] >= QuarterlyDate(1999, 2), average_consum_fred)
filter!(row -> row[:time] >= QuarterlyDate(1999, 2), average_consum_micro)

# Plot the two series
Plots.plot(average_consum_fred[!, :time], log.(average_consum_fred[!, :consum_per_hh]), xformatter=:latex, yformatter=:latex, xticks=(average_consum_fred[1:20:end, :time], [L"%$(date)"[1:5] * "\$" for (_,date) in enumerate(average_consum_fred[1:20:end, :time])]), ylabel=L"\textrm{Log \,\, Average \,\, Consumption}", lc=:blue, lw=3, label=L"\textrm{Fred}", legend=:topleft)
Plots.plot!(average_consum_micro[!, :time], log.(average_consum_micro[!, :consum_cop_share_function]), xformatter=:latex, yformatter=:latex, lc=:red, lw=3, label=L"\textrm{Baseline}")
Plots.savefig("fred_vs_micro_consum.pdf")