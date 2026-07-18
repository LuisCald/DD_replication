**# Notes for later:
* - Deal with top-coding 
* - net worth is equal to wealth - (total debt - secured debt) ... why? this seems to be for years prior to 1996, something to check 
* - don't forget: we need annual income, so maybe multiply by 4
** - also found in wave 4?

**# Functions 
// Define a program to return the start month and year for a given panel
program define get_start_date
    // Declare inputs
    args panel

    // Initialize variables to store start month and year
    local start_month
    local start_year

    // Determine the start month and year based on the panel
    if `panel' == 1996 {
        local start_month = 4
        local start_year = 1996
    }
    else if `panel' == 2001 {
        local start_month = 2
        local start_year = 2001
    }
    else if `panel' == 2004 {
        local start_month = 2
        local start_year = 2004
    }
    else if `panel' == 2008 {
        local start_month = 9
        local start_year = 2008
    }
    else {
        // Handle invalid panel input
        di "Invalid panel year. Please enter 1996, 2001, 2004, or 2008."
        exit
    }

    // Store the start month and year in global macros for extraction
    global start_month = `start_month'
    global start_year = `start_year'

    // Output the start month and year
    di "Start Month: " `start_month' ", Start Year: " `start_year'
end

**# Master do-file: imports data and processes it 

* Variables to import 
global id_vars su_rot su_id id h_add h_addid_ h_addid pp_entry pp_pnum
global measures hhtwlth hhusdbt hhscdbt hhdebt hhtnw h_totinc
global other_vars age h_wgt h_year h_month panel spanel swave pp_wave

* other possible names for the variables 
global other_id_vars srotaton ssuid epppnum shhadid swave
global other_measures thhtwlth thhscdbt thhmortg thhdebt rhhuscbt thhtnw


**# Getting wealth from all years, waves
clear
cap log close // the sip`yr2't`i'.do begin with a 'log' command. This ensures it runs
save "/Users/lc/Dropbox/Distributional_Dynamics/1_Data/SIPP/made_panels/sipp_file_wealth.dta", emptyok replace
foreach x in 1996 2001 2004 2008 { // 2014 2018{
	global missing_waves
	cd "/Users/lc/Dropbox/Distributional_Dynamics/1_Data/SIPP/raw_materials/`x'"
	clear
	save "/Users/lc/Dropbox/Distributional_Dynamics/1_Data/SIPP/made_panels/sipp_file`x'.dta", emptyok replace
	
	
	local yr2 = substr("`x'", 3, 2)
	foreach i in 3 4 6 7 9 10 12 { // these are the 'waves'
		cap log close
		cap do sip`yr2't`i'.do
// 		do sip`yr2't`i'.do
// 		do sippp`yr2'putm`i'.do
		if _rc != 0 { // 0 = it worked
			cap do sippp`yr2'putm`i'
			if _rc != 0 {
				disp "`x' , wave `i'"
				global missing_waves $missing_waves "`x' , wave `i'" // FIX
				continue
			}
		}
		
		local existing_vars ""
		foreach var in $id_vars $measures $other_vars $other_measures $other_id_vars {
			disp "`var'"
			capture confirm variable `var'
			if !_rc {
				local existing_vars "`existing_vars' `var'"
			}
		}
		disp "`existing_vars'"
		keep `existing_vars'
		
		append using "/Users/lc/Dropbox/Distributional_Dynamics/1_Data/SIPP/made_panels/sipp_file`x'.dta"
		save "/Users/lc/Dropbox/Distributional_Dynamics/1_Data/SIPP/made_panels/sipp_file`x'.dta", replace
		cap log close
	}
	use "/Users/lc/Dropbox/Distributional_Dynamics/1_Data/SIPP/made_panels/sipp_file`x'.dta", clear

	* Assigning the months and years 
	get_start_date `x'
	gen h_month = .
	gen h_year  = .
	summ swave
	local max_wave = r(max)
	
	summ srotaton
	local max_rot = r(max)
	
	// Loop over waves 
	forval wave = 1/`max_wave' {
		// Loop over rotations
		forval rot = 1/`max_rot' {
			// Calculate the current month and year
			local month = $start_month + (`wave' - 1) * 4 + (`rot' - 1)
			local year = $start_year

			// Adjust year if the month goes beyond December
			if `month' > 12 & `month' <= 24 {
				local month = `month' - 12
				local year = `year' + 1
			}
			else if `month' > 24 & `month' <= 36 {
				local month = `month' - 24
				local year = `year' + 2
			}
			else if `month' > 36 & `month' <= 48 {
				local month = `month' - 36
				local year = `year' + 3
			}
			else if `month' > 48 & `month' <= 60 {
				local month = `month' - 48
				local year = `year' + 4
			}

			// Apply the replacement
			replace h_month = `month' if swave == `wave' & srotaton == `rot'
			replace h_year = `year' if swave == `wave' & srotaton == `rot'
		}
	} 

	append using "/Users/lc/Dropbox/Distributional_Dynamics/1_Data/SIPP/made_panels/sipp_file_wealth.dta"
	save "/Users/lc/Dropbox/Distributional_Dynamics/1_Data/SIPP/made_panels/sipp_file_wealth.dta", replace
}

* Rename some variables 
use "/Users/lc/Dropbox/Distributional_Dynamics/1_Data/SIPP/made_panels/sipp_file_wealth.dta", clear 
rename ssuid su_id 
rename srotaton su_rot
rename epppnum pp_pnum
rename shhadid h_add
rename h_year year
rename h_month month

* Some cleaning / noticed some weird stuff
drop if rhhuscbt == -100000000 // associated with duplicates .. also should not be negative
drop if rhhuscbt >= 10000000 & spanel == 2004 // associated with duplicates
drop if thhscdbt < 0 // should only be positive 
drop if thhdebt < 0 // should only be positive 

// egen hh_id = group() // group doesn't work because this will assign different numbers every time

* We can just collapse and merge on some identifiers since we only have aggregated data 
collapse (max) thhtnw thhtwlth thhmortg thhdebt thhscdbt rhhuscbt, by(spanel su_id h_add year month)



* when merging, beware that su_id begins with zeros and the other dataset does not
destring su_id, replace
tostring h_add, replace
save "/Users/lc/Dropbox/Distributional_Dynamics/1_Data/SIPP/made_panels/sipp_file_wealth_collapsed.dta", replace


* Import the data we already had, of which the earlier years have wealth
cd "/Users/lc/Dropbox/Distributional_Dynamics/1_Data/SIPP/raw_materials/1984"
clear all

save "/Users/lc/Dropbox/Distributional_Dynamics/1_Data/SIPP/made_panels/sipp_file.dta", emptyok replace
foreach x in 1984 1985 1986 1987 1988 1989 1990 1991 1992 1993 1996 2001 2004 2008 { // 2014 2018{

	cd "/Users/lc/Dropbox/Distributional_Dynamics/1_Data/SIPP/raw_materials/`x'"
	
	if `x' < 2000 {
		local yr2 = substr("`x'", 3, 2)
	}
	else {
		local yr2 = "`x'"
	}

	use "`yr2'_panel.dta", clear
	local existing_vars ""
	foreach var in $id_vars $measures $other_vars {
		capture confirm variable `var'
		if !_rc {
			local existing_vars "`existing_vars' `var'"
		}
	}
	
	keep `existing_vars'

	tostring h_add*, replace
	tostring pp_entry pp_pnum , replace 

	append using "/Users/lc/Dropbox/Distributional_Dynamics/1_Data/SIPP/made_panels/sipp_file.dta"
	save "/Users/lc/Dropbox/Distributional_Dynamics/1_Data/SIPP/made_panels/sipp_file.dta", replace
} 




* Clean the data 
use "/Users/lc/Dropbox/Distributional_Dynamics/1_Data/SIPP/made_panels/sipp_file.dta", replace
replace h_add = h_addid if missing(h_add)
replace h_add = h_addid_ if missing(h_add)

rename panel panel_year
rename h_year year 
rename h_month month

drop if age < 18
* for some reason, panel_year is missing for some households
replace panel_year = 2008 if year >= 2008 & missing(panel_year)

egen hh_id = group(su_id h_add panel_year)

// bysort hh_id year month: gen n_members=_N
// keep if n_members < 10 // to remove exhorbitantly large "households"

* Since we keep household statistics, we just keep 1 value from each month
collapse (max) hhtwlth hhusdbt hhscdbt hhdebt hhtnw h_totinc (mean) h_wgt,  by(panel_year su_id h_add year month) 

* check the collapse of data here

rename panel_year spanel
replace spanel =  spanel+ 1900 if spanel < 2000

* Merge
merge 1:1 spanel su_id h_add year month using "/Users/lc/Dropbox/Distributional_Dynamics/1_Data/SIPP/made_panels/sipp_file_wealth_collapsed.dta"

gen     quarter=1 if month>=1 & month<=3
replace quarter=2 if month>=4 & month<=6
replace quarter=3 if month>=7 & month<=9
replace quarter=4 if month>=10 & month<=12

egen hh_id = group(su_id h_add spanel)
bysort hh_id year quarter: gen check_month = _N
replace h_totinc = . if check_month < 3

drop if check_month < 3 & missing(hhtnw)
// keep if check_month == 3 // FIX

replace hhtwlth = thhtwlth if missing(hhtwlth)
replace hhusdbt = rhhuscbt if missing(hhusdbt)
replace hhtnw = thhtnw if missing(hhtnw)
replace hhscdbt = thhscdbt if missing(hhscdbt)
replace hhdebt = thhdebt if missing(hhdebt)

drop thhtwlth rhhuscbt thhtnw thhscdbt thhdebt

* To think about here is: for quarterly income, we need all 3 months
* for quarterly wealth, we just need a snapshot at the end quarter

* Aggregate income to quarter
collapse (mean) hhtwlth hhusdbt hhscdbt hhdebt hhtnw (mean) h_wgt (sum) h_totinc (first) spanel,  by(hh_id year quarter)

* Now merge in wealth
rename hh_id id
rename hhtwlth assets 
rename hhusdbt undebt
rename hhscdbt scdebt
rename hhdebt tdebt
rename h_wgt weight
rename h_totinc income

* ── PREP (verify, then activate the fix below): era-1/2 net-worth check ──────
* SIPP variable definitions (ported from the deleted clean_SIPP_panels.do):
*   hhtwlth: total wealth of the household    hhdebt:  unsecured + secured debt
*   hhtnw:   hhtwlth - unsecured              hhscdbt: secured debt
*   hhusdbt: unsecured debt
* Census convention: hhtnw = hhtwlth - unsecured,
* i.e. "total wealth" already measures home/vehicle/business as EQUITY (net of
* secured debt). If the diagnostic prints ~0, the active formula below
* double-subtracts secured debt; switch to the commented line, which equals
* hhtnw and matches the THNETWORTH concept used for 2013+.
gen double _nw_check = hhtnw - (assets - undebt)
summ _nw_check, d
count if abs(_nw_check) > 1 & !missing(_nw_check)
drop _nw_check

// gen wealth = assets - undebt - scdebt // net worth is computed weirdly by the SIPP at times
* Diagnostic result (2026-07-18, 554,309 obs): hhtnw - (assets - undebt) = 0 at
* every percentile 1-99 (largest negatives ~ -3e-11, float noise). 1,954 obs
* (0.35%) differ by large positive amounts up to the 999999 top-code sentinel:
* there the COMPONENT arithmetic is corrupted while hhtnw is the official value.
* So use the survey's own net worth directly (mirrors THNETWORTH for 2013+),
* falling back to the component formula only where hhtnw is missing.
gen wealth = hhtnw
replace wealth = assets - undebt if missing(wealth)
* gen wealth = assets - undebt   // (equivalent for 99.65% of obs; kept for reference)
drop hhtnw

* Net worth in the SIPP is defined in a weird way
save "/Users/lc/Dropbox/Distributional_Dynamics/1_Data/SIPP/made_panels/sipp_1983_2013.dta", replace

**# Adding newer waves
**# Clean later SIPP waves
// cd /Users/lc/Dropbox/Distributional_Dynamics/1_Data/SIPP/raw_materials/2014
// import delimited "sipp2014_panel.csv", clear
// 	rename tehc_st state
// 	drop if state== 60       // drop Puerto Rico, islands (27 obs)
// 	drop if state== 61       // drop Foreign Country (1023 obs)
//
// 		gen year = 2012 + swave  // the first wave is Jan-Dec 2013, swave = 1, swave non-missing
//
// 	rename wpfinwgt weight  	// person and household weight identical for 97% of obs
//
// 	tostring pnum, replace		// person #: code that tells us when they entered the SIPP 2014 panel and who they are in the family (father, mother, child)
// 	rename shhadid h_add		// recommended not to use
// 	rename monthcode month 		// no missings

	
foreach x in 2014 2018 2019 2020 2021 2022 2023 { 	//
	cd /Users/lc/Dropbox/Distributional_Dynamics/1_Data/SIPP/raw_materials/`x'
	
	if `x' == 2014 {
		import delimited "sipp`x'_panel.csv", clear
	}
	else if `x' == 2018 {
		use pu`x'.dta, clear
		
		global sipp_variables_later thnetworth tprloanamt tmhloanamt tftotinc ///
		thtotinc tdebt_ast tdebt_home tdebt_sec thdebt_ast thdebt_home ///
		thdebt_sec thdebt_usec thval_ast tehc_metro eresidenceid tehc_st ///
		spanel swave monthcode tage esex eeduc erace ems tjb1_msum ///
		tjb2_msum tjb1_mwkhrs tjb2_mwkhrs rmwkwjb ssuid shhadid wpfinwgt ///
		rfrelu18 pnum rfpov tpprpinc tptrninc tsnap_amt twic_amt tga_amt ///
		ttanf_amt tssi_amt tva2amt tpscininc tva1amt tva3amt tva4amt ///
		tva5amt twcamt tuc1amt tuc2amt tuc3amt tsssamt tsscamt
		
		keep $sipp_variables_later
		destring tehc_st, replace

	}
	
	else {
		use pu`x'.dta, clear
		* Define the global macro for the list of variables
		global sipp_variables_later THNETWORTH TPRLOANAMT TMHLOANAMT TFTOTINC ///
			THTOTINC TDEBT_AST TDEBT_HOME TDEBT_SEC THDEBT_AST THDEBT_HOME ///
			THDEBT_SEC THDEBT_USEC THVAL_AST TEHC_METRO ERESIDENCEID TEHC_ST ///
			SPANEL SWAVE MONTHCODE TAGE ESEX EEDUC ERACE EMS TJB1_MSUM ///
			TJB2_MSUM TJB1_MWKHRS TJB2_MWKHRS RMWKWJB SSUID SHHADID WPFINWGT ///
			RFRELU18 PNUM RFPOV TPPRPINC TPTRNINC TSNAP_AMT TWIC_AMT TGA_AMT ///
			TTANF_AMT TSSI_AMT TVA2AMT TPSCININC TVA1AMT TVA3AMT TVA4AMT ///
			TVA5AMT TWCAMT TUC1AMT TUC2AMT TUC3AMT TSSSAMT TSSCAMT
		
		keep $sipp_variables_later
		destring TEHC_ST, replace
		rename TEHC_ST tehc_st
		rename SWAVE swave
		rename WPFINWGT wpfinwgt
		rename PNUM pnum 
		rename SHHADID shhadid
		rename MONTHCODE monthcode
		rename SSUID ssuid 
		rename ERESIDENCEID eresidenceid
		rename SPANEL spanel
		rename THNETWORTH thnetworth
		rename THTOTINC thtotinc
		rename THVAL_AST thval_ast
		rename THDEBT_USEC thdebt_usec
		rename THDEBT_SEC thdebt_sec
		rename THDEBT_AST thdebt_ast
		rename THDEBT_HOME thdebt_home
	}

	* clean data 
	rename tehc_st state
	drop if state== 60       // drop Puerto Rico, islands (27 obs)
	drop if state== 61       // drop Foreign Country (1023 obs)
	
	if `x' == 2014 {
		gen year = 2012 + swave  // the first wave is Jan-Dec 2013, swave = 1, swave non-missing
	}
	
	else {
		gen year = `x' - 1  // the year is just the year prior
	}
							 // it overlaps with the last 4 waves of the SIPP 2008 (waves then were 4 months long)

	rename wpfinwgt weight  	// person and household weight identical for 97% of obs

	tostring pnum, replace		// person #: code that tells us when they entered the SIPP 2014 panel and who they are in the family (father, mother, child)
	rename shhadid h_add		// recommended not to use
	rename monthcode month 		// no missings

	
	* uniquely identify households
	egen hh_id = group(ssuid eresidenceid spanel)  // suggested by documentation and SIPP ppl // do not use this function for the newer SIPP
	// alternatively: gen new_id = ssuid_eresidenceid -- for annual SIPPs
	
	* concerned with households with 2 to 9 members
	bysort hh_id year month: gen n_members=_N
	keep if n_members>=1 & n_members<10

	* Screen implausible asset values (diagnosed 2026-07-18): in the 2014-panel
	* wave 3 (ref-2015), 28 households carry thval_ast in a narrow $110-150M band,
	* 17-156x their OWN values in adjacent waves (median ~30-50x) — the top-code
	* substitution values appear misscaled ~100x. Divided by 100 the band lands at
	* $1.1-1.5M, exactly the top-code replacement range. No SIPP sample (no wealth
	* oversample) legitimately contains $100M+ households (W1/W2/W4: 60/12/0 such
	* person-months vs W3's 849). Analogue of the junk-code screens for the old
	* panels above. Wealth becomes missing for these obs; income is unaffected.
	replace thnetworth = . if thval_ast >= 1e8 & !missing(thval_ast)
	replace thval_ast  = . if thval_ast >= 1e8 & !missing(thval_ast)

	collapse (max) thval_ast thdebt_usec thdebt_sec thdebt_ast thnetworth thdebt_home thtotinc (mean) weight (first) spanel,  by(hh_id year month)

	gen quarter=.
	replace quarter=1 if month>=1 & month<=3
	replace quarter=2 if month>=4 & month<=6
	replace quarter=3 if month>=7 & month<=9
	replace quarter=4 if month>=10 & month<=12


	bysort hh_id year quarter: gen check_month = _N

	replace thtotinc = . if check_month < 3
	drop if check_month < 3 & missing(thnetworth) // check that thnetworth is correctly computed

	collapse (mean) thval_ast thdebt_usec thdebt_sec thdebt_ast thnetworth thdebt_home (mean) weight (sum) thtotinc (first) spanel,  by(hh_id year quarter)

	* Now merge in wealth
	rename hh_id id
	rename thval_ast assets 
	rename thdebt_usec undebt
	rename thdebt_sec scdebt
	rename thdebt_ast tdebt
	rename thtotinc income
	rename thdebt_home mgdebt 
	rename thnetworth wealth
	
// 	replace income = . if income == 0 // mostly, if not all observations where an ID is not observed for 4 quarters

// 	gen wealth = assets - undebt - scdebt // net worth is computed weirdly by the SIPP at times

	* Wealth-side variables are measured ONCE per reference year (as of ~Dec 31)
	* and replicated by the Census across all monthly records — keeping them in
	* all four quarters would feed the smoother the same number four times
	* (asserting within-year constancy and overstating precision ~4x). Keep the
	* stock variables only in Q4, the quarter the measurement refers to; Q1-Q3
	* become missing and the smoother interpolates. Income is genuinely monthly
	* and stays quarterly. (Old panels: topical-module wealth is already dated
	* to interview waves — unchanged.)
	foreach v in assets undebt scdebt tdebt mgdebt wealth {
		replace `v' = . if quarter != 4
	}

	* Net worth in the SIPP is defined in a weird way
	save "/Users/lc/Dropbox/Distributional_Dynamics/1_Data/SIPP/made_panels/sipp`x'_final.dta", replace
}


**# Appending all of the files together 
cd "/Users/lc/Dropbox/Distributional_Dynamics/1_Data/SIPP/made_panels

use sipp_1983_2013, clear

drop if year == 2013 & quarter <= 3
drop if year == 2000

foreach x in 2014 2018 2019 2020 2021 2022 2023 {
	append using sipp`x'_final.dta
}
drop spanel 

* Put in 2019 dollars 
merge m:1 year quarter using /Users/lc/Dropbox/Distributional_Dynamics/2_Data_processing/quarterly_inflation_ratio.dta, keepusing(inflation_ratio)

foreach var in wealth undebt tdebt scdebt mgdebt income assets {
	replace `var' = `var' * inflation_ratio
}

* Treatment of zeros may be inducing weird dynamics 
replace income = 0 if missing(income) 
replace income = income * 4

foreach var in undebt scdebt mgdebt tdebt wealth {
	replace `var' = . if `var' == 0 // 40% of people do not have unsecured debt	
}

drop if missing(weight)
drop inflation_ratio _merge

* Clear structural break in 2013
preserve 
keep if year < 2013

* Some cleaning 
sort year quarter 

levelsof year, local(years)
levelsof quarter, local(quarters)

foreach y of local years {
    foreach q of local quarters {
        foreach var in income wealth {
			* Identify the 1st percentile cutoff within each year-quarter
			summ `var' if year == `y' & quarter == `q', d
			local p1 = r(p1)  // r(p1) gives the 1st percentile value

			* Drop observations below the 1st percentile in each year-quarter
			drop if year == `y' & quarter == `q' & `var' < `p1'
		}
    }
}

export delimited using "/Users/lc/Dropbox/Distributional_Dynamics/2_Data_processing/SIPP1.csv", replace
restore

keep if year >= 2013
* export delimited using "/Users/lc/Dropbox/Distributional_Dynamics/2_Data_processing/SIPP2.csv", replace
* ^ BUG (fixed): the 2013+ block was exported to SIPP2.csv (typo for SIPP3.csv) and
*   then overwritten below — so SIPP3.csv was never produced by this pipeline and
*   the trimming loop that follows had no effect. The export now happens AFTER the
*   trim, to SIPP3.csv.

sort year quarter 

levelsof year, local(years)
levelsof quarter, local(quarters)

foreach y of local years {
    foreach q of local quarters {
        foreach var in income wealth {
			* Identify the 1st percentile cutoff within each year-quarter
			summ `var' if year == `y' & quarter == `q', d
			local p1 = r(p1)  // r(p1) gives the 1st percentile value

			* Drop observations below the 1st percentile in each year-quarter
			drop if year == `y' & quarter == `q' & `var' < `p1'
		}
    }
}

export delimited using "/Users/lc/Dropbox/Distributional_Dynamics/2_Data_processing/SIPP3.csv", replace

* Break SIPP 1 into two pieces
import delimited using "/Users/lc/Dropbox/Distributional_Dynamics/2_Data_processing/SIPP1.csv", clear

* Combine year and quarter into a quarterly date
generate qdate = yq(year, quarter)

* Tell Stata to display it in yearq format (e.g. 2025q3)
format qdate %tq

* Keep if qdate >= (1996, 1)
drop if qdate <= yq(1995, 4)

* Drop panel-seam quarters (end-of-panel composition artifacts: mean income dips
* 7-11% with the sample collapsing to ~1/3 — 1999Q4: n 6.5k vs 19.6k in 1999Q1;
* 2003Q4: 6.0k vs 25.9k in 2004Q4. No macro counterpart at either date.)
drop if qdate == yq(2003, 4)
drop if qdate == yq(1999, 4)

export delimited using "/Users/lc/Dropbox/Distributional_Dynamics/2_Data_processing/SIPP2.csv", replace

* Again
import delimited using "/Users/lc/Dropbox/Distributional_Dynamics/2_Data_processing/SIPP1.csv", clear

* Combine year and quarter into a quarterly date
generate qdate = yq(year, quarter)

* Tell Stata to display it in yearq format (e.g. 2025q3)
format qdate %tq

* Drop if qdate > (1996, 1)
drop if qdate > yq(1995, 4)

* Drop panel-seam quarters (the two lowest income quarters of the entire SIPP1
* series: 1985Q4 and 1988Q1 dip 15-20% below neighbors with no macro counterpart
* — both are panel-boundary quarters; see the audit note in SIPP2 slicing above.)
drop if qdate == yq(1988, 1)
drop if qdate == yq(1985, 4)

export delimited using "/Users/lc/Dropbox/Distributional_Dynamics/2_Data_processing/SIPP1.csv", replace



// collapse (sum) weight, by(year quarter )
// drop if weight == 0 
// egen tt = group(year quarter)
// tsset tt

foreach var in wealth {
	collapse (mean) `var' (p10) `var'10=`var' (p20) `var'20=`var' (p30) `var'30=`var' (p40) `var'40=`var' (p50) `var'50=`var' (p60) `var'60=`var' (p70) `var'70=`var' (p80) `var'80=`var' (p90) `var'90=`var' (p99) `var'99=`var' [pw=weight], by(year quarter)
	drop if missing(`var')
	egen tt = group(year quarter)
	tsset tt
	}
