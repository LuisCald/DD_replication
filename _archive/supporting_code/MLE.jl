# Algorith: First Run Kalman Filter
# First Step: Then run the kalman smoother. Save smooth states, covariance and kalman gain 
# Second Step: Run _smooth_pair
# Third Step: Estimate LOM 
# Fourth Step: Estimate SCov 
# EStimate Prior VCV with LOM and Scov 
# Run Kalman Filter 



function smooth_pair(sigma_smoothed, gain_smoothed)
    """Calculate pairwise covariance between hidden states
    Calculate covariance between hidden states at `t` and `t-1` for
    all time step pairs.
    Arguments:
    smoothed_state_covariances : [n_timesteps, n_dim_state, n_dim_state] array
        covariance of hidden state given all observations
    kalman_smoothing_gain : [n_timesteps-1, n_dim_state, n_dim_state]
        Correction matrices from Kalman Smoothing
    Returns
    -------
    pairwise_covariances : [n, n, T] array
        Covariance between hidden states at times t and t-1 for t =
        [2...T-1].  Time 1 is ignored.
    """
    T                    = size(sigma_smoothed, 3)
    n                    = size(sigma_smoothed, 2)
    pairwise_covariances = zeros(n, n, T)
    # Fill matrix with covariances
    for t in 2:T-1
        pairwise_covariances[:, :, t] = sigma_smoothed[:, :, t] * gain_smoothed[:, :, t - 1]'
    end 

    return pairwise_covariances
end


function EM_LOM(x_smoothed, sigma_smoothed, pairwise_covariances, controls, controls_transition=nothing)
    """Apply the EM algorithm to obtain LOM matrix 

    Maximize expected log likelihood of observations with respect to the state
    transition matrix.
    
        A &= ( sum_{t=1}^{T-1} E[x_t x_{t-1}^{T}])
             ( sum_{t=1}^{T-1} E[x_{t-1} x_{t-1}^T] )^{-1}
    """
    T    = size(sigma_smoothed, 3)
    n    = size(sigma_smoothed, 2)
    res1 = zeros(n, n)
    res2 = zeros(n, n)
    
    # With or without controls 
    if controls == nothing
        for t in 2:T-1
            res1 += pairwise_covariances[:, :, t] .+ x_smoothed[t, :] * x_smoothed[t - 1, :]' # the dot is there to allow addition of matrices and floats, which technically happens (e.g., 1 by 1 matrix plus a float)
            res2 += sigma_smoothed[:, :, t - 1] .+ x_smoothed[t - 1, :] * x_smoothed[t - 1, :]'  # This should be a matrix 
        end 
        # Compute the (Moore-Penrose) pseudo-inverse of a matrix
        transition_matrix = res1 * pinv(res2)  # TODO: Reformulate the formula overall to incorporate controls 
    
        return transition_matrix
    else 
        B = copy(controls_transition)

        # Added .-  controls[t - 1, :] * x_smoothed[t - 1, :]' * B'
        for t in 2:T-1
            res1 += pairwise_covariances[:, :, t] .+ x_smoothed[t, :] * x_smoothed[t - 1, :]' .-  controls[t - 1, :] * x_smoothed[t - 1, :]' * B' # the dot is there to allow addition of matrices and floats, which technically happens (e.g., 1 by 1 matrix plus a float)
            res2 += sigma_smoothed[:, :, t - 1] .+ x_smoothed[t - 1, :] * x_smoothed[t - 1, :]'  # This should be a matrix 
        end 
        # Compute the (Moore-Penrose) pseudo-inverse of a matrix
        transition_matrix = res1 * pinv(res2)  # TODO: Reformulate the formula overall to incorporate controls 

        return transition_matrix
    end 

end


function EM_Controls(x_smoothed, sigma_smoothed, pairwise_covariances, controls, transition_matrix)
    """Apply the EM algorithm to obtain Controls matrix, B

    Maximize expected log likelihood of observations with respect to the controls
    matrix
    """
    T    = size(sigma_smoothed, 3)
    n    = size(sigma_smoothed, 2)
    res1 = zeros(n, n)
    res2 = zeros(n, n)

    # With or without controls 
    for t in 2:T-1
        res1 += pairwise_covariances[:, :, t] .+ x_smoothed[t, :] * controls[t - 1, :]' .-  transition_matrix * x_smoothed[t - 1, :] * controls[t - 1, :]' # the dot is there to allow addition of matrices and floats, which technically happens (e.g., 1 by 1 matrix plus a float)
        res2 += sigma_smoothed[:, :, t - 1] .+ controls[t - 1, :] * controls[t - 1, :]'  # This should be a matrix 
    end 
    # Compute the (Moore-Penrose) pseudo-inverse of a matrix
    controls_matrix = res1 * pinv(res2)  # TODO: Reformulate the formula overall to incorporate controls 

    return controls_matrix
end


function EM_MLOM(x_smoothed, sigma_smoothed, pairwise_covariances, controls, measurements, M_controls_transition=nothing)
    """Apply the EM algorithm to obtain Measurement LOM matrix 

    Maximize expected log likelihood of observations with respect to the measurement
    transition matrix, G.
    
    """
    T    = size(sigma_smoothed, 3)
    n    = size(sigma_smoothed, 2)
    res1 = zeros(n, n)
    res2 = zeros(n, n)
    
    # With or without controls 
    if controls == nothing
        for t in 1:T-1
            if measurements[t, :] = []
                res1 .+= 0
                res2 .+= 0
            else
                res1 += pairwise_covariances[:, :, t] .+ measurements[t, :] * x_smoothed[t, :]'  # the dot is there to allow addition of matrices and floats, which technically happens (e.g., 1 by 1 matrix plus a float)
                res2 += sigma_smoothed[:, :, t] .+ x_smoothed[t, :] * x_smoothed[t, :]'  # This should be a matrix 
            end
        end 
        # Compute the (Moore-Penrose) pseudo-inverse of a matrix
        M_transition_matrix = res1 * pinv(res2)  # TODO: Reformulate the formula overall to incorporate controls 
    
        return M_transition_matrix
    else 
        D = copy(M_controls_transition)

        for t in 1:T-1
            if measurements[t, :] = []
                res1 .+= 0
                res2 .+= 0
            else
                res1 += pairwise_covariances[:, :, t] .+ measurements[t, :] * x_smoothed[t, :]' - x_smoothed[t, :] * controls[t, :]' * D'  # the dot is there to allow addition of matrices and floats, which technically happens (e.g., 1 by 1 matrix plus a float)
                res2 += sigma_smoothed[:, :, t] .+ x_smoothed[t, :] * x_smoothed[t, :]'  # This should be a matrix 
            end
        end 
        # Compute the (Moore-Penrose) pseudo-inverse of a matrix
        M_transition_matrix = res1 * pinv(res2)  # TODO: Reformulate the formula overall to incorporate controls 

        return M_transition_matrix
    end 

end

# TODO: This only works if (1) the measurement missing or not, but (2) it doesn't work for when one of the X measurements are missing here and there 
function EM_Feedback(x_smoothed, sigma_smoothed, pairwise_covariances, controls, measurements, C)
    """Apply the EM algorithm to obtain Controls matrix, D

    Maximize expected log likelihood of observations with respect to the controls
    matrix in the measurement equation 
    """
    T    = size(sigma_smoothed, 3)
    n    = size(sigma_smoothed, 2)
    res1 = zeros(n, n)
    res2 = zeros(n, n)

    # With or without controls 
    for t in 1:T-1
        if measurements[t, :] == []
            res1 .+= 0
            res2 .+= 0
        else    
            C = copy(C[(!isnan).(measurements[t, :]), :])  # It takes the matrix when all measurements exist and drops respective rows when the measurement is unavailable
            non_missing_measures = measurements[t, :][(!isnan).(measurements[t, :])]
        
            res1 += controls[t, :] * non_missing_measures[t, :]' .-  controls[t, :] * x_smoothed[t, :]' * C' # the dot is there to allow addition of matrices and floats, which technically happens (e.g., 1 by 1 matrix plus a float)
            res2 += controls[t, :] * controls[t, :]'  # This should be a matrix 
        end 
    end 
    # Compute the (Moore-Penrose) pseudo-inverse of a matrix
    feedback_matrix = res1 * pinv(res2)  # TODO: Reformulate the formula overall to incorporate controls 

    return feedback_matrix
end





function EM_SCov(transition_matrix, x_smoothed, sigma_smoothed, pairwise_covariances, controls=nothing, controls_mat=nothing)
    """Apply the EM algorithm to parameter SCov
    Maximize expected log likelihood of observations with respect to the
    transition covariance matrix SCov.

    """
    T    = size(sigma_smoothed, 3)
    n    = size(sigma_smoothed, 2)
    res  = zeros(n, n)

    # With or without controls 
    if controls == nothing
        for t in 1:T-1
            err         = x_smoothed[t + 1, :] - transition_matrix * x_smoothed[t, :] # n x 1 vector 
            Vt1t_A      = pairwise_covariances[:, :, t + 1] * transition_matrix'  # n x n matrix 
            res         += err * err' + transition_matrix * sigma_smoothed[:, :, t] * transition_matrix' + sigma_smoothed[:, :, t + 1] - Vt1t_A - Vt1t_A'
        end 
    
        return (1 / (T - 1)) .* res
    else
        B = copy(controls_mat)
        for t in 1:T-1
            err         = x_smoothed[t + 1, :] - transition_matrix * x_smoothed[t, :] - B * controls[t, :] # n x 1 vector 
            Vt1t_A      = pairwise_covariances[:, :, t + 1] * transition_matrix'  # n x n matrix 
            Vt1t_B      = B * controls[t, :] * x_smoothed[t + 1, :]'
            Vt1t_B2     = transition_matrix * x_smoothed[t, :] * controls[t, :]' * B'
            Vt1t_B3     = B * controls[t, :] * controls[t, :]' * B'
            A_contr     = err * err' + transition_matrix * sigma_smoothed[:, :, t] * transition_matrix' + sigma_smoothed[:, :, t + 1] - Vt1t_A - Vt1t_A'
            res        += A_contr - 2 .* Vt1t_B + 2 .* Vt1t_B2 * Vt1t_B3
        end 

        return (1 / (T - 1)) .* res
    end 

end 

# TODO: Figure out a way to deal with err   = non_missing_measures - transition_matrix * x_smoothed[t, :]
function EM_MCov(kalman_dict, x_smoothed, sigma_smoothed)
    """Apply the EM algorithm to parameter `observation_covariance`
    Maximize expected log likelihood of observations with respect to the
    observation covariance matrix `observation_covariance`.
    
        R &= frac{1}{T} sum_{t=0}^{T-1}
                [z_t - C_t mathbb{E}[x_t] - b_t]
                    [z_t - C_t mathbb{E}[x_t] - b_t]^T
                + C_t Var(x_t) C_t^T
    """
    T     = size(sigma_smoothed, 3)
    n     = size(sigma_smoothed, 2)
    res   = zeros(n, n)
    y     = set_measurements(kalman_dict)  # Vector of Vectors 
    res   = zeros(length(y), length(y))  # m by m
    n_obs = 0

    # Demean 
    for m in 1:size(y, 1)
        demeaned_data = y[m] .- only(mean(filter(!isnan, y[m]), dims=1))
        y[m]          = demeaned_data
    end 

    # Concatenate
    measures = Matrix{Float64}(undef, length(y[1]), 0)  # T x m matrix, where these m columns are appended 
    for (i, m) in enumerate(y)
        measures = hcat(measures, y[i])
    end 

    transition_matrix = kalman_dict["A"]
    # Create MCov 
    for t in 1:T-1
        non_missing_measures    = measures[t, :][(!isnan).(measures[t, :])]
        if non_missing_measures == []
            res .+= 0
        else 
            err   = non_missing_measures - transition_matrix * x_smoothed[t, :]
            println(size(err))
            res   += err * err' .+ transition_matrix * sigma_smoothed[:, :, t] * transition_matrix'
            n_obs += 1
        end 
    end
    
    if n_obs > 0
        return (1.0 / n_obs) * res
    else
        return res
    end 

end 

function EM_Prior(x_smoothed, sigma_smoothed)
    """Apply the EM algorithm to parameter `initial_state_covariance`
    Maximize expected log likelihood of observations with respect to the
    covariance of the initial state distribution `initial_state_covariance`.
    
    Sigma_0 = E[x_0, x_0^T] - mu_0 E[x_0]^T
                   - E[x_0] mu_0^T + mu_0 mu_0^T
    """ 
    n                  = size(x_smoothed, 2)
    initial_state_mean = x_smoothed[1, :]  # zeros(n, 1)
    x0                 = x_smoothed[1, :]
    x0_x0              = sigma_smoothed[:, :, 1] .+ x0 * x0'
    Sigma_prior        = x0_x0 .- initial_state_mean * x0' .- x0 * initial_state_mean' .+ initial_state_mean * initial_state_mean'
end


