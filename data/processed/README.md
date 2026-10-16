# Processed survey inputs

The household-level survey files the estimation reads (`ModelOptions` data sources in
`code/julia/Structures.jl`), as produced by Stage 1 (`bash master.sh data`). Gzipped CSV.

| File | Survey | Variables used |
|---|---|---|
| `SCF.csv.gz` | Survey of Consumer Finances (SCF+, 1950–2022, with Forbes 400) | income, wealth, balance-sheet items (stocks, real estate, business, pension, debt) |
| `PSID.csv.gz` | Panel Study of Income Dynamics (1968–2021) | income; wealth and items from 1984; consumption from 1999 |
| `CEX.csv.gz` | Consumer Expenditure Survey (1984–2021) | consumption, income |
| `CPS.csv.gz` | Current Population Survey, 1993–2022 | income |
| `CPS2.csv.gz` | Current Population Survey, 1967–1992 | income |
| `SIPP1.csv.gz` | SIPP panels 1984–1993 (data 1983–1995) | income, wealth |
| `SIPP2.csv.gz` | SIPP panels 1996–2008 (data 1996–2012) | income, wealth |
| `SIPP3.csv.gz` | SIPP panels 2014 onward (data 2013–2022) | income, wealth |

Use: unzip into the project's `2_Data_processing/` folder, e.g.

    gunzip -c data/processed/SCF.csv.gz > ../2_Data_processing/SCF.csv

`MD5SUMS_uncompressed.txt` lists the checksums of the unzipped files (the versions used for
the October 2026 estimates).

These files are derived from the original surveys. The SCF, CEX and SIPP are public-domain
U.S. government data; the PSID (University of Michigan) and the CPS extracts (IPUMS) are
distributed by their providers after registration, and their terms apply to the underlying
data. Please cite the original sources (see the main README) and obtain the original data
from the providers for your own work. Questions: luis.calderon@uni-bonn.de.
