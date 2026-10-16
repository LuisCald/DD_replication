# Processed inputs

These are the household-level survey files and the two aggregate workbooks that the estimation
reads (`ModelOptions` data sources and `retrieve_aggregate_data` / `retrieve_rgdp` in
`code/julia/Structures.jl`). Stage 1 (`bash master.sh data`) produces them. The survey files
are gzipped CSV.

| File | Source | Coverage |
|---|---|---|
| `SCF.csv.gz` | SCF: Fed public files 1989–2022 and SCF+ waves before 1989, with the Forbes 400 | 1950–2022 (the estimation uses 1962–2022) |
| `PSID.csv.gz` | Panel Study of Income Dynamics | 1968–2021; wealth from 1984, consumption from 1999 |
| `CEX.csv.gz` | Consumer Expenditure Survey, Interview Survey | 1984–2021 |
| `CPS.csv.gz` | CPS ASEC (IPUMS) | income years 1993–2022 (ASEC 1994–2023) |
| `CPS2.csv.gz` | CPS ASEC (IPUMS) | income years 1967–1992 (ASEC 1968–1993) |
| `SIPP1.csv.gz` | SIPP panels 1984–1993 | 1983–1995 |
| `SIPP2.csv.gz` | SIPP panels 1996–2008 | 1996–2012 |
| `SIPP3.csv.gz` | SIPP 2014 panel and 2018–2023 releases | 2013–2022 |
| `aggregates_HHs_NPs.xlsx` | FRED, FRED-QD and Financial Accounts (Z.1) series, levels and stationary transformations (sheet `stationary_series_infl` for the replication spec) | quarterly |
| `inflation_corrected_correction_series.xlsx` | per-household aggregate anchors (`income_per_hh`, `wealth_per_hh`, `consum_per_hh`, item anchors, `tot_hhs`) from `code/stata/import_aggregates.do` | quarterly |

## Variables

Column names as they appear in each file header:

- `SCF`: year, income, id, hhequiv, impnum, quarter, wealth, assets, finast, illiqd, liquid, tdebt, pdebt, hdebt, stocks, real_estate, business, pension, vehicles, weight
- `PSID`: id, weight, income, wealth, consum, consum_nore, assets, finast, illiqd, liquid, tdebt, pdebt, hdebt, hhequiv, stocks, real_estate, business, year, quarter
- `CEX`: id, year, quarter, weight, income, consum, nore_consumption, finast, liquid, pdebt, hdebt, hhequiv
- `CPS`, `CPS2`: id, year, quarter, weight, income, strata
- `SIPP1`, `SIPP2`: year, quarter, id, assets, undebt, scdebt, tdebt, weight, income, wealth, mgdebt, qdate
- `SIPP3`: year, quarter, id, assets, undebt, scdebt, tdebt, weight, income, wealth, mgdebt

Abbreviations: `finast` = financial assets, `illiqd` = illiquid assets, `tdebt` / `pdebt` /
`hdebt` = total / personal (non-mortgage) / housing debt, `undebt` / `scdebt` = unsecured /
secured debt, `mgdebt` = mortgage debt, `hhequiv` = household equivalence scale, `impnum` =
SCF implicate (1–5), `strata` = CPS stratum.

## Conventions

- **Units:** 2019Q4 US dollars, deflated with the CPI-U (FRED `CPIAUCSL`, 2019-10-01 = 100).
  Income is pre-tax household income including transfers.
- **Weights:** survey weights. In the SCF every household appears once per implicate (five
  rows), and each row's weight is in thousands of households per implicate. Note: in this
  file the 2022 wave is still in households, not thousands (see `code/stata/data_cleaning.do`,
  which now rescales it).
- **Missing values:** the PSID uses `NaN` (empty in the `consum_nore` column). All other
  files use empty fields.
- **`quarter`:** the assigned interview quarter (1–4). CPS income is dated to Q4 of the income
  year, and post-2013 SIPP wealth is dated to Q4 of the reference year.

## Use

Unzip the survey files and copy the workbooks into the project's `2_Data_processing/` folder,
e.g.

    gunzip -c data/processed/SCF.csv.gz > ../2_Data_processing/SCF.csv
    cp data/processed/*.xlsx ../2_Data_processing/

`MD5SUMS_uncompressed.txt` lists the checksums of the unzipped CSV files and the two workbooks
(the versions used for the October 2026 estimates).

## Sources and terms

These files are derived from the original data. They are **not covered by the MIT licence**
of the code in this repository. The providers' terms apply:

- **CEX and SIPP:** public-domain U.S. government data (BLS and Census Bureau).
- **SCF:** Federal Reserve Board public SCF files (1989–2022). The waves before 1989 come from
  the SCF+ of Kuhn, Schularick and Steins (2020), *Journal of Political Economy* 128(9):
  3469–3519. The top tail adds the Forbes 400 (Forbes, 2021–2024; Fernholz and Hagler 2023,
  1985–2020).
- **CPS:** Sarah Flood, Miriam King, Renae Rodgers, Steven Ruggles, J. Robert Warren, Daniel
  Backman, Annie Chen, Grace Cooper, Stephanie Richards, Megan Schouweiler and Michael
  Westberry. IPUMS CPS: Version 11.0 [dataset]. Minneapolis, MN: IPUMS, 2023.
  https://doi.org/10.18128/D030.V11.0. Further redistribution requires IPUMS permission.
- **PSID:** subject to the PSID Conditions of Use. Users should register with PSID
  (https://psidonline.isr.umich.edu/).
- **Aggregate workbooks:** public series from FRED / FRED-QD (Federal Reserve Bank of St. Louis),
  the Financial Accounts of the United States and the NIPA. Some series are third-party
  (S&P 500, Nikkei 225, Shiller price index, University of Michigan consumer sentiment),
  and their owners' terms apply.

Please cite the original sources (see the main README). Questions: luis.calderon@uni-bonn.de.
