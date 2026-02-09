**# Prep micro data 
global measures income_and_wealth
global meas_list income wealth 
global max_grid_point 10
global data_path $init_path/7_Results/$measures/from_mcmc/data

* Import most current Pearson and save to .dta
// import delimited "$data_path/consensus_pearson_A non-diag_.csv", stringcols(1) clear 
//
// save "$init_path/2_Data_processing/consensus_pearson.dta", replace

* Import functional data 
import delimited "$data_path/SCF_micro_data_A non-diag_.csv", clear
set scheme s1color
graph set window fontface "Times New Roman"
graph drop _all 

* clean
gen qdate = quarterly(time, "YQ")
format qdate %tq
drop time 

rename qdate yq 

merge 1:1 yq using "/Users/lc/Dropbox/Distributional_Dynamics/7_Results/coibion_replication/replication_folder/my_files/external_data_files/rr_shocks_coibion.dta"
drop _merge 

rename qdate quarter 
// save "/Users/lc/Dropbox/Distributional_Dynamics/2_Data_processing/functional_data.dta", replace

* Merge in shocks 
merge m:1 quarter using "/Users/lc/Dropbox/Distributional_Dynamics/1_Data/shocks/all_shocks.dta"
drop _merge

* Merge in aggregates 
merge m:1 quarter using "/Users/lc/Dropbox/Distributional_Dynamics/2_Data_processing/lp_data.dta"
drop _merge

rename quarter time 

// merge m:1 time using "/Users/lc/Dropbox/Distributional_Dynamics/2_Data_processing/aggregates_rawdata.dta"
// drop _merge
merge m:1 time using "$init_path/2_Data_processing/stationary_aggs.dta" 
drop _merge

drop if time < date("1960-01-01", "YMD")  // to keep things slightly neater

xtset grid_point time


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
// gen real_gov_spending = gov_spending * CPI_inf  
// gen real_nfedreceipts = nfedreceipts * CPI_inf
// gen real_gdp_m        = gdp * CPI_inf
// gen consumption       = durable_consumption + nondurable_consumption + services_consumption
// gen investment        = nonresidential_investment + private_investment + residential_investment
// gen gov_spend         = gov_defense + gov_nondefense + gov_state_local
// gen real_consum       = consumption * CPI_inf 
// gen real_invest       = investment * CPI_inf 
// gen real_gov          = gov_spend * CPI_inf 
//
// foreach var in real_consum real_invest real_gov real_gdp_m {
// 	gen l`var'= 100 * ln(`var')  // log real variables 
// }

// replace income = sign(income) * log(abs(income) + 1) 
// replace wealth = sign(wealth) * log(abs(wealth) + 1) 
la var income "Income"
la var wealth "Wealth"

* time trend 
gen t = _n
gen t2 = t^2

replace liquidity_ratio   = liquidity_ratio * 100
replace liq_premium       = liq_premium * 100
// replace real_house_price  = real_house_price * 100

**# Shock treatment 
rename CBI_median CB_information_shocks
rename delphic_forward_guidance FG_shock // could be measurement error
rename EXOGENRRATIO standard_tax_FP
rename ramey_gov_shocks standard_gov_FP  // this should instrument variation in government spending  

la var MP_median "Monetary Policy"  // sd shock 
la var CB_information_shocks "Central Bank Information"  // sd shock  
la var FG_shock "Forward Guidance"  // sd shock 
la var standard_tax_FP "Tax"  // percent of GDP 
la var standard_gov_FP "Government Spending"

rename MP_median MP
rename standard_tax_FP FP
global SHOCKS MP FP // CB_information_shocks FG_shock standard_tax_FP standard_gov_FP  


* Split Copula shares into groups
global half_point = floor($max_grid_point /2 )
global poor_poor
global poor_rich
global rich_poor
global rich_rich

levelsof grid_point, local(uniquevalues)
foreach var of local uniquevalues {
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

merge m:1 time using "$init_path/2_data_processing/hh_data.dta"
