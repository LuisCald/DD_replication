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
# cd("/Users/lc/Dropbox/Distributional_Dynamics/5_Code")
using Pkg
Pkg.activate(joinpath(@__DIR__, "env"))
using ProgressMeter
# using QuadGK  # replaced by closed-form Legendre integrals + fixed Gauss–Legendre (SupportingFunctions.jl)
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
using VectorAutoregressions
GR.inline("pdf")

# using GalacticOptim: AutoReverseDiff
using GenericLinearAlgebra: svd
using Distributions
using StatsPlots
using Plots
using MCMCChains
using HypothesisTests
using GLM
using HPFilter # add https://github.com/sdBrinkmann/HPFilter.jl

using LaTeXTabulars
using Dates
using PeriodicalDates
# URL = "https://github.com/andreasKroepelin/KernelDensity.jl"
# Pkg.add(url=URL)
using KernelDensity
using Measures
using MultivariateStats
# using PlotlyJS
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

# @rlibrary kdecopula
# @rlibrary pracma 
# @rlibrary cNORM
# @rlibrary rvinecopulib
# @rlibrary copula

# BLAS.set_num_threads(1)
# include("kernelPCA.jl")
include("config.jl")
include("Structures.jl")
include("DataConstructor.jl")
include("AllPlots.jl")
include("ModelPrep.jl")
include("SupportingFunctions.jl")
include("DIMES.jl")
include("SeparationStrategy.jl")
include("SelectPrior.jl")
include("Model.jl")
# include("MCMC.jl")  # moved to _archive/
# include("Diagnostics.jl")  # acceptance rate, Gelman and Rubin (1992), Geweke (1992) convergence statistics, traceplots
include("Reconstruction.jl")
include("HistoricalDecomposition.jl")
include("IntervalEstimation.jl")
include("Correlations.jl")
include("CreateTimeSeries.jl")
include("PosteriorDraws.jl")
include("ObservationWeights.jl")       # anatomy: information/interpolation shares
include("ObservationWeightsPlots.jl")  # anatomy figures (Koopman–Harvey decomposition)
include("Validation.jl")
include("CounterfactualRuns.jl")
include("ForecastSSM.jl")
include("BlackBoxSSM.jl")
include("CyclicalityOfConsumption2.jl")
include("DIMESampler.jl")
include("EM.jl")
include("RobustProjection.jl")
include("HyperparameterOptimization.jl")
include("MDD.jl")
include("FEVD.jl")

# include("IRFs")

# checking to see if the immutable part is indeed immutable ... 

# TODO: nice reference on dynamic factor models: https://halshs.archives-ouvertes.fr/halshs-02262202/document
# TODO: median absolute deviation (MAD) implementation?
# TODO: using an informative prior for out of sample / in sample performance ie Hierarchical prior: https://watermark.silverchair.com/rest_a_00483.pdf?token=AQECAHi208BE49Ooan9kkhW_Ercy7Dm3ZL_9Cf3qfKAc485ysgAAArYwggKyBgkqhkiG9w0BBwagggKjMIICnwIBADCCApgGCSqGSIb3DQEHATAeBglghkgBZQMEAS4wEQQMQU1qFGgFxPdK71gOAgEQgIICaUjna-Z9tOGZ_H-eyqKq1H2vWjGOti0nO9Nq3pxmvXy0Natltcg1i9oDSWbfBDv-W0bCBD-9fAl2qzicSw520hZvCuN3ZChYYfrlUcVUx0SnOwxqHqicYsUrB84K54qmqw46Nn2XHRnXEWGmQ2gSxi3hBUx-TICHPQYorDGF9yyNDSm63KeHCqVhJJTF3AV7vZrIMcPRMGuLCQuOPKXX3Lwult-P8tTt1hQrdTyejVTS6XmMU0gt8RPHF7x5BYFjPB8JAabaYvRxV6l548j8wtgkWpJ6IzkizI-iO8qLe8hLiN-U75g9qkSxb7jpNzR_kIjJDbE5o27okOAoi9WPnyyUcruyhkA384m8evCNx5Z2EECDlNuddAX7g1MkJrbNxN_j9BHPj-eKS_HQXDXZROvi8WLaT_gli8or1Chghuk56uPxdVrT4ujaFG2twmBNTFou5AVYXcT1fGh8gYVfFAipKW0suZa1UPe9M829h0tOCRl8s0onQPghlNUQeFLxRNJpHbc6CTPTq5UC1l-s2OZqZfyswY1BzG1w5NwWje6n0weJeipXOCBAW8oYZzIf6Ls0-0aHAgwbP72xo-DdD45aHWEJKybUUO1F0RsvJC9n1r6kJVzLqXr2bbdIyzryjls_mqpQoIpuFVPCwJ6qysno-rA5QL65Vv-dYc4chlRpvxROW5jut3_agobA6xMDgCqWGMXnAJTJAVXy3WgpPVlax1Ahe5IGa_FqMaX7TRiNp7l3tTm8pvMSVMFYuMnalJvwDrv0Q_A14DzQJqo7W_t534tWsfTFOBeoygHuLOJazNbpQo2jyTcD
# TODO: make a blocked MH sampler http://sfb649.wiwi.hu-berlin.de/fedc_homepage/xplore/ebooks/html/csa/node27.html#SECTION06133000000000000000
# TODO: use https://github.com/joidegn/FactorModels.jl to select the number of factors
# picking how many factors ... Onatski or Bai and Ng https://www.jstor.org/stable/pdf/40985808.pdf?refreqid=excelsior%3A7877001f8bafd9ff58a8d7f98fcd397e&ab_segments=&origin=&acceptTC=1
# TODO: correlated errors 

# TODO: implement a metropolis within gibbs - The success of this approach depends on how close the artificial MNIW prior is to the “true” prior.
# TODO: checkout scaled inverse prior for measurement equation 
# TODO: for that reason, implement Hierarchical prior, which works with our prior: "The values for ν0 and S0 can be chosen the same way as in the case of the natural conjugate prior." - page 11 https://joshuachan.org/papers/large_BVAR.pdf
# TODO: lowest decile has negative level and share. Kuhn reports negative level. what about share? 
# TODO: marginal functions evaluated at 10, 20, ... 99th percentile, but copula top corner takes from 90 to 100 percentile 

# TODO: The application has been more usually presented using the inverse-gamma distribution formulation instead; however, some authors, following in particular Gelman et al. (1995/2004) argue that the inverse chi-squared parametrisation is more intuitive.





#  DIMESampler,
#  add Optimization, OptimizationOptimJL, ReverseDiff, ForwardDiff, Optim, DataFrames, FreqTables, DualNumbers, AdvancedHMC, CSV, LineSearches, Zygote, Distributed, Printf, ProgressBars, StatsFuns, Interpolations, GR


# using HPFilter

#  add GenericLinearAlgebra, Distributions, StatsPlots, Plots, MCMCChains, HypothesisTests, GLM
#  add LaTeXTabulars Dates, PeriodicalDates, KernelDensity, Measures, MultivariateStats, PlotlyJS, Parameters, FFTW, XLSX, StatsBase, LaTeXStrings, LinearAlgebra, BenchmarkTools, TimerOutputs, Test, DelimitedFiles, PDMats, JLD2, Trapz


