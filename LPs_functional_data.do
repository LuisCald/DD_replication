**# ISSUES HERE: 
* (1)taking "logs" doesnt work for the quantiles at the end of the distribution ... 
* (2) tail dependence files, granular have new names. Need to be imported 
* (3) missing copula stuff 

**# SOLUTIONS: 
* (1) doing group averages? 
* (2) labor basically 
* (3) will have to make a function that adjusts/collapses to the variables of interest 

**# Preliminaries
global init_path /Users/lc/Dropbox/Distributional_Dynamics
cd "$init_path/5_Code"
do prep_functional_data
cd "$init_path/7_Results/IRFs"

**# Transmission of MP and FP on marginals
global p=4
global rounding .00001

global H=12
global ysize 10
global xsize 10
cd /Users/lc/Dropbox/Distributional_Dynamics/7_Results/IRFs/functional_data

local grouplist "QUANTS LEVELS SHARES poor_poor poor_rich rich_poor rich_rich cop_quads ktau pcorr" // tail_dep
tsset time
foreach shock in $SHOCKS {
	foreach group of local grouplist {
		
		global y_unit = "%"
		global call
		foreach var in $`group' {

		* Containers
		matrix `var'level = J($H + 1, 1, 0)	
		matrix `var'level_lb = J($H + 1, 1, 0)
		matrix `var'level_ub = J($H + 1, 1, 0)
		matrix `var'cilb = J($H + 1, 1, 0)	
		matrix `var'ciub = J($H + 1, 1, 0)	
		matrix `var'cumul_vector = J($H + 1, 1, 0)
		matrix `var'se = J($H + 1, 1, 0)
		
		* For the significance bands 
// 		matrix `var's_hat  = J($H + 1, 1, 0)
// 		matrix `var'sig_lb = J($H + 1, 1, 0)
// 		matrix `var'sig_ub = J($H + 1, 1, 0)


		global rcall 
		forvalues h = 0/$H{
			
			* Cumulative 
			qui gen `var'_`h' = f`h'.`var' - l.`var'

			
			if `h' == 0 {	
				* Following Lusompa (2021)
				qui ivreg2 `var'_`h' l(1/$H).d.`var' l(1/$H).`shock', bw(auto) robust
				qui predict r`h', resid
				global rcall $rcall r`h'
			}

			
			else {

				qui ivreg2 `var'_`h' l(1/$H).d.`var' l(1/$H).`shock' $rcall, robust
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
			
			* Save significance bands
// 			matrix `var'sig_lb[`h'+1, 1] = (invnormal(0.1 / (2 * $H)) * `var's_hat[1, 1])
// 			matrix `var'sig_ub[`h'+1, 1] = (invnormal(1 - 0.1 / (2* $H)) * `var's_hat[1, 1])
			

			drop `var'_`h' 
		}
// 		drop eta
// 		 hp_`var'
		forvalues i=0(1)$H {
			drop r`i'
		}
			
			svmat `var'level, names(`var'level)
			svmat `var'level_lb, names(`var'level_lb)
			svmat `var'level_ub, names(`var'level_ub)
			svmat `var'cilb, names(`var'cilb)
			svmat `var'ciub, names(`var'ciub)
			svmat `var'se, names(`var'se)
// 			svmat `var'sig_lb, names(`var'sig_lb)
// 			svmat `var'sig_ub, names(`var'sig_ub)
			
	
		cap drop horizon 
		cap drop zeros
		cap gen horizon = _n-1 if _n<=$H+1
		cap gen zeros = 0 if horizon!=.
	
		loc label: var l `var'
		twoway (rarea `var'ciub1 `var'cilb1 horizon, fcolor(gs14) lcolor(gs14)) ///
		(rarea `var'level_lb1 `var'level_ub1 horizon, fcolor(gs10) lcolor(gs10)) ///
		(line `var'level1 horizon, lcolor(blue) lwidth(medthick)) ///
		(line zeros horizon, lcolor(black) lwidth(thin)), ///
		legend(off) ytitle("`label' ($y_unit)") xtitle("Quarter", height(5)) ylabel(#4) xlabel(0(2)$H) title("") name(irf_`var', replace) saving(irf_`var', replace) nodraw
		global call $call "irf_`var'"
		drop `var'level1 `var'level_lb1 `var'level_ub1 `var'cilb1 `var'ciub1 `var'se
		// 		(line `var'sig_lb horizon, lpattern("-...-") lcolor(black) lwidth(thick)) ///
// 		(line `var'sig_ub horizon, lpattern("-...-") lcolor(black) lwidth(thick)) ///
	}
	if "`group'" == "QUANTS" |  "`group'" == "LEVELS" |  "`group'" == "SHARES" {
		global plot_title  "marginals" 
	}
	else {
		global plot_title  "copula" 
	}
	
	
	loc shock_label: var l `shock'
	gr combine $call, ysize($ysize) xsize($xsize) title("Shocks along the $plot_title: `shock_label'", height(10)) name(`group'_`shock'_$measures, replace) 
	graph export "cop_`group'_`shock'_$measures.pdf", as(pdf) replace
	graph drop _all 
}
}





**# Comparing DFA IRFs to ours 
global init_path /Users/lc/Dropbox/Distributional_Dynamics
cd "$init_path/5_Code"
do prep_functional_data
cd "$init_path/7_Results/IRFs/DFA_comparison"

* Merge in the DFA data 
merge 1:1 time using "$init_path/2_Data_processing/DFA.dta"
drop _merge


* Undo the log transformation, add stuff together and log again 
foreach var in $QUANTS {
	replace `var' = sign(`var') * (exp(abs(`var') / 100) - 1) 
}

gen wealthquantile_bottom50 = (quantileswealth_50+ quantileswealth_40+ quantileswealth_30+ quantileswealth_20+ quantileswealth_10) / 5
gen wealthquantile_next40 = (quantileswealth_60+ quantileswealth_70+ quantileswealth_80+ quantileswealth_90) / 4
gen wealthquantile_top10 = quantileswealth_100


rename wealthquantile_bottom50 wqbottom50 
rename wealthquantile_next40 wqnext40
rename wealthquantile_top10 wqtop10

rename wealthquantile_bottom50_DFA wqbottom50DFA
rename wealthquantile_next40_DFA wqnext40DFA
rename  wealthquantile_top10_DFA wqtop10DFA

global DFA_series wqnext40DFA wqtop10DFA wqbottom50DFA
global reconstruction_series wqnext40 wqtop10 wqbottom50

foreach var in $DFA_series $reconstruction_series {
	replace `var' = 100 * sign(`var') * log(abs(`var') + 1)
}

la var wqbottom50 "Bottom 50"
la var wqnext40 "Next 40"
la var wqtop10 "Top 10"

la var wqbottom50DFA "Bottom 50"
la var wqnext40DFA "Next 40"
la var wqtop10DFA "Top 10"

gen sample1 = !missing(wealthlevels_bottom50_DFA)

global p=4
global rounding=.00001

global H=8	
global ysize 10
global xsize 10

global num_vars : word count $DFA_series
tsset time

foreach shock in $SHOCKS {
	global call  
	forval i = 1/$num_vars {
    
		local var1 : word `i' of $DFA_series
		local var2 : word `i' of $reconstruction_series

		* Containers
		foreach V in `var1' `var2' {
			matrix `V'level = J($H + 1, 1, 0)	
			matrix `V'level_lb = J($H + 1, 1, 0)
			matrix `V'level_ub = J($H + 1, 1, 0)
			matrix `V'cilb = J($H + 1, 1, 0)	
			matrix `V'ciub = J($H + 1, 1, 0)	
			matrix `V'cumul_vector = J($H + 1, 1, 0)
			matrix `V'se = J($H + 1, 1, 0)	

			gen sample = !missing(`var1')
			global condition if sample == 1
			
			global rcall
			
			* Generate forward differences 
			forvalues h = 0/$H{

				qui gen `V'_`h' = f`h'.`V' - l.`V'
				
				if `h' == 0 {	
					qui ivreg2 `V'_`h' l(1/$H).d.`V' l(1/$H).`shock' $condition, bw(auto) robust
					qui predict r`h', resid
					global rcall $rcall r`h'
				}

			
				else {
					qui ivreg2 `V'_`h' l(1/$H).d.`V' l(1/$H).`shock' $rcall $condition, robust
					qui predict r`h', resid
					global rcall $rcall r`h'
				}
				
				matrix `V'level[`h'+1,1] = round(_b[l.`shock'], $rounding)
				matrix `V'level_lb[`h'+1,1] = round(_b[l.`shock'] - _se[l.`shock'], $rounding)			
				matrix `V'level_ub[`h'+1,1] = round(_b[l.`shock'] + _se[l.`shock'], $rounding)	    	
				matrix `V'ciub[`h'+1,1] = round(_b[l.`shock'] + 2*_se[l.`shock'], $rounding)			 
				matrix `V'cilb[`h'+1,1] = round(_b[l.`shock'] - 2*_se[l.`shock'], $rounding) 
				matrix `V'se[`h'+1,1] = round(_se[l.`shock'], $rounding)

				* Save significance bands
// 				matrix `V'sig_lb[`h'+1, 1] = (invnormal(0.1 / (2 * $H)) * `V's_hat[1, 1])
// 				matrix `V'sig_ub[`h'+1, 1] = (invnormal(1 - 0.1 / (2* $H)) * `V's_hat[1, 1])
				
				
				drop `V'_`h'
			}
			drop sample
				forvalues yy=0(1)$H {
					drop r`yy'
				}

			
			svmat `V'level, names(`V'level)
			svmat `V'level_lb, names(`V'level_lb)
			svmat `V'level_ub, names(`V'level_ub)
			svmat `V'cilb, names(`V'cilb)
			svmat `V'ciub, names(`V'ciub)
			svmat `V'se, names(`V'se)
// 			svmat `V'sig_lb, names(`V'sig_lb)
// 			svmat `V'sig_ub, names(`V'sig_ub)
		}
		
		cap drop horizon 
		cap drop zeros
		cap gen horizon = _n-1 if _n<=$H+1
		cap gen zeros = 0 if horizon!=.
	

		loc label: var l `var1'
		twoway 	(rarea `var1'ciub1 `var1'cilb1 horizon, fcolor(gs14) lcolor(gs14)) /// DFA
		(rarea `var2'ciub1 `var2'cilb1 horizon, fcolor(gs14) lcolor(gs14)) ///
		(rarea `var1'level_lb1 `var1'level_ub1 horizon, fcolor(red%30) lcolor(red%30)) ///
		(rarea `var2'level_lb1 `var2'level_ub1 horizon, fcolor(ltblue) lcolor(ltblue)) ///
		(line `var1'level1 horizon, lcolor(red) lwidth(medthick)) ///
		(line `var2'level1 horizon, lcolor(blue) lwidth(medthick)) ///
		(line zeros horizon, lcolor(black) lwidth(thin)), ///
		legend(off) ytitle("`label' (%)") xtitle("Quarter", height(5)) ylabel(#4) xlabel(0(2)$H) title("") name(DFA_irf_`i', replace) saving(DFA_irf_`i', replace) 
		
		graph export "DFA_irf_`i'.pdf", replace
		
		global call $call "DFA_irf_`i'"
		
		
		drop `var1'level1 `var1'level_lb1 `var1'level_ub1 `var1'cilb1 `var1'ciub1 `var1'se //`var1'sig_lb `var1'sig_ub
		drop `var2'level1 `var2'level_lb1 `var2'level_ub1 `var2'cilb1 `var2'ciub1 `var2'se //`var2'sig_lb `var2'sig_ub
// 				(line `var1'sig_lb1 horizon, lpattern("-...-") lcolor(red%50) lwidth(thick)) ///
// 		(line `var1'sig_ub1 horizon, lpattern("-...-") lcolor(red%50) lwidth(thick)) ///
// 		(line `var2'sig_lb1 horizon, lpattern("-...-") lcolor(blue%50) lwidth(thick)) ///
// 		(line `var2'sig_ub1 horizon, lpattern("-...-") lcolor(blue%50) lwidth(thick)) ///
		
	}
	loc shock_label: var l `shock'
	gr combine $call, ysize($ysize) xsize($xsize) title("Comparing IRFs: `shock_label'", height(10)) name(DFA_comparison_`shock', replace) 
	graph export "DFA_comparison_`shock'_$measures.pdf", as(pdf) replace
	graph drop _all 
}


**# Shock wealth by income, DFAs 
macro drop _all
global init_path /Users/lc/Dropbox/Distributional_Dynamics
cd "$init_path/5_Code"
do prep_micro_data
cd "$init_path/7_Results/IRFs"

* Compute wealth by income decile 
gen tot_wealth = wealth * (cop_share * tot_hhs)  // always double check wealth

* Identify all income decile groups 
gen income_groups = .
forvalues i=1(1)10 {
	local j = `i' + 1
	replace income_groups = `i' if grid_point > `i'0 & grid_point < `j'0 & !missing(grid_point)	
}

replace income_groups = 1 if grid_point == 110
replace income_groups = 2 if grid_point == 210
replace income_groups = 3 if grid_point == 310
replace income_groups = 4 if grid_point == 410
replace income_groups = 5 if grid_point == 510
replace income_groups = 6 if grid_point == 610
replace income_groups = 7 if grid_point == 710
replace income_groups = 8 if grid_point == 810
replace income_groups = 9 if grid_point == 910
replace income_groups = 10 if grid_point == 1010

bysort income_groups time: egen tot_wealthl = sum(tot_wealth) 

drop if missing(income_groups)
collapse (mean) tot_wealthl, by(time income_groups)
reshape wide tot_wealthl, i(time) j(income_groups)

rename time quarter

* Merge in shocks 
merge 1:1 quarter using "/Users/lc/Dropbox/Distributional_Dynamics/1_Data/shocks/all_shocks.dta"
drop _merge

* Merge in aggregates 
merge 1:1 quarter using "/Users/lc/Dropbox/Distributional_Dynamics/2_Data_processing/lp_data.dta"
drop _merge

* Merge in DFA data 
merge 1:1 quarter using "$init_path/2_Data_processing/wealth_by_income.dta"
drop _merge

rename quarter time 

merge 1:1 time using "$init_path/2_Data_processing/stationary_aggs.dta" 
drop _merge

tsset time
replace MP_median = MP_median * 100 // to scale it to basis points
replace MP_median = MP_median / 25  // 25 basis pt effect 
rename EXOGENRRATIO standard_tax_FP

la var MP_median "Monetary Policy"
la var standard_tax_FP "Tax"  // percent of GDP 

rename MP_median MP
rename standard_tax_FP FP

global SHOCKS MP FP  

* Generate wealth levels by income, big groups
gen wl_bottom40 =  tot_wealthl1  + tot_wealthl2+ tot_wealthl3+ tot_wealthl4
gen wl_next40   =  tot_wealthl5 + tot_wealthl6+ tot_wealthl7+ tot_wealthl8
gen wl_top20    =  tot_wealthl9 + tot_wealthl10

rename wealthlevels_bottom40_DFA wl_bottom40_DFA
rename wealthlevels_next40_DFA  wl_next40_DFA
rename wealthlevels_top20_DFA wl_top20_DFA

global DFA_series wl_next40_DFA wl_top20_DFA //wl_bottom40_DFA wl_next40_DFA wl_top20_DFA 
global reconstruction_series wl_next40 wl_top20 //wl_bottom40 wl_next40 wl_top20

local i = 4
foreach var in wl_bottom40 wl_next40 wl_top20 {
	replace `var' = 100 * sign(`var') * log(abs(`var') + 1)
	replace `var'_DFA = `var'_DFA * 1000000
	replace `var'_DFA = 100* sign(`var'_DFA) * log(abs(`var'_DFA) + 1)
	
	if `i' == 4 {
		la var `var' "Wealth by Income - Bottom 40"
		la var `var'_DFA "Wealth by Income - Bottom 40"
		local i = `i' + 4
	}
	
	else if `i' == 8 {
		la var `var' "Wealth by Income - Next 40"
		la var `var'_DFA "Wealth by Income - Next 40"
		local i = `i' + 2
	}
	
	else {
		la var `var' "Wealth by Income - Top 20"
		la var `var'_DFA "Wealth by Income - Top 20"
		local i = `i' + 2
	}
	
}

global H=8	
global ysize 10
global xsize 10
global p=4
global rounding .00001

global controls l(1/$p).TB3MS l(1/$p).SP500 l(1/$p).GDP l(1/$p).CPI_INFLATION
foreach var in FP MP TB3MS SP500 GDP CPI_INFLATION {
	forvalues i=1(1)$p {
			gen `var'_l`i' = l`i'.`var'
			summ `var'_l`i'
			replace `var'_l`i' = (`var'_l`i' - r(mean)) / r(sd)
	}
}


global num_vars : word count $DFA_series

foreach shock in $SHOCKS {
	pca `shock'_l1 `shock'_l2 `shock'_l3 `shock'_l4 TB3MS_l1 TB3MS_l2 ///
	TB3MS_l3 TB3MS_l4 SP500_l1 SP500_l2 SP500_l3 SP500_l4 GDP_l1 GDP_l2 ///
	GDP_l3 GDP_l4 CPI_INFLATION_l1 CPI_INFLATION_l2 CPI_INFLATION_l3 CPI_INFLATION_l4
	
	predict pc1 pc2 pc3 pc4 pc5

	global controls pc1 pc2 pc3 pc4 pc5
	
	
	* Get average
// 	gen var_fwl_`shock' = fwl_`shock' * fwl_`shock'
// 	matrix var_mean = J(1, 1, 0)
// 	summ var_fwl_`shock'
// 	mat var_mean[1,1] = r(mean)
	
	global call  
	forval i = 1/$num_vars {
    
		local var1 : word `i' of $DFA_series
		local var2 : word `i' of $reconstruction_series

		* Containers
		foreach V in `var1' `var2' {
			matrix `V'level = J($H + 1, 1, 0)	
			matrix `V'level_lb = J($H + 1, 1, 0)
			matrix `V'level_ub = J($H + 1, 1, 0)
			matrix `V'cilb = J($H + 1, 1, 0)	
			matrix `V'ciub = J($H + 1, 1, 0)	
			matrix `V'cumul_vector = J($H + 1, 1, 0)
			matrix `V'se = J($H + 1, 1, 0)	
			
			gen sample = !missing(`var1')
			global condition if sample == 1

			* For the significance bands 
// 			matrix `V's_hat  = J($H + 1, 1, 0)
// 			matrix `V'sig_lb = J($H + 1, 1, 0)
// 			matrix `V'sig_ub = J($H + 1, 1, 0)
//			
// 			tsfilter hp hp_`V' = `V', smooth(1600)
			global rcall
			
			* Generate forward differences 
			forvalues h = 0/$H{

				local q = $p - 1
				* Perform Frisch-Waugh-Lovell Theorem
				qui gen `V'_`h' = f`h'.`V' //- l.hp_`V'
				qui reg `V'_`h' l(1/`q').`V' $controls, robust // l(1/$p).`shock'
				predict fwl`V'`h', r
				
				* Frisch-Waugh-Lovell, save shocks 
				reg `shock' l(1/`q').`V' $controls, robust 
				predict fwl_`shock', r
				
				if `h' == 0 {	
					* Multiply DV with shock, regress product on constant, save NW s.e.
// 					gen eta = hp_fwl`V'`h' * fwl_`shock'
// 					qui newey eta, lag(8)
//				
// 					matrix `V's_hat[`h'+1, 1] = _se[_cons] / var_mean[1,1]
					
					* Following Lusompa (2021)
					ivreg2 fwl`V'`h' fwl_`shock' $condition, nocons bw(auto) robust
					qui predict r`h', resid
					global rcall $rcall r`h'
				}

			
				else {
					reg fwl`V'`h' fwl_`shock' $rcall $condition, nocons robust
					qui predict r`h', resid
					global rcall $rcall r`h'
				}
				
				matrix `V'level[`h'+1,1] = round(_b[fwl_`shock'], $rounding)
				matrix `V'level_lb[`h'+1,1] = round(_b[fwl_`shock'] - _se[fwl_`shock'], $rounding)			
				matrix `V'level_ub[`h'+1,1] = round(_b[fwl_`shock'] + _se[fwl_`shock'], $rounding)	    	
				matrix `V'ciub[`h'+1,1] = round(_b[fwl_`shock'] + 2*_se[fwl_`shock'], $rounding)			 
				matrix `V'cilb[`h'+1,1] = round(_b[fwl_`shock'] - 2*_se[fwl_`shock'], $rounding) 
				matrix `V'se[`h'+1,1] = round(_se[fwl_`shock'], $rounding)
				

				* Save significance bands
// 				matrix `V'sig_lb[`h'+1, 1] = (invnormal(0.1 / (2 * $H)) * `V's_hat[1, 1])
// 				matrix `V'sig_ub[`h'+1, 1] = (invnormal(1 - 0.1 / (2* $H)) * `V's_hat[1, 1])
				
				
				drop fwl`V'`h' `V'_`h' fwl_`shock'
			}
			drop sample
// 			drop eta hp_`V'
			drop r0 r1 r2 r3 r4 r5 r6 r7 r8 r9 r10 r11 r12
			
			svmat `V'level, names(`V'level)
			svmat `V'level_lb, names(`V'level_lb)
			svmat `V'level_ub, names(`V'level_ub)
			svmat `V'cilb, names(`V'cilb)
			svmat `V'ciub, names(`V'ciub)
			svmat `V'se, names(`V'se)
// 			svmat `V'sig_lb, names(`V'sig_lb)
// 			svmat `V'sig_ub, names(`V'sig_ub)
		}
		
		cap drop horizon 
		cap drop zeros
		cap gen horizon = _n-1 if _n<=$H+1
		cap gen zeros = 0 if horizon!=.
	
	
	

		loc label: var l `var1'
		twoway 	(rarea `var1'ciub1 `var1'cilb1 horizon, fcolor(gs14) lcolor(gs14)) /// DFA
		(rarea `var2'ciub1 `var2'cilb1 horizon, fcolor(gs14) lcolor(gs14)) ///
		(rarea `var1'level_lb1 `var1'level_ub1 horizon, fcolor(red%30) lcolor(red%30)) ///
		(rarea `var2'level_lb1 `var2'level_ub1 horizon, fcolor(ltblue) lcolor(ltblue)) ///
		(line `var1'level1 horizon, lcolor(red) lwidth(medthick)) ///
		(line `var2'level1 horizon, lcolor(blue) lwidth(medthick)) ///
		(line zeros horizon, lcolor(black) lwidth(thin)), ///
		legend(off) ytitle("`label' (%)") xtitle("Quarter", height(5)) ylabel(#4) xlabel(0(2)$H) title("") name(DFA_irf_`i', replace) saving(DFA_irf_`i', replace) nodraw
		global call $call "DFA_irf_`i'"
		drop `var1'level1 `var1'level_lb1 `var1'level_ub1 `var1'cilb1 `var1'ciub1 `var1'se //`var1'sig_lb `var1'sig_ub
		drop `var2'level1 `var2'level_lb1 `var2'level_ub1 `var2'cilb1 `var2'ciub1 `var2'se //`var2'sig_lb `var2'sig_ub
// 		(line `var1'sig_lb1 horizon, lpattern("-...-") lcolor(red%50) lwidth(thick)) ///
// 		(line `var1'sig_ub1 horizon, lpattern("-...-") lcolor(red%50) lwidth(thick)) ///
// 		(line `var2'sig_lb1 horizon, lpattern("-...-") lcolor(blue%50) lwidth(thick)) ///
// 		(line `var2'sig_ub1 horizon, lpattern("-...-") lcolor(blue%50) lwidth(thick)) ///
		
	}
	loc shock_label: var l `shock'
	gr combine $call, ysize($ysize) xsize($xsize) title("Comparing IRFs: `shock_label'", height(10)) name(DFA_levelscomparison_`shock', replace) 
	graph export "DFA_wealthbyincomelevels_`shock'_$measures.pdf", as(pdf) replace
	graph drop _all 
	drop pc1 pc2 pc3 pc4 pc5
}



**# Shock wealth by income, in general 
global init_path /Users/lc/Dropbox/Distributional_Dynamics
cd "$init_path/5_Code"
do prep_micro_data
cd "$init_path/7_Results/IRFs"

* Compute wealth by income decile 
gen tot_wealth = wealth * (cop_share * tot_hhs)

* Identify all income decile groups 
gen income_groups = .
forvalues i=1(1)10 {
	local j = `i' + 1
	replace income_groups = `i' if grid_point > `i'0 & grid_point < `j'0 & !missing(grid_point)	
}

replace income_groups = 1 if grid_point == 110
replace income_groups = 2 if grid_point == 210
replace income_groups = 3 if grid_point == 310
replace income_groups = 4 if grid_point == 410
replace income_groups = 5 if grid_point == 510
replace income_groups = 6 if grid_point == 610
replace income_groups = 7 if grid_point == 710
replace income_groups = 8 if grid_point == 810
replace income_groups = 9 if grid_point == 910
replace income_groups = 10 if grid_point == 1010

bysort income_groups time: egen tot_wealthl = sum(tot_wealth) 

drop if missing(income_groups)
collapse (mean) tot_wealthl, by(time income_groups)
reshape wide tot_wealthl, i(time) j(income_groups)

rename time quarter
* Merge in shocks 
merge 1:1 quarter using "/Users/lc/Dropbox/Distributional_Dynamics/1_Data/shocks/all_shocks.dta"
drop _merge

* Merge in aggregates 
merge 1:1 quarter using "/Users/lc/Dropbox/Distributional_Dynamics/2_Data_processing/lp_data.dta"
drop _merge

* Merge in DFA data 
merge 1:1 quarter using "$init_path/2_Data_processing/wealth_by_income.dta"
drop _merge

rename quarter time 

merge 1:1 time using "$init_path/2_Data_processing/stationary_aggs.dta" 
drop _merge

* Preliminaries 
global p=4
global rounding .00001
global outcomes tot_wealthl1 tot_wealthl2 tot_wealthl3 tot_wealthl4 tot_wealthl5 tot_wealthl6 tot_wealthl7 tot_wealthl8 tot_wealthl9 tot_wealthl10

local i = 1
foreach var in $outcomes {
	replace `var' = 100 * sign(`var') * log(abs(`var') + 1)
	la var `var' "Wealth by Income - `i'0ᵗʰ pct."
	local i = `i' + 1
}

tsset time
replace MP_median = MP_median * 100 /25 // to scale it to basis points
rename EXOGENRRATIO standard_tax_FP

la var MP_median "Monetary Policy"
la var standard_tax_FP "Tax"  // percent of GDP 

rename MP_median MP
rename standard_tax_FP FP

global SHOCKS MP FP  


global controls l(1/$p).TB3MS l(1/$p).SP500 l(1/$p).GDP l(1/$p).CPI_INFLATION
foreach var in FP MP TB3MS SP500 GDP CPI_INFLATION {
	forvalues i=1(1)$p {
			gen `var'_l`i' = l`i'.`var'
			summ `var'_l`i'
			replace `var'_l`i' = (`var'_l`i' - r(mean)) / r(sd)
	}
}

global H=8	
global ysize 10
global xsize 10


foreach shock in $SHOCKS {
	* First define the set of controls 
	pca `shock'_l1 `shock'_l2 `shock'_l3 `shock'_l4 TB3MS_l1 TB3MS_l2 TB3MS_l3 ///
	TB3MS_l4 SP500_l1 SP500_l2 SP500_l3 SP500_l4 GDP_l1 GDP_l2 GDP_l3 GDP_l4 ///
	CPI_INFLATION_l1 CPI_INFLATION_l2 CPI_INFLATION_l3 CPI_INFLATION_l4
	
	predict pc1 pc2 pc3 pc4 pc5

	global controls pc1 pc2 pc3 pc4 pc5
	
	
	* Get average
// 	gen var_fwl_`shock' = fwl_`shock' * fwl_`shock'
// 	matrix var_mean = J(1, 1, 0)
// 	summ var_fwl_`shock'
// 	mat var_mean[1,1] = r(mean)
	
	global call
	foreach var in $outcomes {
		* Containers
		matrix `var'level = J($H + 1, 1, 0)	
		matrix `var'level_lb = J($H + 1, 1, 0)
		matrix `var'level_ub = J($H + 1, 1, 0)
		matrix `var'cilb = J($H + 1, 1, 0)	
		matrix `var'ciub = J($H + 1, 1, 0)	
		matrix `var'cumul_vector = J($H + 1, 1, 0)
		matrix `var'se = J($H + 1, 1, 0)
		
		* For the significance bands 
// 		matrix `var's_hat  = J($H + 1, 1, 0)
// 		matrix `var'sig_lb = J($H + 1, 1, 0)
// 		matrix `var'sig_ub = J($H + 1, 1, 0)

		* Generate forward differences 
// 		tsfilter hp hp_`var' = `var', smooth(1600)
		
		global rcall 
		forvalues h = 0/$H{
			local q = $p - 1
			
			* Frisch-Waugh-Lovell, save shocks 
			reg `shock' l(1/`q').`var' $controls, robust //l(1/$p).`shock'
			predict fwl_`shock', r
			
			* Perform Frisch-Waugh-Lovell Theorem
			qui gen `var'_`h' = f`h'.`var' // - l.hp_`var'
			qui reg `var'_`h' l(1/`q').`var' $controls, robust 
			predict fwl`var'`h', r
			
			if `h' == 0 {	
				* Multiply DV with shock, regress product on constant, save NW s.e.
// 				gen eta = hp_fwl`var'`h' * fwl_`shock'
// 				qui newey eta, lag(8)
//			
// 				matrix `var's_hat[`h'+1, 1] = _se[_cons] / var_mean[1,1]
				
				* Following Lusompa (2021)
				qui ivreg2 fwl`var'`h' fwl_`shock', nocons bw(auto) robust
				qui predict r`h', resid
				global rcall $rcall r`h'
			}

			
			else {
				reg fwl`var'`h' fwl_`shock' $rcall, nocons robust
				qui predict r`h', resid
				global rcall $rcall r`h'
			}
			
			matrix `var'level[`h'+1,1] = round(_b[fwl_`shock'], $rounding)
			matrix `var'level_lb[`h'+1,1] = round(_b[fwl_`shock'] - _se[fwl_`shock'], $rounding)			
			matrix `var'level_ub[`h'+1,1] = round(_b[fwl_`shock'] + _se[fwl_`shock'], $rounding)
			matrix `var'ciub[`h'+1,1] = round(_b[fwl_`shock'] + 2*_se[fwl_`shock'], $rounding)			 
			matrix `var'cilb[`h'+1,1] = round(_b[fwl_`shock'] - 2*_se[fwl_`shock'], $rounding) 
			matrix `var'cumul_vector[`h'+1,1] = round(_b[fwl_`shock'], $rounding)
			matrix `var'se[`h'+1,1] = round(_se[fwl_`shock'], $rounding)
			
			* Save significance bands
// 			matrix `var'sig_lb[`h'+1, 1] = (invnormal(0.1 / (2 * $H)) * `var's_hat[1, 1])
// 			matrix `var'sig_ub[`h'+1, 1] = (invnormal(1 - 0.1 / (2* $H)) * `var's_hat[1, 1])
			

			drop fwl`var'`h' `var'_`h' fwl_`shock' 
		}
// 		drop eta hp_`var'
		drop r0 r1 r2 r3 r4 r5 r6 r7 r8 r9 r10 r11 r12
			
			svmat `var'level, names(`var'level)
			svmat `var'level_lb, names(`var'level_lb)
			svmat `var'level_ub, names(`var'level_ub)
			svmat `var'cilb, names(`var'cilb)
			svmat `var'ciub, names(`var'ciub)
			svmat `var'se, names(`var'se)
// 			svmat `var'sig_lb, names(`var'sig_lb)
// 			svmat `var'sig_ub, names(`var'sig_ub)
			
	
		cap drop horizon 
		cap drop zeros
		cap gen horizon = _n-1 if _n<=$H+1
		cap gen zeros = 0 if horizon!=.
	
		loc label: var l `var'
		twoway (rarea `var'ciub1 `var'cilb1 horizon, fcolor(gs14) lcolor(gs14)) ///
		(rarea `var'level_lb1 `var'level_ub1 horizon, fcolor(gs10) lcolor(gs10)) ///
		(line `var'level1 horizon, lcolor(blue) lwidth(medthick)) ///
		(line zeros horizon, lcolor(black) lwidth(thin)), ///
		legend(off) ytitle("`label' (%)") xtitle("Quarter", height(5)) ylabel(#4) xlabel(0(2)$H) title("") name(irf_`var', replace) saving(irf_`var', replace) nodraw
		global call $call "irf_`var'"
		drop `var'level1 `var'level_lb1 `var'level_ub1 `var'cilb1 `var'ciub1 `var'se
		// `var'sig_lb `var'sig_ub
// 		(line `var'sig_lb horizon, lpattern("-...-") lcolor(black) lwidth(thick)) ///
// 		(line `var'sig_ub horizon, lpattern("-...-") lcolor(black) lwidth(thick)) ///
		
	}
	loc shock_label: var l `shock'
	gr combine $call, ysize($ysize) xsize($xsize) title("Shocks on Copula: `shock_label'", height(10))
	graph export "copula_wealthbyincome_levels_`shock'_$measures.pdf", as(pdf) replace
	graph drop _all 
	drop pc1 pc2 pc3 pc4 pc5
}


**# Aggregate responses from shocks 
global measures income_and_wealth
global meas_list income wealth 
global max_grid_point 10
global data_path $init_path/7_Results/$measures/from_mcmc/data

use "/Users/lc/Dropbox/Distributional_Dynamics/1_Data/shocks/all_shocks.dta", clear
set scheme s1color
graph set window fontface "Times New Roman"
graph drop _all 

* clean
// gen qdate = quarterly(quarter, "YQ")
// format qdate %tq
rename quarter time 


merge 1:1 time using "$init_path/2_Data_processing/deseasoned_aggs.dta" 
drop _merge
destring TB3MS, replace
destring GS1, replace
destring UNEMPLOYMENT_RATE, replace

merge 1:1 time using "/Users/lc/Dropbox/Distributional_Dynamics/1_Data/shocks/romer_romer_MP/RR_monetary_shock_quarterly.dta"
drop _merge

merge 1:1 time using "/Users/lc/Dropbox/Distributional_Dynamics/1_Data/shocks/Aruoba_Drechsel/Aruoba_Drechsel_Data_quarterly.dta"
drop _merge 

rename time yq 
merge 1:1 yq using "rr_shocks_coibion"
drop _merge 

rename yq time
tsset time

* time trend 
gen t = _n
gen t2 = t^2

**# Shock treatment 
// rename CBI_median CB_information_shocks
// rename delphic_forward_guidance FG_shock // could be measurement error
rename EXOGENRRATIO standard_tax_FP
// rename ramey_gov_shocks standard_gov_FP  // this should instrument variation in government spending  
//
// replace MP_median = MP_median * 100 // to scale it to basis points
// replace MP_median = MP_median / 25  // scale the effect to 25 point shocks
//
// la var MP_median "Monetary Policy"  // sd shock 
// la var CB_information_shocks "Central Bank Information"  // sd shock  
// la var FG_shock "Forward Guidance"  // sd shock 
la var standard_tax_FP "Tax"  // percent of GDP 
// la var standard_gov_FP "Government Spending"
//
// rename MP_median MP
la var resid_full "Romer-Romer (2004)" // in percentage points 
la var aruoba_mp "Aruoba-Drechsel (2023)"
la var MP_median "Jarocinski-Karadi (2020)"
la var CBI_median "C.B. Info. Jarocinski-Karadi (2020)"  

// rename aruoba_mp MP
rename resid_full rr
rename MP_median jk
// rename resid_full MP
 

rename standard_tax_FP FP
// global SHOCKS CBI_median aruoba_mp rr jk FP // CB_information_shocks FG_shock standard_tax_FP standard_gov_FP  
global SHOCKS sh_rr

cd /Users/lc/Dropbox/Distributional_Dynamics/7_Results/IRFs

* LPs on aggregates 
**# Transmission of MP and FP on marginals
global p=8
global rounding .00001
global aggregates TNWBSHNO REAL_PERSONAL_INCOME SP500 GDP CPI_INFLATION SHILLER_PRICE_INDEX TB3MS UNEMPLOYMENT_RATE GS1 ///
DURABLE_CONSUMPTION NONDURABLE_CONSUMPTION SERVICES_CONSUMPTION REAL_PERSONAL_INCOME

foreach var in $aggregates {
	if "`var'" != "TB3MS" | "`var'" != "UNEMPLOYMENT_RATE" | "`var'" != "GS1" {
		replace `var' = log(1+`var') * 100
	}
	else {
		disp "not log here"
	}
}


la var GDP "GDP" 
la var DURABLE_CONSUMPTION "Dur. Consumption"
la var NONDURABLE_CONSUMPTION "non-Dur. Consumption"
la var SERVICES_CONSUMPTION "Services"
la var TNWBSHNO "Net Worth"
la var REAL_PERSONAL_INCOME "Personal Income"
la var SP500 "SP500" 
la var SHILLER_PRICE_INDEX "Shiller Price Index"
la var CPI_INFLATION "CPI" 
la var TB3MS "3-Month Treasury Bill"
la var GS1 "1-yr Gov. bond yield"
la var UNEMPLOYMENT_RATE "Unemployment"


global H=16
global ysize 10
global xsize 10

* unit here 
// y_unit


foreach shock in $SHOCKS {
		global call 
		foreach var in $aggregates {

		* Containers
		matrix `var'level = J($H + 1, 1, 0)	
		matrix `var'level_lb = J($H + 1, 1, 0)
		matrix `var'level_ub = J($H + 1, 1, 0)
		matrix `var'cilb = J($H + 1, 1, 0)	
		matrix `var'ciub = J($H + 1, 1, 0)	
// 		matrix `var'cumul_vector = J($H + 1, 1, 0)
		matrix `var'se = J($H + 1, 1, 0)
		
		
		global rcall 
		forvalues h = 0/$H{
			qui gen `var'_`h' = f`h'.`var' 

			
			if `h' == 0 {					
				* Following Lusompa (2021)
				qui ivreg2 `var'_`h' L(1/$p).`var' L(0/16).`shock', bw(auto) robust
				qui predict r`h', resid
				global rcall $rcall r`h'
			}

			
			else {
				reg `var'_`h' L(1/$p).`var' L(0/16).`shock' $rcall, robust
				qui predict r`h', resid
				global rcall $rcall r`h'
			}
			
			matrix `var'level[`h'+1,1] = round(_b[l.`shock'], $rounding)
			matrix `var'level_lb[`h'+1,1] = round(_b[l.`shock'] - _se[l.`shock'], $rounding)			
			matrix `var'level_ub[`h'+1,1] = round(_b[l.`shock'] + _se[l.`shock'], $rounding)
			matrix `var'ciub[`h'+1,1] = round(_b[l.`shock'] + 2*_se[l.`shock'], $rounding)			 
			matrix `var'cilb[`h'+1,1] = round(_b[l.`shock'] - 2*_se[l.`shock'], $rounding) 
// 			matrix `var'cumul_vector[`h'+1,1] = round(_b[l.`shock'], $rounding)
			matrix `var'se[`h'+1,1] = round(_se[l.`shock'], $rounding)

			drop `var'_`h'  
		}
		drop r0 r1 r2 r3 r4 r5 r6 r7 r8 r9 r10 r11 r12 r13 r14 r15 r16
			
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
	
		loc label: var l `var'
		twoway (rarea `var'ciub1 `var'cilb1 horizon, fcolor(gs14) lcolor(gs14)) ///
		(rarea `var'level_lb1 `var'level_ub1 horizon, fcolor(gs10) lcolor(gs10)) ///
		(line `var'level1 horizon, lcolor(blue) lwidth(medthick)) ///
		(line zeros horizon, lcolor(black) lwidth(thin)), ///
		legend(off) ytitle("`label' ($y_unit)") xtitle("Quarter", height(5)) ylabel(#4) xlabel(0(2)$H) title("") name(irf_`var', replace) saving(irf_`var', replace) nodraw
		global call $call "irf_`var'"
		drop `var'level1 `var'level_lb1 `var'level_ub1 `var'cilb1 `var'ciub1 `var'se
	}
	loc shock_label: var l `shock'
	gr combine $call, ysize($ysize) xsize($xsize) title("Aggregate Responses: `shock_label'", height(10)) name(aggregates_`shock', replace) 
	graph export "aggregates_`shock'_$measures.pdf", as(pdf) replace
	graph drop _all 
}


