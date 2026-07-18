* ─────────────────────────────────────────────────────────────
* consumption_recessions.do — consumption dynamics across recessions
* (the paper's fig: "Comparison of Consumption Dynamics during Recessions":
*  relcons{dotcom,greatrecession,covid}{income,wealth,iw}.jpg)
*
* Provenance: moved from "Code Moritz/LuisCode.do" (Nov 2025) — the live
* producer of the paper's panels. Input: the model's synthetic micro export
* "PSID_micro_data_A non-diag_.csv" (CreateTimeSeries/create_micro_df output,
* placed in DATADIR). Output: 7_Results/Application/with_time_varying_trend/,
* copied into the Overleaf Plots/consumption_plots/ tree for compilation.
* Standalone post-estimation step — not part of 00_master_data.do.
* ─────────────────────────────────────────────────────────────
	clear
	set more off

	/* Directories */
	global DATADIR = "/Users/lc/Dropbox/Distributional_Dynamics/5_Code/"
	global FIGUREDIR = "/Users/lc/Dropbox/Distributional_Dynamics/7_Results/Application/with_time_varying_trend/"


	/* Load data */
	import delimited "${DATADIR}PSID_micro_data_A non-diag_.csv", clear
	// import delimited "${DATADIR}PSID_micro_data_detrended_A non-diag_.csv", clear
	set scheme s1color
	graph set window fontface "Times New Roman"

	graph drop _all 

	// keep if implicate == 1

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
	gen relcons = consum / consum_mean
	gen relincome = income / income_mean

	/* Generate groups: bottom 50%, 50% - 90%, top 10% */
	gen wealthgroups = .
	replace  wealthgroups = 1 if wealthgrid <= 2
	replace  wealthgroups = 2 if (wealthgrid >= 3 & wealthgrid <= 4)
	replace  wealthgroups = 3 if (wealthgrid >= 5 & wealthgrid <= 8)
	replace  wealthgroups = 4 if wealthgrid >= 9

	gen incomegroups = .
	replace  incomegroups = 1 if incomegrid <= 2
	replace  incomegroups = 2 if (incomegrid >= 3 & incomegrid <= 4)
	replace  incomegroups = 3 if (incomegrid >= 5 & incomegrid <= 8)
	replace  incomegroups = 4 if incomegrid >= 9

	gen iwgroups = .
	replace iwgroups = 1 if incomegrid <= 2 & wealthgrid <= 2
	replace iwgroups = 2 if (incomegrid <= 4 & wealthgrid >= 8)
	replace iwgroups = 3 if incomegrid >= 5 & incomegrid <= 8 & wealthgrid >= 5 & wealthgrid <=8
	replace iwgroups = 4 if incomegrid >= 9 & wealthgrid >= 9
	// replace iwgroups = 3 if incomegrid <=3 & wealthgrid >= 9


	egen householdgroup  = group(wealthgroups incomegroups) 
	label define householdgroup_lbl 1 "B inc - B wea" 2 "M inc - B wea" 3 "T inc - B wea" /* 
	*/ 4 "B inc - M wea" 5 "M inc - M wea" 6 "T inc - M wea" /* 
	*/ 4 "B inc - T wea" 5 "M inc - T wea" 6 "T inc - T wea"  
	label value householdgroup householdgroup_lbl

	/* Consumption over time */
	foreach hhgroup in "wealth" "income" "iw" {
		
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
			forvalues i = 1(1)4 {
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
				if "`hhgroup'" == "iw" {
					local yscale_low = 0.75
					local yscale_high = 1.25
					
					local ylabel_low = 0.8
					local ylabel_high = 1.2
					
					local int_label = 0.1
				}
				else {
					local yscale_low = 0.87
					local yscale_high = 1.13
					
					local ylabel_low = 0.9
					local ylabel_high = 1.1
					
					local int_label = 0.05
				}
				
				if "`hhgroup'" == "iw" {
					local line_color "purple"
				}
				
				else {
					local line_color "red"
				}
				
			line `cvar'_ma_`timeper' dist2`timeper' if inrange(dist2`timeper',-8,8) & `hhgroup'groups == 1 , lpattern(-) lcolor(blue) ||/*
			*/ line `cvar'_ma_`timeper' dist2`timeper' if inrange(dist2`timeper',-8,8) & `hhgroup'groups == 2 , lpattern(-) lcolor(`line_color')  || /*  
			*/ line `cvar'_ma_`timeper' dist2`timeper' if inrange(dist2`timeper',-8,8) & `hhgroup'groups == 3 , lpattern(-) lcolor(green)  ||  /*  
			*/ line `cvar'_ma_`timeper' dist2`timeper' if inrange(dist2`timeper',-8,8) & `hhgroup'groups == 4 , lpattern(-) lcolor(maroon)  ||  /*  
			*/ scatter `cvar'_`timeper' dist2`timeper' if inrange(dist2`timeper',-8,8) & `hhgroup'groups == 1 , mcolor(blue) msymbol(O) msize(large) ||/*
			*/ scatter `cvar'_`timeper' dist2`timeper' if inrange(dist2`timeper',-8,8) & `hhgroup'groups == 2 , mcolor(`line_color') msymbol(S) msize(large) || /*  
			*/ scatter `cvar'_`timeper' dist2`timeper' if inrange(dist2`timeper',-8,8) & `hhgroup'groups == 3, mcolor(green) msymbol(D) msize(large) || /*  
			*/ scatter `cvar'_`timeper' dist2`timeper' if inrange(dist2`timeper',-8,8) & `hhgroup'groups == 4, mcolor(maroon) msymbol(T) msize(large) /*  
			*/ legend(off) /*
			*/ ysc(r(`yscale_low' `yscale_high')) ylabel(`ylabel_low'(`int_label')`ylabel_high') scale(1.4) /*title("Consumption by `hhgroup' during `timestr'")*/ xtitle("Quarters to Start of Recession") name("`cvar'`timeper'`hhgroup'",replace)
			graph export "${FIGUREDIR}`cvar'`timeper'`hhgroup'.jpg", replace
			
			local t = `t' + 1
			}		
			
		
		tempfile recessiondata	
		save `recessiondata', replace
		restore
			
		preserve
		clear 
		use `recessiondata'

			
		forvalues i = 1(1)4 {
			
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
 
foreach hhgroup in "wealth" "income" "iw" {
	
	preserve
	
	// Use the main dataset before it's collapsed for the recession analysis
	// We need to make sure the group variable is not missing
	keep if !missing(`hhgroup'groups)

	// Collapse the data by summing the cop_share for each group at each timeline point
	// This gives us the total population share of each group in each quarter
	collapse (sum) cop_share, by(timeline `hhgroup'groups)

	// --- Create a temporary variable for plot labels ---
	// This is a robust way to handle labels for the legend
// 	gen group_label = `hhgroup'groups
// 	if "`hhgroup'" == "wealth" {
// 		label define group_lbl 1 "Bottom 20% Wealth" 2 "Middle 40% Wealth" 3 "Top 20% Wealth"
// 		label values group_label group_lbl
// 	}
// 	else if "`hhgroup'" == "income" {
// 		label define group_lbl 1 "Bottom 20% Income" 2 "Middle 40% Income" 3 "Top 20% Income"
// 		label values group_label group_lbl
// 	}
// 	else if "`hhgroup'" == "iw" {
// 		label define group_lbl 1 "Low Inc & Wea" 2 "Mid Inc & Wea" 3 "Top Inc & Wea"
// 		label values group_label group_lbl
// 	}


	// --- Generate the Time Series Plot ---
	// Using the fvseries command can be cleaner for this type of plot
	twoway (line cop_share timeline if `hhgroup'groups == 1, lpattern(-) lcolor(blue)) ///
		   (line cop_share timeline if `hhgroup'groups == 2, lpattern(-) lcolor(red))  ///
		   (line cop_share timeline if `hhgroup'groups == 3, lpattern(-) lcolor(green)) ///
		   (line cop_share timeline if `hhgroup'groups == 4, lpattern(-) lcolor(black)), ///
		   ytitle("Population Share") ///
		   xtitle("Time") ///
		   title("Population Shares by `hhgroup' Groups") ///
		   legend(order(1 2 3) pos(1) rows(1) ring(0) `legend_labels') ///
		   name("cop_share_`hhgroup'", replace)

	graph export "${FIGUREDIR}cop_share_`hhgroup'.jpg", replace
	
	restore
}


// foreach timeper in "dotcom" "greatrecession" "covid"  { 
// 	preserve
//	 
// 	collapse (mean) consum relcons income relincome [pw = cop_share], by(dist2`timeper' wealthgrid)
//
//
// 	gen relincome0 = relincome
// 	gen relcons0 = relcons
// 	foreach cvar in "relincome" "relcons" {
// 		forvalues i = 1(1)10 {
// 			quietly : sum `cvar' if inrange(dist2`timeper',-2,2) & wealthgrid == `i' 
// 			replace `cvar'0 = `cvar' / `r(mean)' if wealthgrid == `i' 
// 			}
// 		}
// 	scatter relincome0  wealthgrid if dist2`timeper' == 4, mcolor(blue) msymbol(O) msize(large) || /*
// 	*/ scatter relcons0 wealthgrid if dist2`timeper' == 4, mcolor(red) msymbol(S) msize(large) || /*
// 	*/ qfit relcons0 wealthgrid if dist2`timeper' == 4 , lpattern(dash) lcolor(red) || /*
// 	*/ qfit relincome0 wealthgrid if dist2`timeper' == 4, lpattern(dash) lcolor(blue) /*
// 	*/ legend(order(1 2) rows(1) pos(6) ring(0) lab(1 "Rel. Income Change") lab(2 "Rel. Consumption Change")) name(ConsDQ4`timeper', replace) xtitle("Wealth decile")
//
// 	restore
// 	}

 
 

// xxxx

//
// preserve
//
// collapse rel_cons [pw = cop_share], by(timenum householdgroup)
// gen dist2dotcom = timenum - 2001.25
// gen dist2greatrecession = timenum - 2008
// gen dist2covid = timenum - 2020
//
// foreach timeper in "dotcom" "greatrecession" "covid" {
// gen rel_cons_`timeper' = rel_cons
// forvalues i = 1(1)4 {
// 	quietly : sum rel_cons if dist2`timeper' == 0 & householdgroup == `i' 
// 	replace rel_cons_`timeper' = rel_cons_`timeper' /(`r(mean)') if householdgroup == `i'
// 	}
//
// line rel_cons_`timeper' dist2`timeper' if inrange(dist2`timeper',-2,2) & householdgroup == 1 ||/*
// */ line rel_cons_`timeper' dist2`timeper' if inrange(dist2`timeper',-2,2) & householdgroup == 2 || /*
// */ line rel_cons_`timeper' dist2`timeper' if inrange(dist2`timeper',-2,2) & householdgroup == 3 || /*
// */ line rel_cons_`timeper' dist2`timeper' if inrange(dist2`timeper',-2,2) & householdgroup == 4 , /*
// */ legend(lab(1 "low I-low W") lab(2 "low I-high W") lab(3 "high I-low W") lab(4 "high I-high W")) xscale(r(-2 2)) name("`timeper'",replace)
// }
//
// restore


**# Detrended version 
clear
set more off

/* Directories */
global DATADIR = "/Users/lc/Dropbox/Distributional_Dynamics/5_Code/"
global FIGUREDIR = "/Users/lc/Dropbox/Distributional_Dynamics/7_Results/Application/with_constant_trend/"

set scheme s1color
graph set window fontface "Times New Roman"
graph drop _all 
/* Load data */
import delimited "${DATADIR}PSID_micro_data_detrended_A non-diag_.csv", clear
// import delimited "${DATADIR}PSID_micro_data_A non-diag_.csv", clear


// keep if implicate == 1

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

gen dist2gulf = (quarter - 3) + (year - 1990) * 4
gen dist2iran = (quarter - 3) + (year - 1981) * 4
gen dist2oil = (quarter - 4) + (year - 1973) * 4
gen dist2unemp = (quarter - 4) + (year - 1969) * 4

/* Generate quarterly averages */
tempfile timemean
preserve

collapse wealth consum income [pw = cop_share], by(timeline)

rename wealth wealth_mean
rename consum consum_mean 
rename income income_mean

// gen qdate = yq(year, quarter)
// format qdate %tq

keep *_mean timeline
save `timemean', replace

restore

/* Merge in quarterly averages */
merge m:1 timeline using `timemean'
drop _merge

// /* Construct consumption and income relative to mean */
// gen relcons = consum / consum_mean
// gen relincome = income / income_mean

xtset grid_point timeline

/* Generate groups: bottom 50%, 50% - 90%, top 10% */
	gen wealthgroups = .
	replace  wealthgroups = 1 if wealthgrid <= 2
	replace  wealthgroups = 2 if (wealthgrid >= 3 & wealthgrid <= 4)
	replace  wealthgroups = 3 if (wealthgrid >= 5 & wealthgrid <= 8)
	replace  wealthgroups = 4 if wealthgrid >= 9

	gen incomegroups = .
	replace  incomegroups = 1 if incomegrid <= 2
	replace  incomegroups = 2 if (incomegrid >= 3 & incomegrid <= 4)
	replace  incomegroups = 3 if (incomegrid >= 5 & incomegrid <= 8)
	replace  incomegroups = 4 if incomegrid >= 9

	gen iwgroups = .
	replace iwgroups = 1 if incomegrid <= 2 & wealthgrid <= 2
	replace iwgroups = 2 if (incomegrid <= 4 & wealthgrid >= 8)
	replace iwgroups = 3 if incomegrid >= 5 & incomegrid <= 8 & wealthgrid >= 5 & wealthgrid <=8
	replace iwgroups = 4 if incomegrid >= 9 & wealthgrid >= 9

egen householdgroup  = group(wealthgroups incomegroups) 
label define householdgroup_lbl 1 "B inc - B wea" 2 "M inc - B wea" 3 "T inc - B wea" /* 
*/ 4 "B inc - M wea" 5 "M inc - M wea" 6 "T inc - M wea" /* 
*/ 4 "B inc - T wea" 5 "M inc - T wea" 6 "T inc - T wea"  
label value householdgroup householdgroup_lbl

/* Consumption over time */
foreach hhgroup in "wealth" "income" "iw" {
	
	preserve
	
	/* Relative consumption around recessions by group */
	collapse (mean) consum (first) dist2* [pw = cop_share], by(timeline `hhgroup'groups)
	
	merge m:1 timeline using `timemean'
	drop _merge
	
	xtset `hhgroup'groups timeline

// 	replace consum = log(consum+1)
// 	replace consum_mean = log(consum_mean+1)
	sleep 5000
	
// 	* Generate trend 
// 	bysort `hhgroup'groups: gen t = _n
//	
// 	* Linear Detrend 
// 	levelsof `hhgroup'groups, local(for_loop)
// 	foreach g in  `for_loop' {
// 		reg consum t if `hhgroup'groups == `g'
// 		predict lin_trend
//		
// 		reg consum_mean t if `hhgroup'groups == `g'
// 		predict lin_trend2
//		
// 		replace consum = consum -  lin_trend if `hhgroup'groups == `g'
// 		replace consum_mean = consum_mean -  lin_trend2 if `hhgroup'groups == `g'
// 		tsline consum consum_mean if `hhgroup'groups == `g'
// 		sleep 10000
// 		drop lin_trend lin_trend2
// 	}
	
	gen relcons = consum / consum_mean
	
	* Detrend 
// 	gen consumption_cycle = .
// 	gen consumption_trend = .
// 	levelsof `hhgroup'groups, local(for_loop)
// 	foreach g in  `for_loop' {
// 		tsfilter hp cycle = consum if `hhgroup'groups == `g', smooth(1600) trend(trend)
// 		replace consumption_cycle = cycle if `hhgroup'groups == `g'
// 		replace consumption_trend = trend if `hhgroup'groups == `g'
// 		replace consum = consum - consumption_trend if `hhgroup'groups == `g'
// 		drop cycle trend
// 	}
	
	
	tssmooth ma relcons_ma = relcons, window(1 1 1)
// 	tssmooth ma consum_ma = consum , window(1 1 1)
	
	
	
	/* Create plots */
	foreach cvar in "relcons" /*"relcons" "consum"*/ {
	local t = 1
	foreach timeper in "dotcom" "greatrecession" "covid" "oil" "gulf" "unemp" "iran"  {
		gen `cvar'_`timeper' = `cvar'
		gen `cvar'_ma_`timeper' = `cvar'_ma
		forvalues i = 1(1)4 {
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
			
		if "`hhgroup'" == "iw" {
			local line_color "purple"
		}
		
		else {
			local line_color "red"
		}
		summ `cvar'_ma_`timeper' if inrange(dist2`timeper',-8,8) & !missing(`hhgroup'groups)
		local ysc_ub = r(max) + .01*r(max) 
		local ysc_lb = r(min) - .01*r(min) 
		line `cvar'_ma_`timeper' dist2`timeper' if inrange(dist2`timeper',-8,8) & `hhgroup'groups == 1 , lpattern(-) lcolor(blue) ||/*
		*/ line `cvar'_ma_`timeper' dist2`timeper' if inrange(dist2`timeper',-8,8) & `hhgroup'groups == 2 , lpattern(-) lcolor(`line_color')  || /*  
		*/ line `cvar'_ma_`timeper' dist2`timeper' if inrange(dist2`timeper',-8,8) & `hhgroup'groups == 3 , lpattern(-) lcolor(green)  ||  /*  
		*/ line `cvar'_ma_`timeper' dist2`timeper' if inrange(dist2`timeper',-8,8) & `hhgroup'groups == 4 , lpattern(-) lcolor(maroon)  ||  /*  
		*/ scatter `cvar'_`timeper' dist2`timeper' if inrange(dist2`timeper',-8,8) & `hhgroup'groups == 1 , mcolor(blue) msymbol(O) msize(large) ||/*
		*/ scatter `cvar'_`timeper' dist2`timeper' if inrange(dist2`timeper',-8,8) & `hhgroup'groups == 2 , mcolor(`line_color') msymbol(S) msize(large) || /*  
		*/ scatter `cvar'_`timeper' dist2`timeper' if inrange(dist2`timeper',-8,8) & `hhgroup'groups == 3, mcolor(green) msymbol(D) msize(large) || /* 
		*/ scatter `cvar'_`timeper' dist2`timeper' if inrange(dist2`timeper',-8,8) & `hhgroup'groups == 4, mcolor(maroon) msymbol(T) msize(large) /* 
		*/ legend(off) /*
		*/  xtitle("Quarters to Start of Recession") name("`cvar'`timeper'`hhgroup'",replace) ysc(r(`ysc_lb' `ysc_ub')) ylabel(#5)  scale(1.4)
		graph export "${FIGUREDIR}`cvar'`timeper'`hhgroup'.jpg", replace
		
		local t = `t' + 1
		}
// 				legend(order(4 5 6) pos(6) rows(1) ring(0) lab(4 "bottom 50%") lab(5 "middle class (50%-90%)") lab(6 "top 10%") )

		
// 		/ ysc(r(0.87 1.13)) ylabel(0.9(0.05)1.1)
	
// 	tempfile recessiondata	
// 	save `recessiondata', replace
// 	restore
//		
// 	preserve
// 	clear 
// 	use `recessiondata'
//
//		
// 	forvalues i = 1(1)3 {
// 		if(`i' == 1) {
// 			local hhstr = "Bottom 50%"
// 			}
// 		else if(`i' == 2) {
// 			local hhstr = "Middle class (50%-90%)"
// 			}
// 		else {
// 			local hhstr = "Top 10%"
// 			}
//		
// 		line `cvar'_ma_dotcom dist2dotcom  if inrange(dist2dotcom,-8,8) & `hhgroup'groups == `i' , lpattern(-) lcolor(blue)  || /*
//       */ line `cvar'_ma_greatrecession dist2greatrecession  if inrange(dist2greatrecession,-8,8) & `hhgroup'groups == `i' , lpattern(-) lcolor(red) || /*
// 		*/ line `cvar'_ma_covid dist2covid  if inrange(dist2covid,-8,8) & `hhgroup'groups == `i' , lpattern(-) lcolor(green) || /*
// 		*/ scatter `cvar'_dotcom dist2dotcom  if inrange(dist2dotcom ,-8,8) & `hhgroup'groups == `i' , mcolor(blue) msymbol(O) msize(large) || /*
// 		*/ scatter `cvar'_greatrecession dist2greatrecession  if inrange(dist2greatrecession,-8,8) & `hhgroup'groups == `i' , mcolor(red) msymbol(S) msize(large) || /*
// 		*/ scatter `cvar'_covid dist2covid  if inrange(dist2covid,-8,8) & `hhgroup'groups == `i' , mcolor(green) msymbol(D) msize(large)  /*
// 		*/ legend(order(4 5 6) rows(1) pos(6) ring(0) lab(4 "Dotcom") lab(5 "Financial Crisis") lab(6 "Covid") ) xtitle("Quarters to Start of Recession") /*
// 	*/ ysc(r(0.87 1.13)) ylabel(0.9(0.05)1.10) /*title("Consumption of `hhstr' `hhgroup'")*/ name("`cvar'households`hhgroup'`i'",replace)
//	
// 		graph export "${FIGUREDIR}`cvar'households`hhgroup'`i'.jpg", replace
// 		} 
	}
	restore
	
 }

//
// foreach timeper in "dotcom" "greatrecession" "covid"  { 
// 	preserve
//	 
// 	collapse (mean) consum relcons income relincome [pw = cop_share], by(dist2`timeper' wealthgrid)
//
//
// 	gen relincome0 = relincome
// 	gen relcons0 = relcons
// 	foreach cvar in "relincome" "relcons" {
// 		forvalues i = 1(1)10 {
// 			quietly : sum `cvar' if inrange(dist2`timeper',-2,2) & wealthgrid == `i' 
// 			replace `cvar'0 = `cvar' / `r(mean)' if wealthgrid == `i' 
// 			}
// 		}
// 	scatter relincome0  wealthgrid if dist2`timeper' == 4, mcolor(blue) msymbol(O) msize(large) || /*
// 	*/ scatter relcons0 wealthgrid if dist2`timeper' == 4, mcolor(red) msymbol(S) msize(large) || /*
// 	*/ qfit relcons0 wealthgrid if dist2`timeper' == 4 , lpattern(dash) lcolor(red) || /*
// 	*/ qfit relincome0 wealthgrid if dist2`timeper' == 4, lpattern(dash) lcolor(blue) /*
// 	*/ legend(order(1 2) rows(1) pos(6) ring(0) lab(1 "Rel. Income Change") lab(2 "Rel. Consumption Change")) name(ConsDQ4`timeper', replace) xtitle("Wealth decile")
//
// 	restore
// 	}
//
 
 

// xxxx

//
// preserve
//
// collapse rel_cons [pw = cop_share], by(timenum householdgroup)
// gen dist2dotcom = timenum - 2001.25
// gen dist2greatrecession = timenum - 2008
// gen dist2covid = timenum - 2020
//
// foreach timeper in "dotcom" "greatrecession" "covid" {
// gen rel_cons_`timeper' = rel_cons
// forvalues i = 1(1)4 {
// 	quietly : sum rel_cons if dist2`timeper' == 0 & householdgroup == `i' 
// 	replace rel_cons_`timeper' = rel_cons_`timeper' /(`r(mean)') if householdgroup == `i'
// 	}
//
// line rel_cons_`timeper' dist2`timeper' if inrange(dist2`timeper',-2,2) & householdgroup == 1 ||/*
// */ line rel_cons_`timeper' dist2`timeper' if inrange(dist2`timeper',-2,2) & householdgroup == 2 || /*
// */ line rel_cons_`timeper' dist2`timeper' if inrange(dist2`timeper',-2,2) & householdgroup == 3 || /*
// */ line rel_cons_`timeper' dist2`timeper' if inrange(dist2`timeper',-2,2) & householdgroup == 4 , /*
// */ legend(lab(1 "low I-low W") lab(2 "low I-high W") lab(3 "high I-low W") lab(4 "high I-high W")) xscale(r(-2 2)) name("`timeper'",replace)
// }
//
// restore

clear
set more off

/* Directories */
global DATADIR = "/Users/lc/Dropbox/Distributional_Dynamics/5_Code/"
global FIGUREDIR = "/Users/lc/Dropbox/Distributional_Dynamics/7_Results/Application/with_time_varying_trend/"


/* Load data */
import delimited "${DATADIR}PSID_micro_data_A non-diag_.csv", clear
set scheme s1color
graph set window fontface "Times New Roman"

graph drop _all 

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


//==============================================================================
// MODIFICATION 1: Define HANK Groups
// We define three groups based on the joint income/wealth distribution.
// The grids are assumed to be deciles (1-10), so 5 marks the 50th percentile.
//==============================================================================

gen hank_group = .
// Group 1: Poor Hand-to-Mouth (Bottom 50% income, Bottom 50% wealth)
replace hank_group = 1 if incomegrid <= 5 & wealthgrid <= 5

// Group 2: Wealthy Hand-to-Mouth (Bottom 50% income, Top 50% wealth)
replace hank_group = 2 if incomegrid < 4 & wealthgrid >= 6 & wealthgrid <=9

// Group 3: Wealthy Non-Hand-to-Mouth / "Savers" (Top 50% income, Top 50% wealth)
replace hank_group = 3 if incomegrid > 5 & wealthgrid > 5


label define hank_group_lbl 1 "Poor HtM" 2 "Wealthy HtM" 3 "Wealthy Savers"
label values hank_group hank_group_lbl

//==============================================================================
// MODIFICATION 2: Simplify the main loop to use the new HANK groups
//==============================================================================

/* Consumption over time for HANK groups */
preserve

/* Relative consumption around recessions by group */
// Note: We now use `hank_group` instead of the old grouping variables
collapse (mean) consum (first) dist2* [pw = cop_share], by(timeline hank_group)

// Drop observations for groups we didn't define (e.g., low-income savers)
drop if missing(hank_group)

xtset hank_group timeline
tssmooth ma consum_ma = consum , window(1 1 1)

/* Create plots */
local t = 1
foreach timeper in "dotcom" "greatrecession" "covid"  {
	gen consum_`timeper' = consum
	gen consum_ma_`timeper' = consum_ma
	
	// Normalize consumption relative to the value at the start of the recession (t=0)
	forvalues i = 1(1)3 {
		quietly : sum consum_ma if dist2`timeper' == 0 & hank_group == `i' 
		replace consum_`timeper' = consum_`timeper' /(`r(mean)') if hank_group  == `i'
		replace consum_ma_`timeper' = consum_ma_`timeper' /(`r(mean)') if hank_group  == `i'
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
	
	// PLOT 1: Compare the 3 HANK groups within each recession
	line consum_ma_`timeper' dist2`timeper' if inrange(dist2`timeper',-8,8) & hank_group == 1 , lpattern(-) lcolor(blue) ||/*
	*/ line consum_ma_`timeper' dist2`timeper' if inrange(dist2`timeper',-8,8) & hank_group == 2 , lpattern(-) lcolor(red)  || /*  
	*/ line consum_ma_`timeper' dist2`timeper' if inrange(dist2`timeper',-8,8) & hank_group == 3 , lpattern(-) lcolor(green)  ||  /*  
	*/ scatter consum_`timeper' dist2`timeper' if inrange(dist2`timeper',-8,8) & hank_group == 1 , mcolor(blue) msymbol(O) msize(large) ||/*
	*/ scatter consum_`timeper' dist2`timeper' if inrange(dist2`timeper',-8,8) & hank_group == 2 , mcolor(red) msymbol(S) msize(large) || /*  
	*/ scatter consum_`timeper' dist2`timeper' if inrange(dist2`timeper',-8,8) & hank_group == 3, mcolor(green) msymbol(D) msize(large) /*  
	*/ legend(order(4 5 6) pos(6) rows(1) ring(0) lab(4 "Poor HtM") lab(5 "Wealthy HtM") lab(6 "Wealthy Savers") ) /*
	*/ ytitle("Consumption (Normalized to 1 at t=0)") scale(1.4) title("Consumption by HANK Group during `timestr'") xtitle("Quarters to Start of Recession") name("consum_`timeper'",replace)
	
	graph export "${FIGUREDIR}consum_`timeper'.jpg", replace
	
	local t = `t' + 1
}
	
// Create a temporary file to hold the collapsed data for the next set of plots
tempfile recessiondata	
save `recessiondata', replace
restore
	
preserve
clear 
use `recessiondata'
	
// PLOT 2: Compare the 3 recessions for each HANK group
forvalues i = 1(1)3 {
	// Get the string label for the current group for the title
	local group_label : label (hank_group) `i'
	
	line consum_ma_dotcom dist2dotcom  if inrange(dist2dotcom,-8,8) & hank_group == `i' , lpattern(-) lcolor(blue)  || /*
  */ line consum_ma_greatrecession dist2greatrecession  if inrange(dist2greatrecession,-8,8) & hank_group == `i' , lpattern(-) lcolor(red) || /*
	*/ line consum_ma_covid dist2covid  if inrange(dist2covid,-8,8) & hank_group == `i' , lpattern(-) lcolor(green) || /*
	*/ scatter consum_dotcom dist2dotcom  if inrange(dist2dotcom ,-8,8) & hank_group == `i' , mcolor(blue) msymbol(O) msize(large) || /*
	*/ scatter consum_greatrecession dist2greatrecession  if inrange(dist2greatrecession,-8,8) & hank_group == `i' , mcolor(red) msymbol(S) msize(large) || /*
	*/ scatter consum_covid dist2covid  if inrange(dist2covid,-8,8) & hank_group == `i' , mcolor(green) msymbol(D) msize(large)  /*
	*/ legend(order(4 5 6) rows(1) pos(6) ring(0) lab(4 "Dotcom") lab(5 "Financial Crisis") lab(6 "Covid") ) xtitle("Quarters to Start of Recession") /*
	*/ ytitle("Consumption (Normalized to 1 at t=0)") title("Consumption of `group_label' Households") name("consum_recessions_for_group`i'",replace)

	graph export "${FIGUREDIR}consum_recessions_for_group`i'.jpg", replace
	} 
restore

