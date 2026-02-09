# To just generate the plots 
# cd("/Users/lc/Dropbox/Distributional_Dynamics/5_Code")
include("DistributionalDynamics.jl")

@unpack measures, data_cutoffs, tag = model_options
println(tag)
label = "3D_A non-diag"
m_label = measures_folder(measures)

const func_data, time_params, model_elements = estimation_prep(obs_data, model_options);
println("finished prepping data")
const (param_vector, param_sizes, priors, meas_ind, Σ_ids) = set_params(model_elements, time_params, model_options)
println("finished setting priors")

# Extract hyperpriors
hyperpriors = priors[end-5:end]
SSM(par) = -likeli(model_elements, par, param_sizes, hyperpriors, Σ_ids, model_options)[1]
SSM(par, _) = -likeli(model_elements, par, param_sizes, hyperpriors, Σ_ids, model_options)[1]

# Generate plots 
kind_of_plots = :mcmc
# par_final = run_black_box_opt(SSM, param_vector, param_sizes, priors, measures)
# println("finished optimization")
# par_final = get_param_vector(measures, kind_of_plots, label, data_cutoffs, tag) #TODO: adapt code to actual number of chains


niter = 400 #param_sizes[1][1] * 50
par_final = run_DIME_sampler(model_elements, niter, param_vector, param_sizes, priors, meas_ind, Σ_ids, model_options)
println("finished optimization")

# min_param_vectors now contains the parameter vector for each chain that minimizes the log probability
# store_optim_estimate(par_final, label, m_label, data_cutoffs, tag)

@unpack tmin, tmax = time_params
@unpack gdp_series = obs_data
@unpack data_sources = func_data
user_t = (deepcopy(tmin), deepcopy(tmax))
opttag = "from_mcmc"
logV, alarm = likeli(model_elements, par_final, param_sizes, hyperpriors, Σ_ids, model_options)

local dv
if tag == "Γ estimated"
    A_new, B_new, Ω_new, Δ_new, G_new, likeli_vec, Δ_log = run_EM_algorithm(param_vector, param_sizes, meas_ind, Σ_ids, model_elements, model_options)
    dv, _ = reconstruct_data_short(A_new, B_new, Ω_new, Δ_new, G_new, likeli_vec, Δ_log, model_elements, obs_data, model_options, time_params, data_sources; reconstruction_to_show=false, dε_smoothed=false)
else
    dv, _ = reconstruct_data(par_final, param_sizes, hyperpriors, meas_ind, Σ_ids, model_elements, obs_data, model_options, time_params, data_sources)
end

within_stat_dict = Dict()
include("ReconstructionOLD.jl")
include("CreateTimeSeries.jl")
include("Validation.jl")
for (c, k) in enumerate(keys(dv))
    within_stat_dict[k] = Dict()
    # for ty in ["normal", "average"]
    for ty in ["normal"]
        within_stat_dict[k][ty], dv[k][ty] = export_functional_data(dv[k][ty], ty, k, kind_of_plots, obs_data, func_data, time_params, user_t, model_options, false, true)

        if c == length(keys(dv)) && ty == "normal"
            init_path = dirname(pwd())[end-7:end] == "Dynamics" ? dirname(pwd()) : pwd()
            dict_path = init_path * "/7_Results/$m_label" * "$tag" * "/$opttag/plots/"
            compare_to_data(dv, ty, func_data, obs_data, user_t, time_params, model_options, kind_of_plots, label)
            export_combined_stat_dict_to_latex(within_stat_dict, [measures..., "copula"], dict_path, label) # [measures..., "copula"]
            if !occursin(" HANK", tag)
                compare_to_external_sources(dv, ty, func_data, obs_data, user_t, time_params, model_options, kind_of_plots, label)
            end
        end
    end
end
println("done!")

# Generate Correlations Table 
type = "from_mcmc"
export_table_to_tex_with_strings(measures, :from_mcmc)
generate_correlations_table_for_external_comparisons("SCF", measures, tag, type, "cycle")

# MDD# Loop through files in the directory
folder = "/home/luisc/Distributional_Dynamics/7_Results/MDD/"

# Get a list of all .jld2 files in the folder, Julia
jld2_files = [f for f in readdir(folder) if endswith(f, ".jld2")]

for file in jld2_files
    println("Processing file: ", file)
    dd = jldopen(folder * file, "r")
    println("harmonic mean", dd["mdd_hm"])
    println("bridge sampler", dd["mdd_bs"])
end


# sizes: Φ (n×n), J (r×n), B (n×(r_dist+q_agg))
A, B, C, D, Ω_var, Ω_corr, Σ = matrisize(par_final[1:end-6], param_sizes)
r_dist = param_sizes[1][1]
q_agg = param_sizes[2][2]

# Example
Ω_var[diagind(Ω_var)] = log.(exp.(Ω_var[diagind(Ω_var)]) .+ 1)  # softplus transformation
mat_Ω_corr = Matrix(Ω_corr)
Ω = Ω_var * mat_Ω_corr * Ω_var'

r, q = size(B)
nₛ = 4r + q
Tval = eltype(A)

# Getting priors
# priors = get_priors(model_elements, model_options, hyper_params)
# push!(priors, hyperpriors...)

# Get controls 
@unpack u = model_elements
smoother_res, logV, alarm = likeli(model_elements, par_final, param_sizes, hyperpriors, Σ_ids, model_options; smooth=true)
@unpack x_smoothed, dε_smoothed = smoother_res

# Y = x_smoothed[vcat(collect(1:8), collect(33:57)), :]; #
# Y = vcat(x_smoothed[collect(1:8), :], u);
# p = 1;
# y = Y';
# (T, K) = size(y);
# X = y;
# y = transpose(y);
# Y = y[:, p+1:T];
# X = lagmatrix(X, p)';
# β = (Y * X') / (X * X');
# ϵ = Y - β * X;
# Σ_var = ϵ * ϵ' / (T - p * K - 1);

# --------- constant matrices ------------------------------------
AI = Matrix{Tval}(I, r, r);

Φ = zeros(Tval, nₛ, nₛ);
@views begin
    Φ[1:r, 1:r] .= A
    Φ[1:r, 4r+1:4r+q] .= B
    Φ[r+1:2r, 1:r] .= AI
    Φ[2r+1:3r, r+1:2r] .= AI
    Φ[3r+1:4r, 2r+1:3r] .= AI
    Φ[4r+1:end, 1:r] .= C
    Φ[4r+1:end, 4r+1:end] .= D
end

ids_sub = vcat(1:r, 4r+1:4r+q);  # indices of nonzero shock rows
Φ_sub = Φ[ids_sub, ids_sub];  # truncate zero rows/cols if q < full q

tbl = fevd_dist_vs_agg(model_elements, model_options, obs_data, Φ_sub, Ω; r, q, horizon=1, factor_names=nothing, shock_order=:agg_first)
# tbl = fevd_dist_vs_agg(model_elements, model_options, obs_data, Φ_sub, Ω; r, q, horizon=20, factor_names=nothing, shock_order=:dist_first)

# LaTeX export
latex_str = pretty_table(tbl, backend=Val(:latex), tf=tf_latex_default)

# Write to a .tex file
open("fevd_table.tex", "w") do io
    write(io, latex_str)
end

function VAR_fit(y::AbstractArray, p::Int64)
    (T, K) = size(y)
    X = y
    y = transpose(y)
    Y = y[:, p+1:T]
    X = lagmatrix(X, p)'
    β = (Y * X') / (X * X')
    ϵ = Y - β * X
    Σ = ϵ * ϵ' / (T - p * K - 1)
    return diag(Σ)
end


# Generate parameter vectors based on the MCMC chains
# param_mat = vcat(par_final, DIME_chains[end, rand(1:50, 4), :])
# while size(param_mat, 2) < 50
#     param_mat_int = copy(par_final)
#     while size(param_mat_int, 2) < 5
#         pv        = min_param_vectors[rand(1:end), :]
#         if all(isnan.(pv))
#             nothing
#         else
#             param_mat_int = hcat(param_mat_int, pv)
#         end
#     end
#     # Take average 
#     param_mat = hcat(param_mat, mean(param_mat_int, dims=2))
# end


# Generate microdata implicates
# include("CreateTimeSeries.jl")
# generate_microdata_implicates(200, "SCF", param_sizes, priors, meas_ind, Σ_ids, model_elements, obs_data, model_options, time_params, data_sources, tag)
# generate_microdata_implicates(200, "CEX", param_sizes, priors, meas_ind, Σ_ids, model_elements, obs_data, model_options, time_params, data_sources, tag)
# generate_microdata_implicates(draws, "PSID", param_sizes, priors, meas_ind, Σ_ids, model_elements, obs_data, model_options, time_params, data_sources, tag)





# # Generate Consumption plots 
# generate_relative_to_peak_plots()


# Performing the different forecasts 
how_much = 1 # removes X observation(s) from SCF
perform_forecast("SCF", par_final, param_sizes, priors, meas_ind, Σ_ids, how_much, obs_data, model_options, model_elements, time_params, user_t, func_data, kind_of_plots, ["iterative"])


# filtering_criteria = Dict("periods" => 20)
# filtering_criteria = Dict("dates" => ("2004-Q4", "2009-Q4"))
# perform_forecast("SCF", par_final, param_sizes, priors, meas_ind, Σ_ids, filtering_criteria, obs_data, model_options, model_elements, time_params, user_t, func_data, kind_of_plots, ["extensive", "all_data"])

@unpack time_dict = time_params
@unpack year_vec = time_params
periods_to_remove = muted_quarters_between(QuarterlyDate(1984, 1), QuarterlyDate(2021, 4))
cex_quarters = QuarterlyDate(1984, 1):Quarter(1):QuarterlyDate(2021, 4)
dvec = filter(x -> x ∉ periods_to_remove, cex_quarters)

filtering_criteria = Dict("periods_to_remove" => periods_to_remove)
perform_forecast("CEX", par_final, param_sizes, hyperpriors, meas_ind, Σ_ids, filtering_criteria, obs_data, model_options, model_elements, time_params, user_t, func_data, kind_of_plots, ["extensive", "data_only"])
