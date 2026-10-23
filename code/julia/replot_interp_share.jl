# replot_interp_share.jl — redraw only the interpolation-share heatmap (Anatomy figure) for the run selected by the DD_*
# switches, at its stored mode, without the rest of post-estimation. Output: 7_Results/<run>/from_mcmc/plots/anatomy/
# ow_interp_share_relabel.pdf (the published ow_interp_share.pdf is left untouched).
#   DD_EXAMPLE=replication DD_TAG=" scf22" DD_AGG_MEAS=published DD_INC_SHIFT=0 julia --project=5_Code/code/julia/env 5_Code/code/julia/replot_interp_share.jl
include(joinpath(@__DIR__, "DistributionalDynamics.jl"))
func_data, time_params, model_elements = estimation_prep(obs_data, model_options)
param_vector, param_sizes, priors, meas_ind, Σ_ids = set_params(model_elements, time_params, model_options)
hyperpriors = st_hyperpriors(priors, param_sizes)
@unpack tmin = time_params
par_final = get_param_vector(model_options.measures, :mcmc, "3D_$(model_options.case)", model_options.data_cutoffs, model_options.tag)
length(par_final) == length(param_vector) || error("mode/spec mismatch")
sm, _, _ = likeli(model_elements, par_final, param_sizes, hyperpriors, Σ_ids, model_options; smooth=true)
A2, B2, C2, D2, Ωv2, Ωc2, _ = matrisize(st_core_params(par_final, param_sizes), param_sizes)
Ωv2[diagind(Ωv2)] = log.(exp.(Ωv2[diagind(Ωv2)]) .+ 1)
Ω2 = Ωv2 * Matrix(Ωc2) * Ωv2'
Φ2, Ωbig = build_Phi_Omega(A2, B2, C2, D2, Ω2, 4)
P∞ = stationary_cov(Φ2, Ωbig)
dts = collect(QuarterlyDate(tmin["year"], tmin["quarter"]) .+ Quarter.(0:length(sm.sigma_smoothed)-1))
an_dir = joinpath(RESULTS_DIR, measures_folder(model_options.measures) * model_options.tag, "from_mcmc", "plots", "anatomy")
mkpath(an_dir)
plot_interpolation_share(sm.sigma_smoothed, P∞; states=1:param_sizes[1][1], dates=dts, outfile=joinpath(an_dir, "ow_interp_share_relabel.pdf"))
@info "written $(joinpath(an_dir, "ow_interp_share_relabel.pdf"))"
