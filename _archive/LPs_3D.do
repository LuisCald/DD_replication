**# LPs 3D
global init_path /Users/lc/Dropbox/Distributional_Dynamics
cd "$init_path/5_Code"
global measures consum_and_income_and_wealth
global meas_list consum income wealth


* Runs function 
global data_choice "CEX_all"
cap do prep_micro_3D
program drop prepare_micro_data
do prep_micro_3D
prepare_micro_data $data_choice

cd "$init_path/7_Results/IRFs"
replace consum = 100 * log(consum)

global H=8
global hh=4
global rounding .00001
global ysize 10
global xsize 10
global split_param = 5
gen quarter = quarter(dofq(time))
replace cop_share = . if cop_share < 0

// drop t_bill 

// drop if time <= tq(1999q1)
// drop if time >= tq(2019q4)

* What are the different households 
gen hand_to_mouth = (incomegrid <= 4 & wealthgrid <= 4 & !missing(incomegrid)) 
// gen w_hand_to_mouth = (incomegrid <= 3 & wealthgrid >= 6 & wealthgrid <= 10 & !missing(incomegrid)) // roughly 23% of the pop. across time
gen v_hh = (incomegrid >= 9 & wealthgrid >= 9 & !missing(incomegrid))
gen v_ll = (incomegrid <= 2 & wealthgrid <= 2 & !missing(incomegrid))
gen indebted_hhs = (wealth < 0 & !missing(wealth))
gen indebted_wy_hhs = (wealth < 0 & incomegrid >= 6 & !missing(wealth))
gen indebted_ny_hhs = (wealth < 0 & incomegrid < 6 & !missing(wealth))

* Define groups 
gen low_income = (incomegrid <= $split_param  & !missing(incomegrid))
gen high_income = (incomegrid > $split_param & !missing(incomegrid))

gen low_wealth = (wealthgrid <= $split_param & !missing(wealthgrid))
gen high_wealth = (wealthgrid > $split_param & !missing(wealthgrid))

gen ll_il = (incomegrid <= $split_param & wealthgrid <= $split_param & !missing(incomegrid) & !missing(wealthgrid))
gen lh_il = (incomegrid <= $split_param & wealthgrid > $split_param & !missing(incomegrid) & !missing(wealthgrid))
gen hl_il = (incomegrid > $split_param & wealthgrid <= $split_param & !missing(incomegrid) & !missing(wealthgrid))
gen hh_il = (incomegrid > $split_param & wealthgrid > $split_param & !missing(incomegrid) & !missing(wealthgrid))

gen all_groups = (incomegrid <= 10 & wealthgrid <= 10 & !missing(incomegrid))

la var low_income "Low income"
la var high_income "High income"
la var low_wealth "Low wealth"
la var high_wealth "High wealth"
la var ll_il "Low income, low wealth"
la var lh_il "Low income, high wealth"
la var hl_il "high income, low wealth"
la var hh_il "high income, high wealth"

la var hand_to_mouth "Hand-to-Mouth"
// la var w_hand_to_mouth "Wealthy Hand-to-Mouth"
la var v_hh "Top 20 in Income and Wealth"
la var v_ll "Bottom 20 in Income and Wealth"
la var indebted_hhs "Indebted Households"
la var indebted_wy_hhs "Indebted Households w/ below or at Median Income"
la var indebted_ny_hhs "Indebted Households w/ above Median Income"

local local1 "Consumption Response{subscript: (Y ≤ Median)}"
local  local2 "Consumption Response{subscript: (Y > Median)}"
local  local3 "Consumption Response{subscript: (W ≤ Median)}"
local  local4 "Consumption Response{subscript: (W > Median)}"
local  local5 "Consumption Response{subscript: (Y ≤ Median, W ≤ Median)}"
local  local6 "Consumption Response{subscript: (Y ≤ Median, W > Median)}"
local  local7 "Consumption Response{subscript: (Y > Median, W ≤ Median)}"
local  local8 "Consumption Response{subscript: (Y > Median, W > Median)}"

local  local9 "Consumption Response{subscript: (Y < Median, W < Median)}"
local  local10 "Consumption Response{subscript: (Y > 80th perc., W > 80th perc.)}"
local  local11 "Consumption Response{subscript: (Y ≤ 20th perc., W ≤ 20th perc.)}"
local  local12 "Consumption Response{subscript: (W < 0)}"
local  local13 "Consumption Response{subscript: (W < 0, Y ≤ Median)}" 
local  local14 "Consumption Response{subscript: (W < 0, Y > Median)}" 

global var_list low_income high_income low_wealth high_wealth ll_il lh_il hl_il hh_il ///
hand_to_mouth  v_hh v_ll indebted_hhs indebted_ny_hhs indebted_wy_hhs

drop if missing(income)

// summ time 
// local rmin= r(min)
// local rmax= r(max)
//		
// foreach var in indebted_wy_hhs indebted_ny_hhs { // ll_il lh_il hl_il hh_il hand_to_mouth w_hand_to_mouth v_hh v_ll ///
// 	disp "`var'"
// 	unique time 
// 	mat `var'_tot = J(r(unique), 1, 0)
// 	local i = 0
// 	forvalues t=`rmin'(1)`rmax' {
// 		disp "`t'"
//		
// 		qui cap total cop_share if `var' == 1 & time == `t' 
// 		local i = `i'+1
// 		if _rc == 0 {
// 			matrix `var'_tot[`i', 1] = r(table)[1,1]	
// 		}
// 		else {
// 			matrix `var'_tot[`i', 1] = .
// 		}
//		
// 	}
// 	svmat `var'_tot, names(`var'_tot)
// }
// export excel tot_hhs ll_il_tot1 lh_il_tot1 hl_il_tot1 hh_il_tot1 /// 
// hand_to_mouth_tot1 w_hand_to_mouth_tot1 v_hh_tot1 v_ll_tot1 indebted_wy_hhs_tot1 indebted_ny_hhs_tot1 using  "/Users/lc/Dropbox/Distributional_Dynamics/2_Data_processing/group_shares.xlsx", replace firstrow(variables)
//

global y_unit = "%"
// local grouplist "low_income high_income low_wealth high_wealth ll_il lh_il hl_il hh_il hand_to_mouth v_hh v_ll indebted_hhs indebted_ny_hhs indebted_wy_hhs"

xtset grid_point time

global SHOCKS MPS_ORTH aruoba_mp jk standard_MP RRshock_old_end RRshock_old_avg RRshock_new_end RRshock_new_avg //sh_rr rr
// global shock_choice standard_MP

// foreach var in  gs1 eff_ff_rate yTreas RRshock_new RRshock_old {
// 	replace `var' = `var' * 100 // so, in basis points 
// 	replace `var' = `var' / 25 // so, in 25 basis points 

// }



* Treat Covid 
// replace consum = . if time >= tq(2019q4) &  time <= tq(2020q3)

drop if hh_count < 0

* Collapse by group 

* Define the dep. variable as a ratio 
// replace consum = consum / l.income

* Creating cumulative variables
// gen cumul_consumption = 0
//
// forvalues i=0/$H {
// gen f`i'cumul_consumption = 100*(f`i'.consum - l.consum) + cumul_consumption // *100 for percent 
// replace cumul_consumption = f`i'cumul_consumption
// }


// gen time2 = time^2
// tsset time 
// gen real_receipts = nfedreceipts * CPI_inf 
// foreach var in real_receipts real_gdp {
// 	replace `var' = log(1+`var')	
// }
local grouplist "all_groups" //"ll_il lh_il hl_il hh_il" // "aggregate"  all_groups 
global shock_choice RRshock_new_avg

if $data_choice == "CEX_all" {
	drop if wealthgrid != 1
}

foreach shock in $shock_choice {
	global zz = 1
	disp "hi"
	* First define the set of controls 
	global call
	local label_id = 0 
	foreach var of local grouplist {
		cap restore 
		preserve 
		if "`var'" != "aggregate" {
			disp "hi"
			collapse (mean) consum (first) yTreas $SHOCKS gs1 eff_ff_rate sp500_hf pc1ff1_hf if `var' == 1 [pw=cop_share], by(time)	
				
			* For each shock, have the shock generate a 1% increase in the FFR
			tsset time
			gen t = _n
			locproj eff_ff_rate l(0/4).`shock'  t, h(12) m(newey) hopt(lag) yl(3)
			replace `shock' =  `shock' * e(irf)[1,1]
			
			disp "hi"
		}
		else {
			collapse (first) yTreas tot_consum consum_per_hh $SHOCKS gs1 eff_ff_rate sp500_hf pc1ff1_hf, by(time)
			replace tot_consum = 100 * log(tot_consum)
			replace consum_per_hh = 100 * log(consum_per_hh)
// 			gen consum = tot_consum
			gen consum = consum_per_hh
		}
		
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
		global controls l(1/$hh).d.eff_ff_rate l(1/$hh).d.consum t 
// 		global controls l(1/$hh).d.eff_ff_rate l(1/$hh).d.hp_consum
		
// 		tsfilter hp hp_consum = consum, smooth(1600)
		
		gen d`shock' = d.`shock'
		forvalues h = 0/$H{
			
			* Perform Frisch-Waugh-Lovell Theorem
			qui gen consumption_`h' = f`h'.consum - l.consum
			
// 		    qui gen consumption_`h' = f`h'.hp_consum - l.hp_consum

			
		
			disp "hi"
			if `h' == 0 {	

				qui ivreg2 consumption_`h' $controls l(0/$hh).d`shock', bw(auto) robust
// 				ivreg2 consumption_`h' (eff_ff_rate = `shock') $controls, bw(auto) robust // sp500_hf pc1ff1_hf
				estat ic
				qui predict r`h', resid
				global rcall $rcall r`h'
				
			}
			
			else if `h' == 1 {	

				qui ivreg2 consumption_`h' $controls l(0/$hh).d`shock', bw(auto) robust
// 				ivreg2 consumption_`h' (eff_ff_rate = `shock') $controls $rcall, bw(auto) robust // sp500_hf pc1ff1_hf
				estat ic
				qui predict r`h', resid
				global rcall $rcall r`h'
				
			}

			
			else {
				qui ivreg2 consumption_`h' $controls l(0/$hh).d`shock' $rcall,  robust
// 				ivreg2 consumption_`h' (eff_ff_rate = `shock') $controls $rcall, robust 
				estat ic

				qui predict r`h', resid
				global rcall $rcall r`h'
			}
// 			matrix `var'level[`h'+1,1] = round(_b[eff_ff_rate], $rounding)
// 			matrix `var'level_lb[`h'+1,1] = round(_b[eff_ff_rate] - _se[eff_ff_rate], $rounding)			
// 			matrix `var'level_ub[`h'+1,1] = round(_b[eff_ff_rate] + _se[eff_ff_rate], $rounding)
// 			matrix `var'ciub[`h'+1,1] = round(_b[eff_ff_rate] + 1.65*_se[eff_ff_rate], $rounding)			 
// 			matrix `var'cilb[`h'+1,1] = round(_b[eff_ff_rate] - 1.65*_se[eff_ff_rate], $rounding) 
// 			matrix `var'cumul_vector[`h'+1,1] = round(_b[eff_ff_rate], $rounding)
// 			matrix `var'se[`h'+1,1] = round(_se[eff_ff_rate], $rounding)
			
// 			matrix `var'level[`h'+1,1] = round(_b[d.eff_ff_rate], $rounding)
// 			matrix `var'level_lb[`h'+1,1] = round(_b[d.eff_ff_rate] - _se[d.eff_ff_rate], $rounding)			
// 			matrix `var'level_ub[`h'+1,1] = round(_b[d.eff_ff_rate] + _se[d.eff_ff_rate], $rounding)
// 			matrix `var'ciub[`h'+1,1] = round(_b[d.eff_ff_rate] + 2*_se[d.eff_ff_rate], $rounding)			 
// 			matrix `var'cilb[`h'+1,1] = round(_b[d.eff_ff_rate] - 2*_se[d.eff_ff_rate], $rounding) 
// 			matrix `var'cumul_vector[`h'+1,1] = round(_b[d.eff_ff_rate], $rounding)
// 			matrix `var'se[`h'+1,1] = round(_se[d.eff_ff_rate], $rounding)

// 			matrix `var'level[`h'+1,1] = round(_b[yTreas], $rounding)
// 			matrix `var'level_lb[`h'+1,1] = round(_b[yTreas] - _se[yTreas], $rounding)			
// 			matrix `var'level_ub[`h'+1,1] = round(_b[yTreas] + _se[yTreas], $rounding)
// 			matrix `var'ciub[`h'+1,1] = round(_b[yTreas] + 2*_se[yTreas], $rounding)			 
// 			matrix `var'cilb[`h'+1,1] = round(_b[yTreas] - 2*_se[yTreas], $rounding) 
// 			matrix `var'cumul_vector[`h'+1,1] = round(_b[yTreas], $rounding)
// 			matrix `var'se[`h'+1,1] = round(_se[yTreas], $rounding)
			
// 			matrix `var'level[`h'+1,1] = round(_b[gs1], $rounding)
// 			matrix `var'level_lb[`h'+1,1] = round(_b[gs1] - _se[gs1], $rounding)			
// 			matrix `var'level_ub[`h'+1,1] = round(_b[gs1] + _se[gs1], $rounding)
// 			matrix `var'ciub[`h'+1,1] = round(_b[gs1] + 2*_se[gs1], $rounding)			 
// 			matrix `var'cilb[`h'+1,1] = round(_b[gs1] - 2*_se[gs1], $rounding) 
// 			matrix `var'cumul_vector[`h'+1,1] = round(_b[gs1], $rounding)
// 			matrix `var'se[`h'+1,1] = round(_se[gs1], $rounding)
			
// 			matrix `var'level[`h'+1,1] = round(_b[l.eff_ff_rate], $rounding)
// 			matrix `var'level_lb[`h'+1,1] = round(_b[l.eff_ff_rate] - _se[l.eff_ff_rate], $rounding)			
// 			matrix `var'level_ub[`h'+1,1] = round(_b[l.eff_ff_rate] + _se[l.eff_ff_rate], $rounding)
// 			matrix `var'ciub[`h'+1,1] = round(_b[l.eff_ff_rate] + 2*_se[l.eff_ff_rate], $rounding)			 
// 			matrix `var'cilb[`h'+1,1] = round(_b[l.eff_ff_rate] - 2*_se[l.eff_ff_rate], $rounding) 
// 			matrix `var'cumul_vector[`h'+1,1] = round(_b[l.eff_ff_rate], $rounding)
// 			matrix `var'se[`h'+1,1] = round(_se[l.eff_ff_rate], $rounding)
//			
// 			matrix `var'level[`h'+1,1] = round(_b[l.gs1], $rounding)
// 			matrix `var'level_lb[`h'+1,1] = round(_b[l.gs1] - _se[l.gs1], $rounding)			
// 			matrix `var'level_ub[`h'+1,1] = round(_b[l.gs1] + _se[l.gs1], $rounding)
// 			matrix `var'ciub[`h'+1,1] = round(_b[l.gs1] + 2*_se[l.gs1], $rounding)			 
// 			matrix `var'cilb[`h'+1,1] = round(_b[l.gs1] - 2*_se[l.gs1], $rounding) 
// 			matrix `var'cumul_vector[`h'+1,1] = round(_b[l.gs1], $rounding)
// 			matrix `var'se[`h'+1,1] = round(_se[l.gs1], $rounding)
//			
// 			matrix `var'level[`h'+1,1] = round(_b[l.`shock'], $rounding)
// 			matrix `var'level_lb[`h'+1,1] = round(_b[l.`shock'] - _se[l.`shock'], $rounding)			
// 			matrix `var'level_ub[`h'+1,1] = round(_b[l.`shock'] + _se[l.`shock'], $rounding)
// 			matrix `var'ciub[`h'+1,1] = round(_b[l.`shock'] + 2*_se[l.`shock'], $rounding)			 
// 			matrix `var'cilb[`h'+1,1] = round(_b[l.`shock'] - 2*_se[l.`shock'], $rounding) 
// 			matrix `var'cumul_vector[`h'+1,1] = round(_b[l.`shock'], $rounding)
// 			matrix `var'se[`h'+1,1] = round(_se[l.`shock'], $rounding)

			matrix `var'level[`h'+1,1] = round(_b[l.d`shock'], $rounding)
			matrix `var'level_lb[`h'+1,1] = round(_b[l.d`shock'] - _se[l.d`shock'], $rounding)			
			matrix `var'level_ub[`h'+1,1] = round(_b[l.d`shock'] + _se[l.d`shock'], $rounding)
			matrix `var'ciub[`h'+1,1] = round(_b[l.d`shock'] + 2*_se[l.d`shock'], $rounding)			 
			matrix `var'cilb[`h'+1,1] = round(_b[l.d`shock'] - 2*_se[l.d`shock'], $rounding) 
			matrix `var'cumul_vector[`h'+1,1] = round(_b[l.d`shock'], $rounding)
			matrix `var'se[`h'+1,1] = round(_se[l.d`shock'], $rounding)

// 			matrix `var'level[`h'+1,1] = round(_b[`shock'], $rounding)
// 			matrix `var'level_lb[`h'+1,1] = round(_b[`shock'] - _se[`shock'], $rounding)			
// 			matrix `var'level_ub[`h'+1,1] = round(_b[`shock'] + _se[`shock'], $rounding)
// 			matrix `var'ciub[`h'+1,1] = round(_b[`shock'] + 2*_se[`shock'], $rounding)			 
// 			matrix `var'cilb[`h'+1,1] = round(_b[`shock'] - 2*_se[`shock'], $rounding) 
// 			matrix `var'cumul_vector[`h'+1,1] = round(_b[`shock'], $rounding)
// 			matrix `var'se[`h'+1,1] = round(_se[`shock'], $rounding)

// 			matrix `var'level[`h'+1,1] = round(_b[l.yTreas], $rounding)
// 			matrix `var'level_lb[`h'+1,1] = round(_b[l.yTreas] - _se[l.yTreas], $rounding)			
// 			matrix `var'level_ub[`h'+1,1] = round(_b[l.yTreas] + _se[l.yTreas], $rounding)
// 			matrix `var'ciub[`h'+1,1] = round(_b[l.yTreas] + 2*_se[l.yTreas], $rounding)			 
// 			matrix `var'cilb[`h'+1,1] = round(_b[l.yTreas] - 2*_se[l.yTreas], $rounding) 
// 			matrix `var'cumul_vector[`h'+1,1] = round(_b[l.yTreas], $rounding)
// 			matrix `var'se[`h'+1,1] = round(_se[l.yTreas], $rounding)
//			
			cap drop consumption_`h'
			cap drop hp_consum`h'
// 			cap drop f`h'cumul_consumption
		}
		forvalues i=0(1)$H {
				cap drop r`i'
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
	
	disp "hi3"
// 		loc label: var l `var'
// 		 loc label "`var'"
		
		twoway (rarea `var'ciub1 `var'cilb1 horizon, fcolor(navy*.20) lcolor(navy*.10)) ///
		(rarea `var'level_lb1 `var'level_ub1 horizon, fcolor(navy*.40) lcolor(navy*.30)) ///
		(line `var'level1 horizon, lcolor(blue*.8) lpattern(dash) lwidth(medthick)) ///
		(line zeros horizon, lcolor(black) lwidth(thin)), scale(2) ///
		legend(order(3 "`var'") position(inside) ring(0)) ytitle("$y_unit Δ C(Y, W)", height(5)) xtitle("Horizon", height(5)) xlabel(0(4)$H) title("") name(irf_`var', replace) saving(irf_`var', replace)
		
		graph export "irf_cons_`shock'_`var'.pdf", replace
		
		global call $call "irf_`var'"
		drop `var'level1 `var'level_lb1 `var'level_ub1 `var'cilb1 `var'ciub1 `var'se
		global zz = $zz + 1
		
	}
	disp "hi4"
	loc shock_label: var l `shock'
	gr combine $call, ysize($ysize) xsize($xsize) title("Shocks on Consumption: `shock_label'", height(10)) name(`shock'_cil, replace) 
	graph export "`shock'_cil.png", as(png) replace
	graph drop _all 
}


**# LPs 3D for income, consumption and liquid assets 
global init_path /Users/lc/Dropbox/Distributional_Dynamics
cd "$init_path/5_Code"
global measures consum_and_income_and_liquid
global meas_list consum income liquid

* Runs function 
// do prep_micro_3D
prepare_micro_data

cd "$init_path/7_Results/IRFs"
// replace consum = 100 * log(consum)

global H=12
global rounding .00001
global ysize 10
global xsize 10
global split_param = 6
gen quarter = quarter(dofq(time))
replace cop_share = . if cop_share < 0

// drop t_bill 

drop if time <= tq(1999q1)
// replace consum =. if time >= tq(2019q4) & time <= tq(2020q2)

* What are the different households 
gen hand_to_mouth = (incomegrid <= 4 & liquidgrid <= 4 & !missing(incomegrid)) // roughly 23% of the pop. across time
// gen w_hand_to_mouth = (incomegrid <= 3 & liquidgrid >= 6 & liquidgrid <= 10 & !missing(incomegrid)) // roughly 23% of the pop. across time
gen v_hh = (incomegrid >= 9 & liquidgrid >= 9 & !missing(incomegrid))
gen v_ll = (incomegrid <= 2 & liquidgrid <= 2 & !missing(incomegrid))
gen indebted_hhs = (liquid < 0 & !missing(liquid))
gen indebted_wy_hhs = (liquid < 0 & incomegrid >= 6 & !missing(liquid))
gen indebted_ny_hhs = (liquid < 0 & incomegrid < 6 & !missing(liquid))

* Define groups 
gen low_income = (incomegrid < $split_param  & !missing(incomegrid))
gen high_income = (incomegrid >= $split_param & !missing(incomegrid))

gen low_wealth = (liquidgrid < $split_param & !missing(liquidgrid))
gen high_wealth = (liquidgrid >= $split_param & !missing(liquidgrid))

gen ll_il = (incomegrid < $split_param & liquidgrid < $split_param & !missing(incomegrid))
gen lh_il = (incomegrid < $split_param & liquidgrid >= $split_param & !missing(incomegrid))
gen hl_il = (incomegrid >= $split_param & liquidgrid < $split_param & !missing(incomegrid))
gen hh_il = (incomegrid >= $split_param & liquidgrid >= $split_param & !missing(incomegrid))

la var low_income "Low income"
la var high_income "High income"
la var low_wealth "Low liquidity"
la var high_wealth "High liquidity"
la var ll_il "Low income, low liquidity"
la var lh_il "Low income, high liquidity"
la var hl_il "high income, low liquidity"
la var hh_il "high income, high liquidity"

la var hand_to_mouth "Hand-to-Mouth"
// la var w_hand_to_mouth "Wealthy Hand-to-Mouth"
la var v_hh "Top 20 in Income and Liquidity"
la var v_ll "Bottom 20 in Income and Liquidity"
la var indebted_hhs "Indebted Households"
la var indebted_wy_hhs "Indebted Households w/ below or at Median Income"
la var indebted_ny_hhs "Indebted Households w/ above Median Income"

local local1 "Consumption Response{subscript: (Y ≤ Median)}"
local  local2 "Consumption Response{subscript: (Y > Median)}"
local  local3 "Consumption Response{subscript: (L ≤ Median)}"
local  local4 "Consumption Response{subscript: (L > Median)}"
local  local5 "Consumption Response{subscript: (Y ≤ Median, L ≤ Median)}"
local  local6 "Consumption Response{subscript: (Y ≤ Median, L > Median)}"
local  local7 "Consumption Response{subscript: (Y > Median, L ≤ Median)}"
local  local8 "Consumption Response{subscript: (Y > Median, L > Median)}"

local  local9 "Consumption Response{subscript: (Y < Median, L < Median)}"
local  local10 "Consumption Response{subscript: (Y > 80th perc., L > 80th perc.)}"
local  local11 "Consumption Response{subscript: (Y ≤ 20th perc., L ≤ 20th perc.)}"
local  local12 "Consumption Response{subscript: (L < 0)}"
local  local13 "Consumption Response{subscript: (L < 0, Y ≤ Median)}" 
local  local14 "Consumption Response{subscript: (L < 0, Y > Median)}" 

global var_list low_income high_income low_wealth high_wealth ll_il lh_il hl_il hh_il ///
hand_to_mouth  v_hh v_ll indebted_hhs indebted_ny_hhs indebted_wy_hhs

drop if missing(income)

// summ time 
// local rmin= r(min)
// local rmax= r(max)
//		
// foreach var in indebted_wy_hhs indebted_ny_hhs { // ll_il lh_il hl_il hh_il hand_to_mouth w_hand_to_mouth v_hh v_ll ///
// 	disp "`var'"
// 	unique time 
// 	mat `var'_tot = J(r(unique), 1, 0)
// 	local i = 0
// 	forvalues t=`rmin'(1)`rmax' {
// 		disp "`t'"
//		
// 		qui cap total cop_share if `var' == 1 & time == `t' 
// 		local i = `i'+1
// 		if _rc == 0 {
// 			matrix `var'_tot[`i', 1] = r(table)[1,1]	
// 		}
// 		else {
// 			matrix `var'_tot[`i', 1] = .
// 		}
//		
// 	}
// 	svmat `var'_tot, names(`var'_tot)
// }
// export excel tot_hhs ll_il_tot1 lh_il_tot1 hl_il_tot1 hh_il_tot1 /// 
// hand_to_mouth_tot1 w_hand_to_mouth_tot1 v_hh_tot1 v_ll_tot1 indebted_wy_hhs_tot1 indebted_ny_hhs_tot1 using  "/Users/lc/Dropbox/Distributional_Dynamics/2_Data_processing/group_shares.xlsx", replace firstrow(variables)
//

global y_unit = "%"
local grouplist "low_income high_income low_wealth high_wealth ll_il lh_il hl_il hh_il hand_to_mouth v_hh v_ll indebted_hhs indebted_ny_hhs indebted_wy_hhs"
xtset grid_point time

global SHOCKS jk 

* Treat Covid 
// replace consum = . if time >= tq(2019q4) &  time <= tq(2020q3)

drop if hh_count < 0

* Collapse by group 

* Define the dep. variable as a ratio 
// replace consum = consum / l.income

* Creating cumulative variables
// gen cumul_consumption = 0
//
// forvalues i=0/$H {
// gen f`i'cumul_consumption = 100*(f`i'.consum - l.consum) + cumul_consumption // *100 for percent 
// replace cumul_consumption = f`i'cumul_consumption
// }


// gen time2 = time^2
// tsset time 
// gen real_receipts = nfedreceipts * CPI_inf 
// foreach var in real_receipts real_gdp {
// 	replace `var' = log(1+`var')	
// }

foreach shock in $SHOCKS {
	global zz = 1

	* First define the set of controls 
	global call
	local label_id = 0 
	foreach var of local grouplist {
		cap restore 
		preserve 
		collapse (mean) consum (first) $SHOCKS if `var' == 1 [pw=cop_share], by(time)
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
		
		local group : word $zz of $var_list
		
		global rcall 
		forvalues h = 0/$H{
			local q= $p - 1
			
			* Perform Frisch-Waugh-Lovell Theorem
			
// 			qui gen consumption_`h' = f`h'.consum - l.consum
			qui gen consumption_`h' = f`h'.consum - l.consum


// 			reg consumption_`h' l(1/`q').consum $controls i.grid_point if `group' == 1 [fw=cop_share], cluster(grid_point)
// 			predict fwl_consum`h', r
//			
//			
// 			* Frisch-Waugh-Lovell, save shocks 
// 			qui reg `shock' l(1/`q').consum $controls if `group' == 1, robust, 
// 			predict fwl_`shock', r
			
			
			if `h' == 0 {	
				disp "hi"
				* Following Lusompa (2021)
// 				reg fwl_consum`h' fwl_`shock' if `group' == 1 [fw=cop_share], fe vce(cluster grid_point)
// 				qui reg consumption_`h' l(1/$H).consum l(1/$H).`shock' i.grid_point if `group' == 1 [fw=hh_count], cluster(grid_point)
// 				 reg f`h'cumul_consumption l(1/$H).consum l(1/$H).`shock' i.grid_point if `group' == 1 [fw=hh_count], cluster(grid_point)
// 				 ivreg2 f`h'cumul_consumption (t_bill= l(1/$H).d.consum l(0/$H).`shock' i.grid_point time time2 ) if `group' == 1 [fw=hh_count], cluster(grid_point)
// 				ivreg2 consumption_`h' l(1/$H).consum l(0/$H).`shock' i.grid_point time time2  if `group' == 1 [fw=hh_count], // // //cluster(grid_point)


				qui ivreg2 consumption_`h' l(1/$H).d.consum l(0/$H).`shock', bw(auto) robust
				estat ic
				qui predict r`h', resid
				global rcall $rcall r`h'
				
			}

			
			else {
				disp "hi2"
// 				xtreg fwl_consum`h' fwl_`shock' $rcall if `group' == 1 [fw=cop_share], fe vce(cluster grid_point)
// 				qui reg consumption_`h' l(1/$H).consum $rcall l(1/$H).`shock' i.grid_point if `group' == 1 [fw=hh_count], cluster(grid_point)
// 				 reg f`h'cumul_consumption l(1/$H).consum $rcall l(1/$H).`shock' i.grid_point if `group' == 1 [fw=hh_count], cluster(grid_point)
// 				ivreg2 consumption_`h' l(1/$H).consum l(0/$H).`shock' i.grid_point time time2 if `group' == 1 [fw=hh_count], cluster(grid_point)
				qui ivreg2 consumption_`h' l(1/$H).d.consum l(0/$H).`shock' $rcall, robust
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

// 			matrix `var'level[`h'+1,1] = round(_b[t_bill], $rounding)
// 			matrix `var'level_lb[`h'+1,1] = round(_b[t_bill] - _se[t_bill], $rounding)			
// 			matrix `var'level_ub[`h'+1,1] = round(_b[t_bill] + _se[t_bill], $rounding)
// 			matrix `var'ciub[`h'+1,1] = round(_b[t_bill] + 2*_se[t_bill], $rounding)			 
// 			matrix `var'cilb[`h'+1,1] = round(_b[t_bill] - 2*_se[t_bill], $rounding) 
// 			matrix `var'cumul_vector[`h'+1,1] = round(_b[t_bill], $rounding)
// 			matrix `var'se[`h'+1,1] = round(_se[t_bill], $rounding)
//			
			cap drop consumption_`h'
// 			cap drop f`h'cumul_consumption
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
	
	disp "hi3"
// 		loc label: var l `var'
// 		 loc label "`var'"
		
		twoway (rarea `var'ciub1 `var'cilb1 horizon, fcolor(gs14) lcolor(gs14)) ///
		(rarea `var'level_lb1 `var'level_ub1 horizon, fcolor(gs10) lcolor(gs10)) ///
		(line `var'level1 horizon, lcolor(green) lpattern(dash) lwidth(medthick)) ///
		(line zeros horizon, lcolor(black) lwidth(thin)), ///
		legend(off) ytitle("`local`label_id'' ($y_unit)", height(5)) xtitle("Quarter", height(5)) ylabel(#4) xlabel(0(2)$H) title("") name(irf_`var', replace) saving(irf_`var', replace)
		
		graph export "irf_liquid_`var'.pdf", replace
		
		global call $call "irf_`var'"
		drop `var'level1 `var'level_lb1 `var'level_ub1 `var'cilb1 `var'ciub1 `var'se
		global zz = $zz + 1
		
	}
	disp "hi4"
	loc shock_label: var l `shock'
	gr combine $call, ysize($ysize) xsize($xsize) title("Shocks on Consumption: `shock_label'", height(10)) name(`shock'_cil, replace) 
	graph export "`shock'_cil.png", as(png) replace
	graph drop _all 
}




**# Shocks on consumption aggregates 
use "/Users/lc/Dropbox/Distributional_Dynamics/1_Data/shocks/all_shocks.dta", clear
set scheme s1color
graph set window fontface "Times New Roman"
graph drop _all 

* clean
// gen qdate = quarterly(quarter, "YQ")
// format qdate %tq

global H=20
global rounding=.0001
global p=4

merge m:1 quarter using "/Users/lc/Dropbox/Distributional_Dynamics/1_Data/shocks/all_shocks.dta"
drop _merge

rename quarter time 


merge 1:1 time using "/Users/lc/Dropbox/Distributional_Dynamics/2_Data_processing/deseasoned_aggs.dta"
drop _merge


merge 1:1 time using "/Users/lc/Dropbox/Distributional_Dynamics/1_Data/shocks/romer_romer_MP/RR_monetary_shock_quarterly.dta"
drop _merge

merge 1:1 time using "/Users/lc/Dropbox/Distributional_Dynamics/1_Data/shocks/unconventional_MP.dta"
drop _merge

cd "/Users/lc/Dropbox/Distributional_Dynamics/7_Results/IRFs"

* Running LPs on the aggregates 
global consum_aggs DURABLE_CONSUMPTION SERVICES_CONSUMPTION NONDURABLE_CONSUMPTION

foreach var in $consum_aggs {
// 	replace `var' = exp(`var')
	replace `var' = 100 * `var'
}

drop if time < tq(1969q3)
// drop if time > tq(2008q4)

* Some shock treatment 
replace MP_median = MP_median * 100 // to scale it to basis points
replace MP_median = MP_median / 25  // scale the effect to 25 bps

replace u1_sum = u1_sum / 100

la var MP_median "Info. free MP from Jarocinski (2021)" // in percentage points 
la var u1_sum "Standard MP u1 from Jarocinski (2023)" // standard monetary policy, in percentage points  
la var resid_full "Romer-Romer (2004)" // in percentage points 
rename resid_full rr

rename MP_median jk 

tsset time

// foreach var in $consum_aggs {
// gen cumul_`var' = 0
// 	forvalues h = 0/$H {
// 		gen f`h'cumul_`var' = (f`h'.`var' - l.`var') + cumul_`var'
//		
// 		replace cumul_`var' = f`h'cumul_`var'
// 	}
// }

// foreach var in $consum_aggs {
// 	local g = 0
// forvalues h = 0/$H {
// 	if `h' == 0 {
// 		gen `var'_0 = (f`h'.`var' - l.`var') 
// 	}
// 	else {
// 		gen `var'_`h' = (f`h'.`var' - f`g'.`var') 	
// 		local g = `g' + 1
// 	}
//	
// }
// }

global H=20
foreach shock in jk rr {
	global call
	foreach var of varlist $consum_aggs {
		* Containers
		matrix `var'level = J($H + 1, 1, 0)	
		matrix `var'level_lb = J($H + 1, 1, 0)
		matrix `var'level_ub = J($H + 1, 1, 0)
		matrix `var'cilb = J($H + 1, 1, 0)	
		matrix `var'ciub = J($H + 1, 1, 0)	
		matrix `var'se = J($H + 1, 1, 0)
		
		global rcall 
		forvalues h = 0/$H{
			local q= 2 //$p - 1
			* Perform Frisch-Waugh-Lovell Theorem
			tsset time 
			qui gen `var'_`h' = f`h'.`var' - l.`var' // (1)
// 			qui gen `var'_`h' = d.f`h'.`var' 

			
// 			gen fwl_`shock' = `shock'
			if `h' == 0 {	
				disp "hi"
				* Following Lusompa (2021)
// 				qui ivreg2 `var'_`h' l(1/20).`var'  l(1/20).`shock', bw(auto) robust // (1)
// 				newey `var'_`h' l(1/2).`var'_`h'  l(1/20).`shock', lag(8)
				qui ivreg2 `var'_`h' l(1/$H).`var'  l(1/$H).`shock', bw(auto) robust 
				qui predict r`h', resid
				global rcall $rcall r`h'
				
			}

			
			else {
				disp "hi2"
// 				newey `var'_`h' l(1/2).`var'_`h' $rcall l(1/20).`shock', lag(8)
// 				qui ivreg2 `var'_`h' l(1/20).`var' l(1/20).`shock', bw(auto) robust // (1)
				qui ivreg2 `var'_`h' l(1/$H).`var' l(1/$H).`shock' $rcall, bw(auto) robust 

// 				qui ivreg2 `var'_`h' l(1/4).`var' $rcall l(1/4).`shock', robust
				qui predict r`h', resid
				global rcall $rcall r`h'
			}
			matrix `var'level[`h'+1,1] = round(_b[l.`shock'], $rounding)
			matrix `var'level_lb[`h'+1,1] = round(_b[l.`shock'] - _se[l.`shock'], $rounding)			
			matrix `var'level_ub[`h'+1,1] = round(_b[l.`shock'] + _se[l.`shock'], $rounding)
			matrix `var'ciub[`h'+1,1] = round(_b[l.`shock'] + 2*_se[l.`shock'], $rounding)			 
			matrix `var'cilb[`h'+1,1] = round(_b[l.`shock'] - 2*_se[l.`shock'], $rounding) 
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
	
		loc label: var l `var'
		twoway (rarea `var'ciub1 `var'cilb1 horizon, fcolor(gs14) lcolor(gs14)) ///
		(rarea `var'level_lb1 `var'level_ub1 horizon, fcolor(gs10) lcolor(gs10)) ///
		(line `var'level1 horizon, lcolor(blue) lwidth(medthick)) ///
		(line zeros horizon, lcolor(black) lwidth(thin)), ///
		legend(off) ytitle("`label' ($y_unit)") xtitle("Quarter", height(5)) ylabel(#4) xlabel(0(2)$H) title("") name(`var'_`shock', replace) saving(`var'_`shock', replace)

		
		global call $call "`var'_`shock'"
		drop `var'level1 `var'level_lb1 `var'level_ub1 `var'cilb1 `var'ciub1 `var'se
		global zz = $zz + 1
		
	}
	loc shock_label: var l `shock'
	gr combine $call, ysize($ysize) xsize($xsize) title("Shocks on Agg. Consumption: `shock_label'", height(10)) name(`shock'_aggs, replace) 
	graph export "`shock'_aggs.png", as(png) replace
	graph drop _all 
}
