
function drop_empty_columns(y)
    # Find columns where all values are NaN
    non_empty_cols = [i for i in axes(y, 2) if !all(isnan, y[:, i])]
    
    # Return the matrix with only non-empty columns
    return y[:, non_empty_cols]
end

function sort_columns_by_observations(y)
    N, T = size(y)
    
    # Count the number of non-NaN values in each column
    obs_per_col = sum((!isnan).(y), dims=1)[:]
    
    # Sort the columns based on the number of non-NaN values (descending order)
    # First column remains in place, so we sort only columns 2 to T
    sorted_indices = sortperm(obs_per_col, rev=true)
    
    # Reorder the columns based on the sorted indices
    y_sorted = y[:, sorted_indices]
    
    return y_sorted
end


# Function to sort rows by observed values
function sort_rows_by_observations(y)
    # Count the number of non-NaN values in each row
   obs_per_row = sum((!isnan).(y), dims=2)[:]
    
    # Sort the rows based on the number of non-NaN values (descending order)
    sorted_indices = sortperm(obs_per_row, rev=true) 
    
    # Reorder the rows based on the sorted indices
    y_sorted_rows = y[sorted_indices, :]
    
    return y_sorted_rows, sorted_indices
end


function rearrange_data(y)
    y0 = drop_empty_columns(y)
    y1 = sort_columns_by_observations(y0)
    y2, sorted_indices = sort_rows_by_observations(y1)
    return y2, sorted_indices
end


# Function to overlay datasets one by one
function overlay_datasets(MV; type="tallest")
    # M is the 1002 x 240 matrix initialized with NaNs
    # datasets is a vector of matrices to overlay
    # time_indices is a vector of vectors specifying the time periods each dataset occupies
    N = size(MV[1], 1)
    T = size(MV[1], 2)

    M = fill(NaN, N, T)
    
    for i in eachindex(MV)
        dataset     = MV[i]
        obs_per_col = sum((!isnan).(dataset), dims=1)[:]
        
        # Time indices where the current dataset has observations
        time_idx    = findall(obs_per_col .> 0) 
        
        # Overlay the dataset without overwriting existing values
        for current_t in time_idx

            # Fill only where the current matrix has NaNs
            for n in axes(dataset, 1)
                if isnan(M[n, current_t]) && !isnan(dataset[n, current_t])
                    M[n, current_t] = dataset[n, current_t]
                end
            end
        end
    end
    
    M, sorted_indices = rearrange_data(M) # T by N
    M = transpose(M)


    if type == "second tallest"
        # rows_to_keep = []
        NaN_count_out    = []
        where_second_block_begins = []
        where_second_block_ends = []

        for j in axes(M, 1)
            NaN_count = sum(isnan.(M[j, :]))
            push!(NaN_count_out, NaN_count)

            # if length(unique(NaN_count_out)) == 2 && NaN_count_out[j-1] == 0
            #     push!(where_second_block_begins, j)
            # end

            if length(unique(NaN_count_out)) == 3
                push!(where_second_block_ends, j-1)
                break
            end
            # push!(rows_to_keep, j)
        end

        # Find new No
        println(where_second_block_begins)
        tot_NaN = sum(isnan.(M[where_second_block_ends[1], :]))
        new_No  = size(M, 2) - tot_NaN

        M = M[1:where_second_block_ends[1], :]         # (T x No)
        # tall_block     = X[1:where_second_block_ends[1], 1:new_No]         # (T x No)
        # wide_block     = X[To, :]         # (To x N)
        # return tall_block, wide_block
    end

    
    return M, sorted_indices
end


# Function to find the indices of Tₒ (fully observed time periods) and Nₒ (fully observed units for many time periods)
function find_Nₒ_Tₒ(X)
    T, N = size(X)

    obs_per_row = sum((!isnan).(X), dims=2)  # Count non-missing values in each row (time period)
    obs_per_col = sum((!isnan).(X), dims=1)  # Count non-missing values in each column (observation)
    
    # Find indices of time periods (T_o) where all observations are observed
    T_o = findall(x -> x == N, vec(obs_per_row))
    N_o = findall(x -> x == T, vec(obs_per_col))
    
    return T_o, N_o
end

function reorganize_matrix(X, No, To)
    # Assumes X is (T x N) matrix
    # Reorganize the data into "tall", "wide" and "balanced" blocks
    tall_block     = X[:, No]         # (T x No)
    wide_block     = X[To, :]         # (To x N)
    # balanced_block = X[To, No]  # (To x No)
    # missing_block  = X[To[end]+1:end, No[end]+1:end] # Missing data block
        
    return tall_block, wide_block
end


# Function to estimate factor loadings using the "tall-wide" algorithm
function run_TW_algorithm(MV, pr, block_type)
"Factor structure relies on both tall and wide part"
    # Step 0: Overlay the datasets
    X, sorted_indices = overlay_datasets(MV; type=block_type) # X = (T by N)
    
    # Step 1: Identify T_o and N_o
    T_o, N_o = find_Nₒ_Tₒ(X)
    tall_block, wide_block = reorganize_matrix(X, N_o, T_o)
    
    # Step 3: Estimate factors from the tall block using PCA
    Ftall, Λtall = perform_pca_missing(Matrix(tall_block'), .99) # Ftall is a r by T matrix
    
    # Step 4: Estimate loadings from the wide block using PCA
    Fwide, Λwide = perform_pca_missing(Matrix(wide_block'), .99)
    
    some_subset = size(Λtall, 1)

    # Step 5: Re-rotation using the balanced block
    # Regress Λtall on Λwide from the balanced block
    Hmiss = Λtall \ Λwide[1:some_subset, :] # Rotation matrix (Hmiss)
    
    # Step 6: Re-rotate loadings using Hmiss
    Λ_re_rotated = Hmiss * Λwide' # Λwide is N by r, Hmiss is r by r

    # Step 7: Impute missing values using the factor model
    # y_imputed = (Ftall * Λ_re_rotated)' # Imputed values
    y_imputed = (Ftall * Λ_re_rotated)' # N by T
    

    # Replace NaN's in the original matrix with the imputed values
    X_imputed = copy(X') # N by T
    

    # Find indices where 'X' is NaN
    missing_indices = isnan.(X_imputed)

    # Replace NaN's with imputed values
    X_imputed[missing_indices] = y_imputed[missing_indices]

    # Technical detail: Data here needs to be reordered 
    X_imputed = X_imputed[invperm(sorted_indices), :] # Rearrange 'X_imputed' so that loadings correspond to correct series

    # Re run pca on the imputed matrix
    X_pc, X_proj = perform_pca_missing(X_imputed, pr)

    return X_pc', X_proj  # These are the final factor loadings
end


function run_TP_algorithm(MV, pr)
    " More information efficient"

    # Step 0: Overlay the datasets
    X, sorted_indices = overlay_datasets(MV) # X = (T by N)

    # Step 1: Identify T_o and N_o
    T_o, N_o = find_Nₒ_Tₒ(X)
    println("T_o: ", T_o)
    println("N_o: ", N_o)
    tall_block, wide_block, _, _ = reorganize_matrix(X, N_o, T_o)
    
    # Step 2: Estimate factors from the tall block using PCA
    Ftall, Λtall = perform_pca_missing(Matrix(tall_block'), pr) # must be N by T
    
    # Step 3: Regress each column of X on some submatrix of Ftall
    Λ = zeros(size(X, 2), size(Ftall, 2))

    for i in axes(X, 2)
        # Find indices of missing values in column i
        Xᵢ = reshape(X[:, i], :, 1)
        non_missing_indices = (!isnan).(Xᵢ[:, 1])
        
        # Regress the missing values on the non-missing values
        Λ[i, :] = inv(Ftall[non_missing_indices, :]' * Ftall[non_missing_indices, :]) * Ftall[non_missing_indices, :]' * Xᵢ[non_missing_indices]
    end
    
    # Step 4: Impute missing values using the factor model
    y_imputed = Λ * Ftall' # Imputed values

    # Replace NaN's in the original matrix with the imputed values
    X_imputed = copy(X')
    
    # Find indices where 'X' is NaN
    missing_indices = isnan.(X_imputed)

    # Replace NaN's with imputed values
    X_imputed[missing_indices] = y_imputed[missing_indices]
    
    # Re run pca on the imputed matrix
    X_pc, X_proj = perform_pca_missing(X_imputed, pr)

    # Rearrange 'X_proj' so that loadings correspond to correct series
    X_proj = X_proj[sorted_indices, :] # Rearrange 'X_proj' so that loadings correspond to correct series

    return X_pc, X_proj  # These are the final factor loadings
end



function perform_pca_missing(X_pca, pr)
    M     = MultivariateStats.fit(PCA, X_pca; pratio=pr, method=:svd) # mean=0
    pcs   = MultivariateStats.transform(M, X_pca) # predict() produces the same # r by T

    λ     = sqrt.(principalvars(M))
    proj  = projection(M) * diagm(λ)
    pcs_s = pcs ./ λ

    return pcs_s', proj
end

# Plots.plot(axes(proj, 1), proj, label=L"\textrm{Factors\,\, |\,\, balanced}")
# Plots.savefig("factor_loadings.pdf")
# Plots.plot(axes(X_proj, 1), X_proj, label=L"\textrm{Factors\,\, |\,\, all}")
# Plots.savefig("factor_loadings2.pdf")

