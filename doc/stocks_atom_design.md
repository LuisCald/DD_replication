# Semicontinuous components (point mass at zero): design note

**Status:** design + scaffolding landed; estimation-core implementation in progress.
**Scope:** lets the state-space model handle a balance-sheet component with a
non-negligible mass of households at exactly zero (stocks, business equity, most
debt categories), so we can produce DFA-style series for `(income, wealth, component)`
including the component's distribution *by* income group and *by* wealth group.

This implements the method in Appendix `local_linear.tex`, §"Treatment of
non-Differentiability of the Marginal", and resolves the copula question that
appendix leaves open. The copula choice below is **route b** (population
marginals, copula split by participation), chosen 2026.

---

## 1. The problem

The published estimator models each measure `m` as a continuous quantile
function `Ξ⁻¹_{m,t}(u)` (Legendre series, orders 0–11) and links measures with a
copula `κ` on the trimmed cube `[ε,1-ε]^d`. Both assume a continuous marginal.

For a component like equities, a large fraction `π_t` of households hold exactly
zero. The marginal is then semicontinuous: a flat segment pinned at 0 on
`u ∈ [0, π_t]`, then a continuous rise for `u > π_t`. A low-order polynomial
cannot represent "exactly 0 on a long flat stretch, then a kink" — it oscillates
and smears the kink. And `π_t` itself (the participation rate) is an economic
object that moves over the cycle.

## 2. Marginal: two-part / hurdle (per appendix)

Let `Z_{mt}` be the (aggregate-scaled) component and `π_{mt} = P_t(Z=0)`.

- CDF mixture: `Ξ^Z = π·1{z≥0} + (1-π)·Ξ^{Z,c}`, where `Ξ^{Z,c}` is the CDF
  conditional on `Z>0`.
- Unconditional quantile:
  ```
  Ξ^{Z,-1}_t(u) = 0,                                     u ≤ π_t
                = Ξ^{Z,c,-1}_t( (u-π_t)/(1-π_t) ),       u > π_t
  ```
- The asinh transform `T` used in the paper has `T(0)=0`, so the decomposition
  carries over to transformed space verbatim.

**Estimation (two steps):**
1. `π̂_{mt} = Σ_i s_{it}·1{Z=0} / Σ_i s_{it}` (weighted zero share).
2. On `Z>0` only, asinh-transform and fit the *same* Legendre expansion using
   conditional ranks within the positive subsample → `ξ^{c}_{mot}`.

`π̂_{mt}` is carried as **one additional scalar coefficient** alongside the
Legendre coefficients and rides PCA → factors → Kalman on the same footing.
Because `π ∈ [0,1]` while all other coefficients are unbounded, we carry
`logit(π̂)` (option `participation_link = :logit`) so Gaussian measurement error
and AR state dynamics make sense and reconstructed `π_t` stays in `[0,1]`.

## 3. Copula: participation-split (route b)

Let `D = 1{S>0}`. The joint factors into two groups glued by `π_t`:

```
f_t(Y,W,S) = π_t · f_t(Y,W | S=0) · δ₀(S)        (non-holders)
           + (1-π_t) · f_t(Y,W,S | S>0)          (holders)
```

**Route b = keep population Y,W marginals; split only the copula.** Compute copula
ranks `u_Y=F_Y(Y), u_W=F_W(W)` over *everyone*; selection then shows up as
non-holders concentrating in the low-rank corner.

Objects actually estimated (per measure-time):

| Object            | What                                   | Informed by              |
|-------------------|----------------------------------------|--------------------------|
| `ξ_Y`, `ξ_W`      | population marginals (unchanged)       | all datasets             |
| `ξ_S^cond` + `π`  | mixed stocks marginal (§2)             | stock datasets           |
| `κ^{YW}`          | **population** (Y,W) copula            | all datasets, incl. CEX  |
| `κ^{YWS}`         | **holder** trivariate copula (S>0)     | stock datasets only      |

The non-holder (Y,W) copula needed at reconstruction is **derived**, not
estimated, from the consistency identity:

```
κ^{YW,0}_t = ( κ^{YW}_t − (1-π_t)·κ^{YWS}_t|_{YW} ) / π_t
```

where `κ^{YWS}|_{YW}` is the (Y,W) marginal of the holder trivariate.

**Why carry `κ^{YW}` separately** (and pay an extra measurement error for it):
it lets stock-blind surveys (CEX, CPS observe Y/W but not S) load *linearly* on
`κ^{YW}`, preserving the linear-Gaussian smoother. The alternative (derive
`κ^{YW}` from `π, κ^{YWS}`) forces a nonlinear observation equation. Cost: the
identity above holds only up to measurement error — acceptable, and consistent
with how the paper already treats mixed-frequency / partially-observed objects.

**Observation map:** SCF/PSID/SIPP → all six objects; CEX/CPS → `ξ_Y, ξ_W, κ^{YW}`
only (auto-detected via `non_missing_cols`).

## 4. Reconstruction

At `(u_Y, u_W, u_S)`:
- `u_S ≤ π_t`: stocks = 0; dependence from `κ^{YW,0}_t` (identity above).
- `u_S > π_t`: rescale `u_S' = (u_S-π_t)/(1-π_t)`, evaluate `κ^{YWS}_t`, value
  from `ξ_S^cond`.

DFA component outputs (component by income group, by wealth group) consume this
reassembled mixture. Sanity checks to add: `π_t ∈ [0,1]`, reconstructed slab mass
≈ `π_t`, identity residual small.

## 5. Bonus outputs

`π_t` (participation dynamics) and the holder-vs-non-holder (Y,W) dependence are
first-class results: stock-market participation over the cycle, and who
participates by income/wealth.

---

## 6. Implementation map (file : where)

- **`Structures.jl`** — `atom_measures::Vector{String}` and
  `participation_link::Symbol` added to `ModelOptions`; `examples/` selection via
  `DD_EXAMPLE`. *(done)*
- **`examples/Structures_stocks.jl`** — `(income, wealth, stocks)` variant with
  `atom_measures=["stocks"]`. *(done)*
- **`DataConstructor.jl`**
  - `treat_quantile_functions` (~L1126) / `series_estimator` (~L1167): for atom
    measures, split `π̂`, fit on positives, append `logit(π̂)`. Block length for
    that marginal becomes `grid_pcf + 1`.
  - `series_approximate_copula` / `get_copulas` (~L703–836) and `copula_case`
    (~L936): build `κ^{YW}` on all, `κ^{YWS}` on the positive-stocks subsample;
    add the second copula block to the per-period coefficient vector.
  - copula rank construction (~L799, `rankdata`): tie-handling for the atom is
    sidestepped by the split (holders fit on positive ranks).
- **`ModelPrep.jl`** — measurement-vector / selection-matrix assembly must know
  the atom marginal is `+1` long and that there are two copula blocks.
- **PCA / standardization block layout** (`reconstruct.jl`, `reconstruct.py`,
  `DataConstructor.jl:~1327`) — block slicing currently assumes "copula + D
  marginals each of `grid_pcf`"; generalize.
- **`Reconstruction.jl` / `CreateTimeSeries.jl`** — mixture reassembly (§4) and
  DFA component outputs.

## 7. Data prerequisite

None of the estimation paths can be exercised until the cleaning stage adds a
`stocks` column (same name across PSID/SCF/SIPP) and a `stocks_per_hh` aggregate.
Until then, `atom_measures=[]` (default) keeps the published pipeline byte-identical.

## 8. Open items / to verify against the appendix

- Confirm the appendix's intended treatment of the copula (it specifies only the
  marginal); document route b as the chosen extension in the paper.
- Decide whether `κ^{YW}` and `κ^{YWS}` redundancy needs any soft identity
  penalty, or whether measurement error alone is fine (current plan: the latter).
