function bvar_fn(data, n_lags, constant, n_draws, zero_restriction, first_row_restriction; aggregates=false, n_agg_lags=0)

    # Cleaning bvar_data
    # --- clean data as before ---
    bvar_data = typeof(data) <: DataFrame ? Matrix(select(deepcopy(data), Not(:time))) : deepcopy(data)
    cond = all(!ismissing, bvar_data, dims=2)[:]
    bvar_data = bvar_data[cond, :]

    # --- dimensions ---
    n_var = size(bvar_data, 2)                   # # endogenous
    endogenous_idx = (1+zero_restriction):n_var
    n_var_x = length(endogenous_idx)
    nₐ = aggregates != false ? size(aggregates, 2) : 0

    # --- construct Y and design matrix X ---
    start_y = maximum([n_lags, n_agg_lags])[1] + 1
    yt = bvar_data[start_y:end, :]
    T = size(yt, 1)

    # 0) compute total lags
    total_agg_lags = n_agg_lags + 1

    # 1) adjust m
    m = n_var_x * n_lags + nₐ * total_agg_lags + constant
    xt = zeros(T, m)

    # 2) endogenous lags — unchanged
    # 2) endogenous lags (fixed)
    for i in 1:n_lags
        col_start = (i - 1) * n_var_x + 1
        col_end = i * n_var_x

        # rows start at start_y - i, end at (start_y - i + T - 1)
        row_start = start_y - i
        rows = row_start:(row_start+T-1)

        @assert length(rows) == T
        xt[:, col_start:col_end] .= bvar_data[rows, endogenous_idx]
    end

    # 3) aggregate lags from ℓ=0 (contemporaneous) to ℓ=n_agg_lags
    agg_start = n_var_x * n_lags
    for ℓ in 0:n_agg_lags
        # rows in aggregates to align with xt[1:T, :]
        # xt[t, :] should see aggregates[n_lags + t - ℓ, :]
        row_start = start_y - ℓ
        rows = row_start:(row_start+T-1)

        # columns for this ℓ block:
        # each block is exactly nₐ wide:
        col_start = agg_start + ℓ * nₐ + 1
        col_end = agg_start + (ℓ + 1) * nₐ

        # assign all series at once
        xt[:, col_start:col_end] .= aggregates[rows, 1:nₐ]
    end

    # 4) constants/trends at the very end...
    base = n_var_x * n_lags + nₐ * total_agg_lags
    if constant >= 1
        xt[:, base+1] .= 1
    end
    if constant >= 2
        xt[:, base+2] .= 1:T
    end
    if constant >= 3
        xt[:, base+3] .= (1:T) .^ 2
    end
    # 4) finalize
    Y = yt
    X = xt

    #----------------------------------------------------------------
    # Prior for Reduced Form Parameters
    #----------------------------------------------------------------
    nnuBar = 0
    OomegaBarInverse = zeros(m, m)
    PpsiBar = zeros(m, n_var)
    PphiBar = zeros(n_var, n_var)

    #----------------------------------------------------------------
    # Posterior for Reduced-Form Parameters
    #----------------------------------------------------------------
    nnuTilde = T + nnuBar # degree of freedom
    OomegaTildeInverse = X' * X + OomegaBarInverse
    OomegaTilde = Hermitian(nearest_spd(OomegaTildeInverse)^-1 * I)

    PpsiTilde = OomegaTilde * (X' * Y + OomegaBarInverse * PpsiBar)
    if first_row_restriction
        PpsiTilde[1:(n_var_x*n_lags), 1] .= 0.0 # Adjust so that works for multiple shocks
    end
    A = PpsiBar' * OomegaBarInverse * PpsiBar
    B = PpsiTilde' * OomegaTildeInverse * PpsiTilde
    PphiTilde = Y' * Y + PphiBar + (A) - (B)
    PphiTilde = nearest_spd(PphiTilde) # (PphiTilde' + PphiTilde) * 0.5

    #----------------------------------------------------------------
    # Draw from Posterior
    #----------------------------------------------------------------

    # definitions used to store orthogonal-reduced-form draws, volume elements, and unnormalized weights
    B_draws = zeros(m, n_var, n_draws) # reduced-form lag parameters
    Sigma_draws = zeros(n_var, n_var, n_draws) # reduced-form covariance matrices
    fill!(B_draws, NaN)
    fill!(Sigma_draws, NaN)

    # Set posterior mode as the first draw
    B_draws[:, :, 1] = PpsiTilde
    Sigma_draws[:, :, 1] = PphiTilde / T

    # definition to facilitate the draws from B|Sigma
    cholOomegaTilde = cholesky(OomegaTilde).U' # this matrix is used to draw B|Sigma below, Wolf code: chol() does return upper triangular

    # draws from posterior
    for i_draw in 2:n_draws
        Sigmadraw = rand(InverseWishart(nnuTilde, PphiTilde))
        cholSigmadraw = cholesky(Sigmadraw).U'
        Bdraw = kron(cholSigmadraw, cholOomegaTilde) * randn(m * n_var, 1) + reshape(PpsiTilde, (n_var * m, 1))
        Bdraw = reshape(Bdraw, (m, n_var))

        if first_row_restriction
            Bdraw[1:(n_var_x*n_lags), 1] .= 0.0 # Adjust so that works for multiple shocks
        end

        # store reduced-form draws
        B_draws[:, :, i_draw] = Bdraw


        Sigma_draws[:, :, i_draw] = Sigmadraw
    end

    #----------------------------------------------------------------
    # Collect Results
    #----------------------------------------------------------------

    B_OLS = PpsiTilde
    Sigma_OLS = PphiTilde / T

    # Perform quickly weak instrument test 
    U = Y - X * B_OLS

    # log-ml
    logml = log_ml_glp(Y, X,
        nnuBar, PphiBar,
        nnuTilde, PphiTilde,
        OomegaTilde,
        n_lags)

    println("log marginal: ", logml)

    return B_draws, Sigma_draws, B_OLS, Sigma_OLS, Y, X
end

function nearest_spd(A::AbstractMatrix)
    """It finds the nearest symmetric positive definite matrix to A.
    This allows for the invertibility in the kalman-filter likelihood calculation.
        https://scicomp.stackexchange.com/questions/30631/how-to-find-the-nearest-a-near-positive-definite-from-a-given-matrix
    """
    identity = Matrix(I, size(A, 1), size(A, 1))
    shift = eps() * identity

    # First, adding a small constant 
    if isposdef(A + shift)
        return A + shift
    end
    # if isposdef_approx(A + shift) > 0.5 return A + shift end

    # Nearest spd without LAPACK and ForwardDiff friendly
    B = (A + A') / 2

    # initialize algo 
    _, FS, FVt = LinearAlgebra.LAPACK.gesvd!('N', 'S', copy(B))  # TODO: change this, check out discourse 

    # iterate 
    # FVt_transpose = Diagonal(ones(size(B, 1))) 
    # C, FVt_transpose = run_qr_algorithm!(copy(B), FVt_transpose)
    # dg     = Diagonal(C)
    # H = FVt_transpose * dg * FVt_transpose' 


    # dg[dg .< 0] .= 0 
    # H = FVt' * dg * FVt + .01I

    # Diagonal 
    dg = Diagonal(FS)

    # Construct spd 
    dg[dg.<0] .= 1e-10
    eig_min = minimum(diag(dg)) # minimum(abs.(dg)[abs.(dg) .> 0])
    H = FVt' * dg * FVt
    G = @. 0.5 * (H + H') + shift

    if isposdef(G)
        return G
    else
        # test that H is in fact PD. if it is not so, then tweak it just a bit.
        p = false
        count = 1
        # small_ϵ(k) = (-eig_min .* k .* k .+ eps(eig_min))
        small_ϵ = eps() .* identity
        ii = 0
        while p == false && count < 1000
            G .+= small_ϵ
            p = isposdef(G)
            ii += 1
            count += 1
        end
    end

    return G
end

inverse_hyperbolic_sine(x) = log.(x .+ sqrt.(x .^ 2 .+ 1))

function collect_dist_data(measures_dict; start_year=1980, end_year=2018, start_q=1, end_q=4)
    # Filter rows where Group == "Total"
    tot = Dict()
    tot["Income"] = measures_dict["Income"][measures_dict["Income"].Group.=="Total", :]
    tot["Wealth"] = measures_dict["Wealth"][measures_dict["Wealth"].Group.=="Total", :]

    for (name, df) in measures_dict
        measures_dict[name] = df[df.Group.!="Total", :]
    end


    # Create a dictionary for each dataset, defined across the different categories in "Group"
    for (m_key, df) in measures_dict
        m_dict = Dict{String,DataFrame}()
        for group in unique(df.Group)
            m_dict[group] = df[df.Group.==group, :]

            # Generate "time" column as a QuarterlyDate
            m_dict[group][!, :time] = QuarterlyDate.(m_dict[group][!, :Year], m_dict[group][!, :Quarter])

            # Drop the "Year" and "Quarter" column
            select!(m_dict[group], Not([:Year, :Quarter]))

            # Rename "Real Total Pretax $m_key" to "$Group Real Total Pretax $m_key"
            q_col = m_key == "Income" ? "Real Pretax $m_key Per Unit" : "Real $m_key Per Unit"
            s_col = m_key == "Income" ? "Real Pretax $m_key Share" : "Real $m_key Share"

            rename!(m_dict[group], q_col => "$group $m_key")
            rename!(m_dict[group], s_col => "$group $m_key Share")

            # Drop columns that are not needed
            select!(m_dict[group], ["time", "$group $m_key", "$group $m_key Share"])

            # Scale the variable by its aggregate value
            m_dict[group][!, "$group $m_key"] ./= tot[m_key][!, q_col]

            # Take the inverse hyperbolic sine of the income or wealth column
            m_dict[group][!, "$group $m_key"] = inverse_hyperbolic_sine(m_dict[group][!, "$group $m_key"])

            # Remove trend using Hodrick-Prescott filter
            tr = HP(m_dict[group][!, "$group $m_key"], 1600)
            m_dict[group][!, "$group $m_key"] = m_dict[group][!, "$group $m_key"] .- tr

            # Remove linear trend from shares
            tr = HP(m_dict[group][!, "$group $m_key Share"], 10000000)
            m_dict[group][!, "$group $m_key Share"] = m_dict[group][!, "$group $m_key Share"] .- tr

            # Filter by time period
            m_dict[group] = m_dict[group][m_dict[group].time.>=QuarterlyDate(start_year, start_q).&&m_dict[group].time.<=QuarterlyDate(end_year, end_q), :]
        end

        # Merge all dataframes in the dictionary into a single dataframe
        random_group = "Top 1%"
        m_df = m_dict[random_group] # Start with the first group
        other_groups = filter(x -> x != random_group, keys(m_dict))
        for group in other_groups
            m_df = leftjoin(m_df, m_dict[group], on=:time, makeunique=true)
        end
        measures_dict[m_key] = m_df
    end


    combined_df = leftjoin(measures_dict["Income"], measures_dict["Wealth"], on=:time, makeunique=true)
    combined_mat = Matrix(select(combined_df, Not(:time)))

    # Remove the mean and standardize the data
    combined_mat = (combined_mat .- mean(combined_mat, dims=1)) ./ std(combined_mat, dims=1)

    # Perform PCA on the combined data
    M = MultivariateStats.fit(PCA, Matrix(combined_mat'), pratio=0.95, method=:svd, mean=0)
    pcs = MultivariateStats.transform(M, combined_mat')

    # Make a final dataset with both income and wealth factors, and the time column
    factor_df = DataFrame(time=combined_df.time)
    for i in 1:size(pcs, 1)
        factor_df[!, "Factor $i"] = pcs[i, :]
    end

    return factor_df
end

function generate_aggs(aggregate_data; leads=4, lags=4, start_year=1980, end_year=2018, start_q=1, end_q=4)
    aggregate_data[!, :time] = QuarterlyDate.(aggregate_data[!, :time])
    aggregate_data[!, :Year] = year.(aggregate_data[!, :time])


    # Filter the aggregate data by time period
    agg_cond = aggregate_data[!, :time] .>= QuarterlyDate(start_year, start_q) .&&
               aggregate_data[!, :time] .<= QuarterlyDate(end_year, end_q)
    agg_df = aggregate_data[agg_cond, :]

    for i in leads:-1:1
        # find condition for the aggregate data
        agg_cond = aggregate_data[!, :time] .>= QuarterlyDate(start_year, start_q) .+ Quarter(i) .&&
                   aggregate_data[!, :time] .<= QuarterlyDate(end_year, end_q) .+ Quarter(i)
        agg_df = hcat(agg_df, aggregate_data[agg_cond, :], makeunique=true)
    end

    for i in 1:lags
        # find condition for the aggregate data
        agg_cond = aggregate_data[!, :time] .>= QuarterlyDate(start_year, start_q) .- Quarter(i) .&&
                   aggregate_data[!, :time] .<= QuarterlyDate(end_year, end_q) .- Quarter(i)
        agg_df = hcat(agg_df, aggregate_data[agg_cond, :], makeunique=true)
    end

    # Remove all columns that have "time" in it
    cols_to_keep = filter!(x -> !occursin("time", x), names(agg_df))
    cols_to_keep = filter!(x -> !occursin("Year", x), cols_to_keep)

    select!(agg_df, cols_to_keep)

    # Perform standardization
    agg_mat = Float64.(Matrix(agg_df))
    agg_mat .= (agg_mat .- mean(agg_mat, dims=1)) ./ std(agg_mat, dims=1)

    return agg_mat
end

function validate_role_of_aggs(agg_mat, factor_df, n_lags_policy, n_lags_aggs, draws; specific_aggs=false, type_of_aggs=:standard)
    agg_pca = Matrix(agg_mat')
    nᶠ_dict = n_factor_per_estimator(agg_mat)
    R2_dict = Dict()
    for (k, n_factor) in nᶠ_dict
        # Perform PCA on the aggregate data
        agg_M = MultivariateStats.fit(PCA, agg_pca, pratio=0.95, method=:svd, mean=0)

        # Get PCs
        agg_pcs = MultivariateStats.transform(agg_M, agg_pca)
        λ = sqrt.(principalvars(agg_M))
        agg_pcs = agg_pcs ./ λ  # Scale PCs by their eigenvalues

        agg_pcs = specific_aggs != false ? agg_pcs[:, specific_aggs] : agg_pcs

        # Perform VAR, to get R^2 of each equation
        factor_mat = typeof(factor_df) == Matrix{Float64} ? factor_df : Matrix(select(factor_df, Not(:time)))

        if type_of_aggs == :best
            K = size(factor_mat, 2)
            p = size(agg_pcs, 1)
            scores = zeros(p, K)            # will hold total_gain per target
            for i in 1:K
                bst = xgboost((DataFrame(agg_pcs', :auto), factor_mat[:, i][:]), num_round=600,
                    params=Dict("objective" => "reg:squarederror",
                        "max_depth" => 10, "eta" => 0.05))

                # Make the same table you showed
                imp = importance(bst, "total_gain")

                for j in 1:p
                    try
                        sc = imp["x$j"][1]
                        scores[j, i] = sc
                    catch
                        scores[j, i] = 0.0
                    end
                end
            end
            avg_gain = vec(mean(scores; dims=2))       # or sum/median/max
            rank = sortperm(avg_gain; rev=true)    # best → worst
            agg_pcs = agg_pcs[rank[1:n_factor], :]  # select the best n_factor PCs
            agg_ids = rank[1:n_factor]               # indices of the best PCs

        elseif type_of_aggs == :standard
            agg_pcs = agg_pcs[1:n_factor, :]
            agg_ids = 1:n_factor
        end

        B_draws, Sigma_draws, B_OLS, Sigma_OLS, Y, X = bvar_fn(factor_mat, n_lags_policy, 1, draws, false, false; aggregates=agg_pcs', n_agg_lags=n_lags_aggs)


        # Extract the R^2 from the VAR
        R2 = zeros(size(B_OLS, 2), draws)

        for d in 1:draws
            b_d = B_draws[:, :, d]
            for i in 1:size(B_OLS, 2)
                y = Y[:, i]
                ȳ = mean(y)
                b_i = b_d[:, i]
                R2[i, d] = 1 - sum((y .- X * b_i) .^ 2) / sum((y .- ȳ) .^ 2)
            end
        end
        # Get the average, standard deviation, and 95% confidence interval for R^2
        R2_mean = mean(R2, dims=2)
        R2_std = std(R2, dims=2)
        R2_dict[k] = (n_factor, R2_mean, R2_std, agg_ids)
    end

    return R2_dict
end


function clean_DFA(shares, quantiles, wealth_by_income)
    # Drop missing values
    shares = shares[completecases(shares), :]
    quantiles = quantiles[completecases(quantiles), :]
    wealth_by_income = wealth_by_income[completecases(wealth_by_income), :]

    # Change date column to QuarterlyDate
    shares[!, :time] = QuarterlyDate.(shares[!, :time])
    quantiles[!, :time] = QuarterlyDate.(quantiles[!, :time])
    wealth_by_income[!, :time] = QuarterlyDate.(wealth_by_income[!, :time])

    # Drop any col. that has "levels" or "hhs" in it
    wealth_by_income = select(wealth_by_income, Not(Regex("levels|hhs", "i")))

    # Add "shares" tp the col. names of shares
    for col in names(shares)
        if col != "time" && col != "year" && col != "quarter" && col != "dates"
            shares[!, col] = shares[!, col]
            rename!(shares, col => "shares_$col")
        end
    end
    # Add "quantiles" to the col. names of quantiles
    for col in names(quantiles)
        if col != "time" && col != "year" && col != "quarter" && col != "dates"
            quantiles[!, col] = quantiles[!, col]
            rename!(quantiles, col => "quantiles_$col")
        end
    end

    # Add "wi" to the column names
    for col in names(wealth_by_income)
        if col != "time" && col != "year" && col != "quarter" && col != "dates"
            wealth_by_income[!, col] = wealth_by_income[!, col]
            rename!(wealth_by_income, col => "wi_$col")
        end
    end

    # Merge them all together
    final_df = leftjoin(shares, quantiles, on=:time, makeunique=true)
    final_df = leftjoin(final_df, wealth_by_income, on=:time, makeunique=true)
    q_cond = occursin.("quantile", names(final_df))
    s_cond = occursin.("share", names(final_df))
    q_names = names(final_df)[q_cond]
    s_names = names(final_df)[s_cond]

    tot_wealth = wealth_by_income[!, "wi_tot_wealth"]

    select!(final_df, Not("wi_tot_wealth")) #  

    # Scale the variable by its aggregate value
    for col in names(final_df)

        if col == "time"
            continue
        end

        scale = col ∈ q_names ? tot_wealth : 100 # for shares: remove percent
        final_df[!, col] ./= scale

        # Take the inverse hyperbolic sine of the income or wealth column
        final_df[!, col] = col ∈ q_names ? inverse_hyperbolic_sine(final_df[!, col]) : final_df[!, col]

        # Remove trend using Hodrick-Prescott filter
        tr = col ∈ q_names ? HP(final_df[!, col], 1600) : HP(final_df[!, col], 10000000)
        final_df[!, col] = final_df[!, col] .- tr
    end

    # Standardize
    dfa_mat = Matrix(select(final_df, Not(:time)))
    dfa_mat = (dfa_mat .- mean(dfa_mat, dims=1)) ./ std(dfa_mat, dims=1)

    # Perform PCA
    M = MultivariateStats.fit(PCA, Matrix(dfa_mat'), pratio=0.95, method=:svd, mean=0)
    dfa_pcs = MultivariateStats.transform(M, Matrix(dfa_mat'))

    # Make a final dataset with both income and wealth factors, and the time column
    factor_df = DataFrame(time=final_df.time)
    for i in axes(dfa_pcs, 1)
        factor_df[!, "Factor $i"] = dfa_pcs[i, :]
    end

    return factor_df
end


function clean_data(year_vec, pool, dates)
    before2019 = findall(year_vec[1] .< 2019)
    pool1 = pool[:, before2019]
    keep_rows = .!all(isnan, pool1; dims=2)[:]
    pool_clean = pool1[keep_rows, :]

    # Drop columns with all NaN values
    keep_cols = .!any(isnan, pool_clean; dims=1)[:]
    pool_clean2 = pool_clean[:, keep_cols]

    # Do the same for dates
    dates_clean = dates[before2019]
    dates_clean = dates_clean[keep_cols]
    return pool_clean2, dates_clean
end