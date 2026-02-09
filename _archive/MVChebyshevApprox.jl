include("DistributionalDynamics.jl")
@rlibrary copula
# Pkg.add(url="https://github.com/LuisCald/ChebyshevApprox.jl")
# Chebyshev Approximation

function minimization_objective(x, grid, dom_1)
    # Looping over several orders 
    metric = []
    p1     = nodes(grid, :chebyshev_nodes, dom_1) #TODO: change this to be expand_grid 
    g      = Grid((p1,p1))

    for o in 1:10
      A_plan   = CApproxPlan(g, (o, o), [dom_1 dom_1], do_nothing)
      f_approx = chebyshev_interp(x, A_plan)
      gpoints  = p1.points
      X        = [ [gpoints[i], gpoints[j]] for i in 1:length(gpoints), j in 1:length(gpoints) ]
      append!(metric, sum((x - f_approx.(X)).^2))
    end
    return findall(minimum(metric) .== metric)[1]
end
minimization_objective(cop_dis, 10, [1.0, 0.0])

grid  = 10
dom_1 = [1.0, 0.0] # upper bound first -> package says so
dom_2 = [1.0, 0.0]
expand_grid(x) = (2/ pi) .* acos.(x)
inverse_expand(x::AbstractArray) = sort(cos.(pi./2 .* x))
inverse_expand(x::Real) = cos(pi /2 * x)

# inverse_expand(x) = cos(pi/2 * x)
do_nothing(x) = x

p1     = nodes(grid, :chebyshev_nodes, dom_1) #TODO: change this to be expand_grid 
p2     = nodes(grid, :chebyshev_nodes, dom_2)
g      = Grid((p1,p2))
A_plan = CApproxPlan(g, (9, 9), [dom_1 dom_2], do_nothing)

# Approximation for 3 dimensions 
grid   = 10
dom_1  = [1.0, 0.0, 0.0]
p1     = nodes(grid, :chebyshev_nodes, dom_1)
p2     = nodes(grid, :chebyshev_nodes, dom_1)
p3     = nodes(grid, :chebyshev_nodes, dom_1)
g      = Grid((p1,p2,p3))
A_plan = CApproxPlan(g, (10, 10, 10), [dom_1 dom_1 dom_1], do_nothing)

@unpack df_vec = obs_data
df = df_vec[1][5]
df = df[df[:, :year] .== 2016, :]
non_missing               = filter("income" => !isnan, select(df, ["income", "wealth", "liquid", "weight", "id"]))
non_missing               = coalesce.(non_missing, NaN)
filter!("weight" => !isnan, non_missing)
grid                      = 10
interval                  = 1 / grid
grid_points               = collect(interval:interval:1) 
# grid_points               = p1.points
assign_quantile_groups!(non_missing, "income", grid, grid_points)
assign_quantile_groups!(non_missing, "wealth", grid, grid_points)
assign_quantile_groups!(non_missing, "liquid", grid, grid_points)

# X_r  = Matrix(unique(select!(non_missing, ["income_quantile", "wealth_quantile", "liquid_quantile"]))) ./ (length(grid_points) + 1)
X_r  = Matrix(unique(select!(non_missing, ["income_quantile", "wealth_quantile"]))) ./ (length(grid_points) + 1)
# X_r  = Matrix(X_r[completecases(X_r), :])
# Filter out rows with NaNs
# X_r  = X_r[.!isnan.(X_r), :]
X_r  = rand(10,10,10)
f_approx = chebyshev_interp(X_r, A_plan)


# # if points in [-1, 1] already, then normalize does nothing 
# pp = nodes(grid, :chebyshev_nodes, [1.0, -1.0]).points
# ChebyshevApprox.normalize_node(pp, [1.0, -1.0])

pp = nodes(10, :chebyshev_nodes, [1.0, 0.0]).points
ChebyshevApprox.normalize_node(pp, [1.0, 0.0])

pp = sort(expand_grid(nodes(grid, :chebyshev_nodes, [1.0, 0.0]).points))
ChebyshevApprox.normalize_node(pp, [1.0, 0.0])

# A_plan = CApproxPlan(g, (6, 6), [dom_1 dom_2], do_nothing)

# Import first SCF data 
@unpack df_vec = obs_data
df = df_vec[1][5]
df = df[df[:, :year] .== 2016, :]

lg = length(p1.points)
# xx = sort(inverse_expand(p1.points))
xx = sort(expand_grid(p1.points))
xx = p1.points
X  = Matrix(select(df, ["income", "wealth"]))

R"""
# mesh_grid <- as.matrix(expand.grid(Dim1 = $pp, Dim2 = $pp))
mesh_grid <- as.matrix(expand.grid(Dim1 = $xx, Dim2 = $xx))
EC = copula::C.n(mesh_grid, X = $X, smoothing = "beta") 
mat_dist <- matrix(EC, nrow = $lg, ncol = $lg)

# convert to density 
cop_dis <- matrix(mat_dist, nrow = $lg, ncol = $lg)  # Reshaping
cop_den <- matrix(0, nrow = $lg, ncol = $lg)  # Initialize a matrix of zeros

for (h in 1:$lg) {
  for (j in 1:$lg) {
    if (h == 1 && j == 1) {
      cop_den[h, j] <- cop_dis[h, j]
    } else if (h == 1 && j != 1) {
      cop_den[h, j] <- cop_dis[h, j] - cop_dis[h, j-1]
    } else if (h != 1 && j == 1) {
      cop_den[h, j] <- cop_dis[h, j] - cop_dis[h-1, j]
    } else {
      cop_den[h, j] <- cop_dis[h, j] - cop_dis[h-1, j] - cop_dis[h, j-1] + cop_dis[h-1, j-1]
    }
  }
}         
"""

function cdf_to_pdf!(cop_den, cop_dis)
    for h in 1:length(cop_dis[:,1])
        for j in 1:length(cop_dis[1,:])
            if h == 1 && j == 1
                cop_den[h, j] = cop_dis[h, j]
            elseif h == 1 && j != 1
                cop_den[h, j] = cop_dis[h, j] - cop_dis[h, j-1]
            elseif h != 1 && j == 1
                cop_den[h, j] = cop_dis[h, j] - cop_dis[h-1, j]
            else
                cop_den[h, j] = cop_dis[h, j] - cop_dis[h-1, j] - cop_dis[h, j-1] + cop_dis[h-1, j-1]
            end
        end
    end
end

@rget cop_dis
@rget cop_den

# scale cop_dis so the top is 1
cop_dis = cop_dis ./ maximum(cop_dis)


# cop_dis evaluated at chebyshev nodes, interpolation for those nodes
f_approx = chebyshev_interp(cop_dis, A_plan) 

f_weights = chebyshev_weights(cop_dis, A_plan)

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
    yy = f_approx.(X)
    cop_den = zeros(size(yy))
    cdf_to_pdf!(cop_den, yy)
    println(sum(cop_den .< 0))
    # min-max scale the approximation
    cop_den = (cop_den .- minimum(cop_den)) ./ (maximum(cop_den) .- minimum(cop_den))
    println(sum(cop_den .< 0))
    # normalize s.t. sums to 1 
    cop_den[cop_den .< 0] .= 0
    cop_den = cop_den ./ sum(cop_den)
    if gl == 10 println(cop_den) end

    println(sum(cop_den))
    # Plot the approximation
    Plots.surface(x, y, cop_den, label="Chebyshev Approximation", xlabel="Income Rank", ylabel="Wealth Rank", title="Copula Density Approximation",                camera = (30,10), 
    # Plots.surface(x, x, y, label="Chebyshev Approximation", xlabel="Income Rank", ylabel="Wealth Rank", title="Copula Density Approximation",                camera = (30,10), 
    size=(400,400),
    color=:winter, 
    display_option=Plots.GR.OPTION_SHADED_MESH)
    Plots.savefig("NonParametricAnalysis/beta_estimator_chebyshev_approx$gl.pdf")
end
a = [0.2939443855267666 0.40445807317552973 0.24748235263271368 0.12902737012209023 0.0892814928236359 0.07597589785078729 0.05321630700072184 0.03492560272850365 0.053364822316768624 0.07711985134027917; 0.22213178271553716 0.398325896013583 0.3312271479744907 0.20235892600667557 0.13951241771557454 0.12260880651396089 0.0972679751445857 0.05515529222338121 0.014259807640697095 0.00631620160716808; 0.21251095276286078 0.27700466647237176 0.29238149893433985 0.2343083946594319 0.18573919180195367 0.15908831667282639 0.1200468424363938 0.06360880151392904 0.033195977410981674 0.021980575204164136; 0.23036886916419616 0.20408377749090487 0.234241148406321 0.22411224047442355 0.20019844160064054 0.1822512884579872 0.15308816808385897 0.09585431586653637 0.03820714204669635 0.016884278870076132; 0.20880638871427698 0.1380307793354284 0.17798945788819462 0.21752137319961043 0.21831274539877607 0.20668823175573553 0.19507252613143203 0.15091605659522386 0.05427546171008417 0.00715872730261682; 0.1694845056131056 0.061382437862354304 0.13182969089675556 0.22983999234535385 0.24890137382049157 0.23197458750267735 0.21928952753111053 0.17699123985459406 0.08651690928730739 0.01941276353698055; 0.12681034406512792 0.019293349889817252 0.08594779830310113 0.20362846616752897 0.2518154553277843 0.24904310331077156 0.25346144292939476 0.24242429398369197 0.12873327000279186 0.011484113897835465; 0.06569762863703814 0.03361611402658271 0.03470383564426568 0.09876719630052454 0.17999284434394847 0.2244679523310201 0.29153880485768724 0.3851672464487084 0.2539172463981227 0.007586324473262132; 0.01809821341182846 0.030119829350109786 0.012156373026380353 0.010466727988753729 0.05278809318811637 0.10751470120534846 0.1806365271265 0.3374852106554147 0.5373449640585347 0.28493231065533137; 0.018582744853305532 0.0005324166577561086 0.02020754083231695 0.016740724067510076 0.0 0.009951626264051683 0.005828855611884753 0.023338643484096 0.36970620778121693 1.0]
a = a ./ sum(a)

# Histogram estimator: different because it is not a copula, masses are conditional expectations 
@unpack df_vec = obs_data
df = df_vec[1][5]
df = df[df[:, :year] .== 2016, :]
non_missing               = filter("income" => !isnan, select(df, ["income", "wealth", "liquid", "weight", "id"]))
non_missing               = coalesce.(non_missing, NaN)
filter!("weight" => !isnan, non_missing)
grid                      = 10
interval                  = 1 / grid
# grid_points               = collect(interval:interval:1) 
grid_points               = p1.points
assign_quantile_groups!(non_missing, "income", grid, grid_points)
assign_quantile_groups!(non_missing, "wealth", grid, grid_points)
assign_quantile_groups!(non_missing, "liquid", grid, grid_points)

# Copula histogram at chebynodes 
cop_hist = Array(prop(freqtable(non_missing, tuple(["income_quantile", "wealth_quantile"]...)..., weights=non_missing.weight)))

# Plot copula 
Plots.surface(p1.points, p1.points, cop_hist, label="Copula Histogram", xlabel="Income Rank", ylabel="Wealth Rank", title="Copula Density Estimation", camera = (30,10), size=(400,400), color=:winter, display_option=Plots.GR.OPTION_SHADED_MESH)
Plots.savefig("NonParametricAnalysis/cop_hist.pdf")

# Approximate this with chebynodes 
f_approx_hist = chebyshev_interp(cop_hist, A_plan)

for gl in [100, 20, 10, 5]
  x = collect(1/gl:1/gl:1)
  y = collect(1/gl:1/gl:1)
  x[end] = .995
  y[end] = .995

  X = [ [x[i], y[j]] for i in 1:length(x), j in 1:length(y) ]
  yy = f_approx_hist.(X)

  # # normalize s.t. sums to 1 
  # cop_den[cop_den .< 0] .= 0
  # cop_den = cop_den ./ sum(cop_den)

  println(sum(cop_den))
  # Plot the approximation
  Plots.surface(x, y, yy, label="Chebyshev Approximation", xlabel="Income Rank", ylabel="Wealth Rank", title="Copula Density Approximation",                camera = (30,10), 
  size=(400,400),
  color=:winter, 
  display_option=Plots.GR.OPTION_SHADED_MESH)
  Plots.savefig("NonParametricAnalysis/hist_estimator_chebyshev_approx$gl.pdf")
end



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

# Initialize the PDF matrix with zeros
cdf_matrix = rand(10, 10, 10)
cdf_matrix .= cumsum(cumsum(cumsum(cdf_matrix, dims=1), dims=2), dims=3) # Make sure it's cumulative
cdf_matrix .= cdf_matrix ./ maximum(cdf_matrix)



a = zeros(size(cop_dis))
@time cdf_to_pdf2(cop_dis)

function compute_diffs(data, dim)
  # Shift the array along the dimension and compute the difference
  return cat(zeros(size(data)[1:dim-1]..., 1, size(data)[dim+1:end]...), data, dims=dim) - 
         cat(data, zeros(size(data)[1:dim-1]..., 1, size(data)[dim+1:end]...), dims=dim)[1:end-1, :, :]
end

# Convert an n-dimensional CDF to a PDF
function cdf_to_pdf_nd(cdf_matrix)
  # Initialize PDF as the CDF to start difference calculation
  pdf_matrix = copy(cdf_matrix)

  # Compute differences along each dimension recursively
  for dim in 1:ndims(cdf_matrix)
      pdf_matrix = compute_diffs(pdf_matrix, dim)
  end

  return pdf_matrix
end

# Example: Create a random 3D CDF matrix
cdf_matrix = rand(5, 5)
cdf_matrix .= cumsum(cumsum(cdf_matrix, dims=1), dims=2) # Make sure it's cumulative
cdf_matrix .= cdf_matrix ./ maximum(cdf_matrix)

# Calculate the PDF matrix
pdf_matrix = cdf_to_pdf_nd(cdf_matrix)



for m in ["income", "wealth"]
  df[:, m * "_rank"] = competerank(df[:, m]) ./ (length(df[:, m]) + 1)
end

# X_r  = Matrix(select!(non_missing, ["income_quantile", "wealth_quantile"])) ./ (length(non_missing[:, "income_quantile"]) + 1)
X_r    = Matrix(select!(df, ["income_rank", "wealth_rank"]))
mesh_grid = generate_mesh(xx, 2)



# Using ks package in R
R"""
# Copula density estimator -> only allows for sqrt() grid and linear grid ...  
kde_cop <- ks::kcopula.de(x = $X_r, gridsize = c(11,11), xmin = c(0, 0),
                      xmax = c(1,1), binned=FALSE, boundary.kernel="beta") # gridsize = c(11,11), w=subset_data$weight

# KDE -> allows for arbitrary grid (Page 14)
kde <- ks::kde(x = $X_r, eval.points = $mesh_grid, density =TRUE, xmin = c(0, 0),
                      xmax = c(1,1)) # gridsize = c(11,11)

# KDE with boundary correction (Page 76)
kde_bound <- ks::kde.boundary(x = $X_r, gridsize=c(11, 11), xmin = c(0, 0),
                      xmax = c(1,1), boundary.kernel="beta") # gridsize = c(11,11)

# KDE transformation estimator (Page 73)
kde_transf <- ks::kde(x=$X_r, eval.points = $mesh_grid, adj.positive=c(0,0), positive=TRUE, xmin = c(0, 0), xmax = c(1,1))
"""

@rget kde
@rget kde_cop
@rget kde_bound
@rget kde_transf

# These figures just show how interpolation would look like 
# Plot surface generated by kde_cop 
mat_g = kde_cop[:eval_points][1][2:end-1]
mat_dens = kde_cop[:estimate][2:end-1, 2:end-1] ./ sum(kde_cop[:estimate][2:end-1, 2:end-1])
Plots.surface(mat_g, mat_g, mat_dens, label="KDE Copula", xlabel="Income Rank", ylabel="Wealth Rank", title="Copula Density Estimation", camera = (30,10), size=(400,400), color=:winter, display_option=Plots.GR.OPTION_SHADED_MESH)
Plots.savefig("NonParametricAnalysis/kde_cop_evenly_spaced9.pdf")

# Plot surface generated by kde_bound
mat_g = kde_bound[:eval_points][1][2:end-1]
mat_dens = kde_bound[:estimate][2:end-1, 2:end-1] ./ sum(kde_bound[:estimate][2:end-1, 2:end-1])
Plots.surface(mat_g, mat_g, mat_dens, label="KDE Copula", xlabel="Income Rank", ylabel="Wealth Rank", title="Copula Density Estimation", camera = (30,10), size=(400,400), color=:winter, display_option=Plots.GR.OPTION_SHADED_MESH)
Plots.savefig("NonParametricAnalysis/kde_bound_evenly_spaced9.pdf")


# Interpolation for 'kde'
mat_dens     = reshape(kde[:estimate], (lg,lg))
f_approx_kde = chebyshev_interp(mat_dens ./ sum(mat_dens), A_plan)

# Generate matrix of points to evaluate the approximation
for gl in [100, 20, 10]
  x = collect(1/gl:1/gl:1)
  y = collect(1/gl:1/gl:1)
  X = [ [x[i], y[j]] for i in 1:length(x), j in 1:length(y) ]
  cop_den = f_approx_kde.(X)

  println(sum(cop_den .< 0))
  # min-max scale the approximation
  cop_den = (cop_den .- minimum(cop_den)) ./ (maximum(cop_den) .- minimum(cop_den))

  # normalize s.t. sums to 1 
  cop_den = cop_den ./ sum(cop_den)

  # cop_den[cop_den .< 0] .= 0
  println(sum(cop_den))
  # Plot the approximation
  Plots.surface(x, y, cop_den, label="Chebyshev Approximation", xlabel="Income Rank", ylabel="Wealth Rank", title="Copula Density Approximation",                camera = (30,10), 
  # Plots.surface(x, x, y, label="Chebyshev Approximation", xlabel="Income Rank", ylabel="Wealth Rank", title="Copula Density Approximation",                camera = (30,10), 
  size=(400,400),
  color=:winter, 
  display_option=Plots.GR.OPTION_SHADED_MESH)
  Plots.savefig("NonParametricAnalysis/kde_chebyshev_approx$gl.pdf")
end

mat_dens     = reshape(kde_transf[:estimate], (lg,lg))
f_approx_transf = chebyshev_interp(mat_dens ./ sum(mat_dens), A_plan)

# Generate matrix of points to evaluate the approximation
for gl in [100, 20, 10]
  x = collect(1/gl:1/gl:1)
  y = collect(1/gl:1/gl:1)
  X = [ [x[i], y[j]] for i in 1:length(x), j in 1:length(y) ]
  cop_den = f_approx_transf.(X)

  # println(sum(cop_den .< 0))
  # # min-max scale the approximation
  # cop_den = (cop_den .- minimum(cop_den)) ./ (maximum(cop_den) .- minimum(cop_den))

  # # normalize s.t. sums to 1 
  cop_den = cop_den ./ sum(cop_den)

  # cop_den[cop_den .< 0] .= 0
  println(sum(cop_den))
  # Plot the approximation
  Plots.surface(x, y, cop_den, label="Chebyshev Approximation", xlabel="Income Rank", ylabel="Wealth Rank", title="Copula Density Approximation",                camera = (30,10), 
  # Plots.surface(x, x, y, label="Chebyshev Approximation", xlabel="Income Rank", ylabel="Wealth Rank", title="Copula Density Approximation",                camera = (30,10), 
  size=(400,400),
  color=:winter, 
  display_option=Plots.GR.OPTION_SHADED_MESH)
  Plots.savefig("NonParametricAnalysis/kdetransf_chebyshev_approx$gl.pdf")
end


### IN PROGRESS 
# Now the histogram 
cheby_histogram = Array(prop(freqtable(non_missing, tuple(["income_quantile", "wealth_quantile"]...)..., weights=non_missing.weight)))

# Interpolate 
f_approx_hist = chebyshev_interp(cheby_histogram, A_plan)

# Plot
for gl in [100, 20, 10]
  x = collect(1/gl:1/gl:1)
  y = collect(1/gl:1/gl:1)
  X = [ [x[i], y[j]] for i in 1:length(x), j in 1:length(y) ]
  cop_den = f_approx_hist.(X)

  println(sum(cop_den .< 0))
  # min-max scale the approximation
  cop_den = (cop_den .- minimum(cop_den)) ./ (maximum(cop_den) .- minimum(cop_den))

  # normalize s.t. sums to 1 
  cop_den = cop_den ./ sum(cop_den)

  # cop_den[cop_den .< 0] .= 0
  println(sum(cop_den))
  # Plot the approximation
  Plots.surface(x, y, cop_den, label="Chebyshev Approximation", xlabel="Income Rank", ylabel="Wealth Rank", title="Copula Density Approximation",                camera = (30,10), 
  # Plots.surface(x, x, y, label="Chebyshev Approximation", xlabel="Income Rank", ylabel="Wealth Rank", title="Copula Density Approximation",                camera = (30,10), 
  size=(400,400),
  color=:winter, 
  display_option=Plots.GR.OPTION_SHADED_MESH)
  Plots.savefig("NonParametricAnalysis/histogram_approx$gl.pdf")
end

## Doing stuff from scratch 
# Define Chebyshev nodes
n = 10
chebyshev_nodes_01 = sort([0.5 * (1 + cos((2*i - 1) * pi / (2*n))) for i in 1:n])

# Generate a sample matrix - Example using a Gaussian copula-like function
matrixA = copy(cheby_histogram)


# Define Chebyshev polynomials
function chebyshevT(k, x)
    if k == 0
        return 1
    elseif k == 1
        return x
    else
        return 2 * x * chebyshevT(k-1, x) - chebyshevT(k-2, x)
    end
end

# Calculate coefficients for each row in the matrix using the Clenshaw-Curtis method
function chebyshev_coefficients(matrix_row)
    coeffs = zeros(n)
    for k in 0:n-1
      coeffs[k+1] = sum(matrix_row[j] * chebyshevT(k, chebyshev_nodes_01[j]) for j in 1:n) * (2 - (k == 0)) / n
    end
    return coeffs
end

function normalize_node(x, domain)
  a, b = domain
  return 2 * (x - a) / (b - a) - 1
end

function chebyshev_weights(f, nodes, order, domain)
  N = length(order)
  T = typeof(f[1])
  poly = [chebyshev_polynomial(order[i], normalize_node.(nodes[i], Ref(domain[:, i]))) for i in 1:N]
  weights = Array{T,N}(undef, Tuple(order .+ 1))

  for i in CartesianIndices(weights)
      numerator = zero(T)
      denominator = zero(T)

      for s in CartesianIndices(f)
          product = one(T)
          for j in 1:N
              product *= poly[j][s[j], i[j]]
          end

          numerator += f[s] * product
          denominator += product^2
      end

      weights[i] = denominator != 0 ? numerator / denominator : zero(T)
  end

  return weights
end

# Calculate coefficients for the entire matrix
# coefficients_matrix = reshape(vcat([chebyshev_coefficients(matrixA[i,:]) for i in 1:n]...), n, n)
coefficients_matrix = chebyshev_weights(matrixA, (chebyshev_nodes_01,chebyshev_nodes_01), rand(6:6, 2), [zeros(2) ones(2)]')


# Define an interpolation function
function my_chebyshev_evaluate(weights, x, order, domain)
  N = length(order)
  poly = Array{Array}(undef, N)
  @inbounds for i = 1:N
    poly[i] = chebyshev_polynomial(order[i], normalize_node(x[i], domain[:, i]))
  end

  yhat = zero(1)
  @inbounds for i in CartesianIndices(weights)
    if sum(Tuple(i)) <= order[i] + N
      poly_product = poly[1][i[1]]
      @inbounds for j = 2:N
        poly_product *= poly[j][i[j]]
      end
      yhat += weights[i] * poly_product
    end
  end

  return yhat

end

function interp2(x)

  yhat = my_chebyshev_evaluate(coefficients_matrix, x, rand(6:6, 2), [zeros(2) ones(2)]')

  return yhat

end

# Example evaluation
my_chebyshev_evaluate(coefficients_matrix, [0.5, 0.5], rand(6:6, 2), [zeros(2) ones(2)]')

# gl = 10
# sum(YY)
# Generate a meshgrid
for gl in [100, 20, 10]
  x = collect(1/gl:1/gl:1)
  XX = [ [x[i], x[j]] for i in 1:length(x), j in 1:length(x) ]
  YY = [interp2(XX[i,j]) for i in 1:length(x), j in 1:length(x)]

  # Plot the approximation
  Plots.surface(x, x, YY, label="Chebyshev Approximation", xlabel="Income Rank", ylabel="Wealth Rank", title="Copula Density Approximation",                camera = (30,10),
  size=(400,400),
  color=:winter,
  display_option=Plots.GR.OPTION_SHADED_MESH)
  Plots.savefig("NonParametricAnalysis/histogram_approx_scratch$gl.pdf")
end
