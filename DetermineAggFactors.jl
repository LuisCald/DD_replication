include("DistributionalDynamics.jl")

# Import via excel the FRED-QD file
fred_qd   = DataFrame(XLSX.readtable(raw"/Users/lc/Dropbox/Distributional_Dynamics/2_Data_processing/FRED_QD.xlsx", "FRED_QD", header=true,))

for c in names(fred_qd)
    if any(ismissing, fred_qd[!, c])
        select!(fred_qd, Not(c))
    end
end

# Write a loop that creates exports to csv one dataframe for each type of transformation
for j in 1:7
    a = fred_qd[2:end, [i for i in 1:size(fred_qd, 2) if fred_qd[1, i] == j]]
    # Append date column to it
    a = [fred_qd[2:end, :sasdate] a]
    DataFrames.rename!(a, :x1 => :daten)

    CSV.write("fred_qd_" * string(j) * ".csv", a)
end

# Import the data
fred_qd_stationary = CSV.read("/Users/lc/Dropbox/Distributional_Dynamics/2_Data_processing/master_dataset.csv", DataFrame)

# Make first column a date column
fred_qd_stationary[!, :daten] = QuarterlyDate(parse(Int, fred_qd_stationary[1, :daten][1:4]), parse(Int,fred_qd_stationary[1, :daten][end])) : Quarter(1) : QuarterlyDate(parse(Int, fred_qd_stationary[end, :daten][1:4]), parse(Int, fred_qd_stationary[end, :daten][end]))

# Export to csv
CSV.write("/Users/lc/Dropbox/Distributional_Dynamics/2_Data_processing/stationary_aggregates.csv", fred_qd_stationary)

X = Matrix(fred_qd_stationary[:, 2:end])
X = [X[5:end, :] X[4:end-1, :] X[3:end-2, :] X[2:end-3, :] X[1:end-4, :]]

# # Remove columns 182, 198
# X = X[:, [i for i in 1:size(X, 2) if i != 182 && i != 198 && i != 120 && i != 116]]

# Standardize the data
X = (X .- mean(X, dims=1)) ./ std(X, dims=1)

ssaxis = 1:size(X, 1)
Plots.plot(1:size(X, 1), X, xformatter=:latex, yformatter=:latex, label="", xticks=(ssaxis[1:20:end], [L"%$(date)"[1:5] * "\$" for (_,date) in enumerate(fred_qd_stationary[1:20:end, :daten])]))
Plots.savefig("/Users/lc/Dropbox/Distributional_Dynamics/7_Results/factor_analysis/fred_qd_stationary.pdf")


n_factors(X, 30; include_plot=1, τ=0.5)

function n_factors(X, r_max; include_plot::Int=0, τ::Float64=0.5)
    # Estimates the number of relevant factors for dataset X following Freyaldenhoven (2021)
    #
    # INPUT
    # X: (Txn) matrix of data
    # r_max: upper bound on number of factors
    # include_plot(optional): If set to 1 includes illustrative figures)
    # τ(optional): default is 0.5
    #
    # OUTPUT
    # FR: Estimate for the number of factors
    
    T, n = size(X)
    z = round(Int, min(0.7 * n^τ * sqrt(log(log(n))), n))
    
    # SVD decomposition
    _, d, V = svd(X ./ sqrt(T))

    # Factor Loadings i.e., Projection matrix
    Lambda  = V[:, 1:r_max] * Diagonal(d[1:r_max])

    # Sorting
    sorted = sort(abs.(Lambda), dims=1, rev=true)
    largest_z = sorted[1:z, :]

    error_part = d[r_max+1:end]
    estimate_variance = sum(error_part.^2) / n

    Shat = zeros(r_max)
    T2 = zeros(r_max)

    for k in 1:r_max
        Shat[k] = ((largest_z[:, k]' * largest_z[:, k] / z) / sqrt(Lambda[:, k]' * Lambda[:, k] / n))
        T2[k] = (Lambda[:, k]' * Lambda[:, k]) * Shat[k]^2
    end

    incl_mock_T2 = [estimate_variance * n; T2]
    T2_ratio = incl_mock_T2[1:r_max] ./ T2[1:r_max]
    FR = findall(x -> x == maximum(T2_ratio), T2_ratio)[1]
    FR -= 1

    if include_plot == 1
        eig_X = d[1:min(n, T)].^2

        plot1 = Plots.scatter(0:r_max, [1; Shat.^2], ylab=L"\textrm{Value}", ms=5, markerstrokewidth=3, mc=:orange, guidefontsize=12, tickfontsize=12, legendefontsize=12, xformatter=:latex, yformatter=:latex, xlabel=L"k", label=L"\hat{S}^2", legend=:topright)
        Plots.savefig("/Users/lc/Dropbox/Distributional_Dynamics/7_Results/factor_analysis/factor_analysis_plot1.pdf")

        plot2 = Plots.plot(0:r_max, [estimate_variance * n; eig_X[1:r_max]], lw=2, guidefontsize=12, tickfontsize=12, legendefontsize=12, xformatter=:latex, yformatter=:latex, xlabel=L"k", ylabel=L"\textrm{Value}", label=[L"\hat{\Upsilon}^0_k" L"\hat{\Upsilon}^2_k"], legend=:topright)
        Plots.scatter!([0],[0], label=" ", ms=0, mc=:white, msc=:white)
        Plots.plot!(0:r_max, incl_mock_T2, seriestype=:line, lw=2, label=L"\hat{\Upsilon}^2_k")

        Plots.savefig("/Users/lc/Dropbox/Distributional_Dynamics/7_Results/factor_analysis/factor_analysis_plot2.pdf")

        # Determine 'maxoutdim'
        MOdim = sum(incl_mock_T2[1:r_max] .> eig_X[1:r_max])
        println("Max dimension outputed:", MOdim)

        M     = MultivariateStats.fit(PCA, Matrix(X' ./ sqrt(T)); maxoutdim=MOdim, method=:svd, mean=0)

        # Plot the factors 
        pcs   = MultivariateStats.transform(M, Matrix(X'./ sqrt(T)))
        saxis = 1:size(pcs, 2)

        ls_vec = [:solid, :solid, :solid, :dash, :dot, :dashdot, :solid, :solid, :solid, :solid, :solid, :solid, :solid, :solid, :solid, :solid]
        lc_vec = [:black, :red, :blue, :green, :orange, :purple, :brown, :pink, :cyan, :magenta, :yellow, :gray]
        lo_vec = [1.0, .9, .8, .6, .4, .2, [.2 for _ in 1:size(pcs, 2)-6]...]
        Plots.plot()
        for i in axes(pcs, 1)
            Plots.plot!(saxis, pcs[i, :], xformatter=:latex, yformatter=:latex,legend_columns=3, label=L"\textrm{Factor \,\, %$(i)}", linealpha=lo_vec[i], ls = ls_vec[i], lc = lc_vec[i], ylab=L"\textrm{Factor\,\, Value}", xticks=(saxis[1:20:end], [L"%$(date)"[1:5] * "\$" for (_,date) in enumerate(fred_qd_stationary[1:20:end, :daten])]))
        end
        Plots.savefig("/Users/lc/Dropbox/Distributional_Dynamics/7_Results/factor_analysis/agg_factors.pdf")
    end

    return FR
end
