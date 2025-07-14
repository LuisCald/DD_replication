# Estimating kernel distribution function smoothing with the kernel density estimation method

# Preliminaries
include("DistributionalDynamics.jl")

# Define the kernel distribution function for income, which can handle weights 
function kernel_distribution(x, x_grid, h, weights)
    n = length(x)
    m = length(x_grid)
    f = zeros(m)
    for i in 1:m
        # Evaluate the kernel function at each data point
        kernel_values = weights .* pdf.(Normal(), (x .- x_grid[i]) / h)
        # Compute the weighted sum of kernel values
        f[i] = sum(kernel_values) / sum(weights) # i guess it only works for frequency weights? 
    end
    # Normalize the density estimate
    # f = f #./ sum(f)
    cdf_value(v) = sum(f[x_grid .<= v])
    return cdf_value  # Compute the cumulative sum to obtain the CDF estimate
end

# Compute interquartile range that can deal with weighted data
function iqr(data::Vector{T}, weight::Vector{T}) where T<:Real
    q75, q25 = quantile(data, weights(weight), [0.75, 0.25])
    return q75 - q25
end

function silverman_bandwidth(data::Vector{T}, weight) where T<:Real
    n = length(data)

    h = 0.9 * min(var(data, weights(weight)), iqr(data, weight) / 1.34) / n^(1/5)
    return h
end

function generate_percentiles(rv, weight, method, grid_size)
    # Estimate cdf and generate percentiles 
    obs    = unique(rv)
    local rv_cdf, U 
    if method == "ecdf"
        rv_cdf = ecdf(rv, weights=weight)
    elseif method == "kde"
        # h      = silverman_bandwidth(rv, weight)
        # x_grid = minimum(rv):2000:maximum(rv)
        # rv_cdf = kernel_distribution(rv, x_grid, h, weight)
        U         = kde(rv, weights = weight, npoints = 8192)
    end

    # Percentiles 
    cdf_obs = method == "ecdf" ? map(x -> rv_cdf(x), sort(obs)) : cumsum(pdf(U, sort(obs))) ./ sum(pdf(U, sort(obs))) 

    # Generate probability mass function for next part 
    pmf = Float64[]
    for i in 1:length(obs)
        if i == 1 
            append!(pmf,cdf_obs[1])
        else
            append!(pmf, cdf_obs[i]-cdf_obs[i-1])
        end
    end
    # Generate, using MLE, the distribution object 
    Σ_p = sum(pmf)
    println(pmf[pmf .< 0])

    if Σ_p ≉ 1
        println(Σ_p)
        if round(Σ_p, digits=4) == 1
            pmf = pmf ./ sum(pmf)
        else
            println("Warning: PMF does not sum to 1")
        end
    end
    d = DiscreteNonParametric(sort(obs), pmf)

    # Sampling from the distribution object # out = rand(d,100) # Test it: plot(sort(out))
    # Generate percentile functions 
    # grid      = collect(0.05:1/grid_size:.95)
    # grid[end] = .99
    rv_vals   = zeros(length(grid_size), 1)

    # Inverse transform 
    for (i, v) in enumerate(grid_size)
        rv_vals[i] = quantile(d,v)  # Gives you the income value for some percentile from distribution "d" 
    end 
    return rv_vals
end

@unpack df_vec = obs_data

# Import first SCF data 
df = df_vec[1][5]
df = df[df[:, :year] .== 2019, :]
df = df[.!isnan.(df[:, :income]), :]
df = df[.!isnan.(df[:, :wealth]), :]
df = df[.!isnan.(df[:, :weight]), :]

# Generating the deciles way 
non_missing               = filter("income" => !isnan, df)
non_missing               = coalesce.(non_missing, NaN)
filter!("weight" => !isnan, non_missing)
grid                      = length(non_missing[:, :income])
interval                  = 1 / grid
grid_points               = collect(interval:interval:1) 
assign_quantile_groups!(non_missing, "income", grid, grid_points)
assign_quantile_groups!(non_missing, "wealth", grid, grid_points)

# Create two variables, each sorted
df[:, :income_rank] = competerank(df[:, :income], weights=weights(df[:, :weight])) ./ length(df[:, :income])
df[:, :wealth_rank] = competerank(df[:, :wealth]) ./ length(df[:, :wealth])

# Generate kde of income and wealth 
n = length(df[:, :income])
kernel_dist(::Type{Beta},w::Real) = Beta(1,1)

mv_kde = kde(
    # (non_missing[:, :income_quantile] ./ (n + 1), non_missing[:, :wealth_quantile]  ./ (n + 1)), 
    # weights = non_missing[:, :weight], 
    (df[:, :income_rank], df[:, :wealth_rank]),
    weights = df[:, :weight],
    npoints = (8, 8),
    kernel= Beta,
    boundary=((0, 1), (0, 1))
    )


# Plots.surface(
#     c_axis, 
#     c_axis, 
#     d_data_dict["copulas"]["data"][colons..., y],  # copula 
#     xlabel = L"\textrm{%$(measure1)}",
#     ylabel = L"\textrm{%$(measure2)}",
#     zlabel = L"dC(%$(m1), %$(m2))", 
#     xformatter=:latex, 
#     yformatter=:latex, 
#     zformatter=:latex, 
#     legend=false, 
#     camera = (30,10), 
#     size=(400,400),
#     color=:winter, 
#     display_option=Plots.GR.OPTION_SHADED_MESH)
# Plot the surface generated from this 
Plots.surface(mv_kde.x, mv_kde.y, mv_kde.density ./ sum(mv_kde.density), c=:viridis, xlabel = "Income", ylabel = "Wealth", zlabel = "Density", legend = :none)
Plots.savefig("kde_surface.pdf")

# # Generate the percentile plots 
# grid_size      = collect(0.01:0.01:1)
# grid_size[end] = 0.99
# rv_vals        = generate_percentiles(df[:, :income], df[:, :weight], "kde", grid_size)
# rv_vals_ecdf   = generate_percentiles(df[:, :income], df[:, :weight], "ecdf", grid_size)


# q_vec = zeros(grid)

# for i in 1:grid
#     data_q    = filter(x -> x["income" * "_quantile"] == i, non_missing)
#     q_vec[i]  = mean(data_q[:, "income"], weights(data_q[:, :weight]))
# end
# # symmetric log 
# symlog(x) = sign(x) * log(1 + abs(x))

# # Plot the percentiles
# Plots.plot(grid_size, symlog.(rv_vals), label = "KDE", xlabel = "Percentile", ylabel = "Income", legend = :topleft)
# Plots.savefig("percentiles.pdf")
# Plots.plot!(grid_size, symlog.(rv_vals_ecdf), label = "ECDF", xlabel = "Percentile", ylabel = "Income", legend = :topleft)
# Plots.plot!(grid_size, symlog.(q_vec), label = "Deciles", xlabel = "Percentile", ylabel = "Income", legend = :topleft)

# # Deciles
# Plots.plot(grid_size, symlog.(rv_vals), label = "KDE", xlabel = "Percentile", ylabel = "Income", legend = :topleft)
# Plots.plot!(grid_size, symlog.(rv_vals_ecdf), label = "ECDF", xlabel = "Percentile", ylabel = "Income", legend = :topleft)
# Plots.plot!(grid_size, symlog.(q_vec), label = "Deciles", xlabel = "Percentile", ylabel = "Income", legend = :topleft)
# Plots.savefig("deciles.pdf")

