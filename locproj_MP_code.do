* Select group
// restore, preserve
// collapse (mean) consum (first) yTreas $SHOCKS gs1 eff_ff_rate sp500_hf pc1ff1_hf if hh_il == 1 [pw=cop_share], by(time)
drop if wealthgrid != 1
collapse (mean) consum (first) yTreas $SHOCKS ///
gs1 FEDFUNDS eff_ff_rate sp500_hf pc1ff1_hf /// 
GDPCTPI GDPC1 PCECTPI CPIAUCSL consum_per_hh PCECC96 [pw=cop_share], by(time)

** RECALL THAT OUR CONSUMPTION DATA BEGINS 1999Q2 **

* Cumulative responses 
tsset time
// MPS_ORTH RRshock_old jk standard_MP
gen log_real_gdp = log(GDPC1) * 100
gen log_real_cons = log(PCECC96) * 100
gen log_price    = log(CPIAUCSL) * 100 //GDPCTPI
gen log_consum_per_hh = log(consum_per_hh) * 100

gen t = _n
gen conss = 1

global shock_choices $SHOCKS
foreach var in $shock_choices {
	locproj eff_ff_rate l(0/4).`var'  t conss, h(12) m(newey) hopt(lag) yl(3)
	replace `var' =  `var' * e(irf)[1,1]
}

locproj   eff_ff_rate l(0/4).norm_RRshock_new t, h(12) m(newey) hopt(lag) yl(4) // IRFs impact, matches paper (different controls than paper)
locproj   eff_ff_rate l(0/4).norm_RRshock_new l(1/4).log_real_gdp l(1/4).log_price t, h(12) m(newey) hopt(lag) yl(4) // IRFs impact, same controls as paper
locproj   eff_ff_rate l(0/4).d.norm_RRshock_new l(1/4).d.log_real_gdp l(1/4).d.log_price l(1/4).d.eff_ff_rate, h(12) m(newey) trans(cmlt) hopt(lag) // IRFs cmlt

locproj   log_real_gdp l(0/4).norm_RRshock_new l(1/4).eff_ff_rate l(1/4).log_real_gdp l(1/4).log_price t, h(16) m(newey) hopt(lag) yl(4) // IRFs impact, same controls as paper
locproj   log_real_cons l(0/4).norm_RRshock_new l(1/4).eff_ff_rate l(1/4).log_real_gdp l(1/4).log_price t, h(16) m(newey) hopt(lag) yl(4) // IRFs impact, same controls as paper

locproj   log_consum_per_hh l(0/4).norm_RRshock_new l(1/4).eff_ff_rate l(1/4).log_real_gdp l(1/4).log_price t, h(16) m(newey) hopt(lag) yl(4) // IRFs impact, same controls as paper


locproj   consum l(0/4).RRshock_new_avg l(1/4).eff_ff_rate l(1/4).log_real_gdp l(1/4).log_price t, h(16) m(newey) hopt(lag) yl(4) // til 2007
locproj   consum l(0/4).aruoba_mp l(1/4).eff_ff_rate l(1/4).log_real_gdp l(1/4).log_price t, h(16) m(newey) hopt(lag) yl(4) // til 2007

* Effects are negative but very small 
locproj   consum l(0/4).standard_MP l(1/4).eff_ff_rate l(1/4).log_real_gdp l(1/4).log_price t, h(16) m(newey) hopt(lag) yl(4) // til 2020
locproj   consum l(0/4).d.standard_MP l(1/4).d.eff_ff_rate l(1/4).d.log_real_gdp l(1/4).d.log_price l(1/4).d.consum t, stats h(16) m(newey) hopt(lag) trans(cmlt) // til 2020

locproj   consum l(0/4).jk l(1/4).eff_ff_rate l(1/4).log_real_gdp l(1/4).log_price t, h(16) m(newey) hopt(lag) yl(4) // til 2020
locproj   consum l(0/4).d.jk l(1/4).d.eff_ff_rate l(1/4).d.log_real_gdp l(1/4).d.log_price l(1/4).d.consum t, stats h(16) m(newey) hopt(lag) trans(cmlt) // til 2020

locproj   consum l(0/4).MPS_ORTH l(1/4).eff_ff_rate l(1/4).log_real_gdp l(1/4).log_price t, h(16) m(newey) hopt(lag) yl(4) // til 2020
locproj   log_consum_per_hh l(0/4).MPS_ORTH l(1/4).eff_ff_rate l(1/4).log_real_gdp l(1/4).log_price t, h(16) m(newey) hopt(lag) yl(4) // til 2020
locproj   log_real_cons l(0/4).MPS_ORTH l(1/4).eff_ff_rate l(1/4).log_real_gdp l(1/4).log_price t, h(16) m(newey) hopt(lag) yl(4) // til 2020

* Before and after 1999Q2
locproj   consum l(0/4).MPS_ORTH l(1/4).eff_ff_rate l(1/4).log_real_gdp l(1/4).log_price t if time >= tq(1999q2), h(16) m(newey) hopt(lag) yl(4) // til 2020
locproj   consum l(0/4).MPS_ORTH l(1/4).eff_ff_rate l(1/4).log_real_gdp l(1/4).log_price t if time < tq(1999q2), stats h(16) m(newey) hopt(lag) yl(4) // til 2020

