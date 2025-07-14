
using Plots
using Distributions
using StatsBase
using Polynomials

# Gets some data 
@unpack df_vec = obs_data
data = df_vec[1][5]
data = data[data[:, :year] .== 2016, :]
inverse_hyperbolic_sine(x) = log.(x .+ sqrt.(x.^2 .+ 1))

# grid stuff 
grid_size      = collect(0.05:0.05:1)
# grid_size      =  nodes(20, :chebyshev_nodes, [1.0, 0.0]).points
grid_size[end] = 0.99

# Estimate the percentiles
p_v = inverse_hyperbolic_sine(generate_percentiles(data[:, :income], data[!, :weight], "ecdf", grid_size))

# For chebyshev later 
scale_to_interval(x_values) = 2 * (x_values .- minimum(x_values)) / (maximum(x_values) - minimum(x_values)) .- 1
# x_cheb = scale_to_interval(x_sorted)
p = Polynomials.fit(ChebyshevT, grid_size, p_v[:], 10)
p.coeffs

Plots.plot()
for (i,d) in enumerate(collect(3:2:9))
    p = Polynomials.fit(ChebyshevT, grid_size, p_v[:], d)

    # q = ChebyshevT([p.coeffs...])

    # Step 4: Evaluate the fitted polynomial
    x_values = collect(range(minimum(grid_size), 1, length=20))
    x_values[end] = .99 

    # normalize x-values to be within [-1, 1]
    x_values_cheb = scale_to_interval(x_values)
    y_poly_cdf = p.(x_values_cheb)
    # q_poly_cdf = q.(x_values_cheb)

    if i == 1 Plots.scatter!(grid_size, p_v, label=L"\textrm{Empirical}\,\, F^{-1}", linestyle=:solid, xformatter=:latex, yformatter=:latex, mc=:black) end 
    Plots.scatter!(x_values, y_poly_cdf, label=L"\textrm{Polynomial\,\, Estimator\,\, %$(d)}", linestyle=:dot, alpha=0.4)
    # Plots.scatter!(x_values, q_poly_cdf, label=L"\textrm{Polynomial\,\, Estimator\,\, %$(d)}", linestyle=:dot, alpha=0.4)
    Plots.xlabel!(L"\textrm{Grid\,\, Points}")
    Plots.ylabel!(L"\textrm{Inverse\,\, Hyperbolic\,\, Sine\,\, of\,\, Income}")
end
Plots.savefig("quantile_estimation.pdf")


function cdf_to_pdf2(cdf_matrix)
    # Initialize the PDF matrix with zeros
    pdf_matrix = zeros(size(cdf_matrix))
  
    # Compute differences between adjacent cells
    for i in 1:size(cdf_matrix, 1)
        for j in 1:size(cdf_matrix, 2)
            left = j > 1 ? cdf_matrix[i, j-1] : 0
            above = i > 1 ? cdf_matrix[i-1, j] : 0
            left_above = (i > 1 && j > 1) ? cdf_matrix[i-1, j-1] : 0
            pdf_matrix[i, j] = cdf_matrix[i, j] - left - above + left_above
        end
    end
  
    return pdf_matrix
  end
  
  function cdf_to_pdf_3d(cdf_matrix)
    # Initialize the PDF matrix with zeros
    pdf_matrix = zeros(size(cdf_matrix))
  
    # Compute differences between adjacent cells in 3D
    for i in 1:size(cdf_matrix, 1)
        for j in 1:size(cdf_matrix, 2)
            for k in 1:size(cdf_matrix, 3)
                left = k > 1 ? cdf_matrix[i, j, k-1] : 0
                above = j > 1 ? cdf_matrix[i, j-1, k] : 0
                back = i > 1 ? cdf_matrix[i-1, j, k] : 0
                left_above = (j > 1 && k > 1) ? cdf_matrix[i, j-1, k-1] : 0
                left_back = (i > 1 && k > 1) ? cdf_matrix[i-1, j, k-1] : 0
                above_back = (i > 1 && j > 1) ? cdf_matrix[i-1, j-1, k] : 0
                left_above_back = (i > 1 && j > 1 && k > 1) ? cdf_matrix[i-1, j-1, k-1] : 0
  
                pdf_matrix[i, j, k] = cdf_matrix[i, j, k] - left - above - back + left_above + left_back + above_back - left_above_back
            end
        end
    end
  
    return pdf_matrix
  end


grid  = 10
dom_1 = [1.0, 0.0] # upper bound first -> package says so
dom_2 = [1.0, 0.0]

p1     = nodes(grid, :chebyshev_nodes, dom_1) #TODO: change this to be expand_grid 
g      = Grid((p1,p1))
do_nothing(x) = x
A_plan = CApproxPlan(g, (6, 6), [dom_1 dom_2], do_nothing)
  

# Import first SCF data 
@unpack df_vec = obs_data
df = df_vec[1][1]
df = df[df[:, :year] .== 1984, :]

lg = length(p1.points)
xx = p1.points
xx = collect(1/lg:1/lg:1)
xx[end] = .99

# Filter NaNs from the data
df = df[.!isnan.(df[:, :income]), :]
df = df[.!isnan.(df[:, :consum]), :]
X  = Matrix(select(df, ["income", "consum"]))

R"""
# mesh_grid <- as.matrix(expand.grid(Dim1 = $pp, Dim2 = $pp))
mesh_grid <- as.matrix(expand.grid(Dim1 = $xx, Dim2 = $xx))
EC = copula::C.n(mesh_grid, X = $X, smoothing = "beta") 
mat_dist <- matrix(EC, nrow = $lg, ncol = $lg)       
"""
@rget mat_dist

# Correct the matrix
mat_dist .= mat_dist ./ maximum(mat_dist)

# Quickly do cdf to pdf and plot
cop_den   = cdf_to_pdf2(mat_dist)
Plots.surface(xx, xx, cop_den, label="Copula Density", xlabel="Income Rank", ylabel="Wealth Rank", title="Copula Density", camera = (30,10), size=(400,400), color=:winter, display_option=Plots.GR.OPTION_SHADED_MESH)
Plots.savefig("NonParametricAnalysis/copula_density.pdf")

f_approx  = chebyshev_interp(mat_dist, A_plan)
f_weights = chebyshev_weights(mat_dist, A_plan)

propertynames(f_approx)



function interp_test(x::AbstractArray{R,1}) where {R<:Number}

    yhat = chebyshev_evaluate(f_weights, x, A_plan.order, A_plan.domain)

    return yhat

end


X = [ [xx[i], xx[j]] for i in 1:length(xx), j in 1:length(xx) ]

a = interp_test.(X) ./ maximum(interp_test.(X))
mat_dist

# Compare the two
Plots.plot()
Plots.plot!(1:length(mat_dist), mat_dist[:], label="R")
Plots.plot!(1:length(mat_dist), a[:], label="Julia")
Plots.savefig("NonParametricAnalysis/interp_test.pdf")


# First estimator: beta 
# issue: copula is estimated. Then copula density is extracted ... density can be negative sometimes
# Generate matrix of points to evaluate the approximation
for gl in [100, 20, 10]
    x = collect(1/gl:1/gl:1)
    y = collect(1/gl:1/gl:1)
    # x = nodes(gl, :chebyshev_nodes, dom_1).points
    # y = nodes(gl, :chebyshev_nodes, dom_1).points
    x[end] = .995
    y[end] = .995
    X = [ [x[i], y[j]] for i in 1:length(x), j in 1:length(y) ]
    cop_den = cdf_to_pdf2(f_approx.(X))
    println(sum(cop_den .< 0))
    
    # min-max scale the approximation
    # cop_den = (cop_den .- minimum(cop_den)) ./ (maximum(cop_den) .- minimum(cop_den))

    # normalize s.t. sums to 1 
    cop_den[cop_den .< 0] .= 0
    cop_den = cop_den ./ sum(cop_den)
    if gl == 10 println(cop_den) end


    # Plot the approximation
    Plots.surface(x, y, cop_den, label="Chebyshev Approximation", xlabel="Income Rank", ylabel="Wealth Rank", title="Copula Density Approximation", camera = (30,10), size=(400,400), color=:winter, display_option=Plots.GR.OPTION_SHADED_MESH)
    Plots.savefig("NonParametricAnalysis/beta_estimator_chebyshev_approx$gl.pdf")
end
