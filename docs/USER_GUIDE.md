# User guide

This package supports three kinds of users. Pick the lane that matches what you want:

| Lane | You want… | Start here |
|---|---|---|
| 1 | The published quarterly distributional data — straight off the shelf | [§ 1](#1-just-the-data) |
| 2 | Custom moments (quantiles, copula density, counterfactual factor values) computed from the published coefficients | [§ 2](#2-compute-custom-moments-from-coefficients) |
| 3 | To re-run the model with your own settings (different tag, factor count, muted waves, etc.) | [§ 3](#3-run-the-model-yourself) |

---

## 1. Just the data

Every CSV in [`data/synthetic/`](../data/synthetic/) is quarterly **1962-Q3 → 2024-Q1**, joint over consumption, income, and wealth. See [`data/synthetic/README.md`](../data/synthetic/README.md) for column-by-column documentation. The two most useful files for a quick start:

```python
import pandas as pd

# 43 latent factors F_t — most compact summary of the joint dynamics
F = pd.read_csv("data/synthetic/smoothed_factors.csv", index_col="time")

# Reconstructed PSID coefficients (in-sample, HP-trend conventions)
psid = pd.read_csv("data/synthetic/PSID_coefficients_normal.csv", index_col="time")
```

**Trend convention.** Files named `_normal` re-add the HP-filter trend (date-anchored, use inside 1962–2024). Files named `_average` re-add the time-averaged trend (extrapolation-friendly).

**Functional data vs coefficients.** `*_functional_data*.csv` are *inputs* to the state-space model (per-dataset $\hat\phi^j_t$, NaN where the survey wasn't run). `*_coefficients_*.csv` are *outputs* (Kalman-smoother reconstructions, dense across all 248 quarters).

---

## 2. Compute custom moments from coefficients

The published coefficient files store Legendre polynomial weights. To turn them into moments you can plot (decile means, copula densities at arbitrary points, etc.), use the small standalone helpers shipped with the repo:

* Python: [`code/python/reconstruct.py`](../code/python/reconstruct.py) — needs only `numpy` + `pandas`
* Julia: [`code/julia/reconstruct.jl`](../code/julia/reconstruct.jl) — needs only `CSV.jl` + `DataFrames.jl`

Both implement the same orthonormal Legendre basis $Q_o(u) = \sqrt{2o+1}\,P_o(2u-1)$ and agree to machine precision.

For ready-to-run demos (point-estimate moments **and** posterior bands), see the self-contained folder [`code/moments_from_coefficients/`](../code/moments_from_coefficients/) — Julia-first, with a Python twin.

### Marginal quantile function

```python
from reconstruct import Reconstruction
r = Reconstruction("data/synthetic/PSID_coefficients_normal.csv")
r.quantile_at("2008-Q3", "consum", [0.1, 0.5, 0.9])
# → array([0.325, 0.802, 1.874])    (relative to per-HH mean)
```

```julia
using .DistributionalReconstruction
r = Reconstruction("data/synthetic/PSID_coefficients_normal.csv")
quantile_at(r, "2008-Q3", :consum, [0.1, 0.5, 0.9])
```

### Copula density

```python
r.copula_density_at("2008-Q3", 0.5, 0.5, 0.5)        # density at the joint median
r.copula_density_grid("2008-Q3", n=30)               # 30³ grid for plotting
r.copula_pmf_grid("2008-Q3")                         # 10³ probability masses (matches the published ciw_*)
```

### Factor → coefficient mapping (`FactorMap`)

`FactorMap` builds the map between smoothed factors and a coefficient row directly from the public CSVs — no model export needed. It's a port of `dis_data_rep == "smoothed_factors_dd"` in [`Distributional_Counterfactuals/5_Code/SupportPrepData.jl`](https://github.com/LuisCald/Distributional_Counterfactuals). What it does:

1. Drop rows where any coefficient is NaN.
2. Block-standardize the coefficient matrix — one std for the copula block, one per marginal — matching the model's own object-level standardization.
3. From `smoothed_factors.csv`, build the 4-quarter average $F^{4q}_t = (F_t + F_{t-1} + F_{t-2} + F_{t-3}) / 4$ using columns `x1..x32`. This mirrors how $G_j$ averages factors for annual datasets like PSID/SCF in the state-space model.
4. OLS-fit $\widehat{\Lambda}$ on the standardized coefficients regressed on $F^{4q}_t$ (intercept + factors).

Prediction is then

$$\text{coef}_t = (\alpha + \widehat{\Lambda} \cdot F^{4q}_t) \odot \text{stds}_{\text{block}} + \text{means}$$

**Use the `_coefficients_average.csv` variant.** It carries only a constant trend per coefficient (the time-mean of the HP trend), which gets fully absorbed by the OLS intercept α — so the smoothed factors reconstruct the coefficient row exactly. On the current PSID data this gives **median R² = 1.000** across all 1 730 coefficients with no dropped rows:

```python
from reconstruct import FactorMap

fm = FactorMap(
    "data/synthetic/PSID_coefficients_average.csv",
    "data/synthetic/smoothed_factors.csv",
    n_factors=8,
)
print(fm.summary())
# FactorMap: K=8, T_used=247 (dropped 0 NaN rows of 247),
#   R² median=1.000, R² P25/P75=(1.000, 1.000)

# Historical factor at a date — returns the 4q-average (the OLS input shape)
F = fm.factors_at("2008-Q3")              # shape (8,)
F_cf = F.copy(); F_cf[0] += 1.0           # counterfactual: factor 1 +1 unit
fm.quantile_at(F_cf, "consum", [0.1, 0.5, 0.9])
fm.copula_density_at(F_cf, 0.5, 0.5, 0.5)
```

`factors_at(date, kind="t")` returns the current-period factor `x1..x_K` if you want to perturb just $F_t$ and synthesize lags yourself.

Fitting on `_coefficients_normal.csv` (HP trend re-added per date) is **discouraged** — the time-varying trend isn't a linear function of the factors, so R² drops to ~0.4 and many rows are lost to NaN where the underlying survey doesn't observe the measure.

The Julia API is the same:

```julia
fm = FactorMap(
    "data/synthetic/PSID_coefficients_average.csv",
    "data/synthetic/smoothed_factors.csv";
    n_factors = 8,
)
println(DistributionalReconstruction.summary(fm))

F = factors_at(fm, "2008-Q3")
F[1] += 1.0
quantile_at(fm, F, :consum, [0.1, 0.5, 0.9])
copula_density_at(fm, F, 0.5, 0.5, 0.5)
```

### Posterior bands on a moment

`smoothed_factors.csv` is the posterior mode. `smoothed_factor_draws.csv`
stacks the smoothed factors over posterior draws of the model parameters, so
pushing each draw through `FactorMap` turns any moment into a posterior
distribution. The drop-in scripts do this for you:

```bash
# posterior band on a marginal (default: wealth deciles, 2008-Q3)
julia --project=code/julia/env code/moments_from_coefficients/posterior_bands.jl

# plot the factors themselves with their bands
julia --project=code/julia/env code/moments_from_coefficients/plot_factor_bands.jl
```

Don't have `smoothed_factor_draws.csv` yet? Generate it from the Stage-2 DIME
output (on the estimation machine):

```bash
julia --project=code/julia/env code/julia/export_draws.jl   # DD_N_DRAWS controls the count
```

The raw parameter draws (`posterior_draws/*.jld2`) are hundreds of MB and not
shipped; the compact factor draws carry the same uncertainty downstream.

---

## 3. Run the model yourself

The entry points are:

```bash
bash master.sh data        # Stage 1: clean raw survey data (~1 h)
bash master.sh estimate    # Stage 2: MCMC estimation (~48–72 h)
bash master.sh results     # Stage 3: post-estimation, figures, tables (~3 h)
```

The single file you actually edit when configuring a new run is [`code/julia/Structures.jl`](../code/julia/Structures.jl) — specifically the [`ModelOptions`](../code/julia/Structures.jl) struct. Its docstring lists every field; the seven you'll touch in practice are:

| Field | What it controls | Typical change |
|---|---|---|
| `tag` | Result-folder suffix | `" my_experiment"` (leading space) — outputs go to `7_Results/<m_label><tag>/...` |
| `measures` | Which household variables to model jointly | Always `["consum", "income", "wealth"]` in the paper |
| `number_of_dfs` | # of distributional factors retained from PCA | Default `8` (~99% of business-cycle variation) |
| `lags` / `agg_lags` | AR depth of states and aggregate factors | Defaults `1` / `4` |
| `blind_to` | Mute a measure in a specific survey | `Dict("CEX" => ["wealth"])` etc. |
| `data_to_mute` | Drop survey waves entirely (validation experiments) | `Dict("SCF" => muted_quarters_between(QuarterlyDate(2004,1), QuarterlyDate(2009,4)))` |
| `estimator` | `SeriesEstimator` polynomial order / output grid | `SeriesEstimator(grid_pcf=14, grid_cop=14, …)` for higher-order |

The block of comments immediately below `ModelOptions` lists tag conventions used in the paper's validation runs (e.g., `" excluding housing cycle wealth"`, `" every 4 years"`, `" 6 factors"`), with the matching `data_to_mute` recipes. Use them as templates.

### Output layout for a fresh tag

When you bump `tag` to something new, the pipeline writes to a brand-new tree (the `mkpath` calls scattered through the post-estimation code ensure every subfolder is created on first write):

```
7_Results/
└── consum_and_income_and_wealth<tag>/
    ├── from_mcmc/
    │   ├── data/        ← *_coefficients_*.csv, smoothed_factors.csv, *_functional_data*.csv
    │   ├── plots/       ← quantile / copula plots + correlation tables
    │   └── bayesian_convergence/
    └── other_results/    ← counterfactuals, raw data, likelihood diagnostics
```

### Sanity checks before kicking off

* `model_options.tag` is new (won't collide with old results)
* If you set `compare_to_other_est = true`, the baseline run with the comparison tag must already exist
* `data_to_mute` keys match an actual dataset name in `obs_data.files`

When the run finishes, drop the newly generated `*_coefficients_*.csv`, `*_functional_data*.csv`, and `smoothed_factors.csv` into `data/synthetic/` (overwriting the previous publication) and re-run the validation in [`code/python/validate_reconstruction.py`](../code/python/validate_reconstruction.py) to confirm coherence between the coefficient and functional-data outputs.
