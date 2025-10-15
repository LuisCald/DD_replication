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
SSM(par) = -likeli(model_elements, par, param_sizes, priors, meas_ind, Σ_ids, model_options)[1]
SSM(par, _) = -likeli(model_elements, par, param_sizes, priors, meas_ind, Σ_ids, model_options)[1]

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
logV, alarm = likeli(model_elements, par_final, param_sizes, priors, meas_ind, Σ_ids, model_options)

local dv
if tag == "Γ estimated"
    A_new, B_new, Ω_new, Δ_new, G_new, likeli_vec, Δ_log = run_EM_algorithm(param_vector, param_sizes, meas_ind, Σ_ids, model_elements, model_options)
    dv, _ = reconstruct_data_short(A_new, B_new, Ω_new, Δ_new, G_new, likeli_vec, Δ_log, model_elements, obs_data, model_options, time_params, data_sources; reconstruction_to_show=false, dε_smoothed=false)
else
    dv, _ = reconstruct_data(par_final, param_sizes, priors, meas_ind, Σ_ids, model_elements, obs_data, model_options, time_params, data_sources)
end

within_stat_dict = Dict()
include("ReconstructionOLD.jl")
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
            if tag != " HANK"
                export_combined_stat_dict_to_latex(within_stat_dict, [measures..., "copula"], dict_path, label) # [measures..., "copula"]
                compare_to_external_sources(dv, ty, func_data, obs_data, user_t, time_params, model_options, kind_of_plots, label)
            end
        end
    end
end
println("done!")

# Generate Correlations Table 
export_table_to_tex_with_strings(measures, :from_mcmc)
generate_correlations_table_for_external_comparisons("SCF", measures, tag, type, "cycle")

# MDD# Loop through files in the directory
folder = "/home/luisc/Distributional_Dynamics/7_Results/MDD/"

# Get a list of all .jld2 files in the folder, Julia
jld2_files = [f for f in readdir(folder) if endswith(f, ".jld2")]

for file in jld2_files
    dd = jldopen(folder * file, "r")
    println("harmonic mean", dd["mdd_hm"])
    println("bridge sampler", dd["mdd_bs"])
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
perform_forecast("CEX", par_final, param_sizes, priors, meas_ind, Σ_ids, filtering_criteria, obs_data, model_options, model_elements, time_params, user_t, func_data, kind_of_plots, ["extensive", "data_only"])



A, B, C, D, Ω_big, _ = matrisize(par_final, param_sizes)

r, q = size(B) # number of factors and controls
big_zero = zeros(eltype(A), size(A))
big_zero_b = zeros(eltype(B), size(B))
AI = Matrix{eltype(A)}(I, size(A, 1), size(A, 1))  # Identity matrix of the same type as A


L = [A B;
    C D]

# New procedure for variance decomposition
@unpack u = model_elements
@unpack case = model_options
smoother_res, logV, alarm = likeli(model_elements, par_final, param_sizes, priors, meas_ind, Σ_ids, model_options; smooth=true)
@unpack x_smoothed, x_filtered = smoother_res               # F̂_t   (nF × T)
@unpack u = model_elements
X_choice = x_filtered
Y = u

A, B, C, D, Ω, _ = matrisize(par_final, param_sizes)
r, q = size(B) # number of factors and controls
# e = X_choice[:, 2:end] - A * X_choice[:, 1:end-1] - B * Y[:, 1:end-1] # residuals
# Ω = cov(e; dims=2)                # Var(ε_t)  (nF × nF)
Ωf = Ω[1:r, 1:r]  # Factor covariance matrix
Ωy = Ω[r+1:end, r+1:end]  # Control covariance

A_star = A + B * (I - D)^(-1) * C
IA = (I - A_star)^(-1)
var_F = IA * Ωf * IA' + IA * (B * (I - D)^(-1)) * (B * (I - D)^(-1))' * IA'
var_Y = IA * (B * (I - D)^(-1)) * Ωy * (B * (I - D)^(-1))' * IA'

part_f = tr(IA * Ωf * IA')
part_y = tr(IA * (B * (I - D)^(-1)) * (B * (I - D)^(-1))' * IA')
tot_var = part_f + part_y
share_f = part_f / tot_var
share_y = part_y / tot_var






ϵ = 1e-10
P_big = lyapd(L, Ω_big)   # (4nF+ny) × (4nF+ny)  PSD
Ωf = Ω_big[1:r, 1:r]  # Factor covariance matrix
Ωy = Ω_big[r+1:end, r+1:end]  # Control covariance
G = inv((I - A) - B * inv(I - D) * C)
M = B * inv(I - D)           # convenient shorthand
V_F = G * Ωf * G'
V_Y = G * M * Ωy * M' * G'
V_tot = V_F + V_Y
tr(V_F) / tr(V_tot)  # Fraction of variance explained by factors



# Perform Variance Decomposition
smoother_res, logV, alarm = likeli(model_elements, par_final, param_sizes, priors, meas_ind, Σ_ids, model_options; smooth=true)
@unpack x_smoothed, x_filtered = smoother_res               # F̂_t   (nF × T)
@unpack u = model_elements

X_choice = x_smoothed
# --- 1.  VAR(1) residuals and their covariance -----------------------------
# e = X_choice[:, 2:end] .- L * X_choice[:, 1:end-1]     # (r+q) × (T-1)
A, B, C, D, Ω, _ = matrisize(par_final, param_sizes)
Ω[diagind(Ω)] = log.(exp.(Ω[diagind(Ω)]) .+ 1)
Ω_full = Ω # Diagonal(diag(cov(e; dims = 2)))                               # (r+q) × (r+q)

nx = size(A, 1)                         # = r  (number of factors)
nq = size(D, 1)                         # = q  (idiosyncratic AR processes)

Ω_x = Ω_full[1:nx, 1:nx]     # Var(η^x_t)
Ω_ε = Ω_full[nx+1:end, nx+1:end]     # Var(η^ε_t)
# (cross blocks are zero in most DSGE/FA set-ups; grab them too if not)

# --- 2.  Reduced-form factor VAR -------------------------------------------
A_star = A + B * ((I - D) \ C)          # == A here because C == 0
IA = inv(I - A_star)                   # (I - A*)^{-1}

# --- 3.  “Multiplier” from ε-innovations into x_t ---------------------------
G = B * ((I - D) \ I(nq))                 # = B (I‒D)^{-1}

# --- 4.  Unconditional variance of factors and shares ----------------------
var_F = IA * Ω_x * IA' + IA * G * Ω_ε * G' * IA'

part_f = tr(IA * Ω_x * IA')       # contribution of η^x shocks
part_y = tr(IA * G * Ω_ε * G' * IA')    # contribution of η^ε shocks
tot_var = part_f + part_y

share_f = part_f / tot_var
share_y = part_y / tot_var

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


# off_diagonal_indices = setdiff(1:19^2, diagind(A))
# θ_cop[off_diagonal_indices] .= 0  
n = param_sizes[1][1]
b = param_sizes[2][2]
A = reshape(par_final[1:n*n], (n, n))
B = reshape(par_final[n*n+1:n*n+n*b], (n, b))
Ω = Diagonal(par_final[n*n+n*b+1:n*n+n*b+n])
Σ = Diagonal(par_final[end-param_sizes[4][1]+1:end])



