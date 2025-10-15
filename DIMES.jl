
# function RunDIME(lprobFunc::Function, init::Array, niter::Int; sigma::Float64=1e-5, gamma=nothing, aimh_prob::Float64=0.1, df_proposal_dist::Int=10, delta::Float64=0.999, progress::Bool=true)

#     ndim, nchain = size(init)
#     isplit = nchain ÷ 2

#     # get some default values
#     dft = df_proposal_dist

#     if gamma == nothing
#         g0 = 2.38 / sqrt(2 * ndim)
#     else
#         g0 = gamma
#     end

#     # fix that MvTDist does not accept positive demi-definite covariance matrices
#     fixPSD = Matrix(1e-16I, ndim, ndim)

#     # initialize
#     ccov = Matrix(1.0I, ndim, ndim)
#     cmean = zeros(ndim)
#     dist = MvTDist(dft, cmean, ccov + fixPSD)
#     accepted = ones(nchain)
#     cumlweight = -Inf

#     # calculate intial values
#     x = copy(init)
#     lprob = lprobFunc(x)
#     # split ensemble
#     xref, xcur = (@view x[:, 1:isplit+1]), (@view x[:, isplit+1:end])

#     # preallocate
#     lprobs = Array{Float64,2}(undef, niter, nchain)
#     chains = Array{Float64,3}(undef, niter, nchain, ndim)

#     lprobs = fill!(lprobs, 0.0)
#     chains = fill!(chains, 0.0)

#     # optional progress bar
#     if progress
#         iter = ProgressBar(1:niter)
#     else
#         iter = 1:niter
#     end

#     # mean/covariance temporaries
#     nmean = zeros(Float64, ndim)
#     xc = zeros(Float64, ndim, nchain)   # centered ensemble
#     ncov = zeros(Float64, ndim, ndim)

#     @inbounds for i in iter

#         # calculate stats for current ensemble
#         # log weight of current ensemble
#         lweight = logsumexp(lprobs) + log(sum(accepted)) - log(nchain)

#         # ncov = cov(transpose(x))
#         # nmean = mean(x, dims=2)

#         @views @. nmean = sum(x, dims=2) / nchain
#         @views xc .= x .- nmean             # broadcast centers each column by nmean
#         mul!(ncov, xc, transpose(xc))       # ncov = xc * xc'
#         ncov .*= 1.0 / (nchain - 1)

#         # update AIMH proposal distribution
#         newcumlweight = logaddexp(cumlweight, lweight)
#         statelweight = cumlweight - newcumlweight

#         # ccov = exp(statelweight) * ccov + exp(lweight - newcumlweight) * ncov
#         # cmean = exp(statelweight) * cmean + exp(lweight - newcumlweight) * nmean

#         w_old = exp(statelweight)
#         w_new = exp(lweight - newcumlweight)

#         @. ccov = w_old * ccov + w_new * ncov
#         @. cmean = w_old * cmean + w_new * nmean
#         cumlweight = newcumlweight + log(delta)

#         cumlweight = newcumlweight + log(delta)
#         naccepted = 0

#         # must iterate over current and reference ensemble
#         @inbounds for round2 in (false, true)

#             # define current ensemble
#             if round2
#                 xcur, xref = (@view x[:, 1:isplit+1]), (@view x[:, isplit+1:end])
#                 lprobcur = @view lprob[1:isplit+1]
#             else
#                 xref, xcur = (@view x[:, 1:isplit+1]), (@view x[:, isplit+1:end])
#                 lprobcur = @view lprob[isplit+1:end]
#             end
#             cursize = size(xcur)[2]
#             refsize = nchain - cursize + 1

#             # get differential evolution proposal
#             # draw the indices of the complementary chains
#             i1 = collect(0:cursize-1) .+ rand(1:cursize-1, cursize)
#             i2 = collect(0:cursize-1) .+ rand(1:cursize-2, cursize)
#             i2[i2.>=i1] .+= 1

#             # add small noise and calculate proposal
#             f = sigma * rand(Normal(0, 1), (1, cursize))
#             q = xcur + g0 * (xref[:, (i1.%refsize).+1] - xref[:, (i2.%refsize).+1]) .+ f
#             factors = zeros(cursize)

#             # get AIMH proposals if any chain is drawn
#             xchnge = rand(Uniform(0, 1), cursize) .<= aimh_prob

#             if sum(xchnge) > 0
#                 # draw alternative candidates and calculate their proposal density
#                 try
#                     dist = MvTDist(dft, cmean[:], ccov * (dft - 2) / dft + fixPSD)
#                 catch ee
#                     dist = MvTDist(dft, cmean[:], diagm(ones(length(cmean[:]))))
#                 end

#                 xcand = rand(dist, sum(xchnge))
#                 lprop_old = logpdf(dist, xcur[:, xchnge])
#                 lprop_new = logpdf(dist, xcand)

#                 # update proposals and factors
#                 q[:, xchnge] = xcand
#                 factors[xchnge] = lprop_old - lprop_new
#             end

#             # Metropolis-Hasings 
#             newlprob = lprobFunc(q)
#             lnpdiff = factors + newlprob - lprobcur
#             accepted = lnpdiff .> log.(rand(Uniform(0, 1), cursize))
#             naccepted += sum(accepted)
#             # update chains
#             xcur[:, accepted] = q[:, accepted]
#             lprobcur[accepted] = newlprob[accepted]
#         end

#         # store
#         chains[i, :, :] = transpose(x)
#         lprobs[i, :] = lprob

#         if progress
#             set_description(iter, string(@sprintf("[ll/MAF: %7.3f(%1.0e)/%2.0d%% | %1.0e]", maximum(lprob), std(lprob), 100 * naccepted / nchain, statelweight)))
#         end
#     end

#     return chains, lprobs, dist
# end

# ----------------------------------------------------------------------
# Fast, allocation-free DIME sampler
# ----------------------------------------------------------------------
function RunDIME(
    lprobFunc::Function,         # vectorised log-probability
    init::AbstractMatrix,        # (ndim × nchain) initial ensemble
    niter::Int;                  # number of MCMC iterations
    sigma::Float64=1e-5,
    gamma=nothing,
    aimh_prob::Float64=0.10,
    df_proposal_dist::Int=10,
    delta::Float64=0.999,
    progress::Bool=true)

    ndim, nchain = size(init)
    I_ndim = Matrix{Float64}(I, ndim, ndim)
    isplit = nchain ÷ 2          # current / reference split
    g0 = gamma === nothing ? 2.38 / sqrt(2ndim) : gamma
    dft = df_proposal_dist
    fixPSD = 1e-16I(ndim)        # keeps Σ strictly p.d.
    rng = Random.default_rng()

    # ------------ permanent workspace --------------------------------
    idx1 = zeros(Int, nchain)
    idx2 = zeros(Int, nchain)
    noise = zeros(Float64, nchain)
    factor = zeros(Float64, nchain)      # AIMH log-proposal factors
    swapflg = falses(nchain)

    qbuf = similar(init)               # proposal points (ndim×nchain)
    newlp = zeros(Float64, nchain)      # tmp for new log-probs

    ccov = Matrix{Float64}(I, ndim, ndim)
    cmean = zeros(Float64, ndim)
    dist = MvTDist(dft, cmean, ccov + fixPSD)
    cumlw = -Inf                         # cumulative log-weight

    # ensemble & target density
    x = copy(init)                   # live ensemble (ndim×nchain)
    lprob = lprobFunc(x)

    # views that will be swapped each “round”
    xref = view(x, :, 1:isplit+1)
    xcur = view(x, :, isplit+2:nchain)

    # storage for chains / log-prob trajectories
    chains = Array{Float64}(undef, niter, nchain, ndim)
    lprobs = Array{Float64}(undef, niter, nchain)

    # temporary arrays for mean / covariance update
    nmean = zeros(Float64, ndim)
    xc = similar(x)                   # centred ensemble
    ncov = zeros(Float64, ndim, ndim)

    # progress iterator
    iter = progress ? ProgressBar(1:niter) : 1:niter

    # pre-built scalar distributions
    stdN = Normal()
    uni01 = Uniform()

    @inbounds for it in iter
        # -------- ensemble mean / covariance (BLAS GEMM, no alloc) ---
        fill!(nmean, 0.0)
        @inbounds for j = 1:nchain
            @views nmean .+= x[:, j]
        end
        @. nmean /= nchain

        @inbounds for j = 1:nchain
            @views xc[:, j] .= x[:, j] .- nmean
        end
        mul!(ncov, xc, xc', 1 / (nchain - 1), 0.0)  # ncov ← (1/(N−1)) xc xcᵀ

        # -------- adaptive AIMH moment update ------------------------
        logw_cur = logsumexp(lprob) - log(nchain)
        new_cuml = logaddexp(cumlw, logw_cur)
        w_old = exp(cumlw - new_cuml)
        w_new = exp(logw_cur - new_cuml)

        @. ccov = w_old * ccov + w_new * ncov
        @. cmean = w_old * cmean + w_new * nmean
        cumlw = new_cuml + log(delta)

        nacc = 0

        # -------- two rounds: swap current / reference ---------------
        for round in 0:1
            if round == 1
                xcur = view(x, :, 1:isplit+1)
                xref = view(x, :, isplit+2:nchain)
                lprobcur = view(lprob, 1:isplit+1)
            else
                xcur = view(x, :, isplit+2:nchain)
                xref = view(x, :, 1:isplit+1)
                lprobcur = view(lprob, isplit+2:nchain)
            end
            cursz = size(xcur, 2)
            refsz = nchain - cursz + 1      # +1 for mod1 indexing

            # ---- differential evolution indices (in-place, no alloc)
            @inbounds for k = 1:cursz
                r1 = rand(rng, 1:cursz-1)
                r2 = rand(rng, 1:cursz-2)
                idx1[k] = k - 1 + r1
                idx2[k] = k - 1 + (r2 >= r1 ? r2 + 1 : r2)
            end

            # ---- base DE proposal  q = x_k + g0*(x_a - x_b) + ε
            randn!(rng, noise[1:cursz])
            @. noise[1:cursz] *= sigma
            q = view(qbuf, :, 1:cursz)

            @inbounds for k = 1:cursz
                a = mod1(idx1[k], refsz)
                b = mod1(idx2[k], refsz)
                @views q[:, k] .= xcur[:, k] .+ g0 * (xref[:, a] .- xref[:, b]) .+ noise[k]
            end

            # ---- AIMH proposals for a subset of chains --------------
            @inbounds for k = 1:cursz
                swapflg[k] = rand(rng, uni01) <= aimh_prob
            end
            nchg = count(swapflg)

            if nchg > 0
                # rebuild t-proposal with updated mean / cov
                try
                    dist = MvTDist(dft, cmean, ccov * (dft - 2) / dft + fixPSD)
                catch          # fallback if covariance not p.d.
                    dist = MvTDist(dft, cmean, I_ndim)
                end
                cand = rand(rng, dist, nchg)  # (ndim×nchg) *once*
                pos = 1
                @inbounds for k = 1:cursz
                    if swapflg[k]
                        @views q[:, k] .= cand[:, pos]
                        pos += 1
                        factor[k] = logpdf(dist, xcur[:, k]) - logpdf(dist, q[:, k])
                    else
                        factor[k] = 0.0
                    end
                end
            else
                fill!(factor, 0.0)
            end

            # ---- likelihood & Metropolis test -----------------------
            newlp[1:cursz] .= lprobFunc(q)    # in-place, no alloc

            @inbounds for k = 1:cursz
                if factor[k] + newlp[k] - lprobcur[k] >
                   log(rand(rng, uni01))
                    @views xcur[:, k] .= q[:, k]
                    lprobcur[k] = newlp[k]
                    nacc += 1
                end
            end
        end

        # --------- store trajectory ---------------------------------
        chains[it, :, :] .= permutedims(x, (2, 1))
        lprobs[it, :] .= lprob

        if progress
            set_description(iter,
                @sprintf("[ll %.3f | acc %2d%%]", maximum(lprob),
                    round(Int, 100nacc / nchain)))
        end
    end

    return chains, lprobs, dist
end


@doc raw"""
    CreateDIMETestFunc(ndim::Int, weight::Float, distance::Float, scale::Float)

Create a trimodal Gaussian mixture for testing.
"""
function CreateDIMETestFunc(ndim, weight, distance, scale)

    covm = I(ndim) * scale
    meanm = zeros(ndim)
    meanm[1] = distance

    lw1 = log(weight[1])
    lw2 = log(weight[2])
    lw3 = log(1 - weight[1] - weight[2])

    dist = MvNormal(zeros(ndim), covm)

    function TestLogProb(p)

        stack = cat(lw1 .+ logpdf(dist, p .+ meanm),
            lw2 .+ logpdf(dist, p),
            lw3 .+ logpdf(dist, p .- meanm),
            dims=2)
        return logsumexp(stack, dims=2)[:]

    end
end

@doc raw"""
    DIMETestFuncMarginalPDF(x::Array, cov_scale::Float, distance::Float, weight::Float)

Get the marginal PDF over the first dimension of the test distribution.
"""
function DIMETestFuncMarginalPDF(x, cov_scale, distance, weight)

    normd = Normal(0, sqrt(cov_scale))

    return weight[1] * pdf.(normd, x .+ distance) + weight[2] * pdf.(normd, x) + (1 - weight[1] - weight[2]) * pdf.(normd, x .- distance)
end

# end