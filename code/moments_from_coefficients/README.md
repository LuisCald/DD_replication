# Moments from coefficients

A small, self-contained corner for people who have the published files in
[`../../data/synthetic/`](../../data/synthetic/) and want to compute **their
own moments, micro data, and posterior bands**. Everything here wraps the
canonical helpers (`code/julia/reconstruct.jl`, `code/python/reconstruct.py`);
nothing is re-implemented, so there is a single source of truth.

Scripts are named after the pipeline stage they implement:

```
factors  →  coefficients  →  moments / micro data
```

Julia is the primary language (matching the rest of the package); every script
has a Python twin that agrees to machine precision.

| Script (.jl / .py) | In → Out |
|---|---|
| `factors_to_coefficients` | smoothed factors → coefficient rows (`FactorMap`; counterfactual hook) |
| `coefficients_to_moments` | coefficient file → decile cut points + copula density |
| `coefficients_to_micro_data` | coefficient file → weighted synthetic cross-sections (the model's micro-data layout) |
| `posterior_bands` | factor draws → posterior band on any moment |
| `plot_factor_bands` | factor draws → factor paths with posterior bands |

## What you need

All inputs live in [`../../data/synthetic/`](../../data/synthetic/):

| File | Needed for | Ships in repo? |
|---|---|---|
| `*_coefficients_{normal,average}.csv` | moments, micro data | ✅ yes |
| `smoothed_factors.csv` | `FactorMap` (factors → coefficients) | ✅ yes |
| `smoothed_factor_draws.csv` | posterior bands | ✅ yes (400 draws, θ + state uncertainty) |
| `aggregate_anchors.csv` | scaling relative values to dollar levels | ✅ yes |

## 1. Moments (decile cut points, copula density)

```bash
julia --project=../julia/env coefficients_to_moments.jl                 # PSID, 2008-Q3
DATASET=SCF DATE=2020-Q3 julia --project=../julia/env coefficients_to_moments.jl
```

## 2. Synthetic micro data

```bash
julia --project=../julia/env coefficients_to_micro_data.jl              # all quarters
DATE=2008-Q3 julia --project=../julia/env coefficients_to_micro_data.jl # one quarter
```

Writes one weighted cross-section per quarter (1000 rows = 10³ decile-copula
cells) in the model pipeline's own layout — see the header of
[`coefficients_to_micro_data.jl`](coefficients_to_micro_data.jl) for the row
schema, how it mirrors `CreateTimeSeries.jl`/`construct_micro_dataset`, and
how to scale the relative values to dollar levels with
`aggregate_anchors.csv`. The pre-generated result for PSID ships as
[`../../data/synthetic/PSID_synthetic_microdata.csv`](../../data/synthetic/PSID_synthetic_microdata.csv).

## 3. Factors → coefficients (counterfactual hook)

```bash
julia --project=../julia/env factors_to_coefficients.jl
```

Fits `FactorMap` (exact on the `_average` files, median R² = 1.0) and writes
the reconstructed coefficient row for every date. In a session, perturb a
factor before predicting to build counterfactual distributions — example in
the file header.

## 4. Posterior bands on a moment

```bash
julia --project=../julia/env posterior_bands.jl              # wealth deciles, 2008-Q3
MEASURE=income DATE=2020-Q3 LO=0.10 HI=0.90 julia --project=../julia/env posterior_bands.jl
```

## 5. Plot the factors with posterior bands

```bash
julia --project=../julia/env plot_factor_bands.jl            # first 8 factors, 5–95%
N_FACTORS=12 LO=0.10 HI=0.90 julia --project=../julia/env plot_factor_bands.jl
```

## About the draws file

`smoothed_factor_draws.csv` stacks the smoothed factors over posterior draws
of the model parameters; by default each draw also includes **state
uncertainty** (a draw from the smoother's own `N(x̂_{t|T}, Σ_{t|T})`), so
pointwise bands reflect total uncertainty. The draws are marginal per quarter:
exact for pointwise bands and per-date moments (what these scripts compute),
not for joint cross-date statistics within a draw. Regenerate with
`code/julia/export_draws.jl` (`DD_N_DRAWS`, `DD_STATE_UNC`); the raw parameter
draws (`posterior_draws/*.jld2`, hundreds of MB) are not shipped.

## Units

All quantile/micro-data values are **relative to the per-household mean** of
that quarter. Multiply by the matching column of `aggregate_anchors.csv`
(`consum_per_hh`, `income_per_hh`, `wealth_per_hh`) for dollar levels;
`tot_hhs` converts per-household to aggregate totals. The stored marginal
coefficients are asinh-scale — the helpers apply the sinh back-transform, so
values you see are already in natural (relative) units.
