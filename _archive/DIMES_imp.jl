using LinearAlgebra
using Statistics
using StatsFuns: logsumexp, logaddexp
using Distributions
# using ProgressBars   # optional; comment out if not used

"""
RunDIME(lprobFunc, init, niter; sigma=1e-5, gamma=nothing,
        aimh_prob=0.1, df_proposal_dist=10, delta=.999, progress=true)

Optimized rewrite:
- preallocations and @views to minimize allocations
- in-place covariance via BLAS
- rebuild AIMH proposal only if used in a step
- uses current lprob vector in ensemble weighting

Arguments:
- lprobFunc(X) :: returns a Vector{<:Real} of log probabilities for the columns of X
- init :: AbstractMatrix{<:Real} of size (ndim, nchain)
- niter :: Int number of iterations
"""
function RunDIME(lprobFunc::Function,
    init::AbstractMatrix{<:Real},
    niter::Integer;
    sigma::Float64=1e-5,
    gamma::Union{Nothing,Float64}=nothing,
    aimh_prob::Float64=0.1,
    df_proposal_dist::Int=10,
    delta::Float64=0.999,
    progress::Bool=true)

    # --- dimensions and basic constants
    ndim = size(init, 1)
    nchain = size(init, 2)
    @assert nchain ≥ 3 "Need at least 3 chains for differential-evolution proposals."

    isplit = nchain ÷ 2
    max_cursize = max(isplit + 1, nchain - isplit)  # max size of 'current' block

    γ = isnothing(gamma) ? 2.38 / sqrt(2.0 * ndim) : gamma
    dft = df_proposal_dist

    # fix for PSD issues in MvTDist
    fixPSD = Matrix(1e-16I, ndim, ndim)

    # --- mutable state
    x = Array{Float64}(undef, ndim, nchain)
    @views x .= init

    # current log-probabilities for each chain (1 vector per ensemble)
    lprob = lprobFunc(x)::AbstractVector{<:Real}
    lprob = collect(float.(lprob))  # ensure Vector{Float64}

    # split views (will be reassigned each round)
    xref = @view x[:, 1:isplit+1]
    xcur = @view x[:, isplit+1:end]

    # --- storage (preallocate and reuse)
    lprobs = zeros(Float64, niter, nchain)
    chains = zeros(Float64, niter, nchain, ndim)

    # temporaries for proposals
    q = zeros(Float64, ndim, max_cursize)   # proposals for current block
    fnoise = zeros(Float64, ndim, max_cursize)   # small Gaussian noise
    factors = zeros(Float64, max_cursize)         # MH correction for AIMH steps
    lnpdiff = zeros(Float64, max_cursize)
    u = zeros(Float64, max_cursize)         # uniforms

    i1 = Vector{Int}(undef, max_cursize)
    i2 = Vector{Int}(undef, max_cursize)

    mask_aimh = falses(max_cursize)  # which columns get AIMH proposals
    mask_accepted = falses(max_cursize)  # acceptance mask for MH step

    # running mixture stats for AIMH proposal
    ccov = Matrix{Float64}(I, ndim, ndim)
    local_cov = Matrix{Float64}(I, ndim, ndim)  # for AIMH proposal
    cmean = zeros(Float64, ndim)
    cumlweight = -Inf

    # mean/covariance temporaries
    nmean = zeros(Float64, ndim)
    xc = zeros(Float64, ndim, nchain)   # centered ensemble
    ncov = zeros(Float64, ndim, ndim)

    # proposal distribution placeholder (rebuilt only if AIMH used)
    dist = MvTDist(dft, cmean, ccov + fixPSD)

    # acceptance in previous iteration (for ensemble weighting); start with full
    acc_prev = nchain

    # optional progress iterator
    iter_rng = 1:niter
    # iter = progress ? ProgressBar(iter_rng) : iter_rng
    iter = iter_rng  # comment the above and uncomment ProgressBar if using it

    @inbounds for i in iter

        # --- ensemble weight using current lprob (not entire history)
        lweight = logsumexp(lprob) + log(acc_prev) - log(nchain)

        # --- compute ensemble mean and covariance efficiently
        # nmean = mean(x, dims=2) but allocation-free:
        @views @. nmean = sum(x, dims=2) / nchain
        @views xc .= x .- nmean             # broadcast centers each column by nmean
        mul!(ncov, xc, transpose(xc))       # ncov = xc * xc'
        ncov .*= 1.0 / (nchain - 1)

        # --- update AIMH mixture moments with log-weights
        newcumlweight = logaddexp(cumlweight, lweight)
        statelweight = cumlweight - newcumlweight

        w_old = exp(statelweight)
        w_new = exp(lweight - newcumlweight)

        @. ccov = w_old * ccov + w_new * ncov
        @. cmean = w_old * cmean + w_new * nmean
        cumlweight = newcumlweight + log(delta)

        naccepted_total = 0

        # --- two passes: swap roles of current and reference blocks
        for round2 in (false, true)
            if round2
                xcur = @view x[:, 1:isplit+1]
                xref = @view x[:, isplit+1:end]
                lprobcur = @view lprob[1:isplit+1]
            else
                xref = @view x[:, 1:isplit+1]
                xcur = @view x[:, isplit+1:end]
                lprobcur = @view lprob[isplit+1:end]
            end

            cursize = size(xcur, 2)
            refsize = size(xref, 2)

            # --- draw differential-evolution pair indices in place
            for (kp, k) in enumerate(1:cursize)
                i1k = kp + rand(1:refsize)
                i2k = kp + rand(1:refsize-1)
                i2k = (i2k ≥ i1k) ? i2k + 1 : i2k
                i1[k] = i1k
                i2[k] = i2k
            end

            # --- small Gaussian noise
            @views fnoise[:, 1:cursize] .= sigma * rand(Normal(0, 1), (1, cursize))

            # --- build DE proposals column by column (no big gather allocations)
            for k in 1:cursize
                @views q[:, k] .= xcur[:, k] .+
                                  γ .* (xref[:, i1[k]] .- xref[:, i2[k]]) .+
                                  fnoise[:, k]
            end

            # --- AIMH replacement for a subset of columns
            # rand!(view(u, 1:cursize))
            @views mask_aimh[1:cursize] .= rand(Uniform(0, 1), cursize) .<= aimh_prob

            if any(@view mask_aimh[1:cursize])
                # rebuild proposal only if needed this pass
                # scale ccov for Student-t parameterization
                local_cov .= ccov * (dft - 2) / dft .+ fixPSD
                local_dist = try
                    MvTDist(dft, cmean, local_cov)
                catch
                    MvTDist(dft, cmean, I)   # fallback if covariance goes bad
                end

                # draw replacements and compute proposal densities
                kidx = findall(@view mask_aimh[1:cursize])
                kc = length(kidx)

                # candidate draws
                xcand = rand(local_dist, kc)  # (ndim, kc)

                # log proposal densities for old and new
                lprop_old = logpdf(local_dist, @view xcur[:, kidx])
                lprop_new = logpdf(local_dist, xcand)

                # update q and factors on AIMH positions
                for (j, col) in enumerate(kidx)
                    @views q[:, col] .= xcand[:, j]
                    factors[col] = lprop_old[j] - lprop_new[j]
                end
            else
                fill!(view(factors, 1:cursize), 0.0)
            end

            # --- evaluate target at proposals (vectorized over columns)
            newlprob = lprobFunc(@view q[:, 1:cursize])
            @views lnpdiff[1:cursize] .= factors[1:cursize] .+ newlprob .- lprobcur

            # --- MH accept/reject
            # rand!(view(u, 1:cursize))
            @views mask_accepted[1:cursize] .= lnpdiff[1:cursize] .> log.(rand(Uniform(0, 1), cursize))

            # apply accepts
            for k in 1:cursize
                if mask_accepted[k]
                    @views xcur[:, k] .= q[:, k]
                    lprobcur[k] = newlprob[k]
                end
            end

            naccepted_total += count(@view mask_accepted[1:cursize])
        end

        # --- store and update acceptance for next iteration's weight
        chains[i, :, :] .= permutedims(x, (2, 1))
        lprobs[i, :] .= lprob
        acc_prev = naccepted_total

        # --- (optional) progress text
        # if progress
        # replace this with ProgressBars if you use it; here a light printf:
        println(@sprintf("iter %d | max ll: %7.3f | acc: %3.0f%%", i, maximum(lprob), 100naccepted_total / nchain))
        # end
    end

    return chains, lprobs, dist
end
