# hd_tables.jl — the historical decomposition of run_postestimation.jl Step 7 (block Cholesky, aggregates first, smoothed
# innovations at the mode) with its recession table SAVED (the post-estimation step only draws hd_recessions_f*.pdf).
# Output: 7_Results/aggregate_blocks/<tag>/hd_recessions.csv — TargetFactor × Recession × Source (OwnFactor, OtherFactors,
# Aggregates) with VarSharePct as make_hd_tables defines it (the bars of hd_recessions_f*.pdf), plus hd_decades.csv.
#   DD_EXAMPLE=replication DD_TAG=" scf22" [DD_AGG_MODE=blocks DD_AGG_SPEC=b11] julia --project=... hd_tables.jl
include(joinpath(@__DIR__, "DistributionalDynamics.jl"))
using LinearAlgebra

const OUT = joinpath(RESULTS_DIR, "aggregate_blocks", strip(model_options.tag))
mkpath(OUT)
func_data, time_params, model_elements = estimation_prep(obs_data, model_options)
param_vector, param_sizes, priors, meas_ind, Σ_ids = set_params(model_elements, time_params, model_options)
hyperpriors = st_hyperpriors(priors, param_sizes)
@unpack tmin, tmax = time_params
par_final = get_param_vector(model_options.measures, :mcmc, "3D_$(model_options.case)", model_options.data_cutoffs, model_options.tag)

# Φ and Ω exactly as Step 6 builds them
A, B_mat, C, D, Ω_var, Ω_corr, _ = matrisize(st_core_params(par_final, param_sizes), param_sizes)
Ω_var[diagind(Ω_var)] = log.(exp.(Ω_var[diagind(Ω_var)]) .+ 1)
Ω = Ω_var * Matrix(Ω_corr) * Ω_var'
r, q = size(B_mat)
Φ = zeros(4r + q, 4r + q)
Φ[1:r, 1:r] .= A; Φ[1:r, 4r+1:4r+q] .= B_mat
for k in 1:3; Φ[k*r+1:(k+1)*r, (k-1)*r+1:k*r] .= Matrix(I, r, r); end
Φ[4r+1:end, 1:r] .= C; Φ[4r+1:end, 4r+1:end] .= D

smoother_res, _, _ = likeli(model_elements, par_final, param_sizes, hyperpriors, Σ_ids, model_options; smooth = true)
ids_hd = vcat(1:r, 4r+1:4r+q)
hd = historical_decomp_factors_blockchol(Φ[ids_hd, ids_hd], r, q, smoother_res.dε_smoothed[ids_hd, :], smoother_res.x_smoothed[ids_hd, :], Ω;
    splitting = :group, shock_order = :agg_first)
@info "Historical decomposition: max reconstruction error $(hd.maxerr)"
dts_hd = QuarterlyDate(tmin["year"], tmin["quarter"]):Quarter(1):QuarterlyDate(tmax["year"], tmax["quarter"])
# DD_HD_PLOTS=1 also redraws hd_recessions_f*.pdf into the run's plots folder (post-estimation Step 7 output) without a full post-estimation
hd_plots = get(ENV, "DD_HD_PLOTS", "0") == "1"
plot_dir = joinpath(RESULTS_DIR, measures_folder(model_options.measures) * model_options.tag, "from_mcmc", "plots", "historical_decomposition")
hd_plots && mkpath(plot_dir)
rows_dec, rows_nber = make_hd_tables(hd.cube, hd.order, hd.ids, year.(dts_hd), quarter.(dts_hd); make_recession_plots = hd_plots, out_dir = plot_dir)
CSV.write(joinpath(OUT, "hd_recessions.csv"), rows_nber)
CSV.write(joinpath(OUT, "hd_decades.csv"), rows_dec)
println("HDTABLE " * strip(model_options.tag))
show(stdout, unstack(filter(x -> x.Source == "Aggregates", rows_nber), :TargetFactor, :Recession, :VarSharePct); allrows = true, allcols = true); println()
