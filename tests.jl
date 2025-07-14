# Filter Test 
    # (mock) data
    y = reshape([-1.77, -0.78, -1.28, -1.06, -3.65, -2.47, -0.06, -0.91, -0.80, 1.48], (1,10))


    # prior for time 0
    x0 = [-1., 1.]
    P0 = Matrix(1.0I, 2, 2)

    # dynamics
    A = [0.8 0.2; -0.1 0.8]
    b = ones(2)
    Ω = [0.2 0.0; 0.0 0.5]
    u = zeros(3, size(y, 2))
    B = zeros(2,3)

    # observation
    G = [reshape([1.0, 0.0], (1,2)) for i in 1:size(y, 2)]
    Σ = Matrix(0.3I, 1, 1)
    smooth=true

    smoother_output,log_D         = recurse_kalman_filter(A,B,Ω,Σ,G,y,u,smooth)

    @unpack x_updated, x_smoothed = smoother_output

    p1 = Plots.scatter(1:size(y,2), y', color="red", label="observations y")
    plot!(p1, 0:size(y,2), vcat(x0[1], x_updated[1,:]), color="orange", label="filtered x1", grid=false)
    plot!(p1, 0:size(y,2), vcat(x0[1],x_smoothed[1,:]), color="blue", label="filtered x1", grid=false)

    Plots.savefig(p1, "filter2.png")

    # Implementation from Moritz Schauer
    using Kalman, GaussianDistributions, LinearAlgebra
    using GaussianDistributions: ⊕ # independent sum of Gaussian r.v.
    using Statistics
    
    # prior for time 0
    x0 = [-1., 1.]
    P0 = Matrix(1.0I, 2, 2)
    
    # dynamics
    Φ = [0.8 0.2; -0.1 0.8]
    b = ones(2) .* 2
    Q = [0.2 0.0; 0.0 0.5]
    
    # observation
    H = [1.0 0.0]
    R = Matrix(0.3I, 1, 1)
    
    # (mock) data
    ys = [[-1.77], [-0.78], [-1.28], [-1.06], [-3.65], [-2.47], [-0.06], [-0.91], [-0.80], [1.48]]
    
    
    # filter (assuming first observation at time 1)
    N = length(ys)
    
    p = Gaussian(x0, P0)
    ps = [p] # vector of filtered Gaussians
    for i in 1:N
        global p
        # predict
        p = Φ*p ⊕ Gaussian(zero(x0) + b, Q) #same as Gaussian(Φ*p.μ, Φ*p.Σ*Φ' + Q)
        # correct
        p, yres, _ = Kalman.correct(Kalman.JosephForm(), p, (Gaussian(ys[i], R), H))
        push!(ps, p) # save filtered density
    end

p1 = Plots.scatter(1:N, first.(ys), color="red", label="observations y")
plot!(p1, 0:N, [mean(p)[1] for p in ps], color="orange", label="filtered x1", grid=false, ribbon=[sqrt(cov(p)[1,1]) for p in ps], fillalpha=.5)
plot!(p1, 0:N, [mean(p)[2] for p in ps], color="blue", label="filtered x2", grid=false, ribbon=[sqrt(cov(p)[2,2]) for p in ps], fillalpha=.5)

Plots.savefig(p1, "filter_test.png")








#ribbon=[sqrt(cov(p)[1,1]) for p in ps]