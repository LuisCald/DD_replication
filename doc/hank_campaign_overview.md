# HANK validation campaign — what was tried, what it did, what transfers to the real data

Status as of 2026-09-19. Companion notes: `stochastic_trend_design.md`, `copula_identification.tex`,
`em_and_copula_factors.tex`, `em_rank_selection.tex`, `object_factors.tex`.

## 1. The yardsticks

* **Target cells**: `wealth_by_income` bot50 / mid40 / top10 (mean wealth of the bottom 50 %, middle 40 %,
  top 10 % of the *income* distribution, relative to mean wealth), for the PSID (a), SCF (d) and SIPP (e)
  replicas. Everything else (marginals, the other 15 conditional cells) was fine from the start.
* **Correlation with truth**, all quarters, on cells normalised by the truth's `<outcome>_per_hh`
  (this is what `plot_HANK` does; unnormalised correlations are trend-inflated to 80–100).
* **Exact test**: the same correlation restricted to the dataset's own observation dates
  (PSID 13, SCF 9, SIPP 100). Separates "the model does not use the survey" from "the model cannot
  interpolate between surveys".
* **Ceilings**. From the replica microdata at the observation dates: PSID 80/79/76 (all quarters
  87/82/49), SCF 96/94/93, SIPP 90/93/93. From the replica coefficients *in the model's basis*
  (order-11 Legendre marginals and copula, computed 2026-09-19 with `in_basis_cells.jl`):
  PSID 69/−11/−2, SCF 91/12/23, SIPP 87/18/25. The second ceiling is the binding one.

## 2. Timeline of attempts

Verdict column: what the HANK exercise showed. Transfer column: whether it is relevant for the empirical
estimation on real surveys.

### A. Dynamics and specification (2026-08-28 → 09-11)

| # | attempt | switch / code | what it changes | HANK verdict | transfers? |
|---|---|---|---|---|---|
| A1 | stochastic trend (S1–S6) | `HANK_TREND=stochastic`, `StochasticTrend.jl` | HP filter → collapsed random-walk trends τ with shrinkage λ | works; truth-vs-estimate fit ≥ HP; τ vs slow AR weakly identified at truth frequencies | **yes** — planned empirical spec |
| A2 | per-factor persistence | `HANK_PERS=per_factor` (" pf") | one ρ_j prior centre per factor instead of a shared ρ_F | shared ρ_F was pulled to ≈0.25 by income; pf splits it (0.14…0.98); best fit yet at the time | **yes** |
| A3 | stationarity cap | `stationarity_cap = 0.995` (joint [A B; C D]) | rejects explosive modes | 5f pf mode had |eig| = 1.38 (disguised trend); joint cap needed after `naf5` hid the explosion in the aggregate block | **yes** (empirical posteriors were stationary, so harmless) |
| A4 | fewer aggregate factors | `HANK_NAF=5` (" naf5") | 8 → 5 aggregate directions | fails informatively: distribution decouples from aggregates | no — keep MDD-selected count |
| A5 | trend shrinkage scale | `HANK_TLS=0.03` (" tls") | tighter λ prior on τ innovations | ψ locals defeat the squeeze; fit −2…−6 | no — keep 0.1 |
| A6 | factor count 8 / 6 / 5 | `HANK_NDF` | distributional factor count | judged on the target cells, which D4 later showed to be basis-limited — so the comparison is uninformative; on the reachable cells 6f beat 5f on the marginals by 5–10 pts and one factor died | **open**: redo on reachable cells; count via the live-factor rule (§4, item 8) |
| — | **HANK spec after A** | 5f + pf + joint cap 0.995 + tls 0.1 | | cells a ≈ 70/−2/15: bot50 fine, mid40/top10 ≈ 0 | |

### B. Copula information (2026-09-12 → 09-16)

Diagnosis at the time: loadings came from a 12-complete-column PCA (PSID only), the copula measurement
variance was one number broadcast over 1694 coefficients (a:copula multiplier 37), and the model's
implied income–wealth dependence was frozen (rel. sd 2 % vs truth 11 %).

| # | attempt | switch | what it changes | HANK verdict | transfers? |
|---|---|---|---|---|---|
| B1 | communality error weights | `HANK_COPERR=communality` (" cw") | copula coefficients with low PCA communality get more measurement noise | modest; notably the only EM-era-free run without PSID-wave blips (because it never changed the loadings) | superseded by D1 |
| B2 | EM loadings | `HANK_PCA=em` (" em") | PCA on the EM-completed pool instead of complete cases only | first non-zero mid40/top10 (a 26/35) but bot50 collapsed 70 → 20; income/consum −7…−9; **introduced the blips** | see B7, C1 |
| B3 | shocks in levels | `HANK_SHOCKS=levels` (" lvl") | stop ADF-differencing the HANK aggregate shocks | kept (the truth was generated from levels); confounded with B2 in the first run | HANK-only (empirical aggregates stay as they are) |
| B4 | copula factors, block-triangular | `HANK_NCF=k` (" ncfK"/tri) | k extra factors loading on copula rows only | no gain over em | no |
| B5 | block-diagonal loadings | `HANK_LOAD=block` (" blk") | separate projections for marginals and copula | **catastrophic**: marginal factors die (the Λ_cm information channel is deleted; §5 of `em_and_copula_factors.tex`) | no |
| B6 | integration grid 10 | `HANK_GRID=10` | finer quantile grid for panels | no effect on cells (cells are exact integrals; grid only affects panels and cache granularity) | n/a |
| B7 | EM rank cross-validation | `DD_EM_CV=1` | how many factors the completed pool supports | argmin 17, 1-SE 13; copula rows displace marginal rows around r = 9–10 | diagnostic only |
| B8 | EM unit-score bug | `em_unit_scores` (default on) | :em scores had sd ≈ 34 → Minnesota B/C priors 1000× off in every :em run | fixed; B2/B4/B5 verdicts carry this caveat | **yes** if :em is ever used |

### C. Loadings and dynamics (2026-09-16 → 09-18)

| # | attempt | switch | what it changes | HANK verdict | transfers? |
|---|---|---|---|---|---|
| C1 | Kalman-EM loadings | `HANK_PCA=kalman_em` + `run_kalman_em.jl` (" kem") | refine the 278 rows that SCF/SIPP/CEX also observe by E-step smoother / M-step regression, MAP-shrunk to the PCA loadings, damped | cheap look 40/32/50, 46/37/45, 51/31/53 (best pre-ridge); re-estimation 34/29/41, 43/42/46, 47/28/43; wealth-share marginals −7…−13 | **yes** — the empirical PSID is also 12 complete columns; run it once after D1 |
| C2 | 6 factors + kem | `HANK_NDF=6` | | worse cells, better marginals; factor count is not the lever | no |
| C3 | persistence counterfactual | `DD_PERSIST_TARGET=0.85` | shift A's diagonal at the mode, re-run reconstruction | cells unchanged, marginals −14; "more persistence" is not the cure | diagnostic only |
| C4 | object factors | `HANK_OBJF="3D:1@0.98,IW:1"`, `ObjectFactors.jl` | one AR(1) factor per object (3D copula, 2D slices, marginals) on top of the shared ones | 42/26/45, 49/37/48, 54/24/46 — modest; but run under the singular whitening (3D state pinned dead), so **not a fair test** | retest under D1 if a copula-specific channel is still wanted; drop the `@φ` fixing in favour of a common prior |

### D. Numerics and data construction (2026-09-18 → 09-19)

| # | finding | code | what it was | HANK effect | transfers? |
|---|---|---|---|---|---|
| D1 | **whitening singular** | `whitening_ridge` / `HANK_WRIDGE=0.05` (" wr0.05") | pre_multiply uses Σ̂^{-1/2} of a 1730×1730 bootstrap covariance; cond(Σ̂) PSID 9.4e19, CEX 4e10 → near-constant coefficients got ~infinite weight → with any non-PCA loadings the state was **pinned to 0 at every PSID wave** (the blips) | pin gone, blips gone, a:copula Σ 34 → 1.1, all five factors alive, marginals best of campaign (income 99/99), bot50 at PSID's own dates −26 → 74; mid40/top10 down to the in-basis ceiling | **must check**: run the empirical prep once and read `whitening <dataset>: cond(Σ̂)`; if ≳1e12 the published estimates need the ridge (or diagonal whitening) |
| D2 | `sd_scale` is dead code | `Reconstruction.jl` | HANK noise shortcut commented out; replicas take the ordinary bootstrap | none | none |
| D3 | **copula ranks unweighted** | `weighted_rankdata` in `DataConstructor.jl` | `rankdata/(n+1)` ignores survey weights; SCF replica (weight cv 0.79) put the sampled rich at the top of the rank axis → SCF wealth-by-income levels 0.68/1.07/2.37 vs truth 0.31/0.97/4.58 in every run | fixed (identical under uniform weights, PSID verified to the digit); SCF in-basis levels now right, income_by_wealth 100/98/100 | **yes, re-run needed**: the real SCF has the same list-sample oversample |
| D4 | **in-basis ceiling** | `in_basis_cells.jl` | cells from the replica coefficients before any estimation | wealth_by_income mid40/top10 do not survive the order-11 copula in any dataset; marginal truncation is harmless; copula order along the *wealth* rank axis is what matters (K = 30 → PSID 91/66/27, SCF 97/71/54, SIPP 87/51/61); tail-warping the rank axis does not help | decision item, §4 |

Correction to an earlier claim (2026-09-12): "truth cells are 73–83 % spanned by 5 PCs of the truth marginal
grids" was about the *grids*, not the polynomial basis. D4 shows the basis, not the factor count, is the
constraint for these two cells.

## 3. Results on the target cells

Correlation with truth, all quarters, wealth_by_income bot50 / mid40 / top10. SCF (d) numbers before D3
carry the rank bug (levels wrong, correlations partly spurious).

| configuration | a PSID | d SCF | e SIPP | notes |
|---|---|---|---|---|
| HANK spec (5f pf cap tls0.1, complete-case PCA) | 70 / −2 / 15 | — | — | benchmark; income 98–99 |
| em + lvl | 20 / 26 / 35 | 23 / 44 / 40 | 31 / 20 / 34 | bot50 collapsed; blips appear |
| kem cheap look (em+lvl mode, new Λ) | 40 / 32 / 50 | 46 / 37 / 45 | 51 / 31 / 53 | wealth-share marginals −7…−13 |
| kem re-estimation | 34 / 29 / 41 | 43 / 42 / 46 | 47 / 28 / 43 | a:copula Σ 34 |
| 6f em+lvl / 6f kem | 17 / 21 / 22 · 24 / 16 / 23 | 22 / 35 / 28 · 36 / 30 / 32 | 32 / 16 / 21 · 38 / 11 / 22 | |
| object factors (singular whitening) | 42 / 26 / 45 | 49 / 37 / 48 | 54 / 24 / 46 | 3 of 5 shared factors dead |
| **ridge 0.05, kem, re-estimated** | **43 / 8 / 30** | **49 / 16 / 30** | **53 / 5 / 31** | own dates a 74/−18/6; all other cells 64–100; income 99/99 |
| in-basis ceiling (own dates) | 69 / −11 / −2 | 91 / 12 / 23 | 87 / 18 / 25 | what any estimator in this basis can reach |
| microdata ceiling (own dates) | 80 / 79 / 76 | 96 / 94 / 93 | 90 / 93 / 93 | |

Reading: after D1 the model sits at the in-basis ceiling for the target cells and near the microdata
ceiling for everything else. The pre-ridge runs that showed mid40/top10 ≈ 30–45 did so with the state
pinned at PSID dates and the copula down-weighted 34×; those numbers were not evidence of the copula
being used.

## 4. Decisions

**Do now, both pipelines**

1. Sync `DataConstructor.jl` (D3) and run the empirical prep once. Read the `whitening <dataset>: cond(Σ̂)`
   lines (D1). Decide ridge (0.05) vs diagonal whitening (divide by own bootstrap sd, no inverse) — the
   diagonal variant is never singular and is a one-line change in `transform_DCT_boot`.
2. Re-run the empirical estimates with weighted ranks (+ ridge if needed). The SCF copula in the
   published estimates is biased toward the sampled rich; this is not optional.

**Carry over to the empirical spec**

3. Stochastic trend + per-factor persistence + joint stationarity cap (A1–A3). Already planned.
4. Kalman-EM loadings (C1), one pass after the ridge: the empirical PSID has the same 12-complete-column
   problem, and the whitening fix removes what made kem look mixed on HANK.

**Do not carry over**

5. Communality weights, copula factors, block-diagonal loadings, fewer aggregate factors, tighter trend
   shrinkage, 6 factors, mechanical persistence shifts (B1, B4, B5, A4, A5, C2, C3).

**Decide**

6. wealth_by_income mid40/top10. Unreachable at copula order 11. Reachable partly at order ≈30 along the
   wealth axis only (anisotropic K_W = 30, K_I = K_C = 12 → PSID's 3D block 4320 rows instead of 1331;
   SCF/SIPP slices 360 instead of 121). Alternatively state the limit and report the cells the basis
   carries. Recommendation: state the limit in the paper's HANK section; the cost is not worth two cells
   the PSID itself only reaches at 49/76.
7. Object factors (C4): retest once under the ridge only if a copula-specific persistence channel is
   still wanted after 6 is decided; replace `@φ` fixing with a common prior first.
8. **Factor count, systematically and in one run.** Distributional factors are not tied to the aggregate
   count (A is r×r, B r×q, C q×r; the only ceiling is the 12-complete-column PCA, clamped to 10, which EM
   lifts). Protocol: Bai–Ng ICp2 on the pool as the upper bound; estimate once at that count under the
   per-factor persistence prior; report the number of LIVE factors (innovation sd > 5 % of the median,
   `DD_DEAD_FRAC`). Surplus factors die (6f: one dead; object-factor run: three dead), so the single run
   is valid and the count is documented. Test whether the BBO stage alone already shows the collapse:
   `report_mode_dynamics` now prints the live count at the BBO candidate ("BBO point") and at the DIME
   mode — run 8 factors under the ridge and compare. If they agree, add the automatic two-stage driver
   (BBO at the upper bound → count → prep at the live count with loadings re-derived by PCA, not by
   deleting columns → full sampler).

## 5. Loose ends

* `run_kalman_em.jl` refuses `object_factors`; `DD_KEM_INIT=complete_cases` chain not built.
* `sd_scale` argument is dead — remove or revive.
* Likelihoods are not comparable across whitening matrices (missing log|det Σ̂^{-1/2}|) or integral grids.
* Panel R² for marginal *levels* in the CSV exports is meaningless (quantile levels vs quintile means); use
  the panels' own statistics.
