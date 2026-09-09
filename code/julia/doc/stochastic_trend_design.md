# Stochastic trends in the state space — design (S-tasks)

## Why

Today the reconstruction is `cycle + deterministic trend`. The trend is built in
`perform_detrending` (ModelPrep.jl ~L517): each dataset's coefficient series is
linearly interpolated across its observation dates and an HP(λ=1600) trend of
that interpolated series is removed; `Reconstruction.jl` ~L87 adds it back
("normal" = per-dataset time-varying trend → the paper's
`with_time_varying_trend` outputs; "average" = time-constant).

Consequences (established empirically, 2026-08-04, see transcript):

- Within a ±8q recession window, biennial PSID waves make nearly all
  wealth-conditioned movement wave-frequency, so the re-added trend carries
  58–100% of every headline recession-figure feature; the state-space cycle is
  nearly flat there.
- Mid-sample this is benign (trend ≈ interpolation of data; raw waves confirm
  dot-com and GFC features). At the sample end and in thin copula corners it
  is not: the Covid "asset-rich, low-income" (+20%) climb is 100% trend, and
  the raw 2019/2021 waves contradict it (flat) — HP endpoint bias on an
  interpolated series.
- The trend enters reconstruction with ZERO attributed uncertainty and is
  invisible to the information/interp-share decomposition.

## Target design

Move the trend into the state space so it is filtered, uncertainty-quantified,
and covered by the information decomposition.

State vector (per the existing split in `likeli`/`matrisize`, states =
[f_t (Ndim dist factors); a_t (Mdim agg factors)]):

    add τ_t (Ndim trend states):   τ_t = τ_{t-1} + η_t,   η_t ~ N(0, diag(ω_τ))

- Transition: A_aug = blkdiag(A, I_Ndim) — τ has no VAR dynamics, A untouched.
  Stationarity enforcement on A stays; persistence separation (RW vs
  stationary VAR) + a tight ω_τ prior identify the trend/cycle split.
- Measurement: coefficients load on (f_t + τ_t) with the SAME loadings Λ —
  G_aug duplicates the f-columns for τ. No new loadings parameters.
- New parameters: Ndim RW innovation variances ω_τ. Tight prior calibrated to
  wave-frequency movement (e.g. half-normal with scale s.t. 8-quarter trend
  drift matches the cross-wave sd of the detrended-vs-raw gap). Priors carry
  real weight here — document them.
- Data layer: skip HP detrending entirely. Keep per-dataset demeaning (means)
  and ADD per-dataset LINEAR drift removal (deterministic, 2 params/row,
  absorbs operationalization drift so the common τ is not asked to fit
  dataset-specific measurement trends). PCA for Λ runs on the linear-detrended
  pool.
- Reconstruction: smoothed (f+τ) flows through the existing paths; the trend
  re-add block in Reconstruction.jl is SKIPPED under this spec (only the
  linear alignment drift is re-added). Posterior draws then carry trend
  uncertainty; interp-share covers τ automatically.
- Initialization: τ_0 diffuse.

## Review verdict (adversarial agent, 2026-08-04, post-commit 4357529)

Augmentation math CONFIRMED (G layout, lyapd spectrum, st_likeli transform
chain, step-range strip all verified line-by-line). S3b plumbing REFUTED as
incomplete — remaining fixes, to land WITH S4 before lifting the gate:

- F1 (HIGH): trend priors are appended AFTER the hyperpriors, but
  DIMESampler.jl:19, run_estimation.jl:52, run_postestimation.jl:45,
  export_draws.jl:35 slice `hyperpriors = priors[end-5:end]` → they grab
  trend priors; positive-truncated dists meet hyper draws ≤ 0 → -Inf, else
  silently wrong posterior. Fix: st-aware hyper slice (priors[end-n_tr-5:end-n_tr])
  or insert the trend block BEFORE the hyper block everywhere consistently.
- F2 (HIGH): DIME init not plumbed — DIMESampler.jl:53 `par_final[end-5:end]`
  as hypers; SupportingFunctions.jl:280 `draw_from_prior` builds CORE-dim
  chains; DIMESampler.jl:60 broadcast crashes. Fix: st-aware draw_from_prior
  appending trend-prior draws + the hyper-slice fix.
- F4: run_postestimation.jl:160/:230 `matrisize(par_final[1:end-6], …)` —
  must strip end-(6+n_tr) when length(param_sizes)==9.
- F6: HyperparameterOptimization.jl:111 calls define_parameter_space directly
  then likeli → st_likeli strips a trend block that isn't there. Guard it.
- F8 (accepted modeling choice, documented): hierarchy evaluated on the
  softplus scale without Jacobian — valid MCMC target, slightly different
  prior than the stated one; revisit if pile-up behavior looks off at S5.
- FIXED same day: βs transposed (n×3 contract), thin-row detrending contract
  (1–2 obs rows now get constant/exact-line drift; no NaN add-back),
  :as_inputs guard in st_set_params.

## Status & staged tasks

- **S1 (LANDED): spec surface.** `ModelOptions.trend_spec::Symbol = :hp`
  (published baseline, default, bit-identical) vs `:stochastic`.
  `examples/Structures_stochastic_trend.jl` selects it. `estimation_prep`
  ERRORS on `:stochastic` until S3b–S4 land (no silent misbehavior).
- **S2 (LANDED, StochasticTrend.jl): data layer.** `st_perform_detrending` —
  per-dataset LINEAR alignment drift only (no HP); same return signature and
  `trend` container as `perform_detrending`, so the reconstruction add-back
  re-adds only the drift. Call-site shim at ModelPrep.jl ~L322 still pending
  (part of S3b wiring).
- **S3 core (LANDED, StochasticTrend.jl): state block WITHOUT forked filters.**
  τ folds into the factor block: f̃=[f;τ], Ã=blkdiag(A, ρ_τ I) with ρ_τ=0.999
  (near-RW so the recursions' internal `lyapd` init stays valid), B̃=[B;0],
  C̃=[C 0], Ω̃_f=blkdiag(Ω_f, diag(ω_τ²)); `st_augment_G` duplicates each lag
  block's f-columns for τ — the existing lag-chain makes annual observations
  EXACT (no within-year approximation). Verified by `st_selftest()`:
  ω_τ=0 reproduces the baseline `recurse_kalman_filter_forward` likelihood to
  machine precision; ω_τ>0 moves it.
- **S3b (LANDED, StochasticTrend.jl): parameter plumbing.** Trend block
  θ_tr=[ω_raw(r); ψ_raw(r); λ_raw] appended at the END of the parameter
  vector (`st_set_params`); global–local hierarchy ω_τ,j ~ N⁺(0,(λψ_j)²),
  ψ_j ~ C⁺(0,1), λ ~ C⁺(0, 0.1) evaluated explicitly in `st_likeli` (core
  blocks priored by the untouched baseline machinery; no transform Jacobians,
  consistent with the baseline's raw-coordinate prior evaluation). Dispatch:
  TWO 3-line guards only — top of `likeli` and `set_params` (Model.jl) —
  covering every call site (DIMES, MDD, forecasts, anatomy, draws); plus the
  S2 branch at the `perform_detrending` loop (ModelPrep ~L322). G̃ memoized
  (`st_G_cached`). UNVERIFIED: sampler-init block/prior alignment
  (`define_step_ranges`, DIMES init) for the appended trend block — check at
  S5 before lifting the estimation_prep gate.
- **S4: reconstruction & decomposition.** Skip HP re-add under `:stochastic`
  (Reconstruction.jl ~L73–90 + the twin/validation blocks), re-add linear
  drift instead; verify ObservationWeights/interp-share and PosteriorDraws
  paths see the τ states.
- **S5: validation.** `estimation_prep` dims; short-chain MCMC; the Covid
  purple case as acceptance test (expect: flat-ish path with honest bands,
  agreeing with raw 2019/2021 waves); HANK replica (truth has no
  operationalization drift → τ should stay near zero).

### S5 log

- **2026-08-28, smoke #1** (PSID+SCF, `:bai_ng` ⇒ 10 factors, 400 DIME
  iters). Chains plateau by ~200. Level reconstructions hug the raw waves and
  the DFA-cycle comparisons track — but the mode vector says the fit is
  carried by the CYCLE, not τ: Ω_f innovation sd 0.59–1.85 (baseline mode
  0.20–0.91), smoothed factors white-noise-like (AR(1) −0.17–0.45, sd(Δ) up
  to 2.3 vs ≤0.8 baseline), ±8σ swings at 2020Q2 and around the PSID 2021Q2
  wave (SCF-only 2020–21 spike in the level plots). Trend block sits on its
  prior (ω_τ≈0.05, ψ≈1, λ≈0.10): with annual/triennial waves and no quarterly
  survey, τ-vs-f is unidentified between waves, so the prior decides. Prior
  scale is sane — the baseline HP trend drifts 7.5–9.5% of a coefficient sd
  per quarter (median/p90 over 1730 PSID coefficients), i.e. ω≈0.08–0.10 in
  factor units; C⁺(0,0.1)·C⁺(0,1) covers it.
- Diagnosis is confounded: spec vs smoke config (10 factors from a
  rank-11 pool on a flat spectrum 7.5/7.2/5.8/5.7/5.3/4.9 past factor 4; no
  quarterly pins). Actions: `factor_selection = :fixed, n_dist_factors = 6`
  (new option) for both smoke examples; `examples/Structures_hp_control.jl`
  = same config under `:hp` to isolate the spec; `Reconstruction.jl` now
  persists `from_mcmc/data/smoothed_trends.csv`; `st_posterior_summary.jl`
  prints ω_τ/ψ/λ (+ chain quantiles from the .jld2) and τ-path diagnostics.
- Next: rerun stochastic (6 factors) + control; compare Ω_f, factor AR(1),
  Covid-window |z|. Covid-purple acceptance test only on the full-survey run
  (2020 is unobserved in the PSID+SCF config by construction).
- Same day: `ModelOptions.number_of_dfs` REMOVED (it was the max number of
  datasets, documented as the factor count — the source of the "why 2 / why
  SIPP warnings" confusion). Dataset count now comes from
  `length(df_vec.data)` (DataConstructor/ModelPrep) and, inside
  `apply_measurement_criteria`, from `(length(Σ_ids) − agg_count) ÷ (dim+1)`
  (unit-tested against the smoke layout). HANK replica under the new spec:
  `DD_EXAMPLE=HANK HANK_ECON=n HANK_TREND=stochastic` (tag " HANK n stochastic
  trend"; keeps the HANK pins Ndim=Mdim=8; replicas are never deseasoned, so
  no sigma grind). Expectation: truth has no operationalization drift ⇒ ω_τ
  shrink toward zero and truth-vs-estimate fit ≥ HP.
- **2026-08-29, HANK 1 stochastic (all 5 replicas) died at DIME 351/400
  after 13 h**: `DomainError` — `Normal(0, λ·ψ_j)` with NaN scale in the
  hierarchy log-prior. Cause: `sp(x)=log1p(exp(x))` is Inf beyond raw≈709 and
  exactly 0 below raw≈−745, so a far DIME proposal gave 0·Inf. Fix in
  `st_likeli`: overflow-safe softplus + reject (−1e12, alarm) any non-finite
  θ_tr / non-positive scale, mirroring the baseline's out-of-support path.
  Prep log of that run was clean: 8/8 factors (HANK pins), spectrum
  55/15.5/12/5/4.2/2.8/1.7/1.5, corr(f1, year)=0 after linear drift removal,
  381 params (trend block present).
- Added DIME checkpointing (`DIMES.jl` `checkpoint`/`checkpoint_every` kwargs;
  `DIMESampler.jl` writes `posterior_draws/<m_label>_<tag>_checkpoint.jld2`
  every 10 iterations, atomic tmp+rename). Relaunch with `DD_RESUME=1` to
  warm-restart from the live ensemble (skips BBO + prior draws). Toy-tested.
