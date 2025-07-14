#TODO: First Step -> Define the problem 
struct LinearStateSpaceProblemX{uType, uPriorMeanType, uPriorVarType, tType, P, NP, F, AType, BType, CType, RType, ObsType, K} <:AbstractPerturbationProblem
    f::F # HACK: used only for standard interfaces/syms/etc., not used in calculations
    A::AType
    B::BType
    C::CType
    observables_noise::RType
    observables::ObsType
    u0::uType
    u0_prior_mean::uPriorMeanType
    u0_prior_var::uPriorVarType
    tspan::tType
    p::P
    noise::NP
    kwargs::K

    @add_kwonly function LinearStateSpaceProblemX{iip}(A, B, u0, tspan, p = NullParameters();
                            u0_prior_mean     = nothing,
                            u0_prior_var      = nothing, 
                            C                 = nothing,
                            observables_noise = nothing,
                            observables       = nothing,
                            noise             = nothing,
                            syms              = nothing,
                            f                 = ODEFunction{false}(((u, p, t) -> error("not implemented"));
                            syms              = syms),
                            kwargs...) where {iip}
    _tspan       = promote_tspan(tspan)
    _observables = observables

    # Require integer distances between time periods for now.  Later could check with dt != 1
    @assert round(_tspan[2] - _tspan[1]) - (_tspan[2] - _tspan[1]) ≈ 0.0

    return new{typeof(u0), typeof(u0_prior_mean), typeof(u0_prior_var), typeof(_tspan),
    typeof(p),
    typeof(noise), 
    typeof(f),
    typeof(A), 
    typeof(B), 
    typeof(C), 
    typeof(observables_noise),
    typeof(_observables),
    typeof(kwargs)}(f, A, B, C, observables_noise, _observables, u0,
            u0_prior_mean,
            u0_prior_var,
            _tspan, p, noise, kwargs)
    end
end
# just forwards to a iip = false case
function LinearStateSpaceProblemX(args...; kwargs...)
    LinearStateSpaceProblemX{false}(args...; kwargs...)
end

#                                             sensealg, u0, p, args...; kwargs...)
function ChainRulesCore.rrule(::typeof(DiffEqBase.solve), prob::LinearStateSpaceProblem,
    alg::KalmanFilter, args...; kwargs...)
# Preallocate values
T = convert(Int64, prob.tspan[2] - prob.tspan[1] + 1)
# checks on bounds
@assert size(prob.observables, 2) == T - 1

@unpack A, B, C, u0_prior_mean, u0_prior_var = prob
N = length(u0_prior_mean)
L = size(C, 1)

# TODO: move to internal algorithm cache
# This method of preallocation won't work with staticarrays.  Note that we can't use eltype(mean(u0)) since it may be special case of FillArrays.zeros
B_prod = Matrix{eltype(u0_prior_var)}(undef, N, N)
u = [Vector{eltype(u0_prior_var)}(undef, N) for _ in 1:T] # Mean of Kalman filter inferred latent states
P = [Matrix{eltype(u0_prior_var)}(undef, N, N) for _ in 1:T] # Posterior variance of Kalman filter inferred latent states
z = [Vector{eltype(prob.observables)}(undef, size(prob.observables, 1)) for _ in 1:T] # Mean of observables, generated from mean of latent states

# TODO: these intermediates should be of size T-1 instead as the first was skipped.  Left in for checks on timing
# Maintaining allocations for these intermediates is necessary for the rrule, but not for forward only.  Code could be refactored along those lines with solid unit tests.
u_mid = [Vector{eltype(u0_prior_var)}(undef, N) for _ in 1:T] # intermediate in u calculation
P_mid = [Matrix{eltype(u0_prior_var)}(undef, N, N) for _ in 1:T] # intermediate in P calculation
innovation = [Vector{eltype(prob.observables)}(undef, size(prob.observables, 1))
for _ in 1:T]
K = [Matrix{eltype(u0_prior_var)}(undef, N, L) for _ in 1:T] # Gain
CP = [Matrix{eltype(u0_prior_var)}(undef, L, N) for _ in 1:T] # C * P[t]
V = [PDMat{eltype(u0_prior_var), Matrix{eltype(u0_prior_var)}}(L,
                                         Matrix{
                                                eltype(u0_prior_var)
                                                }(undef,
                                                  L,
                                                  L),
                                         Cholesky{
                                                  eltype(u0_prior_var),
                                                  Matrix{
                                                         eltype(u0_prior_var)
                                                         }}(Matrix{
                                                                   eltype(u0_prior_var)
                                                                   }(undef,
                                                                     L,
                                                                     L),
                                                            'U',
                                                            0))
for _ in 1:T] # preallocated buffers for cholesky and matrix itself

R = make_observables_covariance_matrix(prob.observables_noise)  # Support diagonal or matrix covariance matrices.
mul!(B_prod, B, B')

u[1] .= u0_prior_mean
P[1] .= u0_prior_var
z[1] .= C * u[1]

loglik = 0.0

# temp buffers.  Could be moved into algorithm settings
temp_N_N = Matrix{eltype(u0_prior_var)}(undef, N, N)
temp_L_L = Matrix{eltype(u0_prior_var)}(undef, L, L)
temp_L_N = Matrix{eltype(u0_prior_var)}(undef, L, N)
temp_N_L = Matrix{eltype(u0_prior_var)}(undef, N, L)
temp_M = Vector{eltype(u0_prior_var)}(undef, L)
temp_N = Vector{eltype(u0_prior_var)}(undef, N)
retcode = :Failure
try
@inbounds for t in 2:T
# Kalman iteration
mul!(u_mid[t], A, u[t - 1]) # u[t] = A u[t-1]
mul!(z[t], C, u_mid[t]) # z[t] = C u[t]

# P[t] = A * P[t - 1] * A' + B * B'
mul!(temp_N_N, P[t - 1], A')
mul!(P_mid[t], A, temp_N_N)
P_mid[t] .+= B_prod

mul!(CP[t], C, P_mid[t]) # CP[t] = C * P[t]

# V[t] = CP[t] * C' + R
mul!(V[t].mat, CP[t], C')
V[t].mat .+= R

# V_t .= (V_t + V_t') / 2 # classic hack to deal with stability of not being quite symmetric
transpose!(temp_L_L, V[t].mat)
V[t].mat .+= temp_L_L
lmul!(0.5, V[t].mat)

copy!(V[t].chol.factors, V[t].mat) # copy over to the factors for the cholesky and do in place
cholesky!(V[t].chol.factors, NoPivot(); check = false) # inplace uses V_t with cholesky.  Now V[t]'s chol is upper-triangular        
innovation[t] .= prob.observables[:, t - 1] - z[t]
loglik += logpdf(MvNormal(V[t]), innovation[t])  # no allocations since V[t] is a PDMat

# K[t] .= CP[t]' / V[t]  # Kalman gain
# Can rewrite as K[t]' = V[t] \ CP[t] since V[t] is symmetric
ldiv!(temp_L_N, V[t].chol, CP[t])
transpose!(K[t], temp_L_N)

#u[t] += K[t] * innovation[t]
copy!(u[t], u_mid[t])
mul!(u[t], K[t], innovation[t], 1, 1)

#P[t] -= K[t] * CP[t]
copy!(P[t], P_mid[t])
mul!(P[t], K[t], CP[t], -1, 1)
end
retcode = :Success
catch e
loglik = -Inf
end
t_values = prob.tspan[1]:prob.tspan[2]
sol = build_solution(prob, alg, t_values, u; P, W = nothing, logpdf = loglik, z,
retcode)
function solve_pb(Δsol)
# Currently only changes in the logpdf are supported in the rrule
@assert Δsol.u == ZeroTangent()
@assert Δsol.W == ZeroTangent()
@assert Δsol.P == ZeroTangent()
@assert Δsol.z == ZeroTangent()

Δlogpdf = Δsol.logpdf

if iszero(Δlogpdf)
return (NoTangent(), Tangent{typeof(prob)}(), NoTangent(),
map(_ -> NoTangent(), args)...)
end
# Buffers
ΔP = zero(P[1])
Δu = zero(u[1])
ΔA = zero(A)
ΔB = zero(B)
ΔC = zero(C)
ΔK = zero(K[1])
ΔP_mid = zero(ΔP)
ΔP_mid_sum = zero(ΔP)
ΔCP = zero(CP[1])
Δu_mid = zero(u_mid[1])
Δz = zero(z[1])
ΔV = zero(V[1].mat)

# If it was a failure, just return and hope the gradients are ignored!
if retcode == :Success
for t in T:-1:2
# The inverse is used throughout, including in quadratic forms.  For large systems this might not be stable            
inv_V = Symmetric(inv(V[t].chol)) # use cholesky factorization to invert.  Symmetric

# Sensitivity accumulation
copy!(ΔP_mid, ΔP)
mul!(ΔK, ΔP, CP[t]', -1, 0) # i.e. ΔK = -ΔP * CP[t]'
mul!(ΔCP, K[t]', ΔP, -1, 0) # i.e. ΔCP = - K[t]' * ΔP
copy!(Δu_mid, Δu)
mul!(ΔK, Δu, innovation[t]', 1, 1) # ΔK += Δu * innovation[t]'
mul!(Δz, K[t]', Δu, -1, 0)  # i.e, Δz = -K[t]'* Δu
mul!(ΔCP, inv_V, ΔK', 1, 1) # ΔCP += inv_V * ΔK'

# ΔV .= -inv_V * CP[t] * ΔK * inv_V
mul!(temp_L_N, inv_V, CP[t])
mul!(temp_N_L, ΔK, inv_V)
mul!(ΔV, temp_L_N, temp_N_L, -1, 0)

mul!(ΔC, ΔCP, P_mid[t]', 1, 1) # ΔC += ΔCP * P_mid[t]'
mul!(ΔP_mid, C', ΔCP, 1, 1) # ΔP_mid += C' * ΔCP
mul!(Δz, inv_V, innovation[t], Δlogpdf, 1) # Δz += Δlogpdf * inv_V * innovation[t] # Σ^-1 * (z_obs - z)

#ΔV -= Δlogpdf * 0.5 * (inv_V - inv_V * innovation[t] * innovation[t]' * inv_V) # -0.5 * (Σ^-1 - Σ^-1(z_obs - z)(z_obx - z)'Σ^-1)
mul!(temp_M, inv_V, innovation[t])
mul!(temp_L_L, temp_M, temp_M')
temp_L_L .-= inv_V
rmul!(temp_L_L, Δlogpdf * 0.5)
ΔV += temp_L_L

#ΔC += ΔV * C * P_mid[t]' + ΔV' * C * P_mid[t]
mul!(temp_L_N, C, P_mid[t])
transpose!(temp_L_L, ΔV)
temp_L_L .+= ΔV
mul!(ΔC, temp_L_L, temp_L_N, 1, 1)

# ΔP_mid += C' * ΔV * C
mul!(temp_L_N, ΔV, C)
mul!(ΔP_mid, C', temp_L_N, 1, 1)

mul!(ΔC, Δz, u_mid[t]', 1, 1) # ΔC += Δz * u_mid[t]'
mul!(Δu_mid, C', Δz, 1, 1) # Δu_mid += C' * Δz

# Calculates (ΔP_mid + ΔP_mid')
transpose!(ΔP_mid_sum, ΔP_mid)
ΔP_mid_sum .+= ΔP_mid

# ΔA += (ΔP_mid + ΔP_mid') * A * P[t - 1]
mul!(temp_N_N, A, P[t - 1])
mul!(ΔA, ΔP_mid_sum, temp_N_N, 1, 1)

# ΔP .= A' * ΔP_mid * A # pass into next period
mul!(temp_N_N, ΔP_mid, A)
mul!(ΔP, A', temp_N_N)

mul!(ΔB, ΔP_mid_sum, B, 1, 1) # ΔB += ΔP_mid_sum * B
mul!(ΔA, Δu_mid, u[t - 1]', 1, 1) # ΔA += Δu_mid * u[t - 1]'
mul!(Δu, A', Δu_mid)
end
end
return (NoTangent(),
Tangent{typeof(prob)}(; A = ΔA, B = ΔB, C = ΔC, u0 = ZeroTangent(), # u0 not used in kalman filter
            u0_prior_mean = Δu, u0_prior_var = ΔP),
NoTangent(), map(_ -> NoTangent(), args)...)
end
return sol, solve_pb




A = rand(10,10)
B = rand(10,10)
C = rand(10,10)
D = rand(10,10)

e = (;A,B,C,D)

LinearStateSpaceProblem(mod.A, mod.B, u0, (0, T); mod.C, observables_noise = mod.D)

function kalman_model_likelihood(β, u0_prior_mean, u0_prior_var, observables)
    # In this case, β is the single parameter but for us, everything is a parameter 
    mod  = generate_model(β) # generate model from structural parameters

    # This is a structure 
    prob = LinearStateSpaceProblem(mod.A, mod.B, u0, (0, size(observables,2)); mod.C, observables, observables_noise = mod.D, u0_prior_var, u0_prior_mean)

    return solve(prob).logpdf
end

u0_prior_mean = [0.0, 0.0]
u0_prior_var  = [1e-10 0.0;
                0.0 1e-10]  # starting with degenerate prior

kalman_model_likelihood(β, u0_prior_mean, u0_prior_var, observables)

using Optimization, OptimizationOptimJL
# Create a function to minimize only of β and use Zygote based gradients
kalman_objective(β, p) = -kalman_model_likelihood(β, u0_prior_mean, u0_prior_var, observables)
kalman_objective(0.95, nothing)
gradient(β ->kalman_objective(β, nothing),β) # Verifying it can be differentiated
optf = OptimizationFunction(kalman_objective, Optimization.AutoZygote())
β0 = [0.91] # start off of the pseudotrue
optprob = OptimizationProblem(optf, β0)
optsol = solve(optprob,LBFGS())