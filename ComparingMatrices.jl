# coparing matrices 
θ_cop         = get_param_vector(measures, kind_of_plots, label)
θ_cop_test = vec(Matrix(CSV.read("/Users/lc/Dropbox/Distributional_Dynamics/7_Results/income_and_wealth/from_optimization/parameter_vectors/solutiontest_2D_A non-diag.csv", DataFrame, header=0)))


n =param_sizes[1][1]
b =param_sizes[2][2]
A = reshape(θ_cop[1:n*n], (n,n))
A_test = reshape(θ_cop_test[1:n*n], (n,n))

B = reshape(θ_cop[n*n+1:n*n+n*b], (n,b))
B_test = reshape(θ_cop_test[n*n+1:n*n+n*b], (n,b))
mean(abs.(B))
mean(abs.(B_test))


Ω = Diagonal(θ_cop[n*n+n*b+1:n*n+n*b+n])
Ω_test = Diagonal(θ_cop_test[n*n+n*b+1:n*n+n*b+n])

Σ = Diagonal(θ_cop[end-param_sizes[4][1]+1:end])
Σ_test = Diagonal(θ_cop_test[end-param_sizes[4][1]+1:end])

