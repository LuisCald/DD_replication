**# LPs consumption inequality 
* Import Ginis 
* Import functional data 
* run LPs

** But very quickly estimate ginis for longer period 
global init_path /Users/lc/Dropbox/Distributional_Dynamics
cd "$init_path/5_Code"
global measures consum_and_income_and_wealth
global meas_list consum income wealth

* Runs function 
cap do prep_micro_3D
prepare_micro_data CEX
cd "$init_path/7_Results/IRFs"

global H=8
global rounding .00001
global ysize 10
global xsize 10
global split_param = 6
gen quarter = quarter(dofq(time))
replace cop_share = . if cop_share < 0

global SHOCKS jk 

* Treat Covid 
// replace consum = . if time >= tq(2019q4) &  time <= tq(2020q3)

drop if hh_count < 0

cd /Users/lc/Dropbox/Distributional_Dynamics/7_Results/IRFs/Trends
collapse (sum) cop_share (mean) consum income, by(incomegrid consumgrid time)
drop if missing(incomegrid)

* Assuming each row represents a successive quarter
gen quarter_time = yq(1984, 4) + _n - 1

* Format the new variable to display as YearQuarter (e.g., 2000Q1, 2000Q2, ...)
format quarter_time %tq


la var income "Gini{subscript: Y}"
la var consum "Gini{subscript: C}"

**# Generate ginis 
foreach var in income consum {
	mat `var'_ginis = J(149,1,0)
	ineqdec0 `var' [pw=cop_share], by(time)
	local j = 0
	forvalues i=99(1)247 {
		mat `var'_ginis[`j'+1, 1] = r(gini_`i')
				local j = `j'+1
	}
	svmat `var'_ginis, names(`var'_ginis)
	
	summ `var'_ginis if !missing(`var'_ginis)
	gen recession_flag = r(min) 
	summ `var'_ginis if !missing(`var'_ginis)
	replace recession_flag = r(max)*1.02 if (quarter_time >= tq(2008q1) & quarter_time <= tq(2009q2)) | (quarter_time >= tq(2020q1) & quarter_time <= tq(2020q2))

// 	gen recession = r(max) if recession_flag == 1
	summ `var'_ginis if !missing(`var'_ginis)
	local min = r(min)
	
	loc label: var l `var'
	twoway (area recession_flag time if !missing(`var'_ginis), base(`min') color(gs12)) (tsline `var'_ginis if !missing(`var'_ginis), lwidth(medthick) lcolor(black) lpattern(dash)),  legend(off) ytitle("`label'", height(5)) xtitle("Quarter", height(5)) xlabel(, grid) ylabel(, grid) graphregion(color(white)) bgcolor(white)

	graph export "`var'_gini_test.pdf", as(pdf) replace	
	drop recession_flag
}
* Export univariate ginis 
export delimited quarter_time income_ginis1 consum_ginis1 using /Users/lc/Dropbox/Distributional_Dynamics/2_Data_processing/CEX_ginis.csv, replace

import delimited /Users/lc/Dropbox/Distributional_Dynamics/2_Data_processing/CEX_ginis.csv,clear
rename quarter_time time 
gen yq = quarterly(time, "YQ", 2020)
format yq %tq
drop if missing(income_ginis1)
drop time 
rename yq time
save /Users/lc/Dropbox/Distributional_Dynamics/2_Data_processing/CEX_ginis.dta, replace



**# Load in Data, merge and run LPs
import delimited "/Users/lc/Dropbox/Distributional_Dynamics/7_Results/consum_and_income_and_wealth/from_mcmc/data/CEX_functional_data_A non-diag_.csv", clear

gen yq = quarterly(time, "YQ", 2020)
format yq %tq

merge 1:1 yq using "/Users/lc/Dropbox/Distributional_Dynamics/7_Results/coibion_replication/replication_folder/my_files/external_data_files/rr_shocks_coibion.dta"
drop _merge 

drop time 
rename yq time

merge 1:1 time using /Users/lc/Dropbox/Distributional_Dynamics/2_Data_processing/CEX_ginis.dta
drop _merge

rename time quarter

merge 1:1 quarter using "/Users/lc/Dropbox/Distributional_Dynamics/1_Data/shocks/all_shocks.dta"
drop _merge



rename quarter time

replace MP_median = MP_median * 100 // to scale it to basis points
replace MP_median = MP_median / 25  // scale the effect to 25 point shocks

rename MP_median jk

global SHOCKS sh_rr
global H=12
global rounding .00001
global ysize 10
global xsize 10

drop if missing(quantilesconsum_100)

* Generate 90-10 variables 
gen consum9010 = log(quantilesconsum_900) - log(quantilesconsum_100)
gen income9010 = log(quantilesincome_900) - log(quantilesincome_100)

local label1 "Income Gini"
local label2 "Consumption Gini"
local label3 "Consumption 90-10"
local label4 "Income 90-10"


foreach shock in $SHOCKS {
	local label_id = 0

	foreach var in income_ginis1 consum_ginis1 consum9010 income9010 {
		cap restore 
		preserve 
		tsset time 
		local label_id = `label_id' + 1
		
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
			
			* Perform Frisch-Waugh-Lovell Theorem
			qui gen `var'_`h' = f`h'.`var' - l.`var'

			if `h' == 0 {	
				qui ivreg2 `var'_`h' l(1/$H).d.`var' l(1/$H).`shock', bw(auto) r
				estat ic
				qui predict r`h', resid
				global rcall $rcall r`h'
				
			}

			
			else {
				qui ivreg2 `var'_`h' l(1/$H).d.`var' l(1/$H).`shock' $rcall, bw(auto) r
				estat ic
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


			cap drop `var'_`h'
		}
		
		forvalues i=0(1)$H {
				drop r`i'
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
	

// 		loc label: var l `var'
// 		 loc label "`var'"
		
		twoway (rarea `var'ciub1 `var'cilb1 horizon, fcolor(gs14) lcolor(gs14)) ///
		(rarea `var'level_lb1 `var'level_ub1 horizon, fcolor(gs10) lcolor(gs10)) ///
		(line `var'level1 horizon, lcolor(green) lpattern(dash) lwidth(medthick)) ///
		(line zeros horizon, lcolor(black) lwidth(thin)), ///
		legend(off) ytitle("`label`label_id'' ($y_unit)", height(5)) xtitle("Quarter", height(5)) ylabel(#4) xlabel(0(2)$H) title("") name(irf_`var', replace) saving(irf_`var', replace)
		
		graph export "consum_ineq_`var'.pdf", replace
		
		global call $call "irf_`var'"
		drop `var'level1 `var'level_lb1 `var'level_ub1 `var'cilb1 `var'ciub1 `var'se
		global zz = $zz + 1
		
	}
	loc shock_label: var l `shock'
	gr combine $call, ysize($ysize) xsize($xsize) title("Shocks on Consumption Inequality: `shock_label'", height(10)) name(`shock'_cil, replace) 
	graph export "`shock'_cil.png", as(png) replace
	graph drop _all 
}



