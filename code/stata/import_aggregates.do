**# Importing the aggregate series using FRED

* Import inflation first, since I wanted a 2019 series (specific, still from FRED)
import delimited "/Users/lc/Dropbox/Distributional_Dynamics/2_Data_processing/CPIAUCSL.csv", clear 

* Convert the string date to a Stata date
gen dateen = date(date, "YMD")

* Format the new date variable as a Stata date
format dateen %td

* Convert the Stata date to a quarterly date
gen qdate = qofd(dateen)
format qdate %tq
drop dateen date 
rename qdate daten 

save "/Users/lc/Dropbox/Distributional_Dynamics/2_Data_processing/headline_inflation.dta", replace

/* ============================================================================
   DISABLED FOR NOW — model stationary-aggregates path (sp500/expectations/shiller,
   the big FRED-QD import, deseasoning-for-stationary, stationary_aggregates.csv,
   and factor analysis). NONE of this is needed to produce the per-HH correction
   series (inflation_corrected_correction_series.xlsx) that GrowthCorrection.jl reads.
   Re-enable this block for the full model data build.
   ============================================================================
* Import sp500_div_yield
import delimited "/Users/lc/Dropbox/Distributional_Dynamics/2_Data_processing/sp500_dividend_yield.csv", clear 

* Convert the string date to a Stata date
gen dateen = date(time, "MDY", 2024)

* Format the new date variable as a Stata date
format dateen %td

* Convert the Stata date to a quarterly date
gen qdate = qofd(dateen)
format qdate %tq
drop dateen time 
rename qdate daten 

save "/Users/lc/Dropbox/Distributional_Dynamics/2_Data_processing/sp500_dividend_yield.dta", replace

* Import household expectations
import delimited "/Users/lc/Dropbox/Distributional_Dynamics/2_Data_processing/household_expectations.csv", clear 

* Convert the string date to a Stata date
gen dateen = date(time, "YMD")

* Format the new date variable as a Stata date
format dateen %td

* Convert the Stata date to a quarterly date
gen qdate = qofd(dateen)
format qdate %tq
drop dateen time 
rename qdate daten 

save "/Users/lc/Dropbox/Distributional_Dynamics/2_Data_processing/household_expectations.dta"

* Import Shiller index
import delimited "/Users/lc/Dropbox/Distributional_Dynamics/2_Data_processing/shiller_index_quarterly.csv", clear 
drop v*

* Convert the string date to a Stata date
gen dateen = date(time, "YMD")

* Format the new date variable as a Stata date
format dateen %td

* Convert the Stata date to a quarterly date
gen qdate = qofd(dateen)
format qdate %tq
drop dateen time 
rename qdate daten 

save "/Users/lc/Dropbox/Distributional_Dynamics/2_Data_processing/shiller_index_quarterly.dta"




// set fredkey 7e0a268b39badcaee1c9530f9b155466, permanently
import fred GS1	BOGZ1LM153061105Q	OLALBSHNO	TNWBSHNO	///
LIRABSHNO	UEMPMEAN	HNOREMV	HNOPFAQ027S	A997RC1Q027SBEA	HNOLA	///
GS5	PINCOME	NA000332Q	///
AAAFFM	NA000338Q	BOGZ1LM155111005Q	///
INDPRO	BOGZ1LM154022005Q	TB3MS	BOGZ1LM152010005Q	HNOCEA	///
BLNECLBSHNO	HMLBSHNO	MAABSHNO	CCLBSHNO	TFAABSHNO	MVLOAS	///
TABSHNO	TSDABSHNO	NA000346Q	HNOLL	GDP	NA000335Q	///
BOGZ1LM153062005Q	NA000336Q	///
HNOMFSA	TLBSHNO	PCESV	HOOREVLMHMV	UNRATE	///
PCEND	CDCABSHNO	MABSHNO	PAYEMS	///
NA000316Q	BOGZ1LM153063005Q	BOGZ1LM152090205Q	///
AWHMAN, clear aggregate(quarterly)

* Convert the string date to a Stata date
gen dateen = date(datestr, "YMD")

* Format the new date variable as a Stata date
format dateen %td

* Convert the Stata date to a quarterly date
gen qdate = qofd(dateen)
format qdate %tq
drop daten datestr dateen
rename qdate daten

merge 1:1 daten using "/Users/lc/Dropbox/Distributional_Dynamics/2_Data_processing/headline_inflation.dta"
drop _merge
merge 1:1 daten using "/Users/lc/Dropbox/Distributional_Dynamics/2_Data_processing/sp500_dividend_yield.dta"
drop _merge
merge 1:1 daten using "/Users/lc/Dropbox/Distributional_Dynamics/2_Data_processing/household_expectations.dta"
drop _merge
merge 1:1 daten using "/Users/lc/Dropbox/Distributional_Dynamics/2_Data_processing/shiller_index_quarterly.dta"
drop _merge

drop if missing(personalfinanceexpected)
 

* Export the data to python to remove seasonality and generate stationary series 
export delimited using "/Users/lc/Dropbox/Distributional_Dynamics/2_Data_processing/aggregates_nominal_w_season.csv", replace

save "/Users/lc/Dropbox/Distributional_Dynamics/2_Data_processing/aggregates_nominal_w_season.dta", replace


* Import the seasonally adjusted data 
import delimited using "/Users/lc/Dropbox/Distributional_Dynamics/2_Data_processing/aggregates_deseasoned.csv", clear

gen time = quarterly(daten, "YQ")
format time %tq
tsset time

drop bogz1lm153061105q

* Define the variables to log and difference
global log_diff_vars hnoremv na000332q cclbshno hnoll tlbshno mabshno hnopfaq027s tfaabshno gdp pcesv payems cpiaucsl_nbd20191001 olalbshno a997rc1q027sbea na000338q hnocea mvloas na000335q hoorevlmhmv na000316q tnwbshno hnola blneclbshno tabshno sp500 lirabshno indpro hmlbshno tsdabshno na000336q pcend personalfinancecurrent pincome maabshno na000346q hnomfsa cdcabshno personalfinanceexpected house_price_index bogz1lm155111005q bogz1lm154022005q bogz1lm152010005q bogz1lm153063005q bogz1lm152090205q expectedindex currentindex businesscondition5years businesscondition12months buyingconditions uempmean  


* Define the variables to only difference
global diff_vars sp_div_yield gs1 tb3ms gs5 aaaffm unrate awhman

* Put in 2019 dollars
gen defl = 100 / cpiaucsl_nbd20191001 

foreach var in hnoremv na000332q cclbshno hnoll tlbshno mabshno hnopfaq027s tfaabshno gdp pcesv olalbshno a997rc1q027sbea na000338q hnocea mvloas na000335q hoorevlmhmv na000316q tnwbshno hnola blneclbshno tabshno sp500 lirabshno indpro hmlbshno tsdabshno na000336q pcend pincome maabshno na000346q hnomfsa cdcabshno bogz1lm155111005q bogz1lm154022005q bogz1lm152010005q bogz1lm153063005q bogz1lm152090205q {
	replace `var' = `var' * defl
}

* Loop over variables that need log transformation and then differencing
foreach var in $log_diff_vars {
    gen log_`var' = log(1+`var')
    gen d_log_`var' = d.log_`var'
	summ d_log_`var'
	gen std_`var' = (d_log_`var' - r(mean)) / r(sd)
	
	dfuller d_log_`var'
	global res = r(Zt)
	if $res > -2.8 {
		disp "hi"
		disp "`var' not stationary"
	}
}

* Loop over variables that just need differencing
foreach var in  $diff_vars {
    gen d_`var' = D.`var'
	summ d_`var'
	gen std_`var' = (d_`var' - r(mean)) / r(sd)
	
	dfuller d_`var'
	global res = r(Zt)
	if $res > -2.8 {
		disp "`var' not stationary"
	}
}

// gen tlog_bogz1lm153061105q = log(bogz1lm153061105q + 2000)
// gen td_log_bogz1lm153061105q = d.tlog_bogz1lm153061105q
//
// * potentially throw out: blneclbshno bogz1lm153062005q bogz1lm153061105q
//
// tsline td_log_bogz1lm153061105q

drop if missing(d_log_a997rc1q027sbea)
drop v1

export delimited d_log* d_gs1 d_gs5 d_tb3ms d_aaaffm d_unrate time using "/Users/lc/Dropbox/Distributional_Dynamics/2_Data_processing/stationary_aggregates.csv", replace
*/
* ===== end DISABLED model stationary-aggregates block =====

//
// * Number of factors 
// pca std_hnoremv std_na000332q std_cclbshno std_hnoll std_tlbshno ///
// std_mabshno std_hnopfaq027s std_tfaabshno std_gdp std_pcesv std_payems ///
// std_cpiaucsl_nbd20191001 std_olalbshno std_a997rc1q027sbea std_na000338q ///
// std_hnocea std_mvloas std_na000335q std_hoorevlmhmv std_na000316q ///
// std_tnwbshno std_hnola std_blneclbshno std_tabshno std_sp500 std_lirabshno ///
// std_indpro std_hmlbshno std_tsdabshno std_na000336q std_pcend ///
// std_personalfinancecurrent std_pincome std_maabshno std_na000346q ///
// std_hnomfsa std_cdcabshno std_awhman std_personalfinanceexpected ///
// std_house_price_index std_bogz1lm155111005q std_bogz1lm154022005q ///
// std_bogz1lm152010005q std_bogz1lm153063005q std_bogz1lm152090205q ///
// std_expectedindex std_currentindex std_businesscondition5years ///
// std_businesscondition12months std_buyingconditions std_uempmean ///
// std_unrate std_gs1 std_tb3ms std_gs5 std_aaaffm std_sp_div_yield 
// 
// xtnumfac d_log_hnoremv d_log_na000332q d_log_hnoll d_log_cclbshno d_log_tlbshno  ///
// d_log_mabshno d_log_hnopfaq027s d_log_tfaabshno d_log_gdp ///
// d_log_pcesv d_log_payems d_log_cpiaucsl_nbd20191001 d_log_olalbshno ///
// d_log_a997rc1q027sbea d_log_na000338q d_log_hnocea d_log_mvloas ///
// d_log_na000335q d_log_hoorevlmhmv d_log_na000316q d_log_tnwbshno ///
// d_log_hnola  d_log_tabshno d_log_sp500 d_log_lirabshno ///
// d_log_indpro d_log_hmlbshno d_log_tsdabshno d_log_na000336q d_log_pcend ///
// d_log_personalfinancecurrent d_log_pincome d_log_maabshno d_log_na000346q ///
// d_log_hnomfsa  d_log_awhman d_log_personalfinanceexpected ///
// d_log_house_price_index  d_log_bogz1lm155111005q ///
// d_log_bogz1lm154022005q d_log_bogz1lm152010005q ///
// d_log_bogz1lm153063005q d_log_bogz1lm152090205q d_log_expectedindex ///
// d_log_currentindex d_log_businesscondition5years ///
// d_log_businesscondition12months d_log_buyingconditions d_log_cdcabshno ///
// d_tb3ms d_sp_div_yield d_gs5 d_gs1, standardize(3) kmax(8) detail
// 
// * Now plot all the series 
// tsline d_log_hnoremv d_log_na000332q d_log_hnoll d_log_cclbshno d_log_tlbshno  ///
// d_log_mabshno d_log_hnopfaq027s d_log_tfaabshno d_log_gdp ///
// d_log_pcesv d_log_payems d_log_cpiaucsl_nbd20191001 d_log_olalbshno ///
// d_log_a997rc1q027sbea d_log_na000338q d_log_hnocea d_log_mvloas ///
// d_log_na000335q d_log_hoorevlmhmv d_log_na000316q d_log_tnwbshno ///
// d_log_hnola  d_log_tabshno d_log_sp500 d_log_lirabshno ///
// d_log_indpro d_log_hmlbshno d_log_tsdabshno d_log_na000336q d_log_pcend ///
// d_log_personalfinancecurrent d_log_pincome d_log_maabshno d_log_na000346q ///
// d_log_hnomfsa  d_log_awhman d_log_personalfinanceexpected ///
// d_log_house_price_index  d_log_bogz1lm155111005q ///
// d_log_bogz1lm154022005q d_log_bogz1lm152010005q ///
// d_log_bogz1lm153063005q d_log_bogz1lm152090205q d_log_expectedindex ///
// d_log_currentindex d_log_businesscondition5years ///
// d_log_businesscondition12months d_log_buyingconditions d_log_cdcabshno ///
// d_tb3ms d_sp_div_yield d_gs5 d_gs1
//
// tsline std_hnoremv std_na000332q std_cclbshno std_hnoll std_tlbshno ///
// std_mabshno std_hnopfaq027s std_tfaabshno std_gdp std_pcesv std_payems ///
// std_cpiaucsl_nbd20191001 std_olalbshno std_a997rc1q027sbea std_na000338q ///
// std_hnocea std_mvloas std_na000335q std_hoorevlmhmv std_na000316q ///
// std_tnwbshno std_hnola std_blneclbshno std_tabshno std_sp500 std_lirabshno ///
// std_indpro std_hmlbshno std_tsdabshno std_na000336q std_pcend ///
// std_personalfinancecurrent std_pincome std_maabshno std_na000346q ///
// std_hnomfsa std_cdcabshno std_awhman std_personalfinanceexpected ///
// std_house_price_index std_bogz1lm155111005q std_bogz1lm154022005q ///
// std_bogz1lm152010005q std_bogz1lm153063005q std_bogz1lm152090205q ///
// std_expectedindex std_currentindex std_businesscondition5years ///
// std_businesscondition12months std_buyingconditions std_uempmean ///
// std_unrate std_gs1 std_tb3ms std_gs5 std_aaaffm std_sp_div_yield 
//  


// * Series with named changed 
// CPI_INFLATION 
// AVG_DURATION_UNEMP // UEMPMEAN
//  GOV_DEFENSE // A997RC1Q027SBEA
// PERSONAL_INCOME // PINCOME 
//  SHILLER_PRICE_INDEX // CSUSHPINSA
//  GOV_NONDEFENSE // NA000332Q
//  CORP_BOND_PREMIA // AAAFFM
//  RESIDENTIAL_INVESTMENT // NA000338Q, may need seasonal adj.
//  IND_PROD // INDPRO
//  DURABLE_CONSUMPTION // NA000346Q
//  PRIVATE_INVESTMENT // NA000335Q
//  NONRESIDENTIAL_INVESTMENT // NA000336Q
//  SP_DIV_YIELD
//  SERVICES_CONSUMPTION // PCESV
//  UNEMPLOYMENT_RATE // UNRATE
//  NONDURABLE_CONSUMPTION // PCEND
//  NON_FARM_EMP // PAYEMS
//  GOV_STATE_LOCAL // NA000316Q
//  AVG_WEEKLY_HOURS // AWHMAN


**# Importing aggregates for the per household averages 
* I need to import:
// income: personal income (PINCOME) (billions), must be multiplied by 4
// wealth: TNWBSHNO (billions) -- stock
// consumption: non-durables, services, and rental equivalence
//// PCEND (non-durables), PCESV, both in billions 
// total HHS: annual - TTLHH (in thousands)
// assets: TABSHNO -- billions
// hdebt: HHMSDODNS (housing debt) (billions)
// revolving debt: BOGZ1FL153166100Q (millions)
// all personal debt: TOTALSL (consumer credit, revolving and unrevolving, Includes motor vehicle loans and all other loans not included in revolving credit, such as loans for mobile homes, education, boats, trailers, or vacations. These loans may be secured or unsecured.) (billions)
// rental equivalence : DOWNRC1A027NBEA (billions, annual) divided by 4
// net liquid assets: CDCABSHNO (billions)	TSDABSHNO (billions)	BOGZ1LM153061105Q (millions) - TOTALSL (billions) 


* Import total households from excel sheet
import delimited "/Users/lc/Dropbox/Distributional_Dynamics/2_Data_processing/tot_hhs_data.csv", clear
gen qdate = quarterly(date, "YQ")
format qdate %tq

rename qdate daten 
drop date 

save "/Users/lc/Dropbox/Distributional_Dynamics/2_Data_processing/tot_hhs_data.dta", replace

* Import rental eq. from excel sheet
import delimited "/Users/lc/Dropbox/Distributional_Dynamics/2_Data_processing/rental_data.csv", clear
gen qdate = quarterly(date, "YQ")
format qdate %tq

rename qdate daten 
drop date 

save "/Users/lc/Dropbox/Distributional_Dynamics/2_Data_processing/rental_data.dta", replace

* Import FRED 
import fred PINCOME TNWBSHNO PCEND PCESV TABSHNO HHMSDODNS ///
CDCABSHNO TSDABSHNO BOGZ1LM153061105Q TOTALSL BOGZ1FL153166100Q ///
HNOCEA HNOMFSA HNOREMV BOGZ1LM152090205Q HNOPFAQ027S ///
DNDGRG3M086SBEA DSERRG3M086SBEA, clear aggregate(quarterly)

* Export file and remove seasonality 
gen dateen = date(datestr, "YMD")

* Format the new date variable as a Stata date
format dateen %td

* Convert the Stata date to a quarterly date
gen qdate = qofd(dateen)
format qdate %tq
drop daten datestr dateen
rename qdate daten

* Merge in rental eq.
merge 1:1 daten using "/Users/lc/Dropbox/Distributional_Dynamics/2_Data_processing/rental_data.dta"
drop _merge 

* Merge in total HHs 
merge 1:1 daten using "/Users/lc/Dropbox/Distributional_Dynamics/2_Data_processing/tot_hhs_data.dta"
drop _merge

// drop date

drop if daten <= tq(1947, 1) // why? because SCF first obs is 1950 and 1947 is when a decent amount of FRED series begin

* Export the data to python to remove seasonality and generate stationary series 
export delimited using "/Users/lc/Dropbox/Distributional_Dynamics/2_Data_processing/averages_nominal_w_season.csv", replace

* Fun fact: by deseasoning (so imposing a model), we get estimates for missing periods (of which we do not have many)
* Import data with seasonality removed // DSERRG3M086SBEA (price level services) DNDGRG3M086SBEA (non-durable)
import delimited using "/Users/lc/Dropbox/Distributional_Dynamics/2_Data_processing/averages_deseasoned.csv", clear
cap drop v1

gen time = quarterly(daten, "YQ")
format time %tq
tsset time
drop daten
rename time daten

save "/Users/lc/Dropbox/Distributional_Dynamics/2_Data_processing/averages_deseasoned.dta", replace

// * Import price indices for consumption 
// import fred DSERRG3M086SBEA DNDGRG3M086SBEA, clear aggregate(quarterly)
//
// * Convert the string date to a Stata date
// gen dateen = date(datestr, "YMD")
//
// * Format the new date variable as a Stata date
// format dateen %td
//
// * Convert the Stata date to a quarterly date
// gen qdate = qofd(dateen)
// format qdate %tq
// drop daten datestr dateen
// rename qdate daten

use "/Users/lc/Dropbox/Distributional_Dynamics/2_Data_processing/averages_deseasoned.dta", clear

* Put things in similar units, but double check!
global vars_billions tsdabshno totalsl tnwbshno rental_eq pincome pcesv pcend hhmsdodns cdcabshno tabshno
* Z.1 component series in MILLIONS (DFA component anchors) — enabled 2026-07-20.
* Requires averages_deseasoned.csv regenerated from the new nominal export
* (X12_averages.R) so these series are present.
global vars_millions_z1 hnocea hnomfsa hnoremv bogz1lm152090205q hnopfaq027s
global vars_millions bogz1fl153166100q bogz1lm153061105q
global vars_thou tot_hhs
      
foreach var in $vars_billions {
	replace `var' = `var' * 1000000000
}

foreach var in $vars_millions {
	replace `var' = `var' * 1000000
}

foreach var in $vars_millions_z1 {
	replace `var' = `var' * 1000000
}

foreach var in $vars_thou {
	replace `var' = `var' * 1000
}

merge 1:1 daten using "/Users/lc/Dropbox/Distributional_Dynamics/2_Data_processing/headline_inflation.dta"
drop _merge

gen defl = 100 / cpiaucsl_nbd20191001

* Correct for inflation 
foreach var in tnwbshno tabshno hhmsdodns cdcabshno tsdabshno ///
 bogz1lm153061105q totalsl bogz1fl153166100q rental_eq pincome ///
 hnocea hnomfsa hnoremv bogz1lm152090205q hnopfaq027s {
 	replace `var' = `var' * defl
 }
 
replace pcend =  pcend * 100 / dndgrg3m086sbea  // specific deflators 
replace pcesv =  pcesv * 100 / dserrg3m086sbea // specific deflators 

 
 
* Generate variables per hh 
gen consum_per_hh = (pcend + pcesv) / tot_hhs // pces includes rental_eq i think
gen income_per_hh = pincome / tot_hhs
gen wealth_per_hh = tnwbshno / tot_hhs
gen assets_per_hh = tabshno / tot_hhs
gen mgdebt_per_hh = hhmsdodns / tot_hhs
gen ttdebt_per_hh = (bogz1fl153166100q + hhmsdodns) / tot_hhs
gen liquid_per_hh = (cdcabshno + tsdabshno + bogz1lm153061105q) / tot_hhs
// DFA component anchors (enabled 2026-07-20; series deseasoned via X12_averages.R):
gen stocks_per_hh = (hnocea + hnomfsa) / tot_hhs   // DFA corporate equities + mutual funds
gen real_estate_per_hh = hnoremv / tot_hhs         // DFA real estate
gen business_per_hh = bogz1lm152090205q / tot_hhs  // DFA unincorporated business
gen pension_per_hh = hnopfaq027s / tot_hhs         // DFA pension entitlements (DB+DC)
gen hdebt_per_hh = hhmsdodns / tot_hhs            // DFA "home mortgages"; matches micro hdebt (= mgdebt_per_hh)
gen pdebt_per_hh = totalsl / tot_hhs              // DFA "consumer credit"; matches micro pdebt
// Consumer durables: DFA has no standalone "vehicles" line (durables = autos+furniture+
//   appliances+...); SCF micro is vehicles-only, so it is NOT a clean DFA component -> dropped.

drop if missing(pcend) // should just be 1 obs

rename daten time

export excel income_per_hh wealth_per_hh assets_per_hh mgdebt_per_hh liquid_per_hh consum_per_hh ttdebt_per_hh hdebt_per_hh pdebt_per_hh ///
 stocks_per_hh real_estate_per_hh business_per_hh pension_per_hh ///
 time tot_hhs using "/Users/lc/Dropbox/Distributional_Dynamics/2_Data_processing/inflation_corrected_correction_series.xlsx", sheet("data") firstrow(variables) replace
 

**# Importing FRED-QD dataset 
* Initialize a dataset to append all transformed data
clear all 
import delimited "/Users/lc/Dropbox/Distributional_Dynamics/2_Data_processing/fred_qd_3.csv", clear varnames(1)
* Convert the string date to a Stata date
gen dateen = date(daten, "YMD")

* Format the new date variable as a Stata date
format dateen %td

* Convert the Stata date to a quarterly date
gen qdate = qofd(dateen)
format qdate %tq
drop dateen daten 
rename qdate daten

tsset daten

save "/Users/lc/Dropbox/Distributional_Dynamics/2_Data_processing/master_dataset.dta", replace

forvalues i=1(1)7 {
    import delimited "/Users/lc/Dropbox/Distributional_Dynamics/2_Data_processing/fred_qd_`i'.csv", clear varnames(1)

	* Convert the string date to a Stata date
	gen dateen = date(daten, "YMD")

	* Format the new date variable as a Stata date
	format dateen %td

	* Convert the Stata date to a quarterly date
	gen qdate = qofd(dateen)
	format qdate %tq
	drop dateen daten 
	rename qdate daten
	
	tsset daten

    * Check the number of columns and skip if only one column
    local ncols = c(k)
    if `ncols' <= 1 {
        continue // breaks the current iteration in stata 
    }
	else {

		* Store the name of the date column
		local date_column = "daten"  // Assuming the date column is named "date"

		* Perform the transformations
		if `i' == 1 {
			* No transformation
		}
		else if `i' == 2 {
			foreach var of varlist * {
				if "`var'" != "`date_column'" {
					if "`var'" != "tnwmvbsnncbbdix" && "`var'" != "tnwbsnnbbdix"  { 
					gen `var'_diff = D.`var'
					drop `var'
					rename `var'_diff `var'
					}
					else {
						gen log_`var' = log(`var')
						gen `var'_diff = D.log_`var'
						drop `var'
						rename `var'_diff `var'
						drop log_`var'
					}
				}
			}
		}
		else if `i' == 3 {
			foreach var of varlist * {
				if "`var'" != "`date_column'" {
					gen `var'_diff2 = D2.`var'
					drop `var'
					rename `var'_diff2 `var'
				}
			}
		}
		else if `i' == 4 {
			foreach var of varlist * {
				if "`var'" != "`date_column'" {
					gen `var'_log = log(`var')
					drop `var'
					rename `var'_log `var'
				}
			}
		}
		else if `i' == 5 {
			foreach var of varlist * {
				if "`var'" != "`date_column'" {
					gen `var'_log = log(`var')
					gen `var'_log_diff = D.`var'_log
					drop `var'
					rename `var'_log_diff `var'
					drop `var'_log
				}
			}
		}
		else if `i' == 6 {
			foreach var of varlist * {
				if "`var'" != "`date_column'" {
					gen `var'_log = log(`var')
					gen `var'_log_diff2 = D2.`var'_log
					drop `var' 
					rename `var'_log_diff2 `var' 
					drop `var'_log
				}
			}
		}
		else if `i' == 7 {
			foreach var of varlist * {
				if "`var'" != "`date_column'" {
					gen `var'_growth = (`var' / L.`var') - 1
					gen `var'_growth_diff = D.`var'_growth
					drop `var'
					rename `var'_growth_diff `var'
					drop `var'_growth
				}
			}
		}

		* Append the transformed dataset to the master dataset
		save "/Users/lc/Dropbox/Distributional_Dynamics/2_Data_processing/master_dataset_`i'.dta", replace
	}
}
* Merge them all together
use "/Users/lc/Dropbox/Distributional_Dynamics/2_Data_processing/master_dataset.dta", clear

forvalues i=1(1)7 {
	if `i' == 3 | `i' == 4 {
		continue
	}
	merge 1:1 daten using "/Users/lc/Dropbox/Distributional_Dynamics/2_Data_processing/master_dataset_`i'.dta"
	drop _merge
}

* Problematic series
foreach var in tlbsnnbbdix nwpix hwix  { // tnwmvbsnncbbdix
	replace `var' = log(`var')
	gen  D`var' = d.`var'
	drop  `var'
	rename D`var' `var'
}
drop if missing(nonborres )

//awhman aaa aaaffm baa10ym // cumfns   uempmean 

export delimited "/Users/lc/Dropbox/Distributional_Dynamics/2_Data_processing/master_dataset.csv", replace
