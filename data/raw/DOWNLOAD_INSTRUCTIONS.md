# Data Download Instructions

This file describes how to obtain the raw survey data needed for Stage 1 (data cleaning). All datasets are publicly available. Years match the paper's coverage table (`Tables/DataCoverage.tex`); citations are in the main README.

## 1. Panel Study of Income Dynamics (PSID)

- **URL:** https://psidonline.isr.umich.edu/
- **Registration:** Free account required
- **Years:** 1968-2021 (biennial after 1997)
- **Variables needed:** family income, net worth, housing wealth, financial assets, debt, family size, age, education, employment status, interview date
- **Instructions:** Use the PSID Data Center to create a custom extract. The extraction script `J341380.do` (in `1_Data/PSID/`) documents the exact variable list.
- **Output format:** Stata .do extraction file

## 2. Survey of Consumer Finances (SCF, SCF+) and Forbes 400

- **Modern SCF (1989-2022, triennial):** Federal Reserve Board public files, https://www.federalreserve.gov/econres/scfindex.htm (no registration). The code reads the 1989-2019 waves as harmonized in the SCF+ file below, the 2022 wave from the Fed's summary extract (`SCF_2022.dta`, `SCF_2022_wealth.dta`), and the replicate weight files (`p19_rw1.dta`, `p22_rw1.dta`).
- **Historical waves before 1989 (SCF+):** `HSCF_2019.dta` from Kuhn, Schularick and Steins (2020), "Income and Wealth Inequality in America, 1949-2016", *Journal of Political Economy* 128(9): 3469-3519, https://doi.org/10.1086/708815. The file starts in 1950; the estimation sample starts in 1962.
- **Forbes 400:** `Forbes 400 per Capita.csv` (1985-2020, the per-capita dataset of Fernholz and Hagler 2023, *Economics Letters* 230: 111235) and the Forbes 400 lists for 2021-2024 from forbes.com (`code/python/generateForbes400.py` downloads them once and caches them as `Forbes 400 scrape 2021-2024.csv`). Both go in `2_Data_processing/Forbes 400 Data Set/`.
- **Variables needed:** income, net worth, financial assets, housing, debt, family characteristics

## 3. Consumer Expenditure Survey (CEX)

- **URL:** https://www.bls.gov/cex/pumd_data.htm
- **Registration:** None required
- **Years:** 1984-2021 (Interview Survey; the estimation uses 1984Q4-2021Q4)
- **Files needed:** Interview survey public-use microdata (PUMD)
- **Variables needed:** total expenditures, food, housing, transportation, healthcare, entertainment, income
- **Note:** Pre-processed CEX file (`CEX_processed.csv`) is expected in `2_Data_processing/`

## 4. Current Population Survey (CPS)

- **URL:** https://cps.ipums.org/
- **Registration:** Free IPUMS account required
- **Years:** ASEC (March supplement) 1968-2023. ASEC income refers to the previous calendar year, and the code dates it to Q4 of that year (`data_cleaning.do`: `year = year - 1`, `quarter = 4`). So the income years are 1967-2022: `CPS2.csv` covers income years 1967-1992 and `CPS.csv` covers 1993-2022.
- **Extract name:** `cps_00005`
- **Variables needed:** total family income, earnings, family size, age, education, state
- **Citation:** Sarah Flood, Miriam King, Renae Rodgers, Steven Ruggles, J. Robert Warren, Daniel Backman, Annie Chen, Grace Cooper, Stephanie Richards, Megan Schouweiler and Michael Westberry. IPUMS CPS: Version 11.0 [dataset]. Minneapolis, MN: IPUMS, 2023. https://doi.org/10.18128/D030.V11.0

## 5. American Community Survey (ACS), optional

- **Not used in the paper.** Only an external income-validation block in `code/stata/data_cleaning.do` (section `**# ACS`, which writes `2_Data_processing/validation/ACS/`) and `code/julia/CorrelationTables.jl` read it. That block runs unconditionally, so either download the extract or comment the block out before running Stage 1.
- **URL:** https://usa.ipums.org/
- **Registration:** Free IPUMS account required
- **Years:** 2000-2019 (the years the block uses)
- **Extract name:** `usa_00009`
- **Variables needed:** household income, family size, age, education, state

## 6. Survey of Income and Program Participation (SIPP)

- **URL:** https://www.census.gov/programs-surveys/sipp.html
- **Registration:** None required
- **Panels:** 1984-1993 (1984, 1985, 1986, 1987, 1988, 1989, 1990, 1991, 1992, 1993), 1996, 2001, 2004, 2008, the 2014 panel, and the annual 2018, 2019, 2020, 2021, 2022 and 2023 releases (`code/stata/master_sipp_file.do`). Reference years are 1983-2022, used as three sub-surveys: SIPP1 = 1983Q3-1995Q4, SIPP2 = 1996Q1-2012Q4, SIPP3 = 2013Q1-2022Q4.
- **Variables needed:** monthly income, assets, liabilities, demographics
- **Note:** `master_sipp_file.do` builds SIPP1-3 from the panel files; the Census ASCII readers in `code/stata/SIPP/` are legacy

## 7. World Inequality Database (WID)

- **URL:** https://wid.world/data/
- **Registration:** None required
- **Country:** United States
- **Variables needed:** Pre-tax national income shares, net personal wealth shares (quarterly)
- **Files:** Download as CSV, save as `income Data WID.csv` and `wealth Data WID.csv`

## 8. FRED Economic Data

- **URL:** https://fred.stlouisfed.org/
- **Registration:** None required
- **Series needed:**
  - `CPIAUCSL` (CPI-U, all items; indexed to 2019-10-01 = 100, so all dollar values are in 2019Q4 USD)
  - S&P 500 dividend yield
  - University of Michigan household expectations
  - GDP and components
- **Files:** Download as CSV to `2_Data_processing/`

## 9. Distributional Financial Accounts (DFA)

- **URL:** https://www.federalreserve.gov/releases/z1/dataviz/dfa/
- **Registration:** None required
- **Files:** Download wealth distribution by percentile group, save as `DFA.xlsx`
- **Used for:** External validation only (Appendix G)

## Directory Structure After Download

Place downloaded files in the following locations relative to the project root:

```
1_Data/
├── PSID/
│   └── J341380.do          (PSID extraction script)
├── SCF+/
│   ├── HSCF_2019.dta       (Historical SCF)
│   ├── SCF_2022.dta        (2022 wave)
│   ├── SCF_2022_wealth.dta
│   ├── p19_rw1.dta         (2019 replicate weights)
│   └── p22_rw1.dta         (2022 replicate weights)
├── CEX/
│   └── [CEX PUMD files]
├── SIPP/
│   └── [SIPP panel .dta files by year]
├── shocks/
│   └── all_shocks.dta
├── CPS/
│   └── cps_00005.dta       (IPUMS CPS extract)
└── ACS/
    └── usa_00009.dta       (IPUMS USA extract; optional, see section 5)
```
