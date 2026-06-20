**# Importing the series that correct the percentile functions before the DCT 
import excel "/Users/lc/Dropbox/Distributional_Dynamics/2_Data_processing/gdp_series.xlsx", sheet("data") firstrow clear
gen qdate = qofd(time)
format qdate %tq
drop time
rename qdate time

* Generate year variable 
gen year = year(dofq(time))

* multiply each series by the inflation factor 
foreach var in gdp_per_hh assets_per_hh consumption_per_hh debt_per_hh wealth_per_hh {
	replace `var' = `var' * inflation
}

drop year inf_year M CPI_inf CPI_mat

rename gdp_per_hh income_per_hh
// DISABLED: import_aggregates.do is the canonical writer of
// inflation_corrected_correction_series.xlsx (it provides consum_per_hh, which
// GrowthCorrection.jl requires, plus the per-component anchors incl. stocks_per_hh).
// This export used a different convention (consumption_per_hh) and would clobber it.
// export excel using "/Users/lc/Dropbox/Distributional_Dynamics/2_Data_processing/inflation_corrected_correction_series.xlsx", firstrow(variables) replace


**# Importing the aggregates 
import excel "/Users/lc/Dropbox/Distributional_Dynamics/2_Data_processing/aggregates_HHs_NPs.xlsx", sheet("stationary_series") firstrow clear
gen qdate = qofd(time)
format qdate %tq
drop time
rename qdate time

save "/Users/lc/Dropbox/Distributional_Dynamics/2_Data_processing/aggregates_HHs_NPs.dta", replace


**# Establishing correlations between our, DFAs, and macro aggregates 
import excel "/Users/lc/Dropbox/Distributional_Dynamics/2_Data_processing/validation/DFA/DFA.xlsx", sheet("all_data") firstrow clear

gen qdate = qofd(time)
format qdate %tq
drop time 
rename qdate time
drop if missing(time)

* Merge in aggregates 
merge 1:1 time using "/Users/lc/Dropbox/Distributional_Dynamics/2_Data_processing/aggregates_rawdata.dta"
drop if _merge !=3

* Establish some correlations 
 
* Real Economy 
global real_econ BOGZ1LM155111005Q gov_state_local gov_defense gov_nondefense gdp private_investment nonresidential_investment residential_investment durable_consumption nondurable_consumption services_consumption real_personal_income ind_prod

global n_real_econ : list sizeof global(real_econ)

global financial Shiller_Price_Index sp500 sp_div_yield HNOREMV HOOREVLMHMV BOGZ1LM154022005Q BOGZ1LM153061105Q BOGZ1LM153062005Q BOGZ1LM153063005Q HNOCEA HNOMFSA BOGZ1LM152090205Q BOGZ1LM152010005Q TABSHNO

global n_financial : list sizeof global(financial)

global monetary TB3MS gs5 gs1 corp_bond_premia cpi_inflation

global n_monetary : list sizeof global(monetary)

global unemp unemployment_rate avg_duration_unemp avg_weekly_hours non_farm_emp

global n_unemp : list sizeof global(unemp)

ds *shares*
global Shares = r(varlist)

global n_Shares : list sizeof global(Shares)

ds *levels*
global Levels = r(varlist)

global n_Levels : list sizeof global(Levels)

foreach var in $Levels {
	replace `var' = log(`var' + sqrt(`var'^2 + 1))
}

* Rename variables so they don't conflict with our data 
foreach var in $Levels $Shares {
	rename `var' `var'_dfa
}

* these lists need to be made because now they have "_dfa" as a suffix
ds *shares*
global Shares = r(varlist)

ds *levels*
global Levels = r(varlist)

* Merge in our data 
drop _merge
merge 1:1 time using "/Users/lc/Dropbox/Distributional_Dynamics/2_Data_processing/functional_data.dta"
tsset time


global rShares shareswealth_100 shareswealth_200 shareswealth_300 shareswealth_400 shareswealth_500 shareswealth_600 shareswealth_700 shareswealth_800 shareswealth_900 shareswealth_1000

global n_rShares : list sizeof global(rShares)

global rLevels levelswealth_100 levelswealth_200 levelswealth_300 levelswealth_400 levelswealth_500 levelswealth_600 levelswealth_700 levelswealth_800 levelswealth_900 levelswealth_1000

global n_rLevels : list sizeof global(rLevels)

foreach var in $rLevels {
	replace `var' = log(`var' + sqrt(`var'^2 + 1))
}

* perform basic transformations
foreach var in $real_econ $financial non_farm_emp {
	replace `var' = log(`var' + 2)
}

* Generate matrices to fill
mat corr_mat_real = J($n_Levels + $n_Shares, $n_real_econ, 1)  
mat corr_mat_fin  = J($n_Levels + $n_Shares, $n_financial, 1)  
mat corr_mat_mon  = J($n_Levels + $n_Shares, $n_monetary, 1)  
mat corr_mat_unem = J($n_Levels + $n_Shares, $n_unemp, 1)   

local i= 0
local j= 0

* Real Economy 
foreach var in $Shares $Levels {
	local i = `i'+1
	foreach agg in $real_econ {
		local j = `j'+1
		corr `var' `agg' 
		mat corr_mat_real[`i', `j'] = round(r(rho), .01)
	}
	local j= 0
}

local i= 0
local j= 0
* Financial 
foreach var in $Shares $Levels {
	local i = `i'+1
	foreach agg in $financial {
		local j = `j'+1
		corr `var' `agg' 
		mat corr_mat_fin[`i', `j'] = round(r(rho), .01)
	}
	local j= 0
}

local i= 0
local j= 0
* Monetary 
foreach var in $Shares $Levels {
	local i = `i'+1
	foreach agg in $monetary{
		local j = `j'+1
		corr `var' `agg' 
		mat corr_mat_mon[`i', `j'] = round(r(rho), .01)
	}
	local j= 0
}

local i= 0
local j= 0
* Unemployment
foreach var in $Shares $Levels {
	local i = `i'+1
	foreach agg in $unemp {
		local j = `j'+1
		corr `var' `agg' 
		mat corr_mat_unem[`i', `j'] = round(r(rho), .01)
	}
	local j= 0
}

matrix colnames corr_mat_real = "BOGZ1LM155111005Q" "GOV_STATE_LOCAL" "GOV_DEFENSE" "GOV_NONDEFENSE" "GDP" "PRIVATE_INVESTMENT" "NONRESIDENTIAL_INVESTMENT" "RESIDENTIAL_INVESTMENT" "DURABLE_CONSUMPTION" "NONDURABLE_CONSUMPTION" "SERVICES_CONSUMPTION" "REAL_PERSONAL_INCOME" "IND_PROD"   

matrix colnames corr_mat_fin = "SHILLER_PRICE_INDEX" "SP500" "SP_DIV_YIELD" "HNOREMV" "HOOREVLMHMV" "BOGZ1LM154022005Q" "BOGZ1LM153061105Q" "BOGZ1LM153062005Q" "BOGZ1LM153063005Q" "HNOCEA" "HNOMFSA" "BOGZ1LM152090205Q" "BOGZ1LM152010005Q" "TABSHNO"

matrix colnames corr_mat_mon = "TB3MS" "GS5" "GS1" "CORP_BOND_PREMIA" "CPI_INFLATION"
matrix colnames corr_mat_unem = "UNEMPLOYMENT_RATE" "AVG_DURATION_UNEMP" "AVG_WEEKLY_HOURS" "NON_FARM_EMP"

esttab matrix(corr_mat_real) using DFA_correlations_real.tex, replace
esttab matrix(corr_mat_fin) using DFA_correlations_fin.tex, replace
esttab matrix(corr_mat_mon) using DFA_correlations_mon.tex, replace
esttab matrix(corr_mat_unem) using DFA_correlations_unem.tex, replace

* Doing the same, but for our data 
mat corr_mat_real = J($n_rLevels + $n_rShares, $n_real_econ, 1)  
mat corr_mat_fin  = J($n_rLevels + $n_rShares, $n_financial, 1)  
mat corr_mat_mon  = J($n_rLevels + $n_rShares, $n_monetary, 1)  
mat corr_mat_unem = J($n_rLevels + $n_rShares, $n_unemp, 1)   

local i= 0
local j= 0

* Real Economy 
foreach var in $rShares $rLevels {
	local i = `i'+1
	foreach agg in $real_econ {
		local j = `j'+1
		corr `var' `agg' 
		mat corr_mat_real[`i', `j'] = round(r(rho), .01)
	}
	local j= 0
}

local i= 0
local j= 0
* Financial 
foreach var in $rShares $rLevels {
	local i = `i'+1
	foreach agg in $financial {
		local j = `j'+1
		corr `var' `agg' 
		mat corr_mat_fin[`i', `j'] = round(r(rho), .01)
	}
	local j= 0
}

local i= 0
local j= 0
* Monetary 
foreach var in $rShares $rLevels {
	local i = `i'+1
	foreach agg in $monetary{
		local j = `j'+1
		corr `var' `agg' 
		mat corr_mat_mon[`i', `j'] = round(r(rho), .01)
	}
	local j= 0
}

local i= 0
local j= 0
* Unemployment
foreach var in $rShares $rLevels {
	local i = `i'+1
	foreach agg in $unemp {
		local j = `j'+1
		corr `var' `agg' 
		mat corr_mat_unem[`i', `j'] = round(r(rho), .01)
	}
	local j= 0
}

esttab matrix(corr_mat_real) using r_correlations_real.tex, replace
esttab matrix(corr_mat_fin) using r_correlations_fin.tex, replace
esttab matrix(corr_mat_mon) using r_correlations_mon.tex, replace
esttab matrix(corr_mat_unem) using r_correlations_unem.tex, replace



**# Looking at the low frequency data and the role of asset prices 

import delimited "/Users/lc/Dropbox/Distributional_Dynamics/7_Results/income_and_wealth/other_results/raw_data/SCF_wealth.csv", clear

gen qdate = quarterly(time, "YQ", 2021)
format qdate %tq
tsset qdate, quarterly
drop time 
rename qdate time

save "/Users/lc/Dropbox/Distributional_Dynamics/7_Results/income_and_wealth/other_results/raw_data/SCF_wealth.dta", replace

// log using "/Users/lc/Dropbox/Distributional_Dynamics/7_Results/role_of_asset_prices.smcl"

use "/Users/lc/Dropbox/Distributional_Dynamics/7_Results/income_and_wealth/other_results/raw_data/SCF_wealth.dta", clear 
merge 1:1 time using "/Users/lc/Dropbox/Distributional_Dynamics/2_Data_processing/aggregates_rawdata.dta"
drop if _merge != 3

gen t = _n  // should probably refer to the t of the actual time period

gen log_wealth_top10quantile = log(wealth_quants_1000)
gen log_sp500 = log(sp500)

gen log_wealth_top10quantile_diff = log_wealth_top10quantile[_n] - log_wealth_top10quantile[_n-1]
gen log_sp500_diff = log_sp500[_n] - log_sp500[_n-1]

reg wealth_quants_1000 sp500, r 
reg wealth_quants_1000 sp500 t, r

reg log_wealth_top10quantile log_sp500 t, r
reg log_wealth_top10quantile_diff log_sp500_diff, r

// log close
// translate "/Users/lc/Dropbox/Distributional_Dynamics/7_Results/role_of_asset_prices.smcl" "/Users/lc/Dropbox/Distributional_Dynamics/7_Results/role_of_asset_prices.pdf", replace


**# check this!
* aggregate data 
merge 1:1 time using "$init_path/2_Data_processing/aggregates_HHs_NPs.dta"

drop if _merge != 3 

**# Quick check 
tsset time
gen t = _n

**# Merge the low-frequency stuff
cap drop _merge
merge 1:1 time using "/Users/lc/Dropbox/Distributional_Dynamics/7_Results/income_and_wealth/other_results/raw_data/SCF_wealth.dta"

**# Predict
* First get aggregate factors 
foreach var in AVG_DURATION_UNEMP AVG_WEEKLY_HOURS GS1 BOGZ1LM153061105Q CPI_INFLATION OLALBSHNO TNWBSHNO LIRABSHNO HNOREMV BUSINESSCONDITION5YEARS HNOPFAQ027S GOV_DEFENSE BUYINGCONDITIONS PERSONALFINANCEEXPECTED HNOLA GS5 REAL_PERSONAL_INCOME SHILLER_PRICE_INDEX GOV_NONDEFENSE CORP_BOND_PREMIA BUSINESSCONDITION12MONTHS RESIDENTIAL_INVESTMENT PERSONALFINANCECURRENT BOGZ1LM155111005Q IND_PROD BOGZ1LM154022005Q TB3MS BOGZ1LM152010005Q HNOCEA BLNECLBSHNO HMLBSHNO MAABSHNO CCLBSHNO TFAABSHNO MVLOAS TABSHNO TSDABSHNO DURABLE_CONSUMPTION CURRENTINDEX HNOLL GDP PRIVATE_INVESTMENT BOGZ1LM153062005Q NONRESIDENTIAL_INVESTMENT SP_DIV_YIELD SP500 HNOMFSA TLBSHNO EXPECTEDINDEX SERVICES_CONSUMPTION HOOREVLMHMV UNEMPLOYMENT_RATE NONDURABLE_CONSUMPTION CDCABSHNO MABSHNO NON_FARM_EMP GOV_STATE_LOCAL BOGZ1LM153063005Q BOGZ1LM152090205Q {
	summ `var'
	replace `var' = (`var' - r(mean)) / r(sd)
}
pca AVG_DURATION_UNEMP AVG_WEEKLY_HOURS GS1 BOGZ1LM153061105Q CPI_INFLATION OLALBSHNO TNWBSHNO LIRABSHNO HNOREMV BUSINESSCONDITION5YEARS HNOPFAQ027S GOV_DEFENSE BUYINGCONDITIONS PERSONALFINANCEEXPECTED HNOLA GS5 REAL_PERSONAL_INCOME SHILLER_PRICE_INDEX GOV_NONDEFENSE CORP_BOND_PREMIA BUSINESSCONDITION12MONTHS RESIDENTIAL_INVESTMENT PERSONALFINANCECURRENT BOGZ1LM155111005Q IND_PROD BOGZ1LM154022005Q TB3MS BOGZ1LM152010005Q HNOCEA BLNECLBSHNO HMLBSHNO MAABSHNO CCLBSHNO TFAABSHNO MVLOAS TABSHNO TSDABSHNO DURABLE_CONSUMPTION CURRENTINDEX HNOLL GDP PRIVATE_INVESTMENT BOGZ1LM153062005Q NONRESIDENTIAL_INVESTMENT SP_DIV_YIELD SP500 HNOMFSA TLBSHNO EXPECTEDINDEX SERVICES_CONSUMPTION HOOREVLMHMV UNEMPLOYMENT_RATE NONDURABLE_CONSUMPTION CDCABSHNO MABSHNO NON_FARM_EMP GOV_STATE_LOCAL BOGZ1LM153063005Q BOGZ1LM152090205Q

reg wealth_quants_1000 l.wealth_quants_1000 pc1-pc23, r noconst


gen log_wealth_top10quantile = log(quantileswealth_1000)
gen log_sp500 = log(sp500)

gen log_wealth_top10quantile_diff = log_wealth_top10quantile[_n] - log_wealth_top10quantile[_n-1]
gen log_sp500_diff = log_sp500[_n] - log_sp500[_n-1]

reg quantileswealth_1000 sp500, r 
reg quantileswealth_1000 sp500 t, r

reg log_wealth_top10quantile log_sp500, r
reg log_wealth_top10quantile_diff log_sp500_diff, r


*Regarding your last block: Can you please send some of the estimation results (just do levels on levels) do S&P500, Houseprices, GDP. And top 10 incomes/wealth, nextten, and median.
set linesize 100
set rightmargin 10
set leftmargin 10
log using "/Users/lc/Dropbox/Distributional_Dynamics/7_Results/estimation_results.smcl", replace
*** ESTIMATION RESULTS ***
*** TOP 10, NEXT 10, AND MEDIAN, FOR INCOME AND WEALTH ***
foreach var in levelsincome_100 levelswealth_100 quantilesincome_100 quantileswealth_100 ///
levelsincome_90 levelswealth_90 quantilesincome_90 quantileswealth_90 /// 
levelsincome_50 levelswealth_50 quantilesincome_50 quantileswealth_50 {
	disp in red `var' 
	reg `var' Shiller_Price_Index, r
	reg `var' ngdp, r  // nominal GDP 
	reg `var' sp500, r
}

log close 
translate "/Users/lc/Dropbox/Distributional_Dynamics/7_Results/estimation_results.smcl" "/Users/lc/Dropbox/Distributional_Dynamics/7_Results/estimation_results.pdf", replace

