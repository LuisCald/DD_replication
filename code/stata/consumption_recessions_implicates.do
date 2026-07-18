* ─────────────────────────────────────────────────────────────
* consumption_recessions_implicates.do — original variant by Moritz Kuhn
* (moved from "Code Moritz/Application.do", Sep 2024). Same recession panels
* computed on the posterior-implicates micro file (PSID_micro_data_w_imp.csv,
* from generate_microdata_implicates); Windows paths — superseded by
* consumption_recessions.do but kept for provenance.
* ─────────────────────────────────────────────────────────────
clear
set more off

/* Directories */
global DATADIR = "C:\Users\morikuhn\Dropbox\Distributional_Dynamics\5_Code/"
global FIGUREDIR = "C:\Users\morikuhn\Dropbox\Distributional_Dynamics\7_Results\Application/"


/* Load data */
import delimited "${DATADIR}PSID_micro_data_w_imp.csv", clear
keep if implicate == 1

/* Generate calender time variable */
gen year = substr(time, 1, 4)
gen quarter = substr(time, 7, 7)
destring year, replace
destring quarter, replace
gen timeline = yq(year,quarter)
format timeline %tq

/* Determine recession dates */
gen dist2dotcom = (quarter - 1) + (year - 2001) * 4
gen dist2greatrecession = (quarter - 4) + (year - 2007) * 4
gen dist2covid = (quarter - 4) + (year - 2019) * 4


/* Generate quarterly averages */
tempfile timemean
preserve

collapse wealth consum income [pw = cop_share], by(timeline)

rename wealth wealth_mean
rename consum consum_mean 
rename income income_mean

keep *_mean timeline
save `timemean', replace

restore

/* Merge in quarterly averages */
merge m:1 timeline using `timemean'
drop _merge

/* Construct consumption and income relative to mean */
gen relcons = consum/consum_mean
gen relincome = income/income_mean

/* Generate groups: bottom 50%, 50% - 90%, top 10% */
gen wealthgroups = 1 + (wealthgrid > 5) + (wealthgrid > 9)
gen incomegroups = 1 + (incomegrid > 5) + (incomegrid > 9)

egen householdgroup  = group(wealthgroups incomegroups) 
label define householdgroup_lbl 1 "B inc - B wea" 2 "M inc - B wea" 3 "T inc - B wea" /* 
*/ 4 "B inc - M wea" 5 "M inc - M wea" 6 "T inc - M wea" /* 
*/ 4 "B inc - T wea" 5 "M inc - T wea" 6 "T inc - T wea"  
label value householdgroup householdgroup_lbl

/* Consumption over time */
foreach hhgroup in "wealth" "income" {
	
	preserve
	
	/* Relative consumption around recessions by group */
	collapse (mean) consum relcons (first) dist2* [pw = cop_share], by(timeline `hhgroup'groups)
	
	xtset `hhgroup'groups timeline
	tssmooth ma relcons_ma = relcons, window(1 1 1)
	tssmooth ma consum_ma = consum , window(1 1 1)
	
	
	/* Create plots */
	foreach cvar in "relcons" /*"consum"*/ {
	local t = 1
	foreach timeper in "dotcom" "greatrecession" "covid"  {
		gen `cvar'_`timeper' = `cvar'
		gen `cvar'_ma_`timeper' = `cvar'_ma
		forvalues i = 1(1)3 {
			quietly : sum `cvar'_ma if dist2`timeper' == 0 & `hhgroup'groups == `i' 
			replace `cvar'_`timeper' = `cvar'_`timeper' /(`r(mean)') if `hhgroup'groups  == `i'
			replace `cvar'_ma_`timeper' = `cvar'_ma_`timeper' /(`r(mean)') if `hhgroup'groups  == `i'
			}
		if(`t' == 1) {
			local timestr = "Dotcom"
			}
		else if(`t' == 2){
			local timestr = "Financial Crisis"
			}
		else {
			local timestr = "Covid"
			}
		line `cvar'_ma_`timeper' dist2`timeper' if inrange(dist2`timeper',-8,8) & `hhgroup'groups == 1 , lpattern(-) lcolor(blue) ||/*
		*/ line `cvar'_ma_`timeper' dist2`timeper' if inrange(dist2`timeper',-8,8) & `hhgroup'groups == 2 , lpattern(-) lcolor(red)  || /*  
		*/ line `cvar'_ma_`timeper' dist2`timeper' if inrange(dist2`timeper',-8,8) & `hhgroup'groups == 3 , lpattern(-) lcolor(green)  ||  /*  
		*/ scatter `cvar'_`timeper' dist2`timeper' if inrange(dist2`timeper',-8,8) & `hhgroup'groups == 1 , mcolor(blue) msymbol(O) msize(large) ||/*
		*/ scatter `cvar'_`timeper' dist2`timeper' if inrange(dist2`timeper',-8,8) & `hhgroup'groups == 2 , mcolor(red) msymbol(S) msize(large) || /*  
		*/ scatter `cvar'_`timeper' dist2`timeper' if inrange(dist2`timeper',-8,8) & `hhgroup'groups == 3, mcolor(green) msymbol(D) msize(large) /*  
		*/ legend(order(4 5 6) pos(6) rows(1) ring(0) lab(4 "bottom 50%") lab(5 "middle class (50%-90%)") lab(6 "top 10%") ) /*
		*/ ysc(r(0.87 1.13)) ylabel(0.9(0.05)1.1) /*title("Consumption by `hhgroup' during `timestr'")*/ xtitle("Quarters to Start of Recession") name("`cvar'`timeper'`hhgroup'",replace)
		graph export "${FIGUREDIR}`cvar'`timeper'`hhgroup'.jpg", replace
		
		local t = `t' + 1
		}
		
		
	
	tempfile recessiondata	
	save `recessiondata', replace
	restore
		
	preserve
	clear 
	use `recessiondata'

		
	forvalues i = 1(1)3 {
		if(`i' == 1) {
			local hhstr = "Bottom 50%"
			}
		else if(`i' == 2) {
			local hhstr = "Middle class (50%-90%)"
			}
		else {
			local hhstr = "Top 10%"
			}
		
		line `cvar'_ma_dotcom dist2dotcom  if inrange(dist2dotcom,-8,8) & `hhgroup'groups == `i' , lpattern(-) lcolor(blue)  || /*
      */ line `cvar'_ma_greatrecession dist2greatrecession  if inrange(dist2greatrecession,-8,8) & `hhgroup'groups == `i' , lpattern(-) lcolor(red) || /*
		*/ line `cvar'_ma_covid dist2covid  if inrange(dist2covid,-8,8) & `hhgroup'groups == `i' , lpattern(-) lcolor(green) || /*
		*/ scatter `cvar'_dotcom dist2dotcom  if inrange(dist2dotcom ,-8,8) & `hhgroup'groups == `i' , mcolor(blue) msymbol(O) msize(large) || /*
		*/ scatter `cvar'_greatrecession dist2greatrecession  if inrange(dist2greatrecession,-8,8) & `hhgroup'groups == `i' , mcolor(red) msymbol(S) msize(large) || /*
		*/ scatter `cvar'_covid dist2covid  if inrange(dist2covid,-8,8) & `hhgroup'groups == `i' , mcolor(green) msymbol(D) msize(large)  /*
		*/ legend(order(4 5 6) rows(1) pos(6) ring(0) lab(4 "Dotcom") lab(5 "Financial Crisis") lab(6 "Covid") ) xtitle("Quarters to Start of Recession") /*
	*/ ysc(r(0.87 1.13)) ylabel(0.9(0.05)1.10) /*title("Consumption of `hhstr' `hhgroup'")*/ name("`cvar'households`hhgroup'`i'",replace)
	
		graph export "${FIGUREDIR}`cvar'households`hhgroup'`i'.jpg", replace
		} 
	}
	restore
	
 }


foreach timeper in "dotcom" "greatrecession" "covid"  { 
	preserve
	 
	collapse (mean) consum relcons income relincome [pw = cop_share], by(dist2`timeper' wealthgrid)


	gen relincome0 = relincome
	gen relcons0 = relcons
	foreach cvar in "relincome" "relcons" {
		forvalues i = 1(1)10 {
			quietly : sum `cvar' if inrange(dist2`timeper',-2,2) & wealthgrid == `i' 
			replace `cvar'0 = `cvar' / `r(mean)' if wealthgrid == `i' 
			}
		}
	scatter relincome0  wealthgrid if dist2`timeper' == 4, mcolor(blue) msymbol(O) msize(large) || /*
	*/ scatter relcons0 wealthgrid if dist2`timeper' == 4, mcolor(red) msymbol(S) msize(large) || /*
	*/ qfit relcons0 wealthgrid if dist2`timeper' == 4 , lpattern(dash) lcolor(red) || /*
	*/ qfit relincome0 wealthgrid if dist2`timeper' == 4, lpattern(dash) lcolor(blue) /*
	*/ legend(order(1 2) rows(1) pos(6) ring(0) lab(1 "Rel. Income Change") lab(2 "Rel. Consumption Change")) name(ConsDQ4`timeper', replace) xtitle("Wealth decile")

	restore
	}

 
 
 
xxxx


preserve

collapse rel_cons [pw = cop_share], by(timenum householdgroup)
gen dist2dotcom = timenum - 2001.25
gen dist2greatrecession = timenum - 2008
gen dist2covid = timenum - 2020

foreach timeper in "dotcom" "greatrecession" "covid" {
gen rel_cons_`timeper' = rel_cons
forvalues i = 1(1)4 {
	quietly : sum rel_cons if dist2`timeper' == 0 & householdgroup == `i' 
	replace rel_cons_`timeper' = rel_cons_`timeper' /(`r(mean)') if householdgroup == `i'
	}

line rel_cons_`timeper' dist2`timeper' if inrange(dist2`timeper',-2,2) & householdgroup == 1 ||/*
*/ line rel_cons_`timeper' dist2`timeper' if inrange(dist2`timeper',-2,2) & householdgroup == 2 || /*
*/ line rel_cons_`timeper' dist2`timeper' if inrange(dist2`timeper',-2,2) & householdgroup == 3 || /*
*/ line rel_cons_`timeper' dist2`timeper' if inrange(dist2`timeper',-2,2) & householdgroup == 4 , /*
*/ legend(lab(1 "low I-low W") lab(2 "low I-high W") lab(3 "high I-low W") lab(4 "high I-high W")) xscale(r(-2 2)) name("`timeper'",replace)
}
 
restore