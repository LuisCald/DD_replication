# HANK validation exercise

The paper's HANK exhibits (`tab:hank_avg_corr`, Figure `fig:hank_full_v_incomplete_income`)
estimate the model on survey-style samples drawn from a simulated HANK economy and compare the
estimates with the simulated truth. Three steps; all of them are needed for the paper's table.

## 1. Simulate the economies (BASEtoolbox)

The economy is the baseline two-asset HANK model of Bayer, Born and Luetticke in
[BASEtoolbox.jl](https://github.com/BASEforHANK/BASEtoolbox.jl). The simulations use commit
`dfb054246dc316cbc071d917ea76b400a9f0eda3` of the authors' fork (branch `gen_microdata`, which adds
the survey-replica export; Julia 1.10.4, its own `Manifest.toml`). That fork is not yet public;
the simulated economies are available from the authors on request.
Copy the drivers in this folder to `BASEtoolbox.jl/examples/baseline_micro/` and run from the
BASEtoolbox root:

```bash
julia +1.10.4 --project=. -t 32 examples/baseline_micro/generate_HANK_micro_production.jl
```

* `generate_HANK_micro_production.jl` — seed 1234, T = 2700 quarters (1200 burn-in, then 15
  chunks of 100 quarters). Chunks whose mean consumption turns non-positive are rejected (3 of 15
  with this seed); the first 10 good chunks are exported as economies 1–10:
  survey replicas `HANK_{PSID,CPS,CEX,SCF,SIPP}_N.csv` (samples A, B, C, D, E), the truth
  `HANK_truth_N.csv` (group means, 40/40/20 cross-conditional cells) and the shocks
  `HANK_shocks_economy_N.csv`, in `bld/baseline_micro_noestim/simulated_data/`.
* `generate_HANK_truth_x50.jl` — same seed and chunks, truth only, with 50/40/10
  cross-conditional groups (`simulated_data_x50/`), for the table's Top 10% rows (step 3b).

Copy the economy files into `2_Data_processing/` (`DATA_PROCESSING` in `code/julia/config.jl`; rename the x50 truth files to
`HANK_truth_x50_N.csv`). About 1.5 hours on 32 threads; 6.5 GB.

## 2. Estimate the model on each economy

```bash
DD_EXAMPLE=HANK HANK_ECON=N HANK_NDF=5 julia -t 18 --project=code/julia/env code/julia/run_estimation.jl
```

for N = 1, …, 10 (SLURM job arrays work well; about 45 minutes per economy). `HANK_NDF=5` fixes five distributional factors; the aggregate block uses eight factors.

## 3. Table and figure

### 3a. 40/40/20 table and figure

```bash
DD_EXAMPLE=HANK HANK_ECON=10 HANK_NDF=5 HANK_TABLE_ECONS=1-10 DD_FULL_RESULTS=0 \
  julia -t 16 --project=code/julia/env code/julia/run_postestimation.jl
```

writes `7_Results/consum_and_income_and_wealth HANK 1-10/plots/correlations/hank_avg_corr.tex`
(correlations with the truth, averaged over the 10 economies, from the correlation files each
economy's run in step 2 wrote). The figure panels are the economy-1 own-group plots
`from_mcmc/plots/<measure>/quantiles_levels/HANK {a,e} 1_<measure>_own_{bot40,mid40,top20}A non-diag_.pdf`;
`doc/figure10_404020.tex` assembles them.

### 3b. 50/40/10 rows (required)

The paper's table takes its Top 10% rows from a 50/40/10 version. It reuses the five-factor
estimates of step 2 (`DD_MODE_FROM`, no re-estimation) and needs the x50 truth files. Run
post-estimation for every economy, ending with economy 10:

```bash
for N in $(seq 1 10); do
  DD_EXAMPLE=HANK HANK_ECON=$N HANK_NDF=5 HANK_XSHARES=50 HANK_TRUTH_SUFFIX=_x50 \
  DD_MODE_FROM=" HANK $N 5 factors" HANK_TABLE_ECONS=1-10 DD_FULL_RESULTS=0 \
    julia -t 16 --project=code/julia/env code/julia/run_postestimation.jl
done
```

Economy 10 writes `7_Results/consum_and_income_and_wealth HANK 1-10 x50/plots/correlations/hank_avg_corr.tex`.
The paper merges its Top 10% rows into the 40/40/20 table of step 3a.
