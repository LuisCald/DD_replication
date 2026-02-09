# Things to run 
cd("/Users/lc/Dropbox/Distributional_Dynamics/5_Code")
include("DistributionalDynamics.jl")

const func_data, time_params, model_elements            = data_prep(obs_data, method_options);
const (param_vector, param_sizes, priors, meas_ind)     = set_params(model_elements, time_params, method_options)

# look at current measurment error and parameter vector errors 

init_path = dirname(pwd())[end-7:end] == "Dynamics" ? dirname(pwd()) : pwd()
cop_nd_sol_path  = init_path * "/7_Results/income_and_wealth/from_optimization/parameter_vectors/solution2D_A non-diag_copulas and percentile functions_.csv"
# cop_nd_mcmc_path  = init_path * "/7_Results/income_and_wealth/from_mcmc/parameter_vectors/posterior_mean_2D_A non-diag_copulas and percentile functions_eq.csv"

# cop_2D_nd_sol_path  = init_path * "/7_Results/income_and_wealth/from_mcmc/parameter_vectors/posterior_mean_2D_A non-diag.csv"
# θ = vec(Matrix(CSV.read(cop_2D_nd_sol_path, DataFrame, header=0)))

# A = reshape(θ[1:20*20], (20,20))
# B = reshape(θ[20*20+1:20*20+20*37], (20,37))
# Ω = Diagonal(θ[20*20+20*37+1:20*20+20*37+20])
# Σ = Diagonal(θ[20*20+20*37+20+1:end])





# Plug in the different matrices to see which one does it 
-likeli(model_elements, θ₁_nd, param_sizes, priors, meas_ind, method_options)[1]
-likeli(model_elements, θ₂_nd, param_sizes, priors, meas_ind, method_options)[1]

label = "2D_A non-diag_copulas and percentile functions_"
θ_cop = vec(Matrix(CSV.read(cop_nd_sol_path, DataFrame, header=0)))
θ_cop = vcat(θ_cop, rand(110))
@unpack tmin, tmax = time_params 
@unpack gdp_series = obs_data 
@unpack data_sources = func_data
user_t  = (Dict("year" => 1965), tmax)

dv, _     = reconstruct_data(θ_cop, param_sizes, priors, meas_ind, model_elements, obs_data, method_options, time_params, data_sources)
# data_bounds = generate_reconstruction_bounds(parameter_chain, par_mcmc, param_sizes, priors, meas_ind, model_elements, obs_data, method_options, time_params, data_sources, mcmc_options)
# export_functional_data(dv["SCF"], "SCF", :optimization, obs_data, func_data, time_params, user_t, method_options)  
      
for (c, k) in enumerate(keys(dv))
    println(k)
    dv[k] = export_functional_data(dv[k], k, :optimization, obs_data, func_data, time_params, user_t, method_options)        
    if c == length(keys(dv))
        compare_to_WID(dv, func_data, user_t, time_params, method_options, :optimization, label)
    end
end

@info("Generating plots")
generate_all_plots(dv, :mcmc, func_data, gdp_series, time_params, user_t, label, method_options, data_bounds)
f = jldopen(init_path * "/5_Code/DIME_res.jld2", "r")
f = jldopen(init_path * "/5_Code/ci_income_and_wealth_deciles_PSID_and_SCF.jld2", "r")
f = jldopen(init_path * "/5_Code/2D_A non-diag.jld2", "r")

# ac = f["all_chains"]
@unpack par_mcmc, parameter_chain = f["all_chains"]
e = 250000

θD = ac.μ

θ1 = mean(parameter_chain[:,:,2], dims=1)'
θ2 = mean(parameter_chain[Int(end-e):end,:,2], dims=1)'
θ3 = mean(parameter_chain[Int(end-e):end,:,3], dims=1)'
θ4 = mean(parameter_chain[Int(end-e):end,:,4], dims=1)'
# θ5 = mean(parameter_chain[Int(end-e):end,:,5], dims=1)'
# θ6 = mean(parameter_chain[Int(end-e):end,:,6], dims=1)'
θ5 = mean(hcat(θ1, θ2, θ3, θ4), dims=2)
Θ_all = hcat(θ₁_nd, θ1, θ2, θ3, θ4, θ5, par_mcmc)


# substituting the three rows for the opt 
θ5_b         = reshape(θ5[8:217], (7,30))
θ₁_b         = reshape(θ₁[8:217], (7,30))
θ₂[8:217]         = θ₁[8:217]


-likeli(model_elements, θ₁_nd, param_sizes, priors, meas_ind, method_options)[1]
-likeli(model_elements, θ₂, param_sizes, priors, meas_ind, method_options)[1]

-likeli(model_elements, θ1, param_sizes, priors, meas_ind, method_options)[1]
-likeli(model_elements, θ2, param_sizes, priors, meas_ind, method_options)[1]
-likeli(model_elements, θ3, param_sizes, priors, meas_ind, method_options)[1]
-likeli(model_elements, θ4, param_sizes, priors, meas_ind, method_options)[1]
-likeli(model_elements, par_mcmc, param_sizes, priors, meas_ind, method_options)[1]

θ1_b = reshape(θ1[50:259], (7,30))
θ2_b = reshape(θ2[50:259], (7,30))
θ3_b = reshape(θ3[8:217], (7,30))
θ4_b = reshape(θ4[8:217], (7,30))
θ5_b = reshape(θ5[8:217], (7,30))
θ₁_b = reshape(θ₁_nd[8:217], (7,30))
θ₂_b = reshape(θ₂[8:217], (7,30))

θ₁_Ω = θ₁_nd[259:266]
θ₁_Σ = θ₁_nd[267:end]

# looking at the two series 
θ₁_a = θ₁[1:7]
θ₂_a = θ₂[1:7]
θ₁_b = reshape(θ₁[8:210], (7,29))
θ₂_b = reshape(θ₂[8:210], (7,29))
θ₁_e = θ₁[218:end]
θ₂_e = θ₂[218:end]
θ₁_Ω = θ₁[211:217]
θ₂_Ω = θ₂[211:217]

diag(priors[1].Σ)[218:224]
density(diag(priors[1].Σ))
describe(diag(priors[1].Σ))

reshape(diag(priors[1].Σ)[1:49], (7,7))
reshape(diag(priors[1].Σ)[50:252], (7,29))
diag(priors[1].Σ)

θ1_e = θ1[259:266]
θ2_e = θ2[259:266]
θ3_e = θ3[259:266]
θ4_e = θ4[259:266]
θ5_e = θ5[267:end]
Θ_all_e = vcat(θ5_e, θ2_e, θ3_e, θ4_e, θ5_e)

density(θ₁_e)
describe(rand(LogNormal(log(100), 2), 10000))
m        = 0.1
v        = 0.05
mean_log = log(m^2 / sqrt(v + m^2))
var_log  = sqrt(log(v/m^2 + 1))m
p = barhist(rand(LogNormal(mean_log, var_log ), 10000), bins=100)

p = barhist(rand(LogNormal(log(100), 2), 10000), bins=100)
Plots.savefig(p, "test2.png")

repeat([mode(truncated(Cauchy(0,20); lower=0, upper=100))], factor_count)

mode(LogNormal(log(.72) /4, 2))
median(truncated(Cauchy(0,20); lower=0, upper=100))

truncated(Cauchy(0,20); lower=0, upper=100)


p = barhist(rand(truncated(LogNormal(mean_log, var_log/2 ); lower=0, upper=1), 1000000), bins=100)
Plots.savefig(p, "test.png")


0.184561213
0.378170292
0.073061989
0.060322508
0.003235946
0.012507523
0.187506405
0.196322038
0.190169302
0.113346582

# the distribution of this parameter 
all_b = parameter_chain[7:217, :, :]
density(all_b[1,:,1])

# Trying to figure out what kind of values generate the noise I want 
y, Σ = likeli(model_elements, θ₁_nd, param_sizes, priors, meas_ind, method_options)
a = y[:, vec(mapslices(col -> all((!isnan).(col)), y, dims = 1))]
        println(var(a, dims=1))
b = var(a, dims=1)
        Plots.plot(b', kind="histogram")
density(b')
        # Manipulate error term myself (i increase var in Σ => var in Y decreases)

Plots.plot(diag(Σ), kind="histogram")
density(diag(Σ))


 density(rand(LogNormal(log(.72), 1), 100))
 d = rand(LogNormal(log(0.1), 1), 10000)
 density(d[d.<0.5])  # modeling the standard deviations 
 logpdf(Normal(0.9, 0.3), 1.5)
 density(rand(LogNormal(log(.72)/2, 1), 100))
 density(rand(LogNormal(log_mean(log(.72), 1), log_variance(log(.72) / 2, 1)), 1000))


# Debugging the dates situation 
using PeriodicalDates 
aggregate_data[:, "date"] = QuarterlyDate.(aggregate_data[:, "time"]) 
select!(aggregate_data, "date", Not(:date))
filter(row -> row.date < QuarterlyDate(1990, 2), aggregate_data)

    
MV[1][:, vec(mapslices(col -> any((!isnan).(col)), MV[1], dims = 1))]
MV[2][:, vec(mapslices(col -> any((!isnan).(col)), MV[2], dims = 1))]

b = [1950
1953
1956
1959
1962
1965
1968
1971
1977
1983
1989
1992
1995
1998
2001
2004
2007
2010
2013
2016
2019]
b = b .- 1953 .+1
b =b[b .>0]
b = b .*4
b = b .- 4 .+1 
MV[1][:, b]

1967
1968
1969
1970
1971
1972
1973
1974
1975
1976
1977
1978
1979
1980
1981
1982
1983
1984
1985
1986
1987
1988
1989
1990
1991
1992
1993
1994
1995
1996
1998
2000
2002
2004
2006
2008
2010
2012
2014
2016
2018
d = InverseGamma(3,0.1)
e = LogNormal(log(.01), 1.2)
f = InverseGamma(.001, .001)
g = InverseGamma(4, 1)

density(rand(d, 100))
density(rand(e, 100))
density((!isnan).(rand(f, 100)))
logpdf(d, .1)  # increasing noise makes this better -> not good 
logpdf(e, 0.5)
logpdf(e, 1)
logpdf(e, 2)

logpdf(d, 0.5)
logpdf(d, 1)
logpdf(d, 2)

logpdf(f, 0.5)
logpdf(f, 1)
logpdf(f, 2)

logpdf(g, 0.5)
logpdf(g, 1)
logpdf(g, 2)

density(rand(InverseGamma(3,0.05), 10000))
density(rand(LogNormal(log(.01), 0.6), 10000))
density(rand(LogNormal(log(1),2), 10000))
density(rand(TDist(1), 10000000))

# plan: to mess with the measurement error and seeing what happens to Y 
# before, large measurements, small noise. 
param_vector[end-7:end] .= .002 # increase noise from .0009 to .002 => Σ == 1000, y decreased in variance and size 
param_vector[end-7:end] .= .02 # increase noise to .02 => Σ == 1000

y, Σ = likeli(model_elements, θ₂_nd, param_sizes, priors, meas_ind, method_options)
a = y[:, vec(mapslices(col -> all((!isnan).(col)), y, dims = 1))]

a[:, 1]
a[:, end]
        println(vec(var(a, dims=2)))



# Seeing which plots look nice 
a = aggregate_data[:,"TABSHNO"]
b = a .+ 10000
c = a .- 10000
lines = hcat(a, b, c)
Plots.plot(1:281, lines[:,1], linestyle = :solid, ribbon=(10000, 10000), linewidth=2, fillalpha = 0.1)
Plots.plot!(1:281, lines[:,2], linestyle = :dash, linewidth=2)
# Plots.scatter!(1:100, lines[:,3], marker = :diamond)
Plots.plot!(1:281, lines[:,3], linestyle = :dash, linewidth=2)



# Suppose we did not log. This means the mean of the dependent variable has a clear interpretation. 
# Just the level. Taking the average would be (∑ᵢⁿ depᵢ) / n

# Since we log, things change. The mean of deportations ≂̸ exp(mean(log(deportations))). The log is computed first. 
# The mean is not really interpretable. For the estimation sample, the mean of deportations is 35/40 or so. 
# The reason why the mean is so low is => there are 310 zeros within the boundary. 
# They remain zero after the log transformation, but the rest of the numbers are closer to zero now. 
# So, the mean drops. But in reality, this mean is not super interpretable. 


# define distribution
m = 2
cov_scale = 0.05
weight = (0.33, 0.1)
ndim = 35
LogProb = CreateDIMETestFunc(ndim, weight, m, cov_scale)
LogProbParallel(x) = pmap(LogProb, eachslice(x, dims=2))

initvar = 2
nchain = ndim*5 # a sane default
initcov = I(ndim)*initvar
initmean = zeros(ndim)
initchain = rand(MvNormal(initmean, initcov), nchain)


pmap(LogProb, eachslice(rand(35,2), dims=2))



# a = []
# for k in eachindex(MV)
#     for i in axes(MV[k], 1)
#         b = var(MV[k][i, .!isnan.(MV[k][i,:])])
#         println(b)
#         push!(a, b)
#     end
# end
# density(a)
# var(MV[1][:, vec(mapslices(col -> all((!isnan).(col)), MV[1], dims = 1))], dims=2)

# var(MV[1][1, .!isnan.(MV[1][1,:])])

# @unpack pcs = model_elements
# df = DataFrame(y1 = pcs[1, :], y2 = pcs[2, :], y3 = pcs[3, :], y4 = pcs[4, :], y5 = pcs[5, :], y6 = pcs[6, :], y7 = pcs[7, :])

# function lagmatrix(vector::AbstractVector, lags::AbstractVector)
#     n = length(vector)
#     p = length(lags)
#     matrix = Matrix{eltype(vector)}(undef, n, p)
#     for j in 1:p
#         k = lags[j]
#         if k >= 0
#             matrix[:, j] = [fill(NaN, k); vector[1:(n-k)]]
#         else
#             matrix[:, j] = [vector[(1-k):n]; fill(NaN, -k)]
#         end
#     end
#     return matrix
# end


# function fit_ols(df::DataFrame, lag_order::Int)
#     X = hcat([lagmatrix(df[:, i], 1:lag_order)[:, 2:end] for i in 1:size(df, 2)]...) # construct design matrix
#     names_X = ["$(col)_t-$j" for (j, col) in Iterators.product(1:lag_order, names(df))]
#     names_X[1:size(df, 2)] .= names(df)
#     y = df[:, 1] # response variable
#     model = lm(X[lag_order+1:end, :], y[lag_order+1:end]) # fit OLS regression
#     coef_df = coef(model) # save estimated coefficients as a DataFrame
#     return coef_df
# end

# n_ts = size(df, 2)
# max_lag = 2
# coefficients = []
# for i in 1:n_ts
#     for j in 1:max_lag
#         coef_df = fit_ols(df[:, [i, setdiff(1:n_ts, i)...]], j) # pass a DataFrame with the ith column and all others except i
#         push!(coefficients, coef_df)
#     end
# end

# for i in 1:7
#     model = lm(add_trends(Matrix(df[2:end, :])), df[1:end-1, i]) # fit OLS regression
#     println(model)
# end

a = rand(10)
ci_l = a .- 0.5
ci_u = a .+ 0.5
xaxis = 1:10
using Plots
Plots.plot(xaxis, a, ribbon=(0.5, 0.5), fillalpha = 0.1, linewidth=2, linestyle=:dash, label="")

cop = log.(rand(Normal(),10,10) .+ 5)
lb = cop .- 0.5
ub = cop .+ 0.5

Plots.surface(
    1:10, 
    1:10, 
    cop,  # copula 
    xlabel = L"\textrm{measure1}",
    ylabel = L"\textrm{measure2}",
    zlabel = L"dC(m1, m2)", 
    xformatter=:latex, 
    yformatter=:latex, 
    zformatter=:latex, 
    legend=false, 
    camera = (30,10), 
    size=(400,400),
    color=:winter,
    display_option=Plots.GR.OPTION_SHADED_MESH)
    

    Plots.surface!(
    1:10, 
    1:10,
    lb, 
    fillalpha=0.4,
    legend=false, 
    camera = (30,10), 
    size=(400,400),
    color=:winter,
    display_option=Plots.GR.OPTION_SHADED_MESH)
    

    Plots.surface!(
        1:10, 
        1:10,
        ub, 
        fillalpha=0.2,
        legend=false, 
        camera = (30,10), 
        size=(400,400),
        color=:winter, 
        display_option=Plots.GR.OPTION_SHADED_MESH)


    Plots.savefig("/Users/lc/Desktop/test.png")
   
   
   
    df   = retrieve_data(IS_prefixes, true, 1998, 1999)

    for d  in collect(keys(df[1]))
        filter!(x -> x.UCC == 800721, df[1][d]) # x.UCC == 210110 || 
        select!(df[1][d], Not(["COST_", "GIFT", "PUBFLAG"]))
        sort!(df[1][d], ["CUSTOM_CUID", "REF_MO"])
    end
    
    describe(df[1]["mtbi_19991"][!,:COST])
    describe(df[1]["mtbi_19992"][!,:COST])
    describe(df[1]["mtbi_19993"][!,:COST])
    describe(df[1]["mtbi_19994"][!,:COST])
    
    df[2]["fmli_19991"]
    
    for d  in collect(keys(df[2]))
        select!(df[2][d], ["NEWID", "CUSTOM_CUID", "RENTEQVX", "QINTRVMO", "QINTRVYR"])
        sort!(df[2][d], ["CUSTOM_CUID", "QINTRVYR", "QINTRVMO"])
    end
    
    describe(df[2]["fmli_19991"][!,:RENTEQVX])
    describe(df[2]["fmli_19992"][!,:RENTEQVX])
    describe(df[2]["fmli_19993"][!,:RENTEQVX])
    describe(df[2]["fmli_19994"][!,:RENTEQVX])
    
    select!(mtbi_data, ["CUSTOM_CUID", "REF_DATE", "800721", "210110"])
    sort!(df[1][d], ["CUSTOM_CUID", "REF_MO"])
    
    
    describe(filter(x -> x.REF_DATE < Date(1999, 1, 1), mtbi_data)[:, "800721"])