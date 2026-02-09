**# Prep micro data 

* Import most current Pearson and save to .dta
// import delimited "$data_path/consensus_pearson_A non-diag_.csv", stringcols(1) clear 
//
// save "$init_path/2_Data_processing/consensus_pearson.dta", replace
//other file: save "/Users/lc/Dropbox/Distributional_Dynamics/2_Data_processing/functional_data.dta", replace


* Import functional data 
foreach data_name in CEX_all {
	clear all 
	global measures consum_and_income_and_wealth
global meas_list consum income wealth
global max_grid_point 10
global init_path /Users/lc/Dropbox/Distributional_Dynamics
global data_path "$init_path/7_Results/$measures/from_mcmc/data" // check this directory

	import delimited "$data_path/`data_name'_micro_data_A non-diag_.csv", clear
	set scheme s1color
	graph set window fontface "Times New Roman"
	graph drop _all 

	* Aggregate over income and consumption grid 
	collapse (sum) cop_share (mean) consum income, by(incomegrid consumgrid time)

	* clean
	gen qdate = quarterly(time, "YQ")
	format qdate %tq
	drop time 
	rename qdate quarter 



	* Merge in shocks 
	merge m:1 quarter using "/Users/lc/Dropbox/Distributional_Dynamics/1_Data/shocks/all_shocks.dta"
	drop _merge

	rename quarter yq 
	
	merge m:1 yq using "/Users/lc/Dropbox/Distributional_Dynamics/7_Results/coibion_replication/replication_folder/my_files/external_data_files/rr_shocks_coibion.dta"
drop _merge 

	// * Merge in aggregates 
	// merge m:1 quarter using "/Users/lc/Dropbox/Distributional_Dynamics/2_Data_processing/lp_data.dta"
	// drop _merge

	rename yq time 
	merge m:1 time using "/Users/lc/Dropbox/Distributional_Dynamics/1_Data/shocks/romer_romer_MP/RR_monetary_shock_quarterly.dta"
	drop _merge

	merge m:1 time using "/Users/lc/Dropbox/Distributional_Dynamics/1_Data/shocks/Aruoba_Drechsel/Aruoba_Drechsel_Data_quarterly.dta"
	drop _merge 


	drop if time < date("1960-01-01", "YMD")  // to keep things slightly neater

	* Convert integers to strings and concatenate
	gen combined_str = string(incomegrid) + string(consumgrid)

	* Convert the concatenated string back to numeric
	gen grid_point = real(combined_str)

	xtset grid_point time



	* Generate year variable 
	gen year = year(dofq(time))
	la var consum "Consumption"
	la var income "Income"

	**# Shock treatment 
	rename EXOGENRRATIO standard_tax_FP
	// rename ramey_gov_shocks standard_gov_FP  // this should instrument variation in government spending  
	//
	//
	// la var MP_median "Monetary Policy"  // sd shock 
	// la var FG_shock "Forward Guidance"  // sd shock 
	la var standard_tax_FP "Tax"  // percent of GDP 
	// la var standard_gov_FP "Government Spending"
	//
	// rename MP_median MP
	la var resid_full "Romer-Romer (2004)" // percentage point changes in the FFR
	la var aruoba_mp "Aruoba-Drechsel (2023)" // percentage point changes in the FFR. If multiplied by 100, then basis points 
	la var MP_median "Jarocinski-Karadi (2020)"
	la var CBI_median "C.B. Info. Jarocinski-Karadi (2020)"  

	rename resid_full rr
	rename MP_median jk

	* Scaling shocks to 25 basis point contractionary shocks 
	foreach var in jk rr sh_rr aruoba_mp CBI_median {
	replace `var' = `var' * 100 // to scale it to basis points
	replace `var' = `var' / 25  // scale the effect to 25 point shocks	
	}
	
// 	foreach var in rr sh_rr {
// 		replace `var' = jk if missing(`var')
// 	}

	rename standard_tax_FP FP
	global H=12

// 	if "`var'" == "PSID" {
// 		global H=4
// 	}
// 	else {
// 		global H=12
// 	}
		
	* So that results are comparable across data 
	drop if time <= tq(1999q1)
		
	global rounding .00001
	global ysize 10
	global xsize 10
	global split_param = 6
	gen quarter = quarter(dofq(time))
	replace cop_share = . if cop_share < 0


	drop if missing(consum)
	tab time

	global y_unit = "%"
	xtset grid_point time

	global SHOCKS jk //sh_rr rr


	replace consum = 100*log(1+ consum)

	gen income_groups = .
	replace income_groups = 1 if incomegrid <= 4
	replace income_groups = 2 if incomegrid > 4 & incomegrid <= 7
	replace income_groups = 3 if incomegrid > 7
	replace income_groups =. if missing(incomegrid)

	foreach shock in $SHOCKS {
		* First define the set of controls 
		global call
		forvalues i=1(1)10 {
	// 		forvalues i=1(1)3 {

			cap restore 
			preserve 
			collapse (mean) consum (first) `shock' if incomegrid == `i' [pw=cop_share], by(time)
	// 		collapse (mean) consum (first) `shock' if income_groups == `i' [pw=cop_share], by(time)

			tsset time 
			local var var`i' // because of collapse
			
			* Containers
			matrix `var'level = J($H + 1, 1, 0)	
			matrix `var'level_lb = J($H + 1, 1, 0)
			matrix `var'level_ub = J($H + 1, 1, 0)
			matrix `var'cilb = J($H + 1, 1, 0)	
			matrix `var'ciub = J($H + 1, 1, 0)	
			matrix `var'cumul_vector = J($H + 1, 1, 0)
			matrix `var'se = J($H + 1, 1, 0)
			
			
			global rcall 
			forvalues h = 0/$H{
				qui gen consumption_`h' = f`h'.consum - l.consum
				
				if `h' == 0 {	
					qui ivreg2 consumption_`h' l(1/$H).d.consum l(1/$H).`shock', bw(auto) robust
					qui predict r`h', resid
					global rcall $rcall r`h'
				}

				
				else {
					qui ivreg2 consumption_`h' l(1/$H).d.consum l(1/$H).`shock' $rcall, robust
					qui predict r`h', resid
					global rcall $rcall r`h'
				}
				
				matrix `var'level[`h'+1,1] = round(_b[l.`shock'], $rounding)
				matrix `var'level_lb[`h'+1,1] = round(_b[l.`shock'] - _se[l.`shock'], $rounding)			
				matrix `var'level_ub[`h'+1,1] = round(_b[l.`shock'] + _se[l.`shock'], $rounding)
				matrix `var'ciub[`h'+1,1] = round(_b[l.`shock'] + 2*_se[l.`shock'], $rounding)			 
				matrix `var'cilb[`h'+1,1] = round(_b[l.`shock'] - 2*_se[l.`shock'], $rounding) 
				matrix `var'cumul_vector[`h'+1,1] = round(_b[l.`shock'], $rounding)
				matrix `var'se[`h'+1,1] = round(_se[l.`shock'], $rounding)


				cap drop consumption_`h'
			}
			
			forvalues a=0(1)$H {
					drop r`a'
			}
			
				
			svmat `var'level, names(`var'level)
			svmat `var'level_lb, names(`var'level_lb)
			svmat `var'level_ub, names(`var'level_ub)
			svmat `var'cilb, names(`var'cilb)
			svmat `var'ciub, names(`var'ciub)
			svmat `var'se, names(`var'se)
				
		
			cap drop horizon 
			cap drop zeros
			cap gen horizon = _n-1 if _n<=$H+1
			cap gen zeros = 0 if horizon!=.

			if `i' == 1 {
				global  var_label "Consumption - `i'st Income Decile"	
			}
			else if `i' == 2 {
				global var_label "Consumption - `i'nd Income Decile"	
			}
			else if `i' == 3 {
				global var_label "Consumption - `i'rd Income Decile"	
			}
			else {
				global var_label "Consumption - `i'th Income Decile"	
			}
			 cd /Users/lc/Dropbox/Distributional_Dynamics/7_Results/IRFs
			
			twoway (rarea `var'ciub1 `var'cilb1 horizon, fcolor(gs14) lcolor(gs14)) ///
			(rarea `var'level_lb1 `var'level_ub1 horizon, fcolor(gs10) lcolor(gs10)) ///
			(line `var'level1 horizon, lcolor(green) lwidth(medthick)) ///
			(line zeros horizon, lcolor(black) lwidth(thin)), ///
			legend(off) ytitle("$var_label ($y_unit)", height(5)) /// 
			xtitle("Quarter", height(5)) ylabel(#4) xlabel(0(2)$H) title("") /// name(`data_name'_`shock'_irfci`i', replace) 
			saving(`data_name'_`shock'_irfci`i', replace) 
			
			graph export "`data_name'_`shock'_irfci`i'.pdf", replace
			
			global call $call "`data_name'_`shock'_irfci`i'.gph"
			drop `var'level1 `var'level_lb1 `var'level_ub1 `var'cilb1 `var'ciub1 `var'se
			graph drop _all
			
		}
		loc shock_label: var l `shock'
		gr combine $call, ysize($ysize) xsize($xsize) title("Shocks on Consumption: `shock_label'", height(10)) ///
		saving(`data_name'_`shock'_irfci, replace) 
		graph export "`data_name'_`shock'_irfci.pdf", replace
		graph drop _all 
	}
	graph drop _all

}
