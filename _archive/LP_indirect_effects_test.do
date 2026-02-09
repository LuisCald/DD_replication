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
// replace groups = 1
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
gen log_fed_rec = 100 * log(FGRECPTx)
gen nond_serv = 100 * log(PCNDx + PCESVx)
gen consum_sum = consum

* Collapse the data 
collapse (mean) consum (sum) consum_sum (first) $SHOCKS standard_tax_FP standard_gov_FP ///
 log_real_gdp inflation eff_ff_rate GDPC1 GDPCTPI GCEC1 ///
 log_real_cons log_gov log_fed_rec PCECC96 PCNDx PCESVx nond_serv PCDGx ///
[pw=cop_share], by(groups time)	

xtset groups time


replace consum = 100 * log(consum)
replace consum_sum = 100 * log(consum_sum)
replace PCDGx = 100 * log(PCDGx)
replace PCECC96 = 100 * log(PCECC96)
replace PCNDx = 100 * log(PCNDx)
replace PCESVx = 100 * log(PCESVx)

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
			
// 			foreach V in `var' log_real_gdp inflation eff_ff_rate GDPC1 GDPCTPI GCEC1 ///
// 			log_real_cons log_gov log_fed_rec PCECC96 PCNDx PCESVx PCDGx nond_serv {
//  				qui hpfilter `V', trend(`V'_trend) cycle(`V'_cycle)
// 				drop `V'
// 				rename `V'_cycle `V'
// 				}

			foreach V in log_gov log_real_gdp log_fed_rec  {
 				qui hpfilter `V', trend(`V'_trend) cycle(`V'_cycle)
				}

			
			gen t = _n
			gen t2 = t^2
			gen t3 = t^3
			gen t4 = t^4
			gen real_rate = eff_ff_rate - inflation
			
			* Generate BP shocks
// 			gen some_gov = 100 * (GCEC1 / GDPC1)
// 			reg some_gov L(1/4).some_gov L(1/4).log_real_gdp L(1/4).log_fed_rec t t2 
// 			replace bp_shock = bp_shock / 100 
// 			reg log_gov_cycle L(1/4).log_gov_cycle L(1/4).log_real_gdp_cycle L(1/4).log_fed_rec_cycle
			reg log_gov L(1/4).log_gov L(1/4).log_real_gdp L(1/4).log_fed_rec t t2
			predict bp_shock, resid
			
			local shock standard_gov_FP
			if "`shock'" == "standard_gov_FP" {
				* Normalize the spending shock 
				qui reg log_real_gdp t t2 
				qui predict lyquad
				gen yquad = exp(lyquad / 100)
				
				qui hpfilter GDPC1, trend(ytrend)
				
// 				qui replace `shock' = `shock' / (l.ytrend * l.GDPCTPI)	
				qui replace `shock' = `shock' / (l.GDPCTPI)
// 				replace GCEC1 = 100 * GCEC1 / (l.ytrend)
// 				qui hpfilter GCEC1, cycle(GCEC1_cycle)
// 				qui replace `shock' = `shock' / (l.yquad * l.GDPCTPI)
// 				qui replace `shock' = `shock' / (l.GDPCTPI)

// 				replace `shock' = sign(`shock') * log(1 + abs(`shock') / l.GDPCTPI)
// 				replace consum = consum / 1000000000 // since GDP in billions
// 				replace consum = consum / l.yquad // Gordon-Krenn (2010)
			}
			
// 			 gen real_gdp_GK = 100 * (GDPC1 / l.yquad)
// 			 replace GCEC1 = 100 * (GCEC1 / l.yquad)
// 			replace GCEC1 = 100 * (GCEC1 / l.GDPC1)
			
			* Demeaning covariates
			foreach Var in `var' log_real_gdp inflation eff_ff_rate log_gov {
// 			foreach Var in real_gdp_GK inflation eff_ff_rate GCEC1 {

				qui gen d`Var' = d.`Var' 
				qui summ d`Var'
				qui replace d`Var' = (d`Var' - r(mean))
			}
			
			global main_covs l(1/2).dlog_real_gdp  l(1/2).dinflation l(1/2).deff_ff_rate l(1/2).dlog_gov
// 			global main_covs l(1/2).dreal_gdp_GK  l(1/2).dinflation l(1/2).deff_ff_rate l(1/2).dGCEC1
			
			
			* Run first stage regression
// 			ivreg2 d.log_gov l(0/2).`shock' l(0/4).bp_shock $main_covs t t2 t3 t4, bw(auto) robust // adding qtrend or quartic trend here helps with h=0 s.e.
// 			ivreg2 log_gov l(0/2).`shock' l(0/4).bp_shock, bw(auto) robust // $main_covs l(1/$hh).d.`var', bw(auto) robust // adding qtrend or quartic trend here helps with h=0 s.e.
			qui  ivreg2 log_gov l(0/$hh).`shock' l(0/$hh).bp_shock $main_covs, bw(auto) robust // adding qtrend or quartic trend here helps with h=0 s.e.

			predict f_hat
// 			vif, uncentered															// adding lags of the DV affect result
			
// 			ivreg2 GCEC1 l(0/2).`shock' l(0/4).bp_shock l(1/2).d.GCEC1 l(1/2).dinflation l(1/2).deff_ff_rate, bw(auto) robust // adding qtrend or quartic trend here helps with h=0 s.e.
// 			predict gg2
			
			summ f_hat
			gen f_hat_demeaned = f_hat - r(mean) // doesnt matter 
// 			qui hpfilter f_hat, cycle(f_hat_demeaned)

			
			tsline f_hat_demeaned
// 			tsline f_hat_demeaned
// 			summ gg2 
// 			gen gg2_demeaned = gg2 - r(mean)
//			
// 			drop f_hat_demeaned
// 			rename gg2_demeaned f_hat_demeaned
// 			tsline f_hat_demeaned gg2_demeaned
			
			
// 			ivreg2 GCEC1 l(0/2).`shock' l(0/4).bp_shock l(1/4).GCEC1 $main_covs, bw(auto) robust
// 			gen ld_GCEC1 = l.d.GCEC1
// 			summ ld_GCEC1
// 			replace ld_GCEC1 = ld_GCEC1 - r(mean)
// 			ivreg2 GCEC1 l(0/2).`shock' l(0/4).bp_shock l(1/4).d.GCEC1 t, bw(auto) robust	
			
			
			foreach Var in log_real_gdp inflation eff_ff_rate log_gov {
				forvalues i = 1(1)2 {
					qui gen d`Var'_int`i' = f_hat_demeaned * l`i'.d`Var'  
				}
			}
			
			global ind_efx dlog_real_gdp_int1 dlog_real_gdp_int2 dinflation_int1 ///
			 dinflation_int2 deff_ff_rate_int1 deff_ff_rate_int2 dlog_gov_int1 dlog_gov_int2

// 			global ind_efx dreal_gdp_GK_int1 dreal_gdp_GK_int2 dinflation_int1 ///
// 			 dinflation_int2 deff_ff_rate_int1 deff_ff_rate_int2 dGCEC1_int1 dGCEC1_int2

			* Generate variable which are the shocks times these reponses	
			sleep 10000
			ac f_hat_demeaned
			sleep 5000
			if `z' == 1 {
				locproj eff_ff_rate f_hat_demeaned l(1/$hh).bp_shock l(1/$hh).`shock' $main_covs, h(16) m(newey) hopt(lag) trans(cmlt) as(pdf) ///
				grsave("/Users/lc/Dropbox/Distributional_Dynamics/7_Results/IRFs/MP_IRFS_DIS/R_response_FP") // l(1/2).dlog_real_gdp  l(1/2).dinflation
				
				locproj log_gov f_hat_demeaned l(1/$hh).bp_shock l(1/$hh).`shock' $main_covs, h(16) m(newey) hopt(lag) trans(cmlt) as(pdf) ///
				grsave("/Users/lc/Dropbox/Distributional_Dynamics/7_Results/IRFs/MP_IRFS_DIS/G_response_FP")
			}
//			
// 			locproj GCEC1 f_hat $main_covs, h(16) m(newey) hopt(lag) trans(cmlt) as(pdf) ///
//  			grsave("/Users/lc/Dropbox/Distributional_Dynamics/7_Results/IRFs/MP_IRFS_DIS/G_response_FP")

// 			locproj real_rate f_hat $main_covs, h(16) m(newey) hopt(lag) trans(cmlt) as(pdf) ///
// 			grsave("/Users/lc/Dropbox/Distributional_Dynamics/7_Results/IRFs/MP_IRFS_DIS/R_response_FP")

			* Normalize shock s.t. it raises spending by 1% of GDP 
// 			locproj GCEC1 l(0/4).f_hat l(0/4).GCEC1, h(16) m(newey) hopt(lag) yl(3)
// 			replace f_hat =  f_hat * e(irf)[1,1]
//			
// 			qui locproj GCEC1 l(0/4).f_hat l(0/4).GCEC1, h(16) m(newey) hopt(lag) yl(3)
// 			disp e(irf)[1,1]
// 			assert  abs(1 - e(irf)[1,1]) < .02  
			
// 			global coef_sum =0
// 			forvalues i=0(1)$H {
// 				global coef_sum = $coef_sum + e(irf)[`i'+1, 1]
// 			}
//	
// 			global coef_avg = $coef_sum / ($H + 1)
			summ ad_new_avg
			replace ad_new_avg = 100 * ad_new_avg - r(mean) // ad_new_avg is in pp
			
			forvalues i=0(1)$H {
// 				gen mp_fp`i' = f_hat_demeaned * (e(irf)[`i'+1, 1] - $coef_avg )
				gen mp_fp`i' = f_hat_demeaned * f`i'.ad_new_avg // using MP shocks directly 
				disp "done interacting MP and FP"
			}
			
			* Containers
			matrix `var'level = J($H + 1, 1, 0)	
			matrix `var'level_lb = J($H + 1, 1, 0)
			matrix `var'level_ub = J($H + 1, 1, 0)
			matrix `var'cilb = J($H + 1, 1, 0)	
			matrix `var'ciub = J($H + 1, 1, 0)	
			matrix `var'cumul_vector = J($H + 1, 1, 0)
			matrix `var'se = J($H + 1, 1, 0)
			
			matrix `var'level_mp = J($H + 1, 1, 0)	
			matrix `var'level_lb_mp = J($H + 1, 1, 0)
			matrix `var'level_ub_mp = J($H + 1, 1, 0)
			matrix `var'cilb_mp = J($H + 1, 1, 0)	
			matrix `var'ciub_mp = J($H + 1, 1, 0)	
			matrix `var'cumul_vector_mp = J($H + 1, 1, 0)
			matrix `var'se_mp = J($H + 1, 1, 0)
			
			matrix `var'level_mpfp = J($H + 1, 1, 0)	
			matrix `var'level_lb_mpfp = J($H + 1, 1, 0)
			matrix `var'level_ub_mpfp = J($H + 1, 1, 0)
			matrix `var'cilb_mpfp = J($H + 1, 1, 0)	
			matrix `var'ciub_mpfp = J($H + 1, 1, 0)	
			matrix `var'cumul_vector_mpfp = J($H + 1, 1, 0)
			matrix `var'se_mpfp = J($H + 1, 1, 0)

// 			gen dlog_gov100 = 100 * dlog_gov
// 			summ `var'
// 			replace `var' = `var' - r(mean) // demeaning the dependent var. -- doesnt matter
			
			global rcall 		
			forvalues h = 0/$H {
				
				qui gen `var'_`h' = f`h'.`var' - l.`var' // cumulative
				global all_covs l(1/$hh).d`var' $main_covs $ind_efx mp_fp`h' f`h'.ad_new_avg l(1/$hh).bp_shock

					
				if `h' == 0 {	
// 					qui ivreg2 `var'_`h' l(0/2).`shock' l(1/$hh).d.`var' $main_covs $ind_efx mp_fp`h', bw(auto) robust
					
// 					global all_covs l(1/$hh).d.`var' $main_covs
					qui ivreg2 `var'_`h' l(0/$hh).f_hat_demeaned $all_covs, bw(auto) robust
// 					vif, uncentered
// 					ivreg2 `var'_`h' (log_gov = l(0/2).`shock' l(0/4).bp_shock $main_covs mp_fp`h') l(1/$hh).d.`var'  $ind_efx, bw(auto) robust
// 					ivreg2 `var'_`h' (dlog_gov100 = l(0/2).`shock' l(0/4).bp_shock) l(1/2).`shock' l(1/4).bp_shock $all_covs t t2, bw(auto) robust 
					
// 					estat ic
					qui predict r`h', resid
					global rcall $rcall r`h'
					
				}

				
				else {
// 					global all_covs l(1/$hh).d.`var' $main_covs
					qui ivreg2 `var'_`h' l(0/$hh).f_hat_demeaned $all_covs $rcall, bw(auto) robust
// 					vif, uncentered
// 					ivreg2 `var'_`h' (log_gov = l(0/2).`shock' l(0/4).bp_shock $rcall $main_covs mp_fp`h') l(1/$hh).d.`var' $ind_efx,  robust
// 					ivreg2 `var'_`h' (dlog_gov100 = l(0/2).`shock' l(0/4).bp_shock) $rcall $all_covs t t2, bw(auto) robust 
					
// 					estat ic
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

// 				matrix `var'level[`h'+1,1] = round(_b[log_gov], $rounding)
// 				matrix `var'level_lb[`h'+1,1] = round(_b[log_gov] - _se[log_gov], $rounding)			
// 				matrix `var'level_ub[`h'+1,1] = round(_b[log_gov] + _se[log_gov], $rounding)
// 				matrix `var'ciub[`h'+1,1] = round(_b[log_gov] + 2*_se[log_gov], $rounding)			 
// 				matrix `var'cilb[`h'+1,1] = round(_b[log_gov] - 2*_se[log_gov], $rounding) 
// 				matrix `var'cumul_vector[`h'+1,1] = round(_b[log_gov], $rounding)
// 				matrix `var'se[`h'+1,1] = round(_se[log_gov], $rounding)

// 				matrix `var'level[`h'+1,1] = round(_b[dlog_gov100], $rounding)
// 				matrix `var'level_lb[`h'+1,1] = round(_b[dlog_gov100] - _se[dlog_gov100], $rounding)			
// 				matrix `var'level_ub[`h'+1,1] = round(_b[dlog_gov100] + _se[dlog_gov100], $rounding)
// 				matrix `var'ciub[`h'+1,1] = round(_b[dlog_gov100] + 2*_se[dlog_gov100], $rounding)			 
// 				matrix `var'cilb[`h'+1,1] = round(_b[dlog_gov100] - 2*_se[dlog_gov100], $rounding) 
// 				matrix `var'cumul_vector[`h'+1,1] = round(_b[dlog_gov100], $rounding)
// 				matrix `var'se[`h'+1,1] = round(_se[dlog_gov100], $rounding)

				matrix `var'level[`h'+1,1] = round(_b[f_hat_demeaned], $rounding)
				matrix `var'level_lb[`h'+1,1] = round(_b[f_hat_demeaned] - _se[f_hat_demeaned], $rounding)			
				matrix `var'level_ub[`h'+1,1] = round(_b[f_hat_demeaned] + _se[f_hat_demeaned], $rounding)
				matrix `var'ciub[`h'+1,1] = round(_b[f_hat_demeaned] + 2*_se[f_hat_demeaned], $rounding)			 
				matrix `var'cilb[`h'+1,1] = round(_b[f_hat_demeaned] - 2*_se[f_hat_demeaned], $rounding) 
				matrix `var'cumul_vector[`h'+1,1] = round(_b[f_hat_demeaned], $rounding)
				matrix `var'se[`h'+1,1] = round(_se[f_hat_demeaned], $rounding)
				
				matrix `var'level_mp[`h'+1,1] = round(_b[f`h'.ad_new_avg], $rounding)
				matrix `var'level_lb_mp[`h'+1,1] = round(_b[f`h'.ad_new_avg] - _se[f`h'.ad_new_avg], $rounding)			
				matrix `var'level_ub_mp[`h'+1,1] = round(_b[f`h'.ad_new_avg] + _se[f`h'.ad_new_avg], $rounding)
				matrix `var'ciub_mp[`h'+1,1] = round(_b[f`h'.ad_new_avg] + 2*_se[f`h'.ad_new_avg], $rounding)			 
				matrix `var'cilb_mp[`h'+1,1] = round(_b[f`h'.ad_new_avg] - 2*_se[f`h'.ad_new_avg], $rounding) 
				matrix `var'cumul_vector_mp[`h'+1,1] = round(_b[f`h'.ad_new_avg], $rounding)
				matrix `var'se_mp[`h'+1,1] = round(_se[f`h'.ad_new_avg], $rounding)
				
				matrix `var'level_mpfp[`h'+1,1] = round(_b[mp_fp`h'], $rounding)
				matrix `var'level_lb_mpfp[`h'+1,1] = round(_b[mp_fp`h'] - _se[mp_fp`h'], $rounding)			
				matrix `var'level_ub_mpfp[`h'+1,1] = round(_b[mp_fp`h'] + _se[mp_fp`h'], $rounding)
				matrix `var'ciub_mpfp[`h'+1,1] = round(_b[mp_fp`h'] + 2*_se[mp_fp`h'], $rounding)			 
				matrix `var'cilb_mpfp[`h'+1,1] = round(_b[mp_fp`h'] - 2*_se[mp_fp`h'], $rounding) 
				matrix `var'cumul_vector_mpfp[`h'+1,1] = round(_b[mp_fp`h'], $rounding)
				matrix `var'se_mpfp[`h'+1,1] = round(_se[mp_fp`h'], $rounding)
				
				
				

// 				matrix `var'level[`h'+1,1] = round(_b[d.f_hat_demeaned], $rounding)
// 				matrix `var'level_lb[`h'+1,1] = round(_b[d.f_hat_demeaned] - _se[d.f_hat_demeaned], $rounding)			
// 				matrix `var'level_ub[`h'+1,1] = round(_b[d.f_hat_demeaned] + _se[d.f_hat_demeaned], $rounding)
// 				matrix `var'ciub[`h'+1,1] = round(_b[d.f_hat_demeaned] + 2*_se[d.f_hat_demeaned], $rounding)			 
// 				matrix `var'cilb[`h'+1,1] = round(_b[d.f_hat_demeaned] - 2*_se[d.f_hat_demeaned], $rounding) 
// 				matrix `var'cumul_vector[`h'+1,1] = round(_b[d.f_hat_demeaned], $rounding)
// 				matrix `var'se[`h'+1,1] = round(_se[d.f_hat_demeaned], $rounding)

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
			
			svmat `var'level_mp, names(`var'level_mp)
			svmat `var'level_lb_mp, names(`var'level_lb_mp)
			svmat `var'level_ub_mp, names(`var'level_ub_mp)
			svmat `var'cilb_mp, names(`var'cilb_mp)
			svmat `var'ciub_mp, names(`var'ciub_mp)
			svmat `var'se_mp, names(`var'se_mp)
			
			svmat `var'level_mpfp, names(`var'level_mpfp)
			svmat `var'level_lb_mpfp, names(`var'level_lb_mpfp)
			svmat `var'level_ub_mpfp, names(`var'level_ub_mpfp)
			svmat `var'cilb_mpfp, names(`var'cilb_mpfp)
			svmat `var'ciub_mpfp, names(`var'ciub_mpfp)
			svmat `var'se_mpfp, names(`var'se_mpfp)
				
		
			cap drop horizon 
			cap drop zeros
			cap gen horizon = _n-1 if _n<=$H+1
			cap gen zeros = 0 if horizon!=.
		
			twoway (rarea `var'ciub1 `var'cilb1 horizon, fcolor(navy*.20) lcolor(navy*.10)) ///
			(rarea `var'level_lb1 `var'level_ub1 horizon, fcolor(navy*.40) lcolor(navy*.30)) ///
			(line `var'level1 horizon, lcolor(blue*.8) lpattern(dash) lwidth(medthick)) ///
			(line zeros horizon, lcolor(black) lwidth(thin)), scale(1) ///
			legend(order(3 "`var'") position(inside) ring(0)) ytitle("$y_unit Δ", height(5)) xtitle("Horizon", height(5)) xlabel(0(4)$H) title("") name(irf_`var', replace) saving(irf_`var', replace)
			
			graph export "consum`z'_f_hat.pdf", replace
			
			drop `var'level1 `var'level_lb1 `var'level_ub1 `var'cilb1 `var'ciub1 `var'se1
			
			twoway (rarea `var'ciub_mp1 `var'cilb_mp1 horizon, fcolor(navy*.20) lcolor(navy*.10)) ///
			(rarea `var'level_lb_mp1 `var'level_ub_mp1 horizon, fcolor(navy*.40) lcolor(navy*.30)) ///
			(line `var'level_mp1 horizon, lcolor(blue*.8) lpattern(dash) lwidth(medthick)) ///
			(line zeros horizon, lcolor(black) lwidth(thin)), scale(1) ///
			legend(order(3 "`var'") position(inside) ring(0)) ytitle("$y_unit Δ", height(5)) xtitle("Horizon", height(5)) xlabel(0(4)$H) title("") name(irf_`var', replace) saving(irf_`var', replace)
			
			graph export "consum`z'_mp.pdf", replace
			
			drop `var'level_mp1 `var'level_lb_mp1 `var'level_ub_mp1 `var'cilb_mp1 `var'ciub_mp1 `var'se_mp1
			
			twoway (rarea `var'ciub_mpfp1 `var'cilb_mpfp1 horizon, fcolor(navy*.20) lcolor(navy*.10)) ///
			(rarea `var'level_lb_mpfp1 `var'level_ub_mpfp1 horizon, fcolor(navy*.40) lcolor(navy*.30)) ///
			(line `var'level_mpfp1 horizon, lcolor(blue*.8) lpattern(dash) lwidth(medthick)) ///
			(line zeros horizon, lcolor(black) lwidth(thin)), scale(1) ///
			legend(order(3 "`var'") position(inside) ring(0)) ytitle("$y_unit Δ", height(5)) xtitle("Horizon", height(5)) xlabel(0(4)$H) title("") name(irf_`var', replace) saving(irf_`var', replace)
			
			graph export "consum`z'_mpfp.pdf", replace
			
			drop `var'level_mpfp1 `var'level_lb_mpfp1 `var'level_ub_mpfp1 `var'cilb_mpfp1 `var'ciub_mpfp1 `var'se_mpfp1
			
			restore
		}
	}
}



