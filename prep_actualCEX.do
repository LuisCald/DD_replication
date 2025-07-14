program define prepare_micro_data 
	args data_name
    * Check for required global variable
    if ("$measures" == "") {
        display "You must define the global variable 'measures' before running this program."
        exit 198
    }
	**# Prep micro data 
	global max_grid_point 10

	* Import most current Pearson and save to .dta
	// import delimited "$data_path/consensus_pearson_A non-diag_.csv", stringcols(1) clear 
	//
	// save "$init_path/2_Data_processing/consensus_pearson.dta", replace

	* Import functional data 
	local data_name "CEX_all_q"
	import delimited "/Users/lc/Dropbox/Distributional_Dynamics/2_Data_processing/`data_name'.csv", clear
	drop pdebt nore_consumption id hhequiv hdebt
	gen time = yq(year, quarter)
	format time %tq 
	set scheme s1color
	graph set window fontface "Times New Roman"
	graph drop _all 
	drop year quarter 
	rename time quarter
	
	* imputing missing income values 
	gen log_income = log(income)
	gen log_consum = log(consum)
	reg log_income log_consum 
	predict log_income_hat
	replace log_income_hat = exp(log_income_hat)
	replace income = log_income_hat if missing(income) & quarter >= tq(2004, 2) & quarter <= tq(2006, 1)


	* Ensure the data is sorted by quarter and income
	bysort quarter: egen income_rank = rank(income), track
	sort quarter income

	* Calculate total number of observations per quarter
	bysort quarter: gen cum_weight = sum(weight) if !missing(income)
	bysort quarter: egen total_weight = sum(weight) if !missing(income)
	bysort quarter: gen rel_weight = cum_weight / total_weight if !missing(income)
	
	gen groups = .
	bysort quarter: replace groups = 1 if rel_weight <= .5 & !missing(income)  // Bottom 50%
	bysort quarter: replace groups = 2 if rel_weight > .5 & rel_weight <= .9 & !missing(income) // Next 40%
	bysort quarter: replace groups = 3 if rel_weight > .9 & !missing(income)      // Top 10%
// 	replace groups = 1 // average does not square with FRED

	collapse (sum) consum [pw=weight], by(quarter groups)

	// save "/Users/lc/Dropbox/Distributional_Dynamics/2_Data_processing/functional_data.dta", replace

	* Merge in shocks 
	rename quarter time 
	merge m:1 time using "/Users/lc/Dropbox/Distributional_Dynamics/2_Data_processing/shock_files/all_shocks.dta"
	drop _merge

	rename time quarter 
	* Merge in aggregates 
	merge m:1 quarter using "/Users/lc/Dropbox/Distributional_Dynamics/2_Data_processing/lp_data.dta", keepusing(eff_ff_rate)
	drop _merge
	
// 	merge m:1 quarter using "/Users/lc/Dropbox/Distributional_Dynamics/2_Data_processing/FRED_QD_stationary.dta"

	merge m:1 quarter using "/Users/lc/Dropbox/Distributional_Dynamics/2_Data_processing/inflation_corrected_correction_series.dta"
	drop _merge
	
	
// 	merge m:1 time using "/Users/lc/Dropbox/Distributional_Dynamics/1_Data/shocks/romer_romer_MP/RR_monetary_shock_quarterly.dta"
// 	drop _merge
	
	rename quarter time 
	merge m:1 time using "/Users/lc/Dropbox/Distributional_Dynamics/2_Data_processing/FRED_QD.dta"
	drop _merge


	global keep_call
	foreach var in $meas_list {
		if "$keep_call" == "" {
			global keep_call $keep_call !missing(`var')				
		}
		else {
			global keep_call $keep_call | !missing(`var')			
		}
	}
	keep if $keep_call
	
// 	rename time yq 
// 	merge m:1 yq using "/Users/lc/Dropbox/Distributional_Dynamics/7_Results/coibion_replication/replication_folder/my_files/external_data_files/rr_shocks_coibion.dta"
// drop _merge 
	
// 	rename yq time 
// 	merge m:1 time using "/Users/lc/Dropbox/Distributional_Dynamics/1_Data/shocks/Aruoba_Drechsel/Aruoba_Drechsel_Data_quarterly.dta"
// 	drop _merge 
	
// 	merge m:1 time using "/Users/lc/Dropbox/Distributional_Dynamics/2_Data_processing/BauerSwanson_MP.dta"
// 	drop _merge

	merge m:1 time using "/Users/lc/Dropbox/Distributional_Dynamics/2_Data_processing/aggregates_rawdata.dta", keepusing(gs1)
	drop _merge
	// merge m:1 time using "$init_path/2_Data_processing/stationary_aggs.dta" 
	// drop _merge

	drop if time < date("1960-01-01", "YMD")  // to keep things slightly neater

// 	xtset grid_point time


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

	// foreach var in $meas_list {
	// 	replace `var' = sign(`var') * log(abs(`var') + 1) * 100	
	// }

	// replace consum = 100 * log(consum)
	 
	cap la var consum "Consumption"
	cap la var income "Income"
	cap la var wealth "Wealth"
	cap la var liquid "Net Liquid Assets"


	// replace liquidity_ratio   = liquidity_ratio * 100
	// replace liq_premium       = liq_premium * 100
	// replace real_house_price  = real_house_price * 100

	**# Shock treatment 
	rename EXOGENRRATIO standard_tax_FP
	rename rameynews standard_gov_FP  // this should instrument variation in government spending  
	
	la var standard_tax_FP "Tax"  // percent of GDP 
	la var standard_gov_FP "Government Spending"


	merge m:1 time using "$init_path/2_data_processing/hh_data.dta"
	drop _merge

// 	gen hh_count = tot_hhs * cop_share / 10
// 	replace hh_count = ceil(hh_count)
// 	replace hh_count = . if missing(cop_share)

end

capture program drop categorize_households
program define categorize_households, rclass
    syntax, IncomeGrid(varname) WealthGrid(varname) SplitParam(real) Measure1(string) Measure2(string)

    * Generate variable names based on specified measures
    local low_measure1 "low_`Measure1'"
    local high_measure1 "high_`Measure1'"
    local low_measure2 "low_`Measure2'"
    local high_measure2 "high_`Measure2'"
    
    * Generate hand-to-mouth households
    gen hand_to_mouth = (`IncomeGrid' <= 4 & `WealthGrid' <= 4 & !missing(`IncomeGrid'))
    
    * Generate categorizations based on income and the second measure (e.g., liquid assets)
    gen `low_measure1' = (`IncomeGrid' < `SplitParam'  & !missing(`IncomeGrid'))
    gen `high_measure1' = (`IncomeGrid' >= `SplitParam' & !missing(`IncomeGrid'))

    gen `low_measure2' = (`WealthGrid' < `SplitParam' & !missing(`WealthGrid'))
    gen `high_measure2' = (`WealthGrid' >= `SplitParam' & !missing(`WealthGrid'))

    gen ll_`Measure1'_`Measure2' = (`IncomeGrid' < `SplitParam' & `WealthGrid' < `SplitParam' & !missing(`IncomeGrid'))
    gen lh_`Measure1'_`Measure2' = (`IncomeGrid' < `SplitParam' & `WealthGrid' >= `SplitParam' & !missing(`IncomeGrid'))
    gen hl_`Measure1'_`Measure2' = (`IncomeGrid' >= `SplitParam' & `WealthGrid' < `SplitParam' & !missing(`IncomeGrid'))
    gen hh_`Measure1'_`Measure2' = (`IncomeGrid' >= `SplitParam' & `WealthGrid' >= `SplitParam' & !missing(`IncomeGrid'))

//     * Apply labels to the generated variables for easy interpretation
//     local vars `low_measure1' `high_measure1' `low_measure2' `high_measure2' ll_`Measure1'_`Measure2' lh_`Measure1'_`Measure2' hl_`Measure1'_`Measure2' hh_`Measure1'_`Measure2'
//     foreach var of local vars {
//         label variable `var' "`var'"
//     }

    * Additional categorizations and labels can be added here following the same pattern
end
