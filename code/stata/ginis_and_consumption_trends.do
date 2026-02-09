**# Generate univariate ginis 
foreach var in income wealth consum {

	if "`var'" == "income" | "`var'" == "wealth" {
		global init_path /Users/lc/Dropbox/Distributional_Dynamics
		cd "$init_path/5_Code"
		global measures consum_and_income_and_wealth
		global meas_list consum income wealth

		* Runs function 
		cap do prep_micro_3D
		program drop prepare_micro_data
		do prep_micro_3D
		prepare_micro_data SCF
		cd "$init_path/7_Results/IRFs"
	}
	
	else {
		global init_path /Users/lc/Dropbox/Distributional_Dynamics
		cd "$init_path/5_Code"
		global measures consum_and_income_and_wealth
		global meas_list consum income wealth

		* Runs function 
		cap do prep_micro_3D
		program drop prepare_micro_data
		do prep_micro_3D
		prepare_micro_data CEX_all
		cd "$init_path/7_Results/IRFs"
	}
	la var income "Gini{subscript: Y}"
	la var consum "Gini{subscript: C}"
	la var wealth "Gini{subscript: W}"
	
	sort time 
	drop if missing(`var')
	drop if cop_share < 0 & !missing(cop_share)
	gen quarter = quarter(dofq(time))
	
	* Assuming each row represents a successive quarter
	summ year
	global min_year = r(min)
	summ quarter if year == $min_year 
	global min_q = r(min)
	gen quarter_time = yq($min_year, $min_q) + _n - 1

	* Format the new variable to display as YearQuarter (e.g., 2000Q1, 2000Q2, ...)
	format quarter_time %tq

	unique time 
	mat `var'_ginis = J(r(unique), 1, 0)
	levelsof time, local(tt)
	local j = 0
	foreach t of local tt {
		qui ineqdec0 `var' [pw=cop_share] if time == `t'
		mat `var'_ginis[`j'+1, 1] = r(gini)
		local j = `j'+1
}
	
	svmat `var'_ginis, names(`var'_ginis)
	
	summ `var'_ginis if !missing(`var'_ginis)
	gen recession_flag = r(min) 
	summ `var'_ginis if !missing(`var'_ginis)
	replace recession_flag = r(max)*1.02 if quarter_time>=tq(1960q2) & quarter_time<=tq(1961q1)  | ///
                   quarter_time>=tq(1969q4) & quarter_time<=tq(1970q4) | ///
                   quarter_time>=tq(1973q4) & quarter_time<=tq(1975q1) | ///
                   quarter_time>=tq(1980q1) & quarter_time<=tq(1980q3)  | ///
                   quarter_time>=tq(1981q3) & quarter_time<=tq(1982q4) | ///
                   quarter_time>=tq(1990q3) & quarter_time<=tq(1991q1)  | ///
                   quarter_time>=tq(2001q1) & quarter_time<=tq(2001q4) | ///
                   quarter_time>=tq(2007q4) & quarter_time<=tq(2009q2) | ///
                   quarter_time>=tq(2020q1) & quarter_time<=tq(2020q2)
// 				   (quarter_time >= tq(2008q1) & quarter_time <= tq(2009q2)) | (quarter_time >= tq(2020q1) & quarter_time <= tq(2020q2))


	summ `var'_ginis if !missing(`var'_ginis)
	local min = r(min)
	tsset quarter_time
	
	loc label: var l `var'
	twoway (area recession_flag quarter_time if !missing(`var'_ginis), base(`min') color(gs12)) (tsline `var'_ginis if !missing(`var'_ginis), lwidth(medthick) lcolor(black) lpattern(dash)),  legend(off) ytitle("`label'", height(5)) xtitle("Quarter", height(5)) xlabel(, grid) ylabel(, grid) graphregion(color(white)) bgcolor(white)

	graph export "`var'_gini.pdf", as(pdf) replace	
	drop recession_flag
	
	* Export data to dta 
	drop if missing(`var'_ginis)
	keep `var'_ginis quarter_time
	rename quarter_time time
	save "/Users/lc/Dropbox/Distributional_Dynamics/2_Data_processing/`var'_univariate_gini.dta", replace
}

**# Multivariate Ginis (https://link.springer.com/content/pdf/10.1007/s10888-022-09533-x.pdf)
import delimited "/Users/lc/Dropbox/Distributional_Dynamics/2_Data_processing/multivariate_gini_results", clear

graph set window fontface "Times New Roman"
graph drop _all 

* clean
gen qdate = quarterly(time, "YQ")
format qdate %tq
drop time 
rename qdate time 

* merge in all the ginis 
merge 1:1 time using /Users/lc/Dropbox/Distributional_Dynamics/2_Data_processing/consum_univariate_gini.dta, keepusing(consum_ginis1)
drop _merge
merge 1:1 time using /Users/lc/Dropbox/Distributional_Dynamics/2_Data_processing/income_univariate_gini.dta, keepusing(income_ginis1)
drop _merge
merge 1:1 time using /Users/lc/Dropbox/Distributional_Dynamics/2_Data_processing/wealth_univariate_gini.dta, keepusing(wealth_ginis1)
drop _merge

* Generate Multivariate ginis if the cov(X,Y) = 0 "counterfactual"
gen wealth_consum_cf = 1/10 * (1 + 3 * wealth_ginis1 + 3 * consum_ginis1 + 3 * consum_ginis1 * wealth_ginis1 )
gen income_consum_cf = 1/10 * (1 + 3 * income_ginis1 + 3 * consum_ginis1 + 3 * consum_ginis1 * income_ginis1 )
gen wealth_income_cf = 1/10 * (1 + 3 * wealth_ginis1 + 3 * income_ginis1 + 3 * income_ginis1 * wealth_ginis1 )

* To save here 
cd /Users/lc/Dropbox/Distributional_Dynamics/7_Results/IRFs/Trends


* Pursuit
cap drop recession_flag
tsset time
summ wealth_consum_cf
local min = r(min)
gen recession_flag = r(min)
global condition if !missing(wealth_consum_cf)

summ wealth_consum_cf 
replace recession_flag = r(max)*1.02 if time>=tq(1960q2) & time<=tq(1961q1)  | ///
                   time>=tq(1969q4) & time<=tq(1970q4) | ///
                   time>=tq(1973q4) & time<=tq(1975q1) | ///
                   time>=tq(1980q1) & time<=tq(1980q3)  | ///
                   time>=tq(1981q3) & time<=tq(1982q4) | ///
                   time>=tq(1990q3) & time<=tq(1991q1)  | ///
                   time>=tq(2001q1) & time<=tq(2001q4) | ///
                   time>=tq(2007q4) & time<=tq(2009q2) | ///
                   time>=tq(2020q1) & time<=tq(2020q2)

twoway (area recession_flag time $condition, base(`min') color(gs12)) (tsline wealth_consum $condition, lwidth(medthick) lcolor(black) lpattern(dash)) (tsline wealth_consum_cf $condition, lwidth(medthick) lcolor(black) lpattern(dot)), legend(off) ytitle("Gini{subscript: (W, C)}",  height(5)) xtitle("Quarter", height(5)) xlabel(, grid) ylabel(, grid) graphregion(color(white)) bgcolor(white)

graph export "MVG_WC.pdf", as(pdf) replace


summ income_wealth
local min = r(min) 
replace recession_flag = r(min)
global condition if !missing( wealth_income_cf)

summ wealth_income_cf
replace recession_flag = r(max)*1.1 if time>=tq(1960q2) & time<=tq(1961q1)  | ///
                   time>=tq(1969q4) & time<=tq(1970q4) | ///
                   time>=tq(1973q4) & time<=tq(1975q1) | ///
                   time>=tq(1980q1) & time<=tq(1980q3)  | ///
                   time>=tq(1981q3) & time<=tq(1982q4) | ///
                   time>=tq(1990q3) & time<=tq(1991q1)  | ///
                   time>=tq(2001q1) & time<=tq(2001q4) | ///
                   time>=tq(2007q4) & time<=tq(2009q2) | ///
                   time>=tq(2020q1) & time<=tq(2020q2)

twoway (area recession_flag time $condition, base(`min'*.99999) color(gs12)) (tsline income_wealth $condition, lwidth(medthick)  lcolor(black) lpattern(dash)) (tsline wealth_income_cf $condition, lwidth(medthick) lcolor(black) lpattern(dot)),  legend(off) ytitle("Gini{subscript: (Y, W)}", height(5)) xtitle("Quarter", height(5)) xlabel(, grid) ylabel(, grid) graphregion(color(white)) bgcolor(white)

graph export "MVG_YW.pdf", as(pdf) replace

summ income_consum_cf
local min = r(min) 
replace recession_flag = r(min)
global condition if !missing(income_consum_cf)
summ income_consum
replace recession_flag = r(max)*1.1 if time>=tq(1960q2) & time<=tq(1961q1)  | ///
                   time>=tq(1969q4) & time<=tq(1970q4) | ///
                   time>=tq(1973q4) & time<=tq(1975q1) | ///
                   time>=tq(1980q1) & time<=tq(1980q3)  | ///
                   time>=tq(1981q3) & time<=tq(1982q4) | ///
                   time>=tq(1990q3) & time<=tq(1991q1)  | ///
                   time>=tq(2001q1) & time<=tq(2001q4) | ///
                   time>=tq(2007q4) & time<=tq(2009q2) | ///
                   time>=tq(2020q1) & time<=tq(2020q2)

twoway (area recession_flag time $condition, base(`min') color(gs12)) (tsline income_consum $condition, lwidth(medthick)  lcolor(black) lpattern(dash)) (tsline income_consum_cf $condition, lwidth(medthick) lcolor(black) lpattern(dot)),  legend(off) ytitle("Gini{subscript: (Y, C)}", height(5)) xtitle("Quarter", height(5)) xlabel(, grid) ylabel(, grid) graphregion(color(white)) bgcolor(white)

graph export "MVG_YC.pdf", as(pdf) replace



**# Consumption plots of different groups  
global init_path /Users/lc/Dropbox/Distributional_Dynamics
cd "$init_path/5_Code"
global measures consum_and_income_and_wealth
global meas_list consum income wealth

* Runs function 
cap do prep_micro_3D
program drop prepare_micro_data
do prep_micro_3D
prepare_micro_data PSID
cd "$init_path/7_Results/IRFs"

global H=8
global rounding .00001
global ysize 10
global xsize 10
global split_param = 6
gen quarter = quarter(dofq(time))
replace cop_share = . if cop_share < 0

drop if time <= tq(1999q1)
// drop if time >= tq(2019q4)

* What are the different households 
gen hand_to_mouth = (incomegrid <= 4 & wealthgrid <= 4 & !missing(incomegrid)) // roughly 23% of the pop. across time
// gen w_hand_to_mouth = (incomegrid <= 3 & wealthgrid >= 6 & wealthgrid <= 10 & !missing(incomegrid)) // roughly 23% of the pop. across time
gen v_hh = (incomegrid >= 9 & wealthgrid >= 9 & !missing(incomegrid))
gen v_ll = (incomegrid <= 2 & wealthgrid <= 2 & !missing(incomegrid))
gen indebted_hhs = (wealth < 0 & !missing(wealth))
gen indebted_wy_hhs = (wealth < 0 & incomegrid >= 6 & !missing(wealth))
gen indebted_ny_hhs = (wealth < 0 & incomegrid < 6 & !missing(wealth))

* Define groups 
gen low_income = (incomegrid < $split_param  & !missing(incomegrid))
gen high_income = (incomegrid >= $split_param & !missing(incomegrid))

gen low_wealth = (wealthgrid < $split_param & !missing(wealthgrid))
gen high_wealth = (wealthgrid >= $split_param & !missing(wealthgrid))

gen ll_il = (incomegrid < $split_param & wealthgrid < $split_param & !missing(incomegrid))
gen lh_il = (incomegrid < $split_param & wealthgrid >= $split_param & !missing(incomegrid))
gen hl_il = (incomegrid >= $split_param & wealthgrid < $split_param & !missing(incomegrid))
gen hh_il = (incomegrid >= $split_param & wealthgrid >= $split_param & !missing(incomegrid))



global var_list low_income high_income low_wealth high_wealth ll_il lh_il hl_il hh_il ///
hand_to_mouth  v_hh v_ll indebted_hhs indebted_wy_hhs indebted_ny_hhs

drop if missing(income)


global y_unit = "%"
local grouplist "low_income high_income low_wealth high_wealth ll_il lh_il hl_il hh_il hand_to_mouth v_hh v_ll indebted_hhs indebted_ny_hhs indebted_wy_hhs"
xtset grid_point time
//
// * Define the list of labels
// local labels "Low income" "High income" "Low wealth" "High wealth" "Low income, low wealth" "Low income, high wealth" "high income, low wealth" "high income, high wealth" "Hand-to-Mouth" "Top 20 in Income and Wealth" "Bottom 20 in Income and Wealth" "Indebted Households" "Indebted Households, ≤ Median Income" "Indebted Households, > Median Income"
//

global SHOCKS jk 

* Treat Covid 
// replace consum = . if time >= tq(2019q4) &  time <= tq(2020q3)

drop if hh_count < 0

cd /Users/lc/Dropbox/Distributional_Dynamics/7_Results/IRFs/Trends

local grouplist "low_income high_income low_wealth high_wealth ll_il lh_il hl_il hh_il hand_to_mouth v_hh v_ll indebted_hhs indebted_ny_hhs indebted_wy_hhs"

local local1 "Consumption{subscript: (Y ≤ Median)}"
local  local2 "Consumption{subscript: (Y > Median)}"
local  local3 "Consumption{subscript: (W ≤ Median)}"
local  local4 "Consumption{subscript: (W > Median)}"
local  local5 "Consumption{subscript: (Y ≤ Median, W ≤ Median)}"
local  local6 "Consumption{subscript: (Y ≤ Median, W > Median)}"
local  local7 "Consumption{subscript: (Y > Median, W ≤ Median)}"
local  local8 "Consumption{subscript: (Y > Median, W > Median)}"

local  local9 "Consumption{subscript: (Y < Median, W < Median)}"
local  local10 "Consumption{subscript: (Y > 80th perc., W > 80th perc.)}"
local  local11 "Consumption{subscript: (Y ≤ 20th perc., W ≤ 20th perc.)}"
local  local12 "Consumption{subscript: (W < 0)}"
local  local13 "Consumption{subscript: (W < 0, Y ≤ Median)}" 
local  local14 "Consumption{subscript: (W < 0, Y > Median)}" 

local i = 0
preserve
foreach group of local grouplist {
    * Collapse the data for the current group and generate the mean of 'consum' weighted by 'hh_count'
    collapse (mean) consum if `group' == 1 [pw=cop_share], by(time)
	
	local i = `i' + 1
	foreach var in consum {
	* Replace the value for the year 2005
	generate `var'2000 = `var' if time == tq(2000q1)
	
	mean `var'2000
	
	* Fill the entire column with the value from 2005
	gen `var'2000_filled = e(b)[1,1]
	
	replace `var' = round(`var' / `var'2000_filled, .01)
	}
	
    * Generate the time series plot for the current group
	summ consum if !missing(consum)
	gen recession_flag = r(min) 

	mean recession_flag
	global y_lb = round(e(b)[1,1], .01)
	
	summ consum if !missing(consum)
	gen recession_ub = r(max) 
	
	mean recession_ub
	global y_ub = round(e(b)[1,1], .01) 

	la var consum "Consumption"
	
	global interval = round(($y_ub - $y_lb) / 5, 0.01)
	
	global y_label_ub = $y_ub + $interval * .8
	
	replace recession_flag = $y_label_ub if (time >= tq(2008q1) & time <= tq(2009q2)) | (time >= tq(2020q1) & time <= tq(2020q2))
	
    twoway (area recession_flag time, base($y_lb) color(gs12)) ///
	(tsline consum, lcolor(green) lpattern(dash) lwidth(medthick)), legend(off) ytitle("Consumption", height(5)) xtitle("Quarter", height(5)) xlabel(, grid) yscale(r($y_lb $y_ub)) ///
	ylabel($y_lb($interval)$y_ub, grid)
	
    * Save the plot as a PDF file
    graph export "`group'_consumption_plot.pdf", as(pdf) replace
    
    * Restore the data before the next iteration
    restore, preserve
}
* Restore the data after the loop ends
restore


local grouplist "income50 income40 income10"
local local1 "Consumption"
local  local2 "Consumption"
local  local3 "Consumption"

gen income50 = (incomegrid <= 5 & !missing(incomegrid))
gen income40 = (incomegrid > 5 & incomegrid <= 9 & !missing(incomegrid))
gen income10 = (incomegrid == 10 & !missing(incomegrid))

local i = 0
preserve
foreach group of local grouplist {
    * Collapse the data for the current group and generate the mean of 'consum' weighted by 'hh_count'
    collapse (mean) consum wealth if `group' == 1 [pw=cop_share], by(time)
	
	local i = `i' + 1
// 	replace consum = consum / 1000
// 	replace wealth = wealth / 1000

	* Create a new variable that contains the consumption value for the year 1999
	foreach var in consum wealth {
		* Replace the value for the year 2005
		generate `var'2000 = `var' if time == tq(2000q1)
		
		mean `var'2000
		
		* Fill the entire column with the value from 2005
		gen `var'2000_filled = e(b)[1,1]
	}
		
	replace consum = round(consum / consum2000_filled, .01) //log(1+consum)
	replace wealth = round(wealth / wealth2000_filled, .01) //log(1+wealth)
	
	
    * Generate the time series plot for the current group
	summ wealth if !missing(wealth)
	gen recession_flag = r(min) 
	summ consum if !missing(consum)
	replace recession_flag = r(min) if recession_flag > r(min)
	mean recession_flag
	global y_lb = round(e(b)[1,1], .01)
	
	summ wealth if !missing(wealth)
	gen recession_ub = r(max) 
	
	summ consum if !missing(consum)
	replace recession_ub = r(max) if recession_ub < r(max)
	mean recession_ub
	global y_ub = round(e(b)[1,1], .01) 
// 	global interval = ceil(($y_ub - $y_lb) / 5)
	
	disp $y_lb

// 	gen recession = r(max) if recession_flag == 1
// 	summ wealth if !missing(wealth)
// 	local min = r(min) 
// 	global y_lb = `min'
	
// 	summ wealth if !missing(wealth)
// 	global y_ub = r(max) * 1.02
// 	global interval = ceil(($y_ub - $y_lb) / 5)
	
// 	global ys_lb = floor($y_lb)
// 	global ys_ub = ceil($y_ub)
	
	la var consum "Consumption"
	la var wealth "Wealth"
	
	global interval = round(($y_ub - $y_lb) / 5, 0.01)
	global y_label_ub = $y_ub + $interval * .8

	replace recession_flag = $y_label_ub if (time >= tq(2008q1) & time <= tq(2009q2)) | (time >= tq(2020q1) & time <= tq(2020q2))
	
    twoway (area recession_flag time, base($y_lb) color(gs12)) ///
       (tsline consum, lcolor(green) lpattern(dash) lwidth(medthick) yaxis(1)) ///
       (tsline wealth, lcolor(blue) lpattern(dash) lwidth(medthick) yaxis(2)), ///
       legend(order(2 "Consumption" 3 "Wealth") position(inside) ring(0)) xlabel(, grid)  xtitle("", height(0)) ///
       ytitle("Consumption", height(5) axis(1)) ///
       ytitle("Wealth", height(5) axis(2)) ///
	  yscale(r($y_lb $y_ub)) ///
	   ylabel($y_lb($interval)$y_ub, grid) ///


//     twoway (area recession_flag time, base($y_lb) color(gs12)) ///
//        (tsline consum, lcolor(green) lpattern(dash) lwidth(medthick)) ///
//        (tsline wealth, lcolor(blue) lpattern(dash) lwidth(medthick)), ///
//        legend(order(2 "Consumption" 3 "Wealth") position(inside) ring(0)) xlabel(, grid)  xtitle("", height(0)) ///
//        ytitle("Relative to 2000", height(5)) ///
//        yscale(r($y_lb $y_ub)) ///
// 	   ylabel($y_lb($interval)$y_ub, grid) ///

	   
//        ylabel(, grid) ///
// 	   ysc(r($y_lb $y_ub))



    * Save the plot as a PDF file
    graph export "`group'_consumption_plot_scaled.pdf", as(pdf) replace
    
    * Restore the data before the next iteration
    restore, preserve
}

**# Same code above, just enough to make Consumption Figure 
**# Consumption plots of different groups  
global init_path /Users/lc/Dropbox/Distributional_Dynamics
cd "$init_path/5_Code"
global measures consum_and_income_and_wealth
global meas_list consum income wealth

* Runs function 
cap do prep_micro_3D
program drop prepare_micro_data
do prep_micro_3D
prepare_micro_data PSID
cd "$init_path/7_Results/IRFs"

global H=8
global rounding .00001
global ysize 10
global xsize 10
global split_param = 6
gen quarter = quarter(dofq(time))
replace cop_share = . if cop_share < 0

drop if time <= tq(1999q1)

* Define groups 
gen ll_il = (incomegrid < $split_param & wealthgrid < $split_param & !missing(incomegrid))
gen lh_il = (incomegrid < $split_param & wealthgrid >= $split_param & !missing(incomegrid))
gen hl_il = (incomegrid >= $split_param & wealthgrid < $split_param & !missing(incomegrid))
gen hh_il = (incomegrid >= $split_param & wealthgrid >= $split_param & !missing(incomegrid))

gen income_groups = . 
replace income_groups = 1 if ll_il == 1
replace income_groups = 2 if lh_il == 1
replace income_groups = 3 if hl_il == 1
replace income_groups = 4 if hh_il == 1

global var_listll_il lh_il hl_il hh_il 

drop if missing(income)


global y_unit = "%"
local grouplist "ll_il lh_il hl_il hh_il"
xtset grid_point time

global SHOCKS jk 

drop if hh_count < 0

cd /Users/lc/Dropbox/Distributional_Dynamics/7_Results/IRFs/Trends

local grouplist "ll_il lh_il hl_il hh_il"

local  local1 "Consumption{subscript: (Y ≤ Median, W ≤ Median)}"
local  local2 "Consumption{subscript: (Y ≤ Median, W > Median)}"
local  local3 "Consumption{subscript: (Y > Median, W ≤ Median)}"
local  local4 "Consumption{subscript: (Y > Median, W > Median)}"


collapse (mean) consum [pw=cop_share], by(time income_groups)
	
* Focus on 5 years before and after recession 
drop if time <= tq(2003q1)
drop if time >= tq(2013q1)

* Make consumption relative to the year before the recession 
replace consum = consum / 1000
xtset income_groups time 
tsfilter hp consum_detrended = consum , smooth(1600)

gen consum_point = .
gen consum_point_dt = .

forvalues i=1(1)4 {
	summ consum if income_groups == `i' & time == tq(2008q3)
	replace consum_point = r(mean) if income_groups == `i'
	
	summ consum_detrended if income_groups == `i' & time == tq(2008q3)
	replace consum_point_dt = r(mean) if income_groups == `i'
}
replace consum = consum / consum_point
replace consum_detrended = consum_detrended / consum_point_dt

summ consum if !missing(consum)
gen recession_flag = r(min) 
summ consum if !missing(consum)
local min = r(min) 
global y_lb = `min'

summ consum if !missing(consum)
global y_ub = r(max) 
global interval = ceil(($y_ub - $y_lb) / 5)

global ys_lb = $y_lb
global ys_ub = $y_ub

replace recession_flag = $ys_ub if (time >= tq(2008q1) & time <= tq(2009q2)) // | (time >= tq(2020q1) & time <= tq(2020q2))
	
    twoway (area recession_flag time if income_groups ==1, base($y_lb) color(gs12)) ///
	(tsline consum if income_groups == 1, lcolor(black) lpattern(solid) lwidth(medthick)) /// 
	(tsline consum if income_groups == 2, lcolor(navy) lpattern(dot) lwidth(medthick)) ///
	(tsline consum if income_groups == 3, lcolor(green) lpattern(dash) lwidth(medthick)) ///
	(tsline consum if income_groups == 4, lcolor(red) lpattern(dash_dot) lwidth(medthick)), ///
	legend(order(2 "Low Income, Low Wealth" 3 "Low Income, High Wealth" 4 "High Income, Low Wealth" 5 "High Income, High Wealth")) xtitle("") xlabel(, grid) ylabel(, grid) scale(1.2) ysize(5) xsize(8) //ylabel($ys_lb($interval)$ys_ub, grid)

    * Save the plot as a PDF file
    graph export "consumption_plot_groups.pdf", as(pdf) replace

* Detrended 
cap drop recession_flag
summ consum_detrended if !missing(consum_detrended)
gen recession_flag = r(min) 
summ consum_detrended if !missing(consum_detrended)
local min = r(min) 
global y_lb = `min'

summ consum if !missing(consum_detrended)
global y_ub = r(max) 
global interval = ceil(($y_ub - $y_lb) / 5)

global ys_lb = $y_lb
global ys_ub = $y_ub

twoway (area recession_flag time if income_groups ==1, base($y_lb) color(gs12)) ///
(tsline consum_detrended if income_groups == 1, lcolor(black) lpattern(solid) lwidth(medthick)) /// 
(tsline consum_detrended if income_groups == 2, lcolor(navy) lpattern(dot) lwidth(medthick)) ///
(tsline consum_detrended if income_groups == 3, lcolor(green) lpattern(dash) lwidth(medthick)) ///
(tsline consum_detrended if income_groups == 4, lcolor(red) lpattern(dash_dot) lwidth(medthick)), ///
legend(order(2 "Low Income, Low Wealth" 3 "Low Income, High Wealth" 4 "High Income, Low Wealth" 5 "High Income, High Wealth")) xtitle("") xlabel(, grid) ylabel(, grid) scale(1.2) ysize(5) xsize(8) //ylabel($ys_lb($interval)$ys_ub, grid)

* Save the plot as a PDF file
graph export "consumption_detrended_plot_groups.pdf", as(pdf) replace


