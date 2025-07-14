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
prepare_micro_data CEX_all

cd "$init_path/7_Results/IRFs/MP_IRFs_AGGs"
// replace consum = 100 * log(consum)

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

global y_unit = "%"
// local grouplist "low_income high_income low_wealth high_wealth ll_il lh_il hl_il hh_il hand_to_mouth v_hh v_ll indebted_hhs indebted_ny_hhs indebted_wy_hhs"

xtset grid_point time

global SHOCKS ad_old_sum ad_old_avg ad_new_sum ad_new_avg rr_old_sum rr_old_avg rr_new_sum rr_new_avg JK_pc1_hf JK_mp_pm JK_mp_median JC_u1 MPS_sum MPS_avg MPS_ORTH_sum MPS_ORTH2_avg //sh_rr rr



drop if hh_count < 0
local grouplist "all_groups" //"ll_il lh_il hl_il hh_il" // "aggregate"  all_groups 
global shock_choice ADshock_new_avg // MPS_ORTH // standard_MP had weird effects //aruoba_mp // RRshock_new_avg

gen inflation    = 100 * (CPIAUCSL - l3.CPIAUCSL)/l3.CPIAUCSL
gen log_real_gdp = log(GDPC1) * 100
gen log_real_cons = log(PCECC96) * 100
gen log_price    = log(CPIAUCSL) * 100 //GDPCTPI


if "$data_choice" == "CEX_all" {
	drop if wealthgrid != 1
}

* Collapse the data 
collapse (mean) consum (first) $SHOCKS ///
 log_real_gdp log_real_cons inflation eff_ff_rate [pw=cop_share], by(time)	
gen t = _n
tsset time

global macro_vars log_real_gdp log_real_cons inflation eff_ff_rate
global covariates l(1/4).d.log_real_gdp  l(1/4).d.inflation l(1/4).d.eff_ff_rate

replace consum = 100 * log(consum)

foreach shock in $SHOCKS {
	* First define the set of controls 
	global call
	local label_id = 0 

	* For each shock, have the shock generate a 1% increase in the FFR
	locproj eff_ff_rate l(0/4).`shock'  t, h(12) m(newey) hopt(lag) yl(3)
	replace `shock' =  `shock' * e(irf)[1,1]
	
	qui locproj eff_ff_rate l(0/4).`shock'  t, h(12) m(newey) hopt(lag) yl(3)
	disp e(irf)[1,1]
	assert  abs(1 - e(irf)[1,1]) < .02  

	
	foreach var in $macro_vars {
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
		forvalues h = 0/$H {
			
			qui gen `var'_`h' = f`h'.`var' - l.`var' // cumulative
// 			qui gen `var'_`h' = f`h'.d.`var' // impact
			
			if `h' == 0 {	
				qui ivreg2 `var'_`h' `shock' l(1/4).d.`shock' l(1/$hh).d.`var' $covariates, bw(auto) robust
				estat ic
				qui predict r`h', resid
				global rcall $rcall r`h'
				
			}
			
			else {
				qui ivreg2 `var'_`h' `shock' l(1/4).d.`shock' l(1/$hh).d.`var' $rcall $covariates,  robust
				estat ic
				qui predict r`h', resid
				global rcall $rcall r`h'
			}

			matrix `var'level[`h'+1,1] = round(_b[`shock'], $rounding)
			matrix `var'level_lb[`h'+1,1] = round(_b[`shock'] - _se[`shock'], $rounding)			
			matrix `var'level_ub[`h'+1,1] = round(_b[`shock'] + _se[`shock'], $rounding)
			matrix `var'ciub[`h'+1,1] = round(_b[`shock'] + 2*_se[`shock'], $rounding)			 
			matrix `var'cilb[`h'+1,1] = round(_b[`shock'] - 2*_se[`shock'], $rounding) 
			matrix `var'cumul_vector[`h'+1,1] = round(_b[`shock'], $rounding)
			matrix `var'se[`h'+1,1] = round(_se[`shock'], $rounding)

			cap drop `var'_`h'
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
	
		twoway (rarea `var'ciub1 `var'cilb1 horizon, fcolor(navy*.20) lcolor(navy*.10)) ///
		(rarea `var'level_lb1 `var'level_ub1 horizon, fcolor(navy*.40) lcolor(navy*.30)) ///
		(line `var'level1 horizon, lcolor(blue*.8) lpattern(dash) lwidth(medthick)) ///
		(line zeros horizon, lcolor(black) lwidth(thin)), scale(1) ///
		legend(order(3 "`var'") position(inside) ring(0)) ytitle("$y_unit Δ", height(5)) xtitle("Horizon", height(5)) xlabel(0(4)$H) title("") name(irf_`var', replace) saving(irf_`var', replace)
		
		graph export "`shock'_`var'.pdf", replace
		
		global call $call "irf_`var'"
		drop `var'level1 `var'level_lb1 `var'level_ub1 `var'cilb1 `var'ciub1 `var'se
		
	}
}

**# LPs Consumption 
global init_path /Users/lc/Dropbox/Distributional_Dynamics
cd "$init_path/5_Code"
global measures consum_and_income_and_wealth
global meas_list consum income wealth


* Runs function 
global data_choice "CEX_all"
cap do prep_micro_3D
program drop prepare_micro_data
do prep_micro_3D
prepare_micro_data CEX_all

cd "$init_path/7_Results/IRFs/MP_IRFs_DIS"

global H=28
global hh=4
global shh=0
global rounding .00001
global ysize 10
global xsize 10
global split_param = 5
gen quarter = quarter(dofq(time))
replace cop_share = . if cop_share < 0

* Define groups 
gen bottom50 = (incomegrid <= $split_param  & !missing(incomegrid))
gen next40 = (incomegrid > $split_param & incomegrid <10 & !missing(incomegrid))
gen top10 = (incomegrid ==10 & !missing(incomegrid))


gen groups = .
replace groups = 1 if bottom50 == 1
replace groups = 2 if next40 == 1
replace groups = 3 if top10 == 1


drop if missing(income)
global y_unit = "%"
xtset grid_point time

global SHOCKS rr_old_sum rr_old_avg rr_new_sum rr_new_avg ad_old_sum ///
ad_old_avg ad_new_sum ad_new_avg JC_u1 MPS_sum MPS_avg MPS_ORTH_sum MPS_ORTH2_avg JK_mp_median



drop if hh_count < 0
global shock_choice MPS_ORTH_sum //ADshock_new_avg // MPS_ORTH // standard_MP had weird effects //aruoba_mp // RRshock_new_avg

gen inflation    = 100 * (CPIAUCSL - l3.CPIAUCSL)/l3.CPIAUCSL
gen log_real_gdp = log(GDPC1) * 100
gen log_real_cons = log(PCECC96) * 100
gen log_price    = log(CPIAUCSL) * 100 //GDPCTPI


if "$data_choice" == "CEX_all" {
	drop if wealthgrid != 1
}

* Collapse the data 
collapse (mean) consum (first) $SHOCKS ///
 log_real_gdp log_real_cons inflation eff_ff_rate [pw=cop_share], by(groups time)	

xtset groups time

global covariates l(1/4).d.log_real_gdp  l(1/4).d.inflation l(1/4).d.eff_ff_rate
replace consum = 100 * log(consum)

// replace MPS_ORTH2_avg = ad_new_avg if missing(MPS_ORTH2_avg)
// replace MPS_ORTH_sum = ad_new_sum if missing(MPS_ORTH_sum)

foreach shock in $shock_choice {
	* First define the set of controls 
	global call
	local label_id = 0 
	
	foreach var in consum {

		forvalues z=1(1)3 {
			preserve
			keep if groups == `z'
			gen t = _n
			tsset time
			
			* For each shock, have the shock generate a 1% increase in the FFR
			locproj eff_ff_rate l(0/4).`shock'  t , h(12) m(newey) hopt(lag) yl(3)
			replace `shock' =  `shock' * e(irf)[1,1]
			
			qui locproj eff_ff_rate l(0/4).`shock' t , h(12) m(newey) hopt(lag) yl(3)
			disp e(irf)[1,1]
			assert  abs(1 - e(irf)[1,1]) < .02  
		
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
			forvalues h = 0/$H {
											disp "HI"

				qui gen `var'_`h' = f`h'.`var' - l.`var' // cumulative

				if `h' == 0 {	
					qui ivreg2 `var'_`h' l(0/$shh)`shock' l(1/$hh).d.`var' $covariates, bw(auto) robust
					estat ic
					qui predict r`h', resid
					global rcall $rcall r`h'
					
				}

				
				else {
					qui ivreg2 `var'_`h' l(0/$shh)`shock' l(1/$hh).d.`var' $rcall $covariates,  robust
					estat ic
					qui predict r`h', resid
					global rcall $rcall r`h'
				}

				matrix `var'level[`h'+1,1] = round(_b[`shock'], $rounding)
				matrix `var'level_lb[`h'+1,1] = round(_b[`shock'] - _se[`shock'], $rounding)			
				matrix `var'level_ub[`h'+1,1] = round(_b[`shock'] + _se[`shock'], $rounding)
				matrix `var'ciub[`h'+1,1] = round(_b[`shock'] + 2*_se[`shock'], $rounding)			 
				matrix `var'cilb[`h'+1,1] = round(_b[`shock'] - 2*_se[`shock'], $rounding) 
				matrix `var'cumul_vector[`h'+1,1] = round(_b[`shock'], $rounding)
				matrix `var'se[`h'+1,1] = round(_se[`shock'], $rounding)

				cap drop `var'_`h'
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
		
			twoway (rarea `var'ciub1 `var'cilb1 horizon, fcolor(navy*.20) lcolor(navy*.10)) ///
			(rarea `var'level_lb1 `var'level_ub1 horizon, fcolor(navy*.40) lcolor(navy*.30)) ///
			(line `var'level1 horizon, lcolor(blue*.8) lpattern(dash) lwidth(medthick)) ///
			(line zeros horizon, lcolor(black) lwidth(thin)), scale(1) ///
			legend(order(3 "`var'") position(inside) ring(0)) ytitle("$y_unit Δ", height(5)) xtitle("Horizon", height(5)) xlabel(0(4)$H) title("") name(irf_`var', replace) saving(irf_`var', replace)
			
			graph export "consum`z'_`shock'.pdf", replace
			
			drop `var'level1 `var'level_lb1 `var'level_ub1 `var'cilb1 `var'ciub1 `var'se
			restore
		}
	}
}



