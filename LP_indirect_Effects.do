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

global H=16
global hh=2
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
global shock_choice standard_gov_FP //ADshock_new_avg // MPS_ORTH // standard_MP had weird effects //aruoba_mp // RRshock_new_avg

gen inflation    = 100 * (CPIAUCSL - l3.CPIAUCSL)/l3.CPIAUCSL
gen log_real_gdp = log(GDPC1) * 100
gen log_real_cons = log(PCECC96) * 100
gen log_price    = log(CPIAUCSL) * 100 //GDPCTPI


if "$data_choice" == "CEX_all" {
	drop if wealthgrid != 1
}


gen log_gov = 100 * log(GCEC1)

* Collapse the data 
collapse (mean) consum (first) $SHOCKS standard_tax_FP standard_gov_FP ///
 log_real_gdp inflation eff_ff_rate GDPCTPI GCEC1 log_gov [pw=cop_share], by(groups time)	

xtset groups time
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
			tsset time
			
			gen t = _n
			gen t2 = t^2
			gen t3 = t^3
			gen t4 = t^4
			
			
			if "`shock'" == "standard_gov_FP" {
				* Normalize the spending shock 
				qui reg log_real_gdp t t2 
				qui predict lyquad
				tsline lyquad
				gen yquad = exp(lyquad / 100)
				summ yquad
				replace `shock' = 100 * 100 * `shock' / (l.yquad * l.GDPCTPI) // multiply by 100 again?
				disp "done normalizing"
			}
			
			* Demeaning covariates
			foreach Var in log_real_gdp inflation eff_ff_rate log_gov {
				tsset time
				qui gen d`Var' = d.`Var' 
				qui summ d`Var'
				qui replace d`Var' = d`Var' - r(mean)
				forvalues i = 1(1)2 {
					gen d`Var'_int`i' = `shock' * l`i'.d`Var'  
				}
				disp "Done demeaning"
			}
			global main_covs l(1/2).dlog_real_gdp  l(1/2).dinflation l(1/2).deff_ff_rate l(1/2).dlog_gov
			global ind_efx dlog_real_gdp_int1 dlog_real_gdp_int2 dinflation_int1 ///
			 dinflation_int2 deff_ff_rate_int1 deff_ff_rate_int2 dlog_gov_int1 dlog_gov_int2

			
// 			matrix mp_offset = J($H + 1, 1, 0)
			
			locproj eff_ff_rate `shock' $main_covs, h(16) m(newey) hopt(lag) trans(cmlt)
			forvalues i=0(1)$H {
// 				matrix mp_offset[`i'+1,1] = e(irf)[`i'+1, 1]
				gen mp_fp`i' = `shock' * e(irf)[`i'+1, 1]
				disp "done interacting shock"
			}
			
			* Generate variable which are the shocks times these reponses
			 
			
			
// 			* For each shock, have the shock generate a 1% increase in the FFR
// 			locproj eff_ff_rate l(0/4).`shock'  t , h(12) m(newey) hopt(lag) yl(3)
// 			replace `shock' =  `shock' * e(irf)[1,1]
//			
// 			qui locproj eff_ff_rate l(0/4).`shock' t , h(12) m(newey) hopt(lag) yl(3)
// 			disp e(irf)[1,1]
// 			assert  abs(1 - e(irf)[1,1]) < .02  
//		
// 			local label_id = `label_id' + 1
			
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
// 					qui ivreg2 `var'_`h' l(0/2).`shock' l(1/$hh).d.`var' $main_covs $ind_efx mp_fp`h', bw(auto) robust
					qui ivreg2 `var'_`h' (log_gov = l(0/2).`shock') l(1/$hh).d.`var' $main_covs $ind_efx mp_fp`h', bw(auto) robust
					estat ic
					qui predict r`h', resid
					global rcall $rcall r`h'
					
				}

				
				else {
					qui ivreg2 `var'_`h' (log_gov = l(0/2).`shock') l(1/$hh).d.`var' $rcall $main_covs $ind_efx mp_fp`h',  robust
					estat ic
					qui predict r`h', resid
					global rcall $rcall r`h'
				}

// 				matrix `var'level[`h'+1,1] = round(_b[`shock'], $rounding)
// 				matrix `var'level_lb[`h'+1,1] = round(_b[`shock'] - _se[`shock'], $rounding)			
// 				matrix `var'level_ub[`h'+1,1] = round(_b[`shock'] + _se[`shock'], $rounding)
// 				matrix `var'ciub[`h'+1,1] = round(_b[`shock'] + 2*_se[`shock'], $rounding)			 
// 				matrix `var'cilb[`h'+1,1] = round(_b[`shock'] - 2*_se[`shock'], $rounding) 
// 				matrix `var'cumul_vector[`h'+1,1] = round(_b[`shock'], $rounding)
// 				matrix `var'se[`h'+1,1] = round(_se[`shock'], $rounding)

				matrix `var'level[`h'+1,1] = round(_b[log_gov], $rounding)
				matrix `var'level_lb[`h'+1,1] = round(_b[log_gov] - _se[log_gov], $rounding)			
				matrix `var'level_ub[`h'+1,1] = round(_b[log_gov] + _se[log_gov], $rounding)
				matrix `var'ciub[`h'+1,1] = round(_b[log_gov] + 2*_se[log_gov], $rounding)			 
				matrix `var'cilb[`h'+1,1] = round(_b[log_gov] - 2*_se[log_gov], $rounding) 
				matrix `var'cumul_vector[`h'+1,1] = round(_b[log_gov], $rounding)
				matrix `var'se[`h'+1,1] = round(_se[log_gov], $rounding)

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



