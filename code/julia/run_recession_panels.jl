# run_recession_panels.jl — re-plot the paper's recession panels from an existing
# <results>/from_mcmc/data/PSID_recession_groups_A non-diag_.csv (written by the
# post-estimation step), without loading the model. Seconds, runs anywhere.
#
#   julia --project=5_Code/code/julia/env 5_Code/code/julia/run_recession_panels.jl \
#         "7_Results/consum_and_income_and_wealth transfer hp 8 factors pf wr0.05 infl xcovid"

get!(ENV, "GKSwstype", "100")   # headless GR
using CSV, DataFrames, Plots
include(joinpath(@__DIR__, "RecessionPanels.jl"))

isempty(ARGS) && error("usage: run_recession_panels.jl <results folder>")
plot_recession_panels(ARGS[1])
