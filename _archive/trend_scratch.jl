t                = collect(1:1:tot_periods)
# TT               = hcat(ones(tot_periods), t, 2 .* t.^2 ./ tot_periods, 3 .* t.^3, 4 .* t.^4)
TT               = hcat(ones(tot_periods), t, 2 .* t.^2 ./ tot_periods)
interp_series    = zeros(tot_periods)
trend            = zeros(size(df, 1), tot_periods)

# Create a matrix of NaN of size trend to store the coefficients
fill!(trend, NaN)    
βs               = zeros(size(df, 1), size(TT, 2))

# First, interpolate series 
correct_indices  = generate_correct_indices(year_vec[5], freq_type[5], freq, tmin, time_dict[5])
i = 994
for i in condition
    # Linear Interpolation 
    mask             = (!isnan).(df[i,:])
    interp_linear    = linear_interpolation(correct_indices[mask], df[i, mask], extrapolation_bc=Line())
    interp_series   .= convert.(Float64, interp_linear.(t))

    # spl = Spline1D(correct_indices[mask], df[i, mask])
    # interp_series = spl.(t)

    # plot the interp_series
    Plots.plot(1:tot_periods, interp_series)
    Plots.plot!(correct_indices, df[i, :])
    Plots.savefig("/Users/lc/Dropbox/Distributional_Dynamics/testing_trends/interp_series$i" * ".pdf")


    # Find the index of the first non-NaN column
    first_non_nan_index = findfirst(x -> all((!isnan).(x)), df[i,:])
    
    # Slice the matrix to skip the first NaN columns
    trimmed_int = interp_series[correct_indices[first_non_nan_index]:end]
    trimmed_TT  = TT[correct_indices[first_non_nan_index]:end, :]

    hyper_trimmed_int = interp_series[correct_indices[8]:end]
    hyper_trimmed_TT  = TT[correct_indices[8]:end, :]

    βs[i, :]         = (hyper_trimmed_TT' * hyper_trimmed_TT) \ (hyper_trimmed_TT' * hyper_trimmed_int)
    # βs[i, :]         = (trimmed_TT' * trimmed_TT) \ (trimmed_TT' * trimmed_int)
    df[i, mask]      = df[i, mask] .- TT[correct_indices[mask], :] * βs[i, :]

    # ols              = lm(TT, interp_series)
    # df[i, mask]      = residuals(ols)[correct_indices[mask]]
    # βs[i, :]        .= coef(ols) 
    if mod(i, 10) == 0
        # Plots.plot(1:tot_periods, interp_series)
        Plots.plot(correct_indices[first_non_nan_index]:correct_indices[end], trimmed_int[1:229])
        Plots.plot!(correct_indices[first_non_nan_index]:correct_indices[end], HP(trimmed_int[1:229], 1600))

        # Plots.plot!(correct_indices[mask], TT[correct_indices[mask], :] * βs[i, :])
        Plots.plot!(correct_indices[mask], TT[correct_indices[mask], :] * βs[i, :])
        Plots.savefig("/Users/lc/Dropbox/Distributional_Dynamics/testing_trends/test$i" * ".pdf") 
        # Plots.savefig("/Users/lc/Dropbox/Distributional_Dynamics/testing_trends/test$i" * "quad" * ".pdf") 
    end

    # Notes: quartic trend works for longer time series it seems 