# To just generate the plots 
# cd("/Users/lc/Dropbox/Distributional_Dynamics/5_Code")
include("DistributionalDynamics.jl")

@unpack measures, data_cutoffs, tag = model_options
println(tag)
label = "3D_A non-diag"
m_label = measures_folder(measures)

const func_data, time_params, model_elements = estimation_prep(obs_data, model_options);
const (param_vector, param_sizes, priors, meas_ind, Σ_ids) = set_params(model_elements, time_params, model_options)
println("finished setting priors")
SSM(par) = -likeli(model_elements, par, param_sizes, priors, meas_ind, Σ_ids, model_options)[1]
SSM(par, _) = -likeli(model_elements, par, param_sizes, priors, meas_ind, Σ_ids, model_options)[1]

# Generate plots 
kind_of_plots = :mcmc
par_final = run_black_box_opt(SSM, param_vector, param_sizes, priors, measures)
println("finished optimization")
# par_final     = get_param_vector(measures, kind_of_plots, label, data_cutoffs, tag) #TODO: adapt code to actual number of chains


niter = param_sizes[1][1] * 100
par_final = run_DIME_sampler(model_elements, niter, param_vector, param_sizes, priors, meas_ind, Σ_ids, model_options)
println("finished optimization")

# min_param_vectors now contains the parameter vector for each chain that minimizes the log probability
# store_optim_estimate(par_final, label, m_label, data_cutoffs, tag)

# Perform Variance Decomposition
# n = param_sizes[1][1]
# b = param_sizes[2][2]
# A = reshape(par_final[1:n*n], (n, n))
# B = reshape(par_final[n*n+1:n*n+n*b], (n, b))
# Ω = Diagonal(par_final[n*n+n*b+1:n*n+n*b+n])
# Σ = Diagonal(par_final[end-param_sizes[4][1]+1:end])


# New procedure for variance decomposition
@unpack u = model_elements
@unpack case = model_options
smoother_res, logV, alarm = likeli(model_elements, par_final, param_sizes, priors, meas_ind, Σ_ids, model_options; smooth=true)
@unpack x_smoothed, x_filtered = smoother_res               # F̂_t   (nF × T)
@unpack u = model_elements
X_choice = x_filtered

for i in axes(x_filtered, 1)
    Plots.plot(x_filtered[i, :], label="F_$i", xlabel="Time", ylabel="Value", title="Filtered State Variable $i")
    Plots.plot!(x_smoothed[i, :], label="F̂_$i", linestyle=:dash)
    if i > 8
        Plots.plot!(u[i-8, :], label="Y_$i", linestyle=:dot)
    end
    Plots.savefig("filtered_state_variable_$i.pdf")
end

A, B, D, Ω, _ = matrisize(par_final, param_sizes)
D = Diagonal(diag(D))
C = zeros(size(D, 1), size(A, 1))
L = [A B; C D] # VAR(1) representation
e = X_choice[:, 2:end] - L * X_choice[:, 1:end-1]
Ω = cov(e; dims=2)                # Var(ε_t)  (nF × nF)

A_star = A + B * (I - D)^(-1) * C
IA = (I - A_star)^(-1)
var_F = IA * Ω * IA' + IA * (B * (I - D)^(-1)) * (B * (I - D)^(-1))' * IA'

part_f = tr(IA * Ω * IA')
part_y = tr(IA * (B * (I - D)^(-1)) * (B * (I - D)^(-1))' * IA')
tot_var = part_f + part_y
share_f = part_f / tot_var
share_y = part_y / tot_var

part_y2 = tr((I - A)^(-1) * (B * B') * (I - A)^(-1)')
part_f2 = tr((I - A)^(-1) * Ω * (I - A)^(-1)')
tot_var2 = part_f2 + part_y2
share_f2 = part_f2 / tot_var2
share_y2 = part_y2 / tot_var2


# ------------------------------------------------------------------
# 1.  Inputs you already extracted from the smoother / estimation
# ------------------------------------------------------------------
@unpack case = model_options
A, B, _, _ = matrisize(par_final, param_sizes, case)
# Ω[diagind(Ω)] = log.(exp.(Ω[diagind(Ω)]) .+ 1)
Y = u
X_choice = x_filtered
# ------------------------------------------------------------------
# 2.  Sample covariances and cross–covariance
#      cov expects *observations in columns* → no transpose needed
# ------------------------------------------------------------------
# Σ_F = cov(X_choice; dims=2)                # Var(F_t)
# C_FY = (I - A) \ (B)
# Find residuals
e = X_choice[:, 2:end] - A * X_choice[:, 1:end-1] - B * Y[:, 1:end-1] # residuals
Ω = cov(e; dims=2)                # Var(ε_t)  (nF × nF)
C_FY = cov(X_choice, Y; dims=2)
Σ_F = lyapd(A, B * B' + A * C_FY * B' + B * C_FY' * A' + Ω)
Σ_Y = Matrix(I, size(Y, 1), size(Y, 1)) # Var(Y_t) (nY × nY)

# Q = B * Σ_Y * B' + Ω         # everything that hits F_{t+1} unexpectedly
# Σ_F = lyap(A, Q)         # solves Σ = A Σ A' + Q   (discrete Lyapunov)


# ------------------------------------------------------------------
# 3.  Variance-decomposition matrices
# ------------------------------------------------------------------
term_A = A * Σ_F * A'                      # A Σ_F A′
term_BY = B * Σ_Y * B'                      # B Σ_Y B′
term_cross = A * C_FY * B' + B * C_FY' * A'    # cross terms
term_Omega = Ω

# ------------------------------------------------------------------
# 4.  Shares of total variance  tr(term)/tr(Σ_F)
# ------------------------------------------------------------------
trF = tr(Σ_F)

share_A = tr(term_A) / trF
share_BY = tr(term_BY) / trF
share_X = tr(term_cross) / trF
share_Ω = tr(term_Omega) / trF
println("  ------ check sum    : ", round(share_A + share_BY + share_X + share_Ω, digits=4))

# Variance formula 

# println("Optimization done")
# par_final = vec(Matrix(CSV.read("/home/luisc/Distributional_Dynamics/7_Results/consum_and_income_and_wealth Γ estimated/from_mcmc/parameter_vectors/solution3D_A non-diag.jld2", DataFrame, header=0)))
# par_final = vec(Matrix(CSV.read("/Users/lc/Dropbox/Distributional_Dynamics/7_Results/consum_and_income_and_wealth/from_optimization/parameter_vectors/solution3D_A non-diag_A.csv", DataFrame, header=0)))
# Increase measurement error a bit 
# θ_cop[20*20+20*37+20+1:end] = θ_cop[20*20+20*37+20+1:end] ./4

# get the off diagonal of A 
# A    = reshape(θ_cop[1:19*19], (19,19))
# od_A = offdiag(A)
# describe(od_A)

# Issues: handling of missing of SCF ... do we 

# Getting dimensions of each matrix within the parameter vector
# dimensions = [prod(param_sizes[i]) for i in 1:length(param_sizes)]
# condition_Σ = dimensions[1]+dimensions[2]+1:dimensions[1]+dimensions[2]+19
# θ_cop[condition_Σ] .= θ_cop[condition_Σ] ./ 5

# mean(diag(priors[1].Σ)[dimensions[1]+1:dimensions[1]+dimensions[2]])
# mean(diag(priors[1].Σ)[1:dimensions[1]])

# @unpack minnesota_params = model_options
# minnesota_params = [0.2, 0.3, 100, .01, 2.0, 0.95]
# @pack! model_options = minnesota_params

# θ_cop = θ1
# init_path = dirname(pwd())[end-7:end] == "Dynamics" ? dirname(pwd()) : pwd()
# DelimitedFiles.writedlm(init_path * "/7_Results/income_and_wealth/from_mcmc/parameter_vectors/posterior_mean_" * "july7.csv",  θ_cop, ',')

# θ_cop[19*19+1:19*19+19*36] = θ_cop[19*19+1:19*19+19*36] ./ 2
# aggs_start_finish = hcat(priors[1].μ[19*19+1:19*19+19*36], θ_cop[19*19+1:19*19+19*36])
# CSV.write("aggs_params.csv", DataFrame(aggs_start_finish, :auto))
# θ_cop[19*19+1:19*19+19*12] = θ_cop[19*19+1:19*19+19*12] .* 1.5

# θ_cop[19*19+1:19*19+19*23] = θ_cop[19*19+1:19*19+19*23] *.5
# θ_cop[1:20:19*19] .= .90


# off_diagonal_indices = setdiff(1:19^2, diagind(A))
# θ_cop[off_diagonal_indices] .= 0  
n = param_sizes[1][1]
b = param_sizes[2][2]
A = reshape(par_final[1:n*n], (n, n))
B = reshape(par_final[n*n+1:n*n+n*b], (n, b))
Ω = Diagonal(par_final[n*n+n*b+1:n*n+n*b+n])
Σ = Diagonal(par_final[end-param_sizes[4][1]+1:end])



# par_final[n*n+n*b+1:n*n+n*b+n] .= par_final[n*n+n*b+1:n*n+n*b+n] .* 10
# par_final[end-param_sizes[4][1]+1:end] .= par_final[end-param_sizes[4][1]+1:end] ./ 10

# par_final[end-param_sizes[4][1]+1] = .1
# par_final[end-param_sizes[4][1]+4] = 2
# par_final[end-param_sizes[4][1]+1:end] .= 1
# par_final[n*n+1:n*n+n*b] .= par_final[n*n+1:n*n+n*b] ./ 2

# # par_final[end] = par_final[end] * 10
# # par_final[end-4] = par_final[end-4] / 2

# par_final[end-param_sizes[4][1]+1:end] .= par_final[end-param_sizes[4][1]+1:end] .* 10


# par_final[n*n+1:n*n+n*b] .= par_final[n*n+1:n*n+n*b] ./ 2

# par_final[end-7] = par_final[end-7] .* 1000

# par_final[end-param_sizes[4][1]+1:end] = [4, 2, 3, 3, 4, 2, 3, 4, 4, 3, 3]
# par_final[end-param_sizes[4][1]+1:end] .= par_final[end-param_sizes[4][1]+1:end] .* 2

# # HACK 
# par_final[n*n+n*b+1:n*n+n*b+n] .= par_final[n*n+n*b+1:n*n+n*b+n] ./ 2
# par_final[end-7] = par_final[end-7] .* 1000 #CPS 

# init_path = dirname(pwd())[end-7:end] == "Dynamics" ? dirname(pwd()) : pwd()
# DelimitedFiles.writedlm(init_path * "/7_Results/$m_label/from_optimization/parameter_vectors/solution" * "$label.csv",  par_final, ',') 

# θ_cop[end-param_sizes[4][1]+1] = θ_cop[end-param_sizes[4][1]+1] ./ 100
# a = par_final[end-param_sizes[4][1]+1:end]
# a = a .* 100
# par_final[end-param_sizes[4][1]+1:end] .= a

# par_final[end-param_sizes[4][1]+1] = 20.0
# θ_cop[n*n+n*b+1:n*n+n*b+n] .= θ_cop[n*n+n*b+1:n*n+n*b+n] .* 2
# θ_cop[19*19+19*36+19+1:end] = θ_cop[19*19+19*36+19+1:end] .* 10
# smoother_output, _               = likeli(model_elements, par_final, param_sizes, priors, meas_ind, Σ_ids, model_options, true)
# @unpack x_filtered  = smoother_output

# @unpack compare_to_other_est = model_options
# compare_to_other_est = false
# @pack! model_options = compare_to_other_est
# init_path     = dirname(pwd())[end-7:end] == "Dynamics" ? dirname(pwd()) : pwd()
# a = jldopen(init_path * "/posterior_draws" * "/" * m_label * "_$tag.jld2")
# par_final = mean(a["d_chains"][end, :, :][:,:], dims=1)
# store_optim_estimate(par_final, label, m_label, data_cutoffs, tag)

@unpack tmin, tmax = time_params
@unpack gdp_series = obs_data
@unpack data_sources = func_data
# user_t     = (Dict("year" => 1990, "quarter" => 1), Dict("year" => 2021, "quarter" => 4))
user_t = (deepcopy(tmin), deepcopy(tmax))
# init_path                               = dirname(pwd())[end-7:end] == "Dynamics" ? dirname(pwd()) : pwd()
# all_chains = jldopen(init_path * "/2D_income_and_wealth_A non-diag.jld2", "r")
# @unpack par_mcmc, parameter_chain, bounds = all_chains["all_chains"]

opttag = "from_mcmc"
# opttag = "from_optimization"

#TODO: decrease maximum of process eror, mess with aggs 
logV, alarm = likeli(model_elements, par_final, param_sizes, priors, meas_ind, Σ_ids, model_options)

local dv
if tag == "Γ estimated"
    A_new, B_new, Ω_new, Δ_new, G_new, likeli_vec, Δ_log = run_EM_algorithm(param_vector, param_sizes, meas_ind, Σ_ids, model_elements, model_options)
    dv, _ = reconstruct_data_short(A_new, B_new, Ω_new, Δ_new, G_new, likeli_vec, Δ_log, model_elements, obs_data, model_options, time_params, data_sources; reconstruction_to_show=false, dε_smoothed=false)
else
    dv, _ = reconstruct_data(par_final, param_sizes, priors, meas_ind, Σ_ids, model_elements, obs_data, model_options, time_params, data_sources)
end

within_stat_dict = Dict()
include("CreateTimeSeries.jl")
include("Validation.jl")
for (c, k) in enumerate(keys(dv))
    within_stat_dict[k] = Dict()
    for ty in ["normal", "average"]
        within_stat_dict[k][ty], dv[k][ty] = export_functional_data(dv[k][ty], ty, k, kind_of_plots, obs_data, func_data, time_params, user_t, model_options, false, true)

        if c == length(keys(dv)) && ty == "normal"
            init_path = dirname(pwd())[end-7:end] == "Dynamics" ? dirname(pwd()) : pwd()
            dict_path = init_path * "/7_Results/$m_label" * "$tag" * "/$opttag/plots/"
            compare_to_data(dv, ty, func_data, obs_data, user_t, time_params, model_options, kind_of_plots, label)
            export_combined_stat_dict_to_latex(within_stat_dict, [measures..., "copula"], dict_path, label) # [measures..., "copula"]
            compare_to_external_sources(dv, ty, func_data, obs_data, user_t, time_params, model_options, kind_of_plots, label)
        end
    end
end
println("done!")

# Generate Correlations Table 
export_table_to_tex_with_strings(measures, type)

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
# generate_microdata_implicates(200, "CEX_all", param_sizes, priors, meas_ind, Σ_ids, model_elements, obs_data, model_options, time_params, data_sources, tag)
# generate_microdata_implicates(draws, "PSID", param_sizes, priors, meas_ind, Σ_ids, model_elements, obs_data, model_options, time_params, data_sources, tag)





# # Generate Consumption plots 
# generate_relative_to_peak_plots()


# Performing the different forecasts 
# how_much = 1 # removes X observation(s) from SCF
# perform_forecast("SCF", par_final, param_sizes, priors, meas_ind, Σ_ids, how_much, obs_data, model_options, model_elements, time_params, user_t, func_data, kind_of_plots, ["iterative"])


# filtering_criteria = Dict("periods" => 20)
filtering_criteria = Dict("dates" => ("2004-Q4", "2009-Q4"))
perform_forecast("SCF", par_final, param_sizes, priors, meas_ind, Σ_ids, filtering_criteria, obs_data, model_options, model_elements, time_params, user_t, func_data, kind_of_plots, ["extensive", "all_data"])

@unpack time_dict = time_params
nd = length(collect(keys(time_dict[1])))
periods_to_remove = setdiff(collect(1:nd), collect(2:4:nd))
cex_years = sort(collect(keys(time_dict[1])))[periods_to_remove]
dvec = []
for i in cex_years
    push!(dvec, QuarterlyDate(i, 4))
end
filtering_criteria = Dict("periods_to_remove" => dvec)

perform_forecast("CEX_all", par_final, param_sizes, priors, meas_ind, Σ_ids, filtering_criteria, obs_data, model_options, model_elements, time_params, user_t, func_data, kind_of_plots, ["extensive", "data_only"])


