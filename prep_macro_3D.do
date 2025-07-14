**# Prep data 
global measures income_and_wealth
global meas_list income wealth 
global max_grid_point 10
global data_path $init_path/7_Results/$measures/from_mcmc/data

* Import most current Kendall's Tau and save to .dta
import delimited "$data_path/SCF_kendalls_tau_A non-diag_.csv", stringcols(1) clear 
gen qdate = quarterly(time, "YQ")
format qdate %tq
drop time 
rename qdate time

rename income_wealth income_wealth_ktau

save "$init_path/2_Data_processing/SCF_kendalls_tau.dta", replace

* Import most current Tail Dependence and save to .dta
import delimited "$data_path/SCF_tail_dependence_A non-diag_.csv", stringcols(1) clear 
gen qdate = quarterly(time, "YQ", 2021)
format qdate %tq
tsset qdate, quarterly
drop time 
rename qdate time

save "$init_path/2_Data_processing/SCF_tail_dependence.dta", replace

* Import most current Pearson and save to .dta
import delimited "$data_path/SCF_pearson_A non-diag_.csv", stringcols(1) clear 
gen qdate = quarterly(time, "YQ", 2021)
format qdate %tq
tsset qdate, quarterly
drop time 
rename qdate time

rename income_wealth income_wealth_pcorr

save "$init_path/2_Data_processing/SCF_pearson.dta", replace

* Import most current granular Pearson and save to .dta
import delimited "$data_path/SCF_granular_pearson_A non-diag_.csv", stringcols(1) clear 
gen qdate = quarterly(time, "YQ", 2021)
format qdate %tq
tsset qdate, quarterly
drop time 
rename qdate time

rename high_income_high_wealth high_income_high_wealth_pcorr
rename high_income_low_wealth high_income_low_wealth_pcorr
rename low_income_high_wealth low_income_high_wealth_pcorr
rename low_income_low_wealth  low_income_low_wealth_pcorr

save "$init_path/2_Data_processing/SCF_granular_pearson.dta", replace


import delimited "$data_path/SCF_granular_kendalls_tau_A non-diag_.csv", stringcols(1) clear 
gen qdate = quarterly(time, "YQ", 2021)
format qdate %tq
tsset qdate, quarterly
drop time 
rename qdate time

rename high_income_high_wealth high_income_high_wealth_ktau
rename high_income_low_wealth high_income_low_wealth_ktau
rename low_income_high_wealth low_income_high_wealth_ktau
rename low_income_low_wealth  low_income_low_wealth_ktau

save "$init_path/2_Data_processing/SCF_granular_ktau.dta", replace


// import delimited "/Users/lc/Dropbox/Distributional_Dynamics/2_Data_processing/hh_data.csv", clear
// gen qdate = quarterly(time, "YQ", 2021)
// format qdate %tq
// tsset qdate, quarterly
// drop time 
// rename qdate time
//
// save "$init_path/2_Data_processing/hh_data.dta", replace


* Import functional data 
import delimited "$data_path/SCF_functional_data_A non-diag_.csv", clear
set scheme s1color
graph set window fontface "Times New Roman"
graph drop _all 

* clean
gen qdate = quarterly(time, "YQ")
format qdate %tq
drop time 
rename qdate quarter 


// save "/Users/lc/Dropbox/Distributional_Dynamics/2_Data_processing/functional_data.dta", replace

* Merge in shocks 
merge 1:1 quarter using "/Users/lc/Dropbox/Distributional_Dynamics/1_Data/shocks/all_shocks.dta"
drop _merge

* Merge in aggregates 
merge 1:1 quarter using "/Users/lc/Dropbox/Distributional_Dynamics/2_Data_processing/lp_data.dta"
drop _merge

rename quarter time 

* Merge in higher order  
merge 1:1 time using "$init_path/2_Data_processing/SCF_tail_dependence.dta"
drop _merge

merge 1:1 time using "$init_path/2_Data_processing/SCF_kendalls_tau.dta"
drop _merge

merge 1:1 time using "$init_path/2_Data_processing/stationary_aggs.dta" 
drop _merge

merge 1:1 time using "$init_path/2_Data_processing/hh_data.dta"
drop _merge 

merge 1:1 time using "$init_path/2_Data_processing/SCF_pearson.dta"
drop _merge

merge 1:1 time using "$init_path/2_Data_processing/SCF_granular_pearson.dta"
drop _merge

merge 1:1 time using "$init_path/2_Data_processing/SCF_granular_ktau.dta"
drop _merge

tsset time

* Import inflation 
mat input inflation_matrix = ( ///
1951,	8.615560641\ /// 2019 CPI / 1951 CPI 
1952,	8.460674157\ ///
1953,	8.404017857\ ///
1954,	8.329646018\ ///
1955,	8.366666667\ ///
1956,	8.238512035\ ///
1957,	7.976694915\ ///
1958,	7.762886598\ ///
1959,	7.699386503\ ///
1960,	7.575452716\ ///
1961,	7.5\ ///
1962,	7.426035503\ ///
1963,	7.324902724\ ///
1964,	7.226487524\ ///
1965,	7.117202268\ ///
1966,	6.920955882\ ///
1967,	6.711229947\ ///
1968,	6.457975986\ ///
1969,	6.18226601\ ///
1970,	5.892018779\ ///
1971,	5.644677661\ ///
1972,	5.480349345\ ///
1973,	5.157534247\ ///
1974,	4.688667497\ ///
1975,	4.332566168\ ///
1976,	4.096844396\ ///
1977,	3.853633572\ ///
1978,	3.606321839\ ///
1979,	3.293963255\ ///
1980,	2.962234461\ ///
1981,	2.706685838\ ///
1982,	2.552542373\ ///
1983,	2.447984395\ ///
1984,	2.350187266\ ///
1985,	2.272178636\ ///
1986,	2.233096085\ ///
1987,	2.158830275\ ///
1988,	2.083563918\ ///
1989,	1.996288441\ ///
1990,	1.902475998\ ///
1991,	1.835689907\ ///
1992,	1.791151284\ ///
1993,	1.747099768\ ///
1994,	1.711363636\ ///
1995,	1.671105193\ ///
1996,	1.627756161\ ///
1997,	1.593313584\ ///
1998,	1.572025052\ ///
1999,	1.539247751\ ///
2000,	1.488730724\ ///
2001,	1.447520185\ ///
2002,	1.425056775\ ///
2003,	1.393412287\ ///
2004,	1.356756757\ ///
2005,	1.312303939\ ///
2006,	1.271100608\ ///
2007,	1.236047275\ ///
2008,	1.19032564\ ///
2009,	1.194479695\ ///
2010,	1.175093633\ ///
2011,	1.139183056\ ///
2012,	1.115555556\ ///
2013,	1.099270073\ ///
2014,	1.080964686\ ///
2015,	1.079105761\ ///
2016,	1.065365025\ ///
2017,	1.042936288\ ///
2018,	1.018117902\ ///
2019,	1\ ///
2020, 0.987670514\ ///
2021, 0.943609023)

svmat inflation_matrix, names(vars)
rename vars1 inf_year 
rename vars2 CPI_mat

* Generate year variable 
gen year = year(dofq(time))

* Assign the correct CPI to each row, by year 
gen CPI_inf = .
levelsof year, local(levels) 
foreach l of local levels {
	qui summ CPI_mat if inf_year == `l'
	replace CPI_inf = r(mean) if year == `l'
}

// drop cpi_inflation

**# Variable Transformations 
// // gen real_gov_spending = gov_spending * CPI_inf  
// // gen real_nfedreceipts = nfedreceipts * CPI_inf
// gen real_gdp_m        = gdp * CPI_inf
// gen consumption       = durable_consumption + nondurable_consumption + services_consumption
// gen investment        = nonresidential_investment + private_investment + residential_investment
// gen gov_spend         = gov_defense + gov_nondefense + gov_state_local
// gen real_consum       = consumption * CPI_inf 
// gen real_invest       = investment * CPI_inf 
// gen real_gov          = gov_spend * CPI_inf 
//
// foreach var in real_consum real_invest real_gov real_gdp_m {
// 	gen l`var'=ln(`var')  // log real variables 
// }

// foreach var in real_gdp real_consumption real_inv TFP real_wages real_gdp_RZ real_gov_spending real_nfedreceipts{  // real_gdp_RZ comes from ramey zubairy 2018
// 	gen l`var'=ln(`var')  // log real variables 
// }

* time trend 
gen t = _n
gen t2 = t^2


replace liquidity_ratio   = liquidity_ratio * 100
replace liq_premium       = liq_premium * 100
// replace real_house_price  = real_house_price * 100

**# Important globals 
* Global for dependent variable 
ds shares*
global SHARES = r(varlist)

ds quantiles*
global QUANTS = r(varlist)

ds levels*
global LEVELS = r(varlist)

foreach var of varlist $SHARES $QUANTS $LEVELS {
    local newname = substr("`var'", 1, length("`var'")-1)
    rename `var' `newname'
}

* re-do it
ds shares*
global SHARES = r(varlist)

ds quantiles*
global QUANTS = r(varlist)

ds levels*
global LEVELS = r(varlist)

foreach var of varlist $SHARES {
    local measure = substr("`var'", 1, strpos("`var'", "_")-1)  // e.g., sharesincome
    local measure = substr("`measure'", 7, .)
	local perc    = substr("`var'", strpos("`var'", "_")+1, .)
    la var `var' "`perc'th pct `measure'"
	
	* scale up var to percent 
	replace `var' = 100 * `var'
}

foreach var of varlist $QUANTS {
    local measure = substr("`var'", 1, strpos("`var'", "_")-1)  // e.g., quantilesincome
    local measure = substr("`measure'", 10, .)
	local perc    = substr("`var'", strpos("`var'", "_")+1, .)
    la var `var' "`perc'th pct `measure'"
	
	* Take "logs" 
	replace `var' = 100 * sign(`var') * log(abs(`var') + 1)  
}

foreach var of varlist $LEVELS {
    local measure = substr("`var'", 1, strpos("`var'", "_")-1)  // e.g., levelsincome
    local measure = substr("`measure'", 7, .)
	local perc    = substr("`var'", strpos("`var'", "_")+1, .)
    la var `var' "`perc'th pct `measure'"
	
	* Take "logs" 
	replace `var' = 100 * sign(`var') * log(abs(`var') + 1)
}


**# Shock treatment 
rename CBI_median CB_information_shocks
rename delphic_forward_guidance FG_shock // could be measurement error
rename EXOGENRRATIO standard_tax_FP
rename ramey_gov_shocks standard_gov_FP  // this should instrument variation in government spending  

replace MP_median = MP_median * 100 // to scale it to basis points
replace MP_median = MP_median / 25  // scale the effect to 25 point shocks

la var MP_median "Monetary Policy"  // sd shock 
la var CB_information_shocks "Central Bank Information"  // sd shock  
la var FG_shock "Forward Guidance"  // sd shock 
la var standard_tax_FP "Tax"  // percent of GDP 
la var standard_gov_FP "Government Spending"

rename MP_median MP
rename standard_tax_FP FP
global SHOCKS MP FP // CB_information_shocks FG_shock standard_tax_FP standard_gov_FP  

* Gets the initials based on the meas_list
global initials ""

foreach word in $meas_list {
    local first_letter = substr("`word'", 1, 1)
    global initials "$initials`first_letter'"
}

global initials "$initials*"

ds $initials
global COPULA_SHARES = r(varlist)
foreach var in $COPULA_SHARES {
    local newname = substr("`var'", 1, length("`var'")-1)
    rename `var' `newname'
}

* Outcomes 
ds $initials 
global COPULA_SHARES = r(varlist)

foreach var in $COPULA_SHARES {
	replace `var' = 100 * `var'
}


* Split Copula shares into groups
global half_point = floor($max_grid_point /2 )
global poor_poor
global poor_rich
global rich_poor
global rich_rich


foreach var in $COPULA_SHARES {
	local number_part = substr("`var'", strpos("`var'", "_")+1, .)
	if length("`number_part'") == 2 {
		local first_number = substr("`number_part'", 1, 1)
		local second_number = substr("`number_part'", 2, 2)
	}
	
	* Only enters here in the decile case. Would not hold for anything finer
	else if length("`number_part'") == 3 {
		local last_number = substr("`number_part'", 3, 3)
		if "`last_number'" == "0" {
			local first_number = substr("`number_part'", 1, 1)
			local second_number = "$max_grid_point"
		}
		else {
			local first_number = "$max_grid_point"
			local second_number = substr("`number_part'", 3, 3)
		}
	}
	else if length("`number_part'") == 4 {
		local first_number = "$max_grid_point"
		local second_number = "$max_grid_point"
	}
	
	la var `var' "Grid point (`first_number', `second_number')"
	* First case 
	if `first_number' <= $half_point & `second_number' <= $half_point {
		global poor_poor $poor_poor `var'
	}
	
	* Second case 
	else if `first_number' > $half_point & `second_number' > $half_point {
		global rich_rich $rich_rich `var'
	}
	
	* Third case 
	else if `first_number' > $half_point & `second_number' <= $half_point {
		global rich_poor $rich_poor `var'
	}
	
	* Fourth case 
	else if `first_number' <= $half_point & `second_number' > $half_point {
		global poor_rich $poor_rich `var'
	}
}

* Some labeling of the higher moments
la var income_wealth_ktau "τ̄"
la var  low_income_low_wealth_ktau "τ(L,L)"
la var  low_income_high_wealth_ktau "τ(L,H)"
la var  high_income_low_wealth_ktau "τ(H,L)"
la var  high_income_high_wealth_ktau "τ(H,H)"

la var tdl_1 "λₗ(10ᵗʰ,10ᵗʰ)"
la var  tdl_2 "λₗ(20ᵗʰ,20ᵗʰ)"
la var  tdl_3 "λₗ(30ᵗʰ,30ᵗʰ)"
la var  tdl_4 "λₗ(40ᵗʰ,40ᵗʰ)"
la var  tdl_5 "λₗ(50ᵗʰ,50ᵗʰ)"
la var  tdu_6 "λᵤ(60ᵗʰ,60ᵗʰ)"
la var  tdu_7 "λᵤ(70ᵗʰ,70ᵗʰ)"
la var  tdu_8 "λᵤ(80ᵗʰ,80ᵗʰ)"
la var  tdu_9 "λᵤ(90ᵗʰ,90ᵗʰ)"

la var income_wealth_pcorr "ρ̄"
la var  low_income_low_wealth_pcorr "ρ(L,L)"
la var  low_income_high_wealth_pcorr "ρ(L,H)"
la var  high_income_low_wealth_pcorr "ρ(H,L)"
la var  high_income_high_wealth_pcorr "ρ(H,H)"

rename low_income_low_wealth_ktau lilw_ktau
rename low_income_high_wealth_ktau lihw_ktau
rename high_income_low_wealth_ktau hilw_ktau
rename high_income_high_wealth_ktau hihw_ktau

rename low_income_low_wealth_pcorr lilw_pcorr
rename low_income_high_wealth_pcorr lihw_pcorr
rename high_income_low_wealth_pcorr hilw_pcorr
rename high_income_high_wealth_pcorr hihw_pcorr


* Gen the larger share groups
egen H_income_H_wealth = rowtotal(iw_66 iw_76 iw_86 iw_96 iw_106 iw_67 iw_77 iw_87 /// 
iw_97 iw_107 iw_68 iw_78 iw_88 iw_98 iw_108 iw_69 iw_79 iw_89 iw_99 iw_109 ///
iw_610 iw_710 iw_810 iw_910 iw_1010)
	
egen H_income_L_wealth = rowtotal(iw_61 iw_71 iw_81 iw_91 iw_101 iw_62 iw_72 iw_82 ///
iw_92 iw_102 iw_63 iw_73 iw_83 iw_93 iw_103 iw_64 iw_74 iw_84 iw_94 iw_104 ///
iw_65 iw_75 iw_85 iw_95 iw_105)
	
egen L_income_L_wealth = rowtotal(iw_11 iw_21 iw_31 iw_41 iw_51 iw_12 iw_22 iw_32 ///
iw_42 iw_52 iw_13 iw_23 iw_33 iw_43 iw_53 iw_14 iw_24 iw_34 iw_44 iw_54 ///
iw_15 iw_25 iw_35 iw_45 iw_55)
	
egen L_income_H_wealth = rowtotal(iw_16 iw_26 iw_36 iw_46 iw_56 iw_17 iw_27 iw_37 ///
iw_47 iw_57 iw_18 iw_28 iw_38 iw_48 iw_58 iw_19 iw_29 iw_39 iw_49 iw_59 ///
iw_110 iw_210 iw_310 iw_410 iw_510)

global cop_quads H_income_H_wealth H_income_L_wealth L_income_L_wealth L_income_H_wealth

foreach var in $cop_quads {
	replace `var' = . if `var' == 0
}

la var H_income_H_wealth "Copula Share (H,H)"
la var H_income_L_wealth "Copula Share (H,L)"
la var L_income_H_wealth "Copula Share (L,H)"
la var L_income_L_wealth "Copula Share (L,L)"

* Merge with total househouds 
merge 1:1 time using "$init_path/2_data_processing/hh_data.dta"

global ktau income_wealth_ktau lilw_ktau lihw_ktau hilw_ktau hihw_ktau

global tail_dep tdl_1 tdl_2 tdl_3 tdl_4 tdl_5 tdu_6 tdu_7 tdu_8 tdu_9 

global pcorr income_wealth_pcorr lilw_pcorr lihw_pcorr hilw_pcorr hihw_pcorr

foreach var in $ktau $tail_dep $pcorr{
	replace `var' = `var' * 100
}

