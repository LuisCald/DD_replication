**# Cleaning SCF 2019/2022 replicate weights 
forvalues yr = 19(3)22 {
	use /Users/lc/Dropbox/Distributional_Dynamics/1_Data/SCF+/p`yr'_rw1.dta, clear

	* Create new id, Remove implicate number 
	rename yy1 id 

	gen year = "20`yr'"
	gen id_string = string(id)
	drop id

	* Add year to each ID 
	gen id = year + id_string

	* Rename weight columns 
	forvalues i = 1(1)999 {
			rename wt1b`i' wgtI95W95_imp1_`i' 
			
			* Account for multiplicity. This ensures weights sum to total HHs 
			replace wgtI95W95_imp1_`i' = wgtI95W95_imp1_`i' * mm`i'
	}

	drop id_string y1 year mm*

	* Export to CSV 
	export delimited /Users/lc/Dropbox/Distributional_Dynamics/1_Data/SCF+/replicate_weights/replicate_weights_20`yr'.csv, replace
}

**# SCF illiquid share in top 30
*-----------------------------
* 1) Make an "illiquid" measure consistent with your wealth/assets (exclude pensions)
*-----------------------------
gen illiqd_nopen = (house - hdebt) + (oest - oestdebt) ///
                 + vehi + ffabus + life ///
                 + (bnd - savbnd)   // keep this term only if you truly want non-savings bonds in illiquid

* If you prefer bonds treated as financial (recommended for a clean liquid vs illiquid split), use instead:
* gen illiqd_nopen = (house - hdebt) + (oest - oestdebt) + vehi + ffabus + life

*-----------------------------
* 2) Define top 30% by wealth within implicate (SCF has multiple implicates)
*    (If you want one cutoff pooling implicates, see option B below.)
*-----------------------------
* Weighted wealth deciles within impnum (and year, if relevant)
drop if impnum != 1 
keep if year == 2019
xtile wdec = wealth [aw=weight], nq(10)

* Top 30% = deciles 8,9,10
gen top30w = (wdec >= 8) if !missing(wdec)
label define top30 0 "Bottom 70%" 1 "Top 30% wealth"
label values top30w top30

*-----------------------------
* 3) Construct totals and shares
*-----------------------------
gen total_port = liquid + finast + illiqd_nopen
gen sh_liquid  = liquid / total_port
gen sh_illq    = illiqd_nopen / total_port
gen sh_fin     = finast / total_port

* Optional: handle weird denominators / negatives
replace sh_liquid = . if total_port<=0
replace sh_illq   = . if total_port<=0
replace sh_fin    = . if total_port<=0

*-----------------------------
* 4) Weighted summaries: levels and portfolio shares
*-----------------------------
mean liquid finast illiqd_nopen total_port sh_liquid sh_fin sh_illq [aw=weight], over(top30w)

* If you want percentiles (medians etc.)
centile sh_liquid sh_illq sh_fin [aw=weight], centile(10 25 50 75 90) by(top30w)

* Quick check: fraction with "low liquid share" among top 30
gen lowliq = (sh_liquid < 0.05) if !missing(sh_liquid)
mean lowliq [aw=weight] if top30w==1



**# SCF 
cd /Users/lc/Dropbox/Distributional_Dynamics
use 1_Data/SCF+/HSCF_2019.dta, clear

// drop if ageh <25 | ageh > 64 & !missing(ageh)

* Generate illiquid assets 
// original def: house + oest + cerde + pen + life + savbnd - hdebt - oestdebt
gen illiqd  = (house - hdebt) + (oest - oestdebt) + (bnd  - savbnd) ///
+ pen + life + vehi + ffabus 

* Rename for readability, drop irrelevant variables 
rename tinc income 
rename ffanw wealth
rename ffaass assets 
rename ffaequ equity 
rename ffafin finassets // ffaequ, liqcer, bnd, mfun, ofin, life, pen
rename ffanfin non_fin_assets

 
replace finassets = equity + mfun
// ─── DFA balance-sheet components (surfaced for the (Y,W,component) economies) ───
// All collected at the survey date, like wealth (stock variables, NOT growth-adjusted).
// All are semicontinuous (point mass at 0) -> handled via atom_measures downstream.
gen stocks      = equity + mfun // DFA "corporate equities + mutual fund shares"
gen real_estate = house + oest  // DFA "real estate" (owner-occupied + other)
gen business    = ffabus        // DFA "unincorporated business"
gen pension     = pen           // DFA pensions (total; no DB/DC split available)
gen vehicles    = vehi          // DFA "consumer durables" (vehicles only in SCF)
gen liquid = liqcer + savbnd
replace assets = assets - pen // necessary since pensions are not always observed in the PSID
replace wealth = wealth - pen 
// replace finassets = finassets - liqcer - pen - bnd - life // we remove bnd because PSID does not have
// other variables: ccdebt edebt hdebt pdebt tdebt 

replace liquid = liquid - pdebt

rename wgtI95W95 weight
drop year
rename yearmerge year 
drop if missing(weight)
drop id 
rename id_imp5 id 
rename finassets finast
// putexcel set "2_Data_processing/SCF.xlsx", replace
* Correct for inflation 
foreach var in income wealth assets liquid illiqd tdebt pdebt hdebt finast stocks real_estate business pension vehicles {
	replace `var' = `var' * 1.065365025
}

// levelsof year, local(levels) 
// foreach num of local levels {
// 	foreach var in income wealth assets liquid illiqd tdebt pdebt hdebt finast { 
// 	cap summ `var' [aw=wgt] if year == `num', d 
// 	cap replace `var' = . if `var' < r(p1) & year == `num' & !missing(`var')
// 	}
// }

// gen quarter = 4
* Export year, income, wealth and weight
keep id year weight impnum income wealth assets finast liquid illiqd tdebt pdebt hdebt hhequiv stocks real_estate business pension vehicles

append using "/Users/lc/Dropbox/Distributional_Dynamics/1_Data/SCF+/SCF_2022_cleaned.dta"
// 2022 carries the component columns (added in clean_SCF_2022.do). It still lacks
// finast/liquid/assets/illiqd/tdebt/pdebt/hdebt/hhequiv (pre-existing). Output
// renamed nogrowth -> noForbes_nogrowth (Forbes augmentation happens later).

export excel id year weight impnum income wealth assets finast liquid illiqd tdebt pdebt hdebt hhequiv stocks real_estate business pension vehicles using "/Users/lc/Dropbox/Distributional_Dynamics/2_Data_processing/SCF_noForbes_nogrowth.xlsx", firstrow(variables) sheet("data", replace)

la var income "Income"
la var wealth "Wealth"
la var assets "Total assets"
la var liquid "Liquid assets"
la var illiqd "Illiquid assets"
la var undebt "Unsecured Debt"
la var mgdebt "Housing Debt"
la var tdebt "Total Debt"
la var finast "Financial Assets"
la var nlquid "Net Liquid Assets"

* Collapsing data 
foreach var in wealth {
	collapse (mean) `var' (p10) `var'10=`var' (p20) `var'20=`var' (p30) `var'30=`var' (p40) `var'40=`var' (p50) `var'50=`var' (p60) `var'60=`var' (p70) `var'70=`var' (p80) `var'80=`var' (p90) `var'90=`var' (p99) `var'99=`var' [aw=weight], by(year)
	drop if missing(`var')
	mi tsset year 

}


export excel year income wealth assets finassets liquid illiqd nlquid tdebt undebt mgdebt using "/Users/lc/Dropbox/Distributional_Dynamics/2_Data_processing/SCF_totals.xlsx", firstrow(variables) sheet("data", replace)

cd /Users/lc/Dropbox/Distributional_Dynamics/7_Results

eststo clear 
estpost tabstat income wealth assets liquid illiqd tdebt undebt mgdebt, by(year) statistics(mean)
esttab using "dstats_SCF", cells("income(label(`:var lab income')) wealth(label(`:var lab wealth')) assets(label(`:var lab assets')) liquid(label(`:var lab liquid')) illiqd(label(`:var lab illiqd')) undebt(label(`:var lab undebt')) mgdebt(label(`:var lab mgdebt'))") ///
noobs nomtitle nonumber varlabels(`e(labels)') varwidth(20) drop(Total) tex replace
// graph tw (line assets illiqd income liquid tdebt mgdebt undebt wealth year)
graph tw (line tdebt year)

save "/Users/lc/Dropbox/Distributional_Dynamics/2_Data_processing/dstats_SCF.dta", replace


* Assign deciles to each group and generate percentile values 
* Percentile values for income, wealth 
global percentiles 10 20 30 40 50 60 70 80 90 99
	foreach measure in income wealth{
		local size_of_percentile_list : list sizeof global(percentiles)
		
		foreach year of numlist 2016{  // 1950(3)1971 1977 1983 1989(3)2019
			* Assign households to decile group 
			qui xtile `measure'`year'_dec = `measure' if year == `year' [aweight=weight], nq(10)
			* Initialize matrices
			mat `measure'`year'_value = J(`size_of_percentile_list', 1, 1)
			* Percentile values
			_pctile `measure' if year == `year' [aw= weight], percentiles($percentiles) 
			qui ret li
			* Filling matrices 
			forvalues i=1(1)`size_of_percentile_list'{
				mat `measure'`year'_value[`i',1] = r(r`i')  // creates percentile floors
			}
		
// 		putexcel set "2_Data_processing/SCF.xlsx", sheet("`measure'`year'_percentile") mod
//  		putexcel A1 = matrix(`measure'`year'_value)
		
		}
		
		* Equivalized now 
		replace `measure' = `measure' / hhequiv  // uses old OECD eq scale
		foreach year of numlist 1950(3)1971 1977 1983 1989(3)2019{
			qui xtile `measure'`year'_deceq = `measure' if year == `year' [aweight=weight], nq(10)
			* Initialize matrices
			mat `measure'`year'_value = J(`size_of_percentile_list', 1, 1)
			* Percentile values
			_pctile `measure' if year == `year' [aw= weight], percentiles($percentiles) 
			qui ret li
			* Filling matrices 
			forvalues i=1(1)`size_of_percentile_list'{
				mat `measure'`year'_value[`i',1] = r(r`i')
			}
		
//  		putexcel set "2_Data_processing/SCF.xlsx", sheet("`measure'`year'_percentile_eq") mod
//  		putexcel A1 = matrix(`measure'`year'_value)

		}
	}

	* Using cell opmtion in tab
	* bottom coded issue, to check

* Finding the count for each (income, wealth) decile group
foreach year of numlist 1950(3)1971 1977 1983 1989(3)2019 {
	tab income`year'_dec wealth`year'_dec [aweight=weight], matcell(data_matrix) 
	mat proportions = data_matrix / r(N)  // the reason why I don't use cell above is because the proportions cannot be exported. Nonetheless, dividing by r(N) does the trick. 
// 	putexcel set "2_Data_processing/SCF.xlsx", sheet("`year'_count") mod
// 	putexcel A1 = matrix(proportions)
	
	tab income`year'_deceq wealth`year'_deceq [aweight=weight], matcell(data_matrix)
	mat proportions = data_matrix / r(N)
	putexcel set "2_Data_processing/SCF.xlsx", sheet("`year'_count_eq") mod
	putexcel A1 = matrix(proportions)
}


**# PSID
clear
cd /Users/lc/Dropbox/Distributional_Dynamics/1_Data/PSID
// do J325009.do 
// do J325009_formats.do
do J341380.do 
do J341380_formats.do
cd /Users/lc/Dropbox/Distributional_Dynamics
gen id = _n 

* Interview dates 
do /Users/lc/Dropbox/Distributional_Dynamics/5_Code/code/stata/insert_interview_dates.do


* Export Data
// putexcel set "2_Data_processing/PSID.xlsx", replace
drop year 
keep id intdate* income* wealth* consum* consum_nore* assets* finast* illiqd* liquid* undebt* mgdebt* wgt* hhequiv* business* primary_real_estate* other_real_estate*
reshape long income wealth consum consum_nore assets finast illiqd liquid undebt mgdebt wgt hhequiv intdate business primary_real_estate other_real_estate, i(id) j(year)
rename year income_year

gen year = year(dofq(intdate))
gen quarter = quarter(dofq(intdate))

** Comments:
* income: was bottom coded for 1968 til 1993 (collection year) at $1. Top coded before 1979 at 99999, 999999 in 1980, 9999999 in 1981
	* I also will bottom-code, but mostly because there are less than 20 obs per year with income < 0 i.e., PSID not good for financial income perhaps
replace income = 1 if income < 1 & !missing(income)
replace income_year = income_year + 1900 if income_year < 2000 & !missing(income_year)

* Variable cleaning 
replace consum = consum / 4  // for quarterly consumption 
replace consum_nore = consum_nore / 4

replace consum = . if consum == 0
replace consum_nore = . if consum_nore == 0

levelsof year, local(levels)
foreach num of local levels {
	foreach var in consum consum_nore assets finast illiqd liquid undebt mgdebt {
	cap summ `var' [aw=wgt] if year == `num', d
// 	cap replace `var' = . if `var' < r(p1) & year == `num' & !missing(`var')
	cap replace `var' = . if `var' < 0 & year == `num' & !missing(`var') // can't have negative values of these
	}
}

gen tdebt = undebt + mgdebt

* DFA balance-sheet components surfaced to match SCF naming (stock vars; not growth-adjusted).
* stocks = PSID financial assets (equities + mutual funds + investment trusts) ~ SCF equity+mfun.
* real_estate = gross primary + other real estate ~ SCF house+oest. business = farm/business equity ~ SCF ffabus.
* NOTE: PSID has no DB pension wealth (only ira_annuities, DC/IRA) -> `pension` is NOT surfaced for
* PSID to avoid a concept mismatch with the SCF total-pension measure. hdebt/pdebt already exported.
gen stocks = finast
gen real_estate = primary_real_estate + other_real_estate
// `business` already carries through from the reshape.

rename wgt weight

drop if missing(weight)

drop if missing(income) &  missing(wealth) & missing(tdebt) & missing(assets) & missing(illiqd) & missing(liquid) & missing(undebt) & missing(mgdebt) & missing(consum) & missing( consum_nore)

replace liquid = liquid - undebt  // may be a bit inflated since it's missing veh. debt 
rename undebt pdebt 
rename mgdebt hdebt 

* Plan of attack:
// For the PSID, wealth is measured in Q2 basically. 
// I estimate the growth in consumption, in 2019 $, and multiply that with consum 
// I estimate the growth in gdp, in 2019 $, and multiply that with income 

// I then have 2 more observations essentially for each observation. 

replace consum_nore = . if year <2004 // clothing, entertainment only existed after ... can impute, but no

export excel id income_year year quarter weight income wealth consum consum_nore assets finast illiqd liquid tdebt pdebt hdebt hhequiv stocks real_estate business using "/Users/lc/Dropbox/Distributional_Dynamics/2_Data_processing/PSID_nogrowth.xlsx", firstrow(variables) sheet("data", replace)

// export excel id year weight income wealth consum consum_nore assets finast illiqd liquid tdebt pdebt hdebt hhequiv using "/Users/lc/Dropbox/Distributional_Dynamics/2_Data_processing/PSID_nogrowth.xlsx", firstrow(variables) sheet("data",replace)


la var income "Income"
la var wealth "Wealth"
la var assets "Total assets"
la var liquid "Liquid assets"
la var illiqd "Illiquid assets"
la var undebt "Unsecured Debt"
la var mgdebt "Housing Debt"
la var tdebt "Total Debt"
la var consum "Consumption"
la var nlquid "Net Liquid Assets"

* Collapsing data 
foreach var in wealth {
	collapse (mean) `var' (p10) `var'10=`var' (p20) `var'20=`var' (p30) `var'30=`var' (p40) `var'40=`var' (p50) `var'50=`var' (p60) `var'60=`var' (p70) `var'70=`var' (p80) `var'80=`var' (p90) `var'90=`var' (p99) `var'99=`var' [aw=weight], by(year quarter)
	drop if missing(`var')
	gen id = _n
	tsset id 

}




* Exporting totals 
export excel year income wealth consum assets finast liquid illiqd nlquid tdebt undebt mgdebt using "/Users/lc/Dropbox/Distributional_Dynamics/2_Data_processing/PSID_totals.xlsx", firstrow(variables) sheet("data", replace)

cd /Users/lc/Dropbox/Distributional_Dynamics/7_Results

eststo clear 
estpost tabstat income wealth assets liquid illiqd tdebt undebt mgdebt, by(year) statistics(mean)
esttab using "dstats_PSID", cells("income(label(`:var lab income')) wealth(label(`:var lab wealth')) assets(label(`:var lab assets')) liquid(label(`:var lab liquid')) illiqd(label(`:var lab illiqd')) undebt(label(`:var lab undebt')) mgdebt(label(`:var lab mgdebt'))") ///
noobs nomtitle nonumber varlabels(`e(labels)') varwidth(20) drop(Total) tex replace
// graph tw (line assets illiqd income liquid tdebt mgdebt undebt wealth year)
graph tw (line tdebt year)

save "/Users/lc/Dropbox/Distributional_Dynamics/2_Data_processing/dstats_PSID.dta", replace


* Creating percentile data 
global percentiles 10 20 30 40 50 60 70 80 90 99
global wealth_list wealth83 wealth88 wealth93 wealth98 wealth2000 wealth2002 wealth2004 wealth2006 wealth2008 wealth2010 wealth2012 wealth2014 wealth2016 wealth2018

	foreach var in $wealth_list {
		local size_of_percentile_list : list sizeof global(percentiles)	
		local measure = substr("`var'", 1, 6)
		local yr = substr("`var'", 7, .)  // extract year from variable name
		 if `yr' < 2000 {
			local year_digits = 19`yr'
			di "`year_digits' < 2000"
		  }
		  
		 else {
			local year_digits = `yr'
			di "`year_digits' >= 2000"
		  }
		
// 		xtile `measure'`year_digits'_dec = `var' [pweight= wgt`yr'], nq(10)

// 		* Initialize matrices
// 		mat `measure'`year_digits'_value = J(`size_of_percentile_list', 1, 1)

		* Percentile values
		pctile `var' [pweight= wgt`yr'], percentiles($percentiles) 
	}
// 		qui ret li
// 		* Filling matrices 
// 		forvalues i=1(1)`size_of_percentile_list'{
// 			mat `measure'`year_digits'_value[`i',1] = r(r`i')  // creates percentile floors
// 		}
//		
//			
//  		putexcel set "2_Data_processing/PSID.xlsx", sheet("`measure'`year_digits'_percentile") mod
// 		putexcel A1 = matrix(`measure'`year_digits'_value)
//		
//		
// 		* Equivalized
// 		replace `var' = `var' / hhequiv`yr'
// 		xtile `measure'`year_digits'_deceq = `var' [pweight= wgt`yr'], nq(10)
//		
// 		* Initialize matrices
// 		mat `measure'`year_digits'_value = J(`size_of_percentile_list', 1, 1)
// 		* Percentile values
// 		_pctile `var' [pweight= wgt`yr'], percentiles($percentiles) 
// 		qui ret li
// 		* Filling matrices 
// 		forvalues i=1(1)`size_of_percentile_list'{
// 			mat `measure'`year_digits'_value[`i',1] = r(r`i')  // creates percentile floors
// 		}
//			
//  		putexcel set "2_Data_processing/PSID.xlsx", sheet("`measure'`year_digits'_percentile_eq") mod
//  		putexcel A1 = matrix(`measure'`year_digits'_value)
		
	
	
* Finding the count for each (income, wealth) decile group
foreach var in $wealth_list {  // I only use the varlist to extract the years 
	local yr = substr("`var'", 7, .)  // extract year from variable name
		 if `yr' < 2000 {
			local year_digits = 19`yr'
			di "`year_digits' < 2000"
		  }
		  
		 else {
			local year_digits = `yr'
			di "`year_digits' >= 2000"
		  }
		
	svyset [pweight = wgt`yr']
	svy: tabulate income`year_digits'_dec wealth`year_digits'_dec, count
	matrix data_matrix = e(Prop)
	putexcel set "2_Data_processing/PSID.xlsx", sheet("`year_digits'_count") mod
	putexcel A1 = matrix(data_matrix)
	
	svy: tabulate income`year_digits'_deceq wealth`year_digits'_deceq, count 
	matrix data_matrix = e(Prop)	
	putexcel set "2_Data_processing/PSID.xlsx", sheet("`year_digits'_count_eq") mod
	putexcel A1 = matrix(data_matrix)
}
********************************************************************************
**# CEX 
 import delimited "/Users/lc/Dropbox/Distributional_Dynamics/2_Data_processing/CEX_processed.csv", ///
 stringcols(1) clear 
 
 
 * hhequiv 	
qui gen adults = fam_size - perslt18
qui gen adults_contribution = cond(adults == 1, 1, cond(adults > 1, (adults - 1) * .7 + 1, .))
qui gen children_contribution = perslt18 * 0.5
qui gen hhequiv = adults_contribution + children_contribution


* What about timing?
* 1) we merge on NEWID, which corresponds to some interview. We have the interview date 
* and know that expenditures correspond to the 3 months prior 
* 2) For qintrvmo == 1, 4, 7, and 10 we get Q4, Q1, Q2, Q3. For these observations,
* their expenditures completely fall within the quarter period 
* 3) What about qintrvmo == 2 and the others? I compared qintrvmo == 1,2,3 and found identical quarter cycles
* I repeated the same exercise for all quarters and found the same. So, 
* we just move these observations back one period and that's it!

gen qdate = quarterly(ref_date, "YQ")

* Date formatting 
format qdate %tq
rename qdate quarter
gen year = yofd(dofq(quarter))
// drop if year <= 1984 | year == 1988 // in the end, we do not keep many of these households 
// gen interview = substr(newid,length(newid),.)
gen interview = mod(newid, 10)

// destring interview, replace 
destring custom_cuid, replace

* For some years, they re-use the same IDs ... this is how i correct them 
bysort custom_cuid : egen min_year = min(year)
bysort custom_cuid : egen max_year = max(year)
gen diff_year = max_year - year 

replace custom_cuid = custom_cuid + 1234567 if diff_year > 1 & !missing(diff_year)




// bysort custom_cuid : egen int_max = max(interview)
// replace interview = int_max if missing(interview)
drop if year < 1983
replace finlwt21 = round(finlwt21 / 4) // this is only necessary if we want annual estimates, since each quarter the weights sum to the population. 
replace finlwt21 = round(finlwt21)

// gen year = yofd(dofq(date))
gen quarter2 = quarter(dofq(quarter))

** Dealing with income first 
// so, with income, it is collected in the second and fifth interview before 2016 and then, the first and fourth after that 
// so we set to missing the in between periods 
// still some households do not participate in all the interviews, so we essentially take their first interview and the last one   
bysort custom_cuid: egen max_interview = max(interview) 
bysort custom_cuid : egen min_int = min(interview)

* Before and a bit of 2015 
replace fincbtax = . if quarter < tq(2015q1) & (interview == 3 | interview == 4) & min_int == 2 // idea: some HHs have missing income in int = 2 but not int =3, so we keep those 
replace fincbtax = . if quarter < tq(2015q1) & interview == 4 & min_int == 3
replace fincbtax = . if (interview == 3 | interview == 4) & quarter >= tq(2015q1) & quarter <= tq(2015q4) & max_interview == 5 // idea: if they had a 5th interview, then the rest is empty. 

replace fincbtax = . if (interview == 2 | interview == 3) & quarter >= tq(2015q1) & quarter <= tq(2015q4) & max_interview == 4 // idea: if they had a 5th interview, then the rest is empty.
replace fincbtax = . if (interview == 2 | interview == 3) & quarter >= tq(2016q1) 


// do not drop if weight is missing 

* From  David M. Cutler and Lawrence F. Katz: In the second step, we subtracted spending on new and used vehicles from expenditures and added the imputed rental value of existing vehi- cles in its place. To find the imputed rental value, we took consumer units that reported spending on new and used vehicles and regressed the amount of that spending on total expenditures (less vehicle expendi- tures), expenditures squared, income before taxes, the age of the refer- ence person, dummy variables for the sex and education of the reference person, and the size of the consumer unit. We estimated this equation for each year and predicted the value of new spending for each consumer unit. The imputed vehicle consumption is then the predicted value of new car spending times the number of vehicles the consumer unit reported owning times an assumed depreciation factor (one-eighth of pur- chase value). 

* Some cleaning 
// outside 1984-1989 // food rent utilities health pubtrans eduexp childcare house_rental_eq // gas_repairs   
// within 1984-1989  //  fdawaycq fdhomecq rntxrpcq rntxrpcq_1 utilcq healthcq  pubtracq educacq bbydaycq renteqvx // gasmocq mainrpcq mainrpcq_1 vehinscq

// check for missings! See that they are not generated because of other missings. 
// check for size of the measures! Some are reported for one month, others for 1 quarter

// drop if source2 == "right_only"
// drop if food == 0

replace fdawaycq  = 0 if missing(fdawaycq)
replace rntxrpcq_1  = 0 if missing(rntxrpcq_1)

replace utilcq = 0 if missing(utilcq)
replace pubtracq = 0 if missing(pubtracq)
replace educacq = 0 if missing(educacq)

replace food      = fdawaycq + fdhomecq if missing(food) & year >= 1984 & year <=1989 
replace rent      = rntxrpcq + rntxrpcq_1  if missing(rent) & year >= 1984 & year <=1989 
replace utilities = utilcq  if missing(utilities) & year >= 1984 & year <=1989 
replace health    = healthcq if  missing(health) & year >= 1984 & year <=1989 
replace pubtrans  = pubtracq if  missing(pubtrans) & year >= 1984 & year <=1989
replace eduexp    = educacq if  missing(eduexp) & year >= 1984 & year <=1989
replace childcare = bbydaycq if  missing(childcare) & year >= 1984 & year <=1989

replace food = . if food == 0
replace food = . if fdhomecq == 0

** We want rental equivalence for a quarter 
* The MTBI is monthly. The ITBI is also monthly. but the CEX ppl suck at math 
* the MTBI numbers, times 12, equals the quarterly number (FMLI) ... 
* so, for rental equivalence, if you multiply the MTBI numbers by 12, you will get the exact 
* amount in RENTEQVX, which asks:
* If someone were to rent your home today, how much do you think it would ///
// rent for monthly, unfurnished and without utilities?

* What should we do?
* First, we create a rental equivalence based on the market value of the home 
replace mv_home = (mv_home / 3) * 12 // mv_home comes from MTBI 
gen house_rental_eq2 = (mv_home) * (.06 / 4)

* We know renteqvx is correct, but needs to be multiplied by 3 
* to get quarter (since the question is about a single month)
replace renteqvx  =  renteqvx * 3

* For 910050, we have to do the following
replace house_rental_eq  = (house_rental_eq  / 3) * 12 * 3  // equivalent to renteqvx on the intensive margin

* Weight correction 
sort custom_cuid quarter
by custom_cuid: replace finlwt21 = finlwt21[_n+1] if !missing(food) & missing(finlwt21) & !missing(finlwt21[_n+1])

// we divide by 3 since this is aggregated at the quarterly. We now multiply it by 12
// to get the proper monthly number and then multiply by 3 to make it quarterly 

* This is to prevent weird rent equivalences, we winsorize bottom 
levelsof quarter, local(levels) 
foreach q of local levels {
	qui summ  house_rental_eq [fw=finlwt21] if house_rental_eq > 0 & quarter == `q', d // has no missings
	qui replace house_rental_eq = . if house_rental_eq <= r(p1) & quarter == `q'
	
	
	qui summ  house_rental_eq2 [fw=finlwt21] if house_rental_eq2 > 0 & quarter == `q', d // has no missings
	qui replace house_rental_eq2 = . if house_rental_eq2 <= r(p1) & quarter == `q'
	
	qui summ  renteqvx [fw=finlwt21] if renteqvx > 0 & quarter == `q', d
	qui replace renteqvx = . if renteqvx <= r(p1) & quarter == `q'
	
	qui summ  simhousx [fw=finlwt21] if simhousx > 0 & quarter == `q', d
	qui replace simhousx = . if simhousx <= r(p1) & quarter == `q'
}

replace renteqvx  = house_rental_eq if missing(renteqvx)
replace renteqvx  = house_rental_eq2 if missing(renteqvx)
replace renteqvx  = simhousx if missing(renteqvx)


* For rental equivalence, we are just missing 1994, 1980 and 1981. How do we get them?
* we drop 1980,1981 -> so what about 1994 
// foreach num of numlist 1984(1)2021{
// 	disp in red `num'
// 	summ house_rental_eq [aw=finlwt21] if year == `num'   
// 	summ house_rental_eq2 [aw=finlwt21] if year == `num'
// 	summ renteqvx [aw=finlwt21] if year == `num'  
// 	summ simhousx  [aw=finlwt21] if year == `num'  
// 	summ rent [aw=finlwt21] if year == `num' & rent >0
// }

replace renteqvx = 0 if missing(renteqvx)

* Vehicle expenses 
egen temp_repairs = rowtotal(gasmocq  mainrpcq mainrpcq_1)
replace gas_repairs = temp_repairs if missing(gas_repairs) & year >= 1984 & year <=1989

// drop fdawaycq fdhomecq rntxrpcq rntxrpcq_1 utilcq healthcq  pubtracq educacq /// 
// bbydaycq house_rental_eq house_rental_eq2 simhousx vehinscq mainrpcq zcartrkn zcartrku gasmocq

egen nore_consumption = rowtotal(food utilities health pubtrans eduexp childcare gas_repairs)
replace nore_consumption = . if missing(food)
replace nore_consumption = . if  nore_consumption <= 0 
replace nore_consumption = . if food == 0


egen consumption = rowtotal(food rent utilities health pubtrans eduexp childcare renteqvx gas_repairs)
replace consumption  = . if missing(food)
replace consumption = . if consumption <= 0 
replace consumption = . if food == 0
replace consumption = . if rent > 0 & renteqvx > 0 & !missing(rent) & !missing(renteqvx)

** What about liquid assets, financial assets, housing debt, personal debt? 

** liquid assets
// savacctx -- for pre 2013
// ckbkactx
// secestx 
// usbndx 
// liquid = (savacctx + ckbkactx + secestx + usbndx) * indicator for pre2013 + ///
// liquid = ["920010", "920020", "920030", "5100"] # from ITBI: savings, checkings, bonds (before 2013), checkings - savings - money market - CDs (2013 -)


** financial assets 
// stockx is stocks, bonds, mutual funds  

** unsecured debt 
// undebt1         = ["6001", "6002"] # from MTBI: debt to creditors (1990-2013)
// this one is interesting. Normally for the MTBI, newid's are asked to report on monthly stuff
// but for these UCCs, they're only asked their debt once
// in this case, there is no need to undo the aggregation

// For ITBI stuff, the same holds. "For the ITBI file, this annual amount would be divided by 12, and separate records would be created for October, November, and December each containing that amount." (pg 92)

// undebt2         = ["5400", "5500", "5600"] # from ITBI: cc debt, student loans, other loans (2013-)
// undebt1 is supposed to be equivalent to fn2 - creditx1_sum
// undebt2 is post 2013 --- supposed to be equivalent to creditx +studntx+ othlonx


** mortgage debt 
// mortgage_sum

** To check now is what needs to be multiplied.

// foreach var in creditx studntx othlonx {
// 		replace `var' = 0 if missing(`var')
// }


** Generating unsecured debt 

* Some issue as mentioned above: for creditx1_sum, it is collected in the second quarter 
* irrespective of which interview that is and then the balance is carried forward  
* but with undebt1, we have the 2nd interview and the 5th interview. [6001, 6002]
* So, the 2nd interview is equal to creditx1_sum, but the 5th interview is not, since
* as I said, creditx1_sum is carried over. We can do the following:
* we evaluate the trend, assuming the household has a 1st and 5th interview and interpolate
* for undebt1

// drop savacctx ckbkactx secestx usbndx liquidx liquid

** For undebt2, for those custom_cuid that have 1 observation, we leave it like that.
* As missing. The others, we set to zero ... 
// To get levels, multiply again by 4, Pg. 61 (2013 doc) 

* The other debt stuff for comparison  
// egen debt_post2012 = rowtotal(creditx studntx othlonx) // from FMLI
//
// replace debt_post2012 = . if missing(creditx) & missing(studntx) & missing(othlonx)
// replace debt_post2012 = . if year <= 2012 // just a check 
// replace undebt2 = debt_post2012 if missing(undebt2) // does not work since the FMLI is 1 month ahead on this

// bysort custom_cuid: egen max_interview = max(interview) // if !missing(undebt2) //& interview == 5 
// bysort custom_cuid: egen max_debt = max(undebt2) //if !missing(undebt2)

//returns 5 if not missing undebt2 
// if max_interview is missing, it means undebt2 was missing => all interviews should get zero 
// if max_interview is not missing, it means undebt2 was not missing => all previous interviews get missing value 

// replace undebt2 = 0 if interview < max_interview & max_debt == 0
// replace undebt2 = . if interview < max_interview & max_interview == 5 ///
// & !missing(max_debt) & max_debt !=0

// drop max_interview
// drop max_debt

// replace undebt1 = creditx1_sum if missing(undebt1) & interview == 2 // creditx1_sum seems to be the flow ...

** Now, we deal with undebt1 
// we multiply by 4 for the macro correction 6001, 6002 (page 92 of 2002 doc)
// bysort custom_cuid: egen debt2 = max(cond(interview == 2, undebt1, .)) if year <= 2012 //if !missing(undebt2)
// bysort custom_cuid: egen debt5 = max(cond(interview == 5, undebt1, .)) if year <= 2012

// replace undebt1 = debt2 + ((debt5 - debt2) / 4 - 1) * (interview - 2) if (missing(undebt1) | undebt1 == 0) & year <= 2012
replace undebt1 = . if quarter >= tq(2013q1) // there are some observations in 2013Q1, but it will mix with other debt vars i think 

replace undebt1 = . if quarter < tq(2013q1) & (interview == 3 | interview == 4)

replace undebt1 = creditx1_sum if missing(undebt1) & interview == 2 & year <= 2012
replace undebt1 = creditx5_sum if missing(undebt1) & interview == 5 & year <= 2012

// replace undebt1 = creditx1_sum if missing(undebt1)  & year == 2013 & quarter2 == 1  // these cause a weird spike
// replace undebt1 = creditx5_sum if missing(undebt1)  & year == 2013 & quarter2 == 1 // these cause a weird spike

replace undebt2 = (undebt2 / 3) * 12 // undo aggregation and multiply by 12
replace undebt2 = . if quarter <= tq(2013q1)

bysort custom_cuid: egen max_debt = max(undebt2) 
replace undebt2 = 0 if interview < max_interview & max_debt == 0
// replace undebt2 = . if interview < max_interview & max_interview == 5 ///
// & !missing(max_debt) & max_debt !=0


// replace undebt1 = . if interview != 2 & interview !=5

gen temp = .
replace  temp = undebt1 if quarter <= tq(2013q1)
replace  temp = undebt2 if quarter > tq(2013q1)

egen undebt = rowtotal(temp veh_debt_sum)

replace undebt = . if missing(undebt1) & missing(veh_debt_sum) & quarter <= tq(2013q1)
replace undebt = . if missing(undebt2) & missing(veh_debt_sum) & quarter > tq(2013q1)
replace undebt = . if quarter == tq(1989q4)

* Sample re-design in 2015: collection from 4 interviews vs. 5
replace undebt = . if quarter < tq(2015q1) & (interview == 3 | interview == 4)
replace undebt = . if (interview == 3 | interview == 4) & quarter >= tq(2015q1) & quarter <= tq(2015q4) & max_interview == 5 // idea: if they had a 5th interview, then the rest is empty. 

replace undebt = . if (interview == 2 | interview == 3) & quarter >= tq(2015q1) & quarter <= tq(2015q4) & max_interview == 4 // idea: if they had a 5th interview, then the rest is empty.
replace undebt = . if (interview == 2 | interview == 3) & quarter >= tq(2016q1) 

// replace undebt = . if missing(undebt1) & missing(undebt2) 
// replace undebt = . if missing(undebt1)  & year <= 2012
// replace undebt = . if missing(undebt1)  & year == 2013 & quarter2==1
//
// replace undebt = . if missing(undebt2)  & year == 2013 & quarter2!=1
// replace undebt = . if missing(undebt2)  & year >2013




* veh_debt_sum has few observations ... causing spike after 2012 ... 


// gen ones = 1
// bysort custom_cuid: egen totu = sum(ones) if !missing(undebt1)
//
// ** Fill undebt1 with creditx1_sum, conditionally 
// bysort custom_cuid: egen max_interview = max(interview) if !missing(undebt1) 
// bysort custom_cuid: egen max_interview2 = max(max_interview)
//
// replace undebt1 = creditx1_sum if missing(undebt1) & interview == 3 & max_interview2 == 2 & creditx1_sum != undebt1[_n - 1]
// replace undebt1 = creditx1_sum if  missing(undebt1) &  interview == 4 & max_interview2 == 2 & creditx1_sum != undebt1[_n - 1]
//
// replace undebt1 = creditx1_sum if missing(undebt1) & interview == 4 & max_interview2 == 5 & creditx1_sum != undebt1[_n - 1]
//
// drop max_interview max_interview2

* mortgage debt

* Add helocs to it 
egen hdebt = rowtotal(mortgage_sum prinamtx_sum totowed_sum)
replace hdebt = . if missing(mortgage_sum) & missing(prinamtx_sum) & missing(totowed_sum)
replace hdebt = . if missing(mortgage_sum) & (prinamtx_sum == 0 | totowed_sum ==0) 

** What about timing of assets? 
* For the timing of assets, they are in reference to the interview month. So, 
* they are actually not supposed to be lagged ... 

** Liquid assets 
* Before 2013, It is multiplied by 4 because only one-fourth of all CUs interviewed in a quarter 
// are asked this question. This is done automatically before 2013.
// and it is then divided by 12 to make it a monthly figure
// explanation: so, to get the annual value, we just aggregate the 3 months in MTBI 

* Who has 0 in liquid assets?
* those that report 0 in the fifth interview 
// bysort custom_cuid: egen max_interview = max(interview) // if !missing(undebt2) //& interview == 5 
// bysort custom_cuid: egen max_liquid = max(liquid) 

// replace liquid = 0 if interview < max_interview & max_liquid == 0 
// drop age_ref sex_ref educ_ref fincbtax perslt18 fam_size renteqvx vehq stockx mainrpcq_1 food rent utilities health pubtrans eduexp childcare mv_home gas_repairs finassets heloc_sum prinamtx_sum mortgage_sum temp_repairs consumption
//
// drop creditx studntx othlonx othastx undebt1 undebt2 creditx5_sum veh_debt_sum creditx1_sum totowed_sum

* 2013Q1 has some old and new observations, hence the weird mean 
* for the year 2012 Q1, drop those that have a value in liquid, but not in the subcomponents 
* Before 2013 
* First, multiply all the observations after 2013q2 by 4
replace liquid = (liquid / 3) * 12 if quarter >= tq(2013q2) & !missing(liquid) // ITBI, page 61 of 2013s user doc. 
replace liquid = . if quarter == tq(2013q1) //this quarter has a mix of observations from an old and new survey design

// bysort custom_cuid: egen max_liquid = max(liquid) 
// //
// bysort custom_cuid interview: replace savacctx = savacctx[_n+1] if interview[_n+1] == 5 & quarter <=  tq(2013q1)
// bysort custom_cuid interview: replace ckbkactx = ckbkactx[_n+1] if interview[_n+1] == 5 & quarter <=  tq(2013q1)
// bysort custom_cuid interview: replace usbndx = usbndx[_n+1] if interview[_n+1] == 5 & quarter <=  tq(2013q1)
//
// egen old_liq = rowtotal( savacctx  ckbkactx  usbndx)
// replace liquid = old_liq if missing(liquid) & max_interview== 5 & interview==4 & quarter <=  tq(2013q1)


// replace liquid = . if !missing(savacctx) &  !missing(ckbkactx) &  !missing(usbndx) & year == 2013 & quarter2 == 1


* Tag observations 
// gen tag = !missing(liquid)
// bysort custom_cuid : egen tagged = max(tag)
//
//
// bysort custom_cuid: egen max_liquid = max(liquid) 
// bysort custom_cuid: egen max_interview = max(interview)
// egen old_liq = rowtotal(savacctx ckbkactx usbndx)
// replace old_liq = . if missing(savacctx) & missing(ckbkactx) & missing(usbndx)

// replace liquid = old_liq ///
// if year == 2013 & quarter2 == 1 & missing(food) & abs(liquid - old_liq) > 1.2*old_liq & !missing(liquid)

// food is from MTBI, so it should be missing from the observations, which are from the FMLI 

* So, we have "SAVACCTX", "CKBKACTX", "USBNDX", which define liquid assets 
* After 2012, we do not have bonds anymore ... 
* We can substract bonds from observations before 2012 
* What do we see? The above variables are in interviw 
// replace liquid = old_liq if missing(liquid) & missing(max_liquid) & interview==4 & max_interview == 5 & year <= 2012


* After 2012
// replace liquid = liquidx if missing(liquid) & missing(max_liquid) & interview==5 & max_interview == 5 & year > 2013
// replace liquid = liquidx if missing(liquid) & missing(max_liquid) & interview==4 & max_interview == 4 & year > 2013
//
// bysort custom_cuid : replace liquidx = liquidx[_n+1] if interview[_n+1] == 5 & !missing(liquidx[_n+1])
// bysort custom_cuid : replace liquidx = liquidx[_n+1] if interview[_n+1] == 4 & max_interview == 4 & !missing(liquidx[_n+1])
//
// replace liquid = liquidx if missing(liquid) & missing(max_liquid) & interview==4 & max_interview == 5 & year > 2013
// replace liquid = liquidx if missing(liquid) & missing(max_liquid) & interview==3 & max_interview == 4 & year > 2013
//


* Something is weird about 2013q1 and 2012

// drop max_liquid
//
// bysort custom_cuid : egen max_old_liq = max(old_liq) if year <= 2012
// bysort custom_cuid : replace max_old_liq = max_old_liq[_n+1] if interview[_n+1] == 5 & !missing(max_old_liq[_n+1]) & year <= 2012
//
// replace liquid = 0 if max_old_liq == 0 & interview == 4 & year <= 2012
* Take those who are zero in the fifth interview and make them 0 in the fourth 


bysort custom_cuid: egen max_finassets = max(finassets) 
//
// replace finassets = 0 if interview < max_interview & max_finassets == 0 
* so 2013q1 appears to be a mix of old and new. do first what's clear
replace finassets = secestx if missing(finassets) & missing(max_finassets) & interview==5 & quarter <= tq(2012q4)
replace finassets = finassets * 4 if quarter >= tq(2013q1) // ITBI, page 61 of 2013s user doc. 

* so in 2013q1, they need to be multiplied by 4 if the observation comes from 5800, but not 920040 = secestx
bysort custom_cuid : replace finassets = secestx if interview==5 & quarter == tq(2013q1) & abs(finassets - secestx) > 1.1*secestx  // idea: obs associated with secestx does not need to be multiplied by 4.

* To deal with top-coding, I run a regression using the non-top coded sample and extrapolating estimates for the observations before 
// glm finassets fincbtax i.age_ref i.sex_ref i.educ_ref i.quarter if quarter >= tq(1996q1), family(gamma) link(log) r
// cap drop log_finassets_imputed
// predict log_finassets_imputed 
// replace log_finassets_imputed = exp(log_finassets_imputed)
//
// forvalues yr=1990(1)1995 {
// 		replace finassets = log_finassets_imputed if year == `yr' & finassets > 100000 & log_finassets_imputed > 100000 & !missing(finassets) & !missing(log_finassets_imputed)
// 		replace finassets = 0 if finassets < 0 & !missing(finassets)
// }

drop qintrvyr qintrvmo age_ref sex_ref educ_ref perslt18 fam_size savacctx /// 
ckbkactx secestx usbndx ref_date vehq mainrpcq_1 ///
creditx studntx othlonx 


* last min things before saving 
rename finlwt21 weight
rename fincbtax income
rename custom_cuid id

// gen year = yofd(dofq(date))


// there are duplicates because HHs that do 2 surveys 
// duplicates drop weight income id, force
// duplicates drop id interview if year == 1995 | year == 1996, force
// save "temp_CEX.dta", replace 
//
//
// duplicates drop id, force 
// keep id
// expand 5
// gen ones = 1
// bysort id: gen interview = sum(ones)
// save "temp_using_CEX.dta", replace 
//
// use "temp_CEX.dta", clear
// merge 1:1 id interview using "temp_using_CEX.dta"


keep weight income consumption nore_consumption liquid finassets undebt hdebt id year quarter interview quarter2 hhequiv wtrep* finlwt*

* Fill the year and the quarter 
// sort id interview
// by id: replace quarter = 4 if missing(quarter) & quarter[_n+1] == 1 // if the one ahead is 1, then = 4
// by id: replace quarter = quarter[_n+1] - 1 if missing(quarter) & quarter[_n+1] != 1
// by id: replace quarter = quarter[_n+1] - 1 if missing(quarter) & quarter[_n+1] != 1
// by id: replace quarter = quarter[_n-1] + 1 if missing(quarter) & quarter[_n-1] != 4
// by id: replace quarter = quarter[_n-1] + 1 if missing(quarter) & quarter[_n-1] != 4
// by id: replace quarter = 1 if missing(quarter) & quarter[_n-1] == 4
// by id: replace quarter = quarter[_n-1] + 1 if missing(quarter) & quarter[_n-1] != 4
// by id: replace quarter = quarter[_n-1] + 1 if missing(quarter) & quarter[_n-1] != 4
// by id: replace quarter = 4 if missing(quarter) & quarter[_n+1] == 1
// by id: replace quarter = quarter[_n+1] - 1 if missing(quarter) & quarter[_n+1] != 1
// by id: replace quarter = quarter[_n+1] - 1 if missing(quarter) & quarter[_n+1] != 1
// by id: replace quarter = 4 if missing(quarter) & quarter[_n+1] == 1
//
//
// by id: replace year = year[_n+1] - 1 if missing(year) & quarter[_n+1] == 1
// by id: replace year = year[_n+1] if missing(year) & quarter[_n+1] != 1
// by id: replace year = year[_n+1] if missing(year) & quarter[_n+1] != 1
// by id: replace year = year[_n+1] if missing(year) & quarter[_n+1] != 1
// by id: replace year = year[_n+1] - 1 if missing(year) & quarter[_n+1] == 1
//
// by id: replace year = year[_n+1] if missing(year) & quarter[_n+1] != 1
// by id: replace year = year[_n+1] if missing(year) & quarter[_n+1] != 1
//
// by id: replace year = year[_n-1] + 1 if missing(year) & quarter[_n-1] == 4
// by id: replace year = year[_n-1] if missing(year) & quarter[_n-1] != 4
// by id: replace year = year[_n+1] if missing(year) & quarter[_n+1] != 1
//
// by id: replace year = year[_n-1] + 1 if missing(year) & quarter[_n-1] == 4
// by id: replace year = year[_n-1] if missing(year) & quarter[_n-1] != 4
//
//
// * move assets, debt (not mortgage debt) back 1 period
// gen yq = yq(year, quarter)
// format yq %tq
//
// xtset id yq

* Merge in inflation 
rename quarter time
merge m:1 time using /Users/lc/Dropbox/Distributional_Dynamics/2_Data_processing/inflation_data_quarterly.dta 
drop _merge 
rename time quarter

// svmat inflation_matrix, names(vars)
// rename vars1 inf_year 
// rename vars2 CPI
foreach var in income consumption nore_consumption finassets undebt hdebt liquid {
	replace `var' = `var' * inflation
}

replace liquid = liquid - undebt
// 	summ liquid [aw=weight] if year == 2013 & quarter2 == 1, d 
// 	replace liquid = . if year == 2013 & quarter2 == 1 & liquid > r(p99) & !missing(liquid)
// 	replace liquid = . if year == 2013 & quarter2 == 1 & liquid < r(p1) & !missing(liquid)


* Some cleaning since we have some weird observations 
// replace income = . if income == 0
replace weight = round(weight)
replace income = . if income <= 0 & !missing(income)


// foreach var in income {
	* Coibion treatment 
// 	replace `var' = . if `var' < 0
// 	qui summ `var' [fw=weight], d 
// 	replace `var' = r(p1) if `var' <= r(p1) & !missing(`var')
// 	replace `var' = r(p99) if `var' >= r(p99) & !missing(`var')
//	
// 	* My treatment 
// 	levelsof quarter, local(levels)
// 	foreach q of local levels {	
//	
// 		if "`var'" == "income" {
// 			summ income [fw=weight] if quarter == `q', d 
// 			replace income = . if income < r(p1) & quarter == `q'
// 			replace income = . if income > r(p99) & quarter == `q'
// 		}
// 		else {
// 			qui summ `var' [fw=weight] if quarter == `q', d 
// 			replace `var' = . if `var' < r(p1) & quarter == `q'
// 			replace `var' = . if `var' > r(p99) & quarter == `q'
//			
// 		}
//		
// 		qui summ nore_consumption [fw=weight] if quarter == `q', d 
// 		replace nore_consumption = . if nore_consumption < r(p5) & quarter == `q'
// 		replace nore_consumption = . if nore_consumption >= r(p99) & quarter == `q'
//		
// 	}
// 			replace `var' = . if `var' < 0

// }
		
// 	qui summ finassets [fw=weight] if quarter == `q', d 
// 	replace finassets = . if finassets > r(p99) & !missing(finassets) & quarter == `q'
	
// 	qui summ liquid [fw=weight] if quarter == `q', d 
// 	replace liquid = . if liquid > r(p95) & !missing(liquid) & quarter == `q'
// 	replace liquid = . if liquid < r(p5) & !missing(liquid) & quarter == `q'
	
// 	summ undebt [fw=weight] if quarter2 == `q', d 
// 	replace undebt = . if undebt > r(p99) & !missing(undebt) & quarter2 == `q'

// }

* Surpressing the effects of the boom in the CEX from 2004q2 to 2006q1
// summ income [fw=weight] if quarter >= tq(2004q2) & quarter <= tq(2006q1), d 
// replace income = . if quarter >= tq(2004q2) & quarter <= tq(2005q4) // I remove because these values are imputed 


replace finassets = . if year == 1989 & quarter2 == 4
replace liquid = . if year == 1989 & quarter2 == 4
replace liquid = . if year <= 1993 // seems to be a structural break in the data
// drop interview inf_year CPI
rename undebt pdebt 
rename finassets finast
rename consumption consum
drop if missing(income) & missing(consum)& missing(finast)& missing(pdebt)& missing(hdebt)& missing(liquid)
// drop if missing(weight)
duplicates drop
// gen quarter2 = quarter(dofq(quarter))
drop quarter
rename quarter2 quarter


drop if year == 2022
drop if missing(weight)
// replace quarter = 4 // now all observations are in the same period per year 


export delimited id year quarter weight income consum nore_consumption finast liquid pdebt hdebt hhequiv using "/Users/lc/Dropbox/Distributional_Dynamics/2_Data_processing/CEX.csv", replace


* Rename the weight variables and create a separate file for each year 
gen finlwt21 = weight
forvalues i=1(1)9 {
	replace finlwt0`i' = wtrep0`i' if missing(finlwt0`i')
}

forvalues i=10(1)44 {
	replace finlwt`i' = wtrep`i' if missing(finlwt`i')
}

forvalues i=1(1)9 {
 rename finlwt0`i' finlwt`i' 
}

drop wtrep* 
drop weight
* Save the ID and the weights, export them to Julia
keep id year quarter finlwt* 
export delimited using "/Users/lc/Dropbox/Distributional_Dynamics/1_Data/CEX/replicate_weights/CEX_replicate_weights.csv", replace


* Checking some stuff 
import delimited "/Users/lc/Dropbox/Distributional_Dynamics/2_Data_processing/CEX_all.csv", clear
foreach var in liquid {
	collapse (mean) `var' (p10) `var'10=`var' (p20) `var'20=`var' (p30) `var'30=`var' (p40) `var'40=`var' (p50) `var'50=`var' (p60) `var'60=`var' (p70) `var'70=`var' (p80) `var'80=`var' (p90) `var'90=`var' (p95) `var'95=`var' [aw=weight], by(year quarter)
	drop if missing(`var')
	gen id = _n 
	tsset id 
}


la var income "Income"
la var consum "Consumption"
la var liquid "Liquid assets"
la var pdebt "Unsecured Debt"
la var hdebt "Housing Debt"
la var finast "Financial Assets"

* Collapsing data 
collapse (mean) income consum liquid finast pdebt hdebt [fw=weight], by(year quarter)
gen id = _n
tsset id 
tsline income
tsline consum
tsline liquid 
tsline finast 
 

export excel year income consumption finast liquid undebt mgdebt using "/Users/lc/Dropbox/Distributional_Dynamics/2_Data_processing/CEX_totals.xlsx", firstrow(variables) sheet("data",replace)


* Run year by year regressions of rental value 
// foreach i of numlist 1980(1)2021 {
// 	disp in red "`i'"
// 	reg tot_prices_of_veh consumption consumption_sq i.sex i.edu income i.fam_size /// 
// 	ageh [aw=finlwt21] if tot_prices_of_veh > 0 & !missing(tot_prices_of_veh) & year == `i', r
// 	predict tot_prices_of_vehhat if e(sample) 
// 	replace tot_prices_of_vehhat = 0 if tot_prices_of_vehhat < 0 & !missing(tot_prices_of_vehhat)
// }

* Add this to whoever had a vehicle, multiply by depreciation factor and add additional costs to it
// egen veh_exp = rowtotal(parking parking_home parking_out vehicleinsurance vehiclerepairs gas) 
// replace consumption = consumption + veh_exp
//
// * Quick check on making sure those with mortgages have a rental equivalence 
// replace consumption = . if house_renteq > 0 & rent > 0 & !missing(house_renteq) & !missing(rent)

 


********************************************************************************
**# ACS 
cd /Users/lc/Dropbox/Distributional_Dynamics/1_Data/ACS
use "usa_00009.dta", clear

drop if hhincome == 9999999

* Generate Equivalized scale
// bysort year serial: gen children_ind = (age < 18) & !missing(age)
// bysort year serial: egen children = sum(children_ind)
// qui gen adults = famsize - children
// qui gen adults_contribution = cond(adults == 1, 1, cond(adults > 1, (adults - 1) * .7 + 1, .))
// qui gen children_contribution = children * 0.5
// qui gen hhequiv = adults_contribution + children_contribution

mat input inflation_matrix = ( ///
1951,	8.615560641\ ///
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
2019,	1)

svmat inflation_matrix, names(vars)
rename vars1 matrix_year 
rename vars2 CPI

* Put in 2019 dollars 
foreach year of numlist 2000(1)2019{ 
  qui summ CPI if matrix_year == `year' // matrix_year is the year column created from the matrix of containing CPI data 
  qui replace hhincome = hhincome * r(mean) if year == `year'
}

collapse (mean) hhincome hhwt, by(year serial)
rename hhincome income 
rename hhwt weight
rename serial id
drop if missing(income)

* Create plots of the top10, next40 and bottom50 
// Sort the dataset by year and income within each year
sort year income

// Create the cumulative weight 
by year: gen cum_weight = sum(weight)
by year: egen tot_weight = total(weight)
by year: replace cum_weight = cum_weight / tot_weight

gen ii = 1

// Create the cutoffs 
gen income_groups = .
forvalues i = 1(1)10 {
	local k = `i' - 1
	if `i' == 1 {
		replace income_groups = `i' if cum_weight <= .`i'0
	}
	else if `i' == 10 {
		replace income_groups = `i' if cum_weight > .`k'0
	}
	else {
		replace income_groups = `i' if cum_weight <= .`i'0 & cum_weight > .`k'0
	}
}

// Create new data 
collapse (sum) sum_income=income sum_hh=ii (mean) mean_income=income [aw=weight], by(year income_groups)
  
// convert long to wide 
reshape wide sum_income mean_income sum_hh, i(year) j(income_group)
  
// generate percentiles 
gen top10 = mean_income10
gen next40 = mean_income9
gen bottom50 = mean_income5

gen top20 = (sum_income10 + sum_income9) / (sum_hh9 + sum_hh10)
gen next40q = (sum_income5 + sum_income6 + sum_income7 + sum_income8) / (sum_hh5 + sum_hh6 + sum_hh7 + sum_hh8)
gen bottom40 = (sum_income1 + sum_income2 + sum_income3 + sum_income4) / (sum_hh1 + sum_hh2 + sum_hh3 + sum_hh4)

// create shares 
egen tot_inc = rowtotal(sum_income1 sum_income2 sum_income3 sum_income4 sum_income5 sum_income6 sum_income7 sum_income8 sum_income9  sum_income10)

gen top10shares = sum_income10 / tot_inc
gen next40shares = (sum_income6 + sum_income7 + sum_income8 + sum_income9) / tot_inc
gen bottom50shares = (sum_income1 + sum_income2 + sum_income3 + sum_income4 + sum_income5) / tot_inc

gen top20shares = (sum_income10 + sum_income9) / tot_inc
gen next40shares_q = (sum_income5 + sum_income6 + sum_income7 + sum_income8) / tot_inc
gen bottom40shares = (sum_income1 + sum_income2 + sum_income3 + sum_income4) / tot_inc

drop sum_income1 sum_income2 sum_income3 sum_income4 sum_income5 sum_income6 sum_income7 sum_income8 sum_income9 sum_income10

export delimited year top10 next40 bottom50 top20 next40q bottom40 using "/Users/lc/Dropbox/Distributional_Dynamics/2_Data_processing/validation/ACS/income_quantiles_ACS.csv", replace

drop  top10 next40 bottom50 top20 next40q bottom40
rename top10shares top10
rename next40shares next40  
rename bottom50shares bottom50 
rename top20shares top20
rename next40shares_q next40q
rename bottom40shares bottom40 


export delimited year top10 next40 bottom50 top20 next40q bottom40 using "/Users/lc/Dropbox/Distributional_Dynamics/2_Data_processing/validation/ACS/income_shares_ACS.csv", replace


* Construct Excel files of income, wealth values/percentiles 
global percentiles 10 20 30 40 50 60 70 80 90
forvalues w=0/1 {
global equivalize_income = `w'
	foreach measure in hhincome {
		if $equivalize_income == 0 {
			di "No equivalization"
		}
		else {
			replace `measure' = `measure' / hhequiv  // uses old OECD eq scale 
		}
		
		foreach year of numlist 2000(1)2019{
		local size_of_percentile_list : list sizeof global(percentiles)
		* Initialize matrices
		mat `measure'`year'_value = J(`size_of_percentile_list', 1, 1)
		mat `measure'`year'_share = J(`size_of_percentile_list', 1, 1)
		* Percentile values
		_pctile `measure' if year == `year' [aw= hhwt ], percentiles($percentiles) 
		qui ret li
		* Filling matrices 
		forvalues i=1(1)`size_of_percentile_list'{
		mat `measure'`year'_value[`i',1] = r(r`i')
		}
		* Percentile shares (in decimal)
		qui sumdist `measure' if year == `year' [aw= hhwt ]
		forvalues i=1(1)`size_of_percentile_list'{
		mat `measure'`year'_share[`i',1] = r(sh`i')
		}

		svmat `measure'`year'_value, names(`measure'`year'_value)
		svmat `measure'`year'_share, names(`measure'`year'_share)
		rename `measure'`year'_value1 `measure'`year'_value
		rename `measure'`year'_share1 `measure'`year'_share
		qui replace `measure'`year'_share = `measure'`year'_share * 100 // to have in percent  
		}
	* Make Excel sheet
	preserve
	drop if missing(`measure'2000_value)  // any year will do 
	order *_value *_share

		if $equivalize_income == 0 {
			export excel `measure'2000_value-`measure'2019_value using "2_Data_processing\ACS.xlsx", firstrow(variables) sheet("`measure'_per")  
			export excel `measure'2000_share-`measure'2019_share using "2_Data_processing\ACS.xlsx", firstrow(variables) sheet("`measure'_share")
		}
		
		else {
			export excel `measure'2000_value-`measure'2019_value using "2_Data_processing\ACS.xlsx", firstrow(variables) sheet("`measure'_per_eq") 
			export excel `measure'2000_share-`measure'2019_share using "2_Data_processing\ACS.xlsx", firstrow(variables) sheet("`measure'_share_eq") 

		}
		
	restore 
	drop *_value *_share 
	}
}


**# CPS as external source
cd /Users/lc/Dropbox/Distributional_Dynamics/1_Data/CPS
use "cps_00005.dta", clear

drop if age < 15
qui replace hhincome = . if hhincome == -9999997
qui replace hhincome = . if hhincome == 99999999

replace year = year - 1  // https://www.census.gov/content/dam/Census/library/working-papers/2007/acs/2007_Webster_01.pdf (Crtl + F time frame)
drop if asecwth < 0 

mat input inflation_matrix = ( ///
1951,	8.615560641\ ///
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
rename vars1 matrix_year 
rename vars2 CPI

* Generate Equivalized scale 
// bysort year serial: gen children_ind = (age < 18) & !missing(age)
// bysort year serial: egen children = sum(children_ind)
// qui gen adults = famsize - children  // famsize varies at the HH level
// qui gen adults_contribution = cond(adults == 1, 1, cond(adults > 1, (adults - 1) * .7 + 1, .))
// qui gen children_contribution = children * 0.5
// qui gen hhequiv = adults_contribution + children_contribution

* set to missing the flagged values

* Put in 2019 dollars 
* income only exists for these periods 
foreach year of numlist 1967(1)2020{ 
  qui summ CPI if matrix_year == `year' // matrix_year is the year column created from the matrix of containing CPI data 
  qui replace hhincome = hhincome * r(mean) if year == `year'
}

collapse (mean) hhincome asecwth, by(serial year)
rename hhincome income 
rename asecwth weight
rename serial id
drop if missing(income)

* Create plots of the top10, next40 and bottom50 
// Sort the dataset by year and income within each year
sort year income

// Create the cumulative weight 
by year: gen cum_weight = sum(weight)
by year: egen tot_weight = total(weight)
by year: replace cum_weight = cum_weight / tot_weight

gen ii = 1
// Create the cutoffs 
gen income_groups = .
forvalues i = 1(1)10 {
	local k = `i' - 1
	if `i' == 1 {
		replace income_groups = `i' if cum_weight <= .`i'0
	}
	else if `i' == 10 {
		replace income_groups = `i' if cum_weight > .`k'0
	}
	else {
		replace income_groups = `i' if cum_weight <= .`i'0 & cum_weight > .`k'0
	}
}

// Create new data 
collapse (sum) sum_income=income sum_hh=ii (mean) mean_income=income [aw=weight], by(year income_groups)
  
// convert long to wide 
reshape wide sum_income mean_income sum_hh, i(year) j(income_group)
  
// generate percentiles 
gen top10 = mean_income10
gen next40 = mean_income9
gen bottom50 = mean_income5
gen top20 = (sum_income10 + sum_income9) / (sum_hh9 + sum_hh10)
gen next40q = (sum_income5 + sum_income6 + sum_income7 + sum_income8) / (sum_hh5 + sum_hh6 + sum_hh7 + sum_hh8)
gen bottom40 = (sum_income1 + sum_income2 + sum_income3 + sum_income4) / (sum_hh1 + sum_hh2 + sum_hh3 + sum_hh4)

// create shares 
egen tot_inc = rowtotal(sum_income1 sum_income2 sum_income3 sum_income4 sum_income5 sum_income6 sum_income7 sum_income8 sum_income9  sum_income10)

gen top10shares = sum_income10 / tot_inc
gen next40shares = (sum_income6 + sum_income7 + sum_income8 + sum_income9) / tot_inc
gen bottom50shares = (sum_income1 + sum_income2 + sum_income3 + sum_income4 + sum_income5) / tot_inc

gen top20shares = (sum_income10 + sum_income9) / tot_inc
gen next40shares_q = (sum_income5 + sum_income6 + sum_income7 + sum_income8) / tot_inc
gen bottom40shares = (sum_income1 + sum_income2 + sum_income3 + sum_income4) / tot_inc

drop sum_income1 sum_income2 sum_income3 sum_income4 sum_income5 sum_income6 sum_income7 sum_income8 sum_income9 sum_income10

export delimited year top10 next40 bottom50 top20 next40q bottom40 using "/Users/lc/Dropbox/Distributional_Dynamics/2_Data_processing/validation/CPS/income_quantiles_CPS.csv", replace

drop  top10 next40 bottom50 top20 next40q bottom40
rename top10shares top10
rename next40shares next40  
rename bottom50shares bottom50 
rename top20shares top20
rename next40shares_q next40q
rename bottom40shares bottom40 


export delimited year top10 next40 bottom50 top20 next40q bottom40 using "/Users/lc/Dropbox/Distributional_Dynamics/2_Data_processing/validation/CPS/income_shares_CPS.csv", replace

**# CPS top-codes 
use "/Users/lc/Downloads/topcodes-2.dta", clear

egen income = rowtotal(incdrt incgov incaloth incdivid incrent incalim incchild ///
incunemp incwkcom incvet increti1 increti2 incsurv1 incsurv2 incdisa1 incdisa2 ///
inceduc incasist incother incss incwelfr incretir incssi incint oincwage oincbus ///
oincfarm incwage incbus incfarm)

collapse (sum) income, by(year serial)

save "/Users/lc/Downloads/topcodes_collapsed.dta", replace

**# CPS as a data source 
cd /Users/lc/Dropbox/Distributional_Dynamics/1_Data/CPS
use "cps_00005.dta", clear

drop if age < 15
qui replace hhincome = . if hhincome == -9999997
qui replace hhincome = . if hhincome == 99999999

// merge 1:1 year serial pernum using "/Users/lc/Downloads/swapvalues.dta"
// drop _merge 

merge m:1 year serial using "/Users/lc/Downloads/topcodes_collapsed.dta"
drop _merge 

drop if asecwth < 0 
drop if missing(asecwth)

duplicates drop year serial, force 

replace year = year - 1  // https://www.census.gov/content/dam/Census/library/working-papers/2007/acs/2007_Webster_01.pdf (Crtl + F time frame)

mat input inflation_matrix = ( ///
1951,	8.615560641\ ///
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
2021, 0.943609023\ ///
2022, 0.83)

svmat inflation_matrix, names(inf_vars)
rename inf_vars1 matrix_year 
rename inf_vars2 CPI

* Generate Equivalized scale 
// bysort year serial: gen children_ind = (age < 18) & !missing(age)
// bysort year serial: egen children = sum(children_ind)
// qui gen adults = famsize - children  // famsize varies at the HH level
// qui gen adults_contribution = cond(adults == 1, 1, cond(adults > 1, (adults - 1) * .7 + 1, .))
// qui gen children_contribution = children * 0.5
// qui gen hhequiv = adults_contribution + children_contribution

* set to missing the flagged values

* Put in 2019 dollars 
* income only exists for these periods
replace hhincome = income if !missing(income ) & income != 0

foreach year of numlist 1967(1)2022{ 
  qui summ CPI if matrix_year == `year' // matrix_year is the year column created from the matrix of containing CPI data 
  qui replace hhincome = hhincome * r(mean) if year == `year'
//   qui replace testv = testv * r(mean) if year == `year'
}

drop income 
rename hhincome income 
rename asecwth weight
rename serial id
drop if missing(income)
replace weight = round(weight)

gen quarter = 4
drop if region == 97 // state not identified

* Create 4 Strata from the 9 regions 
gen strata = .
replace strata = 4 if region == 42 | region == 41
replace strata = 3 if region == 33 | region == 32 | region == 31
replace strata = 2 if region == 22 | region == 21
replace strata = 1 if region == 12 | region == 11


preserve 
drop if year >= 1993

export delimited id year quarter weight income strata using "/Users/lc/Dropbox/Distributional_Dynamics/2_Data_processing/CPS2.csv", replace
restore 

drop if year < 1993
export delimited id year quarter weight income strata using "/Users/lc/Dropbox/Distributional_Dynamics/2_Data_processing/CPS.csv", replace

foreach var in income {
	collapse (mean) `var' (p10) `var'10=`var' (p20) `var'20=`var' (p30) `var'30=`var' (p40) `var'40=`var' (p50) `var'50=`var' (p60) `var'60=`var' (p70) `var'70=`var' (p80) `var'80=`var' (p90) `var'90=`var' (p99) `var'99=`var' [pw=weight], by(year) // iweight for negative probabilities
	drop if missing(`var')
	tsset year 
}

mat input internal_matrix = ( ///
1967, 0\ ///
1968, 0\ ///
1969, 0\ ///
1970, 0\ ///
1971, 0\ ///
1972, 0\ ///
1973, 0\ ///
1974, 0\ ///
1975, 0\ ///
1976, 15696\ /// 
1977, 17044\ /// 
1978, 18392\ /// 
1979, 20251\ /// 
1980, 22457\ /// 
1981, 24012\ /// 
1982, 25778\ /// 
1983, 27331\ /// 
1984, 28682\ /// 
1985, 30725\ /// 
1986, 32610\ /// 
1987, 34609\ /// 
1988, 36636\ /// 
1989, 38255\ /// 
1990, 41078\ /// 
1991, 42016\ /// 
1992, 42503\ /// 
1993, 43815\ /// 
1994, 46716\ /// 
1995, 48802\ /// 
1996, 50704\ /// 
1997, 52960\ /// 
1998, 56006\ /// 
1999, 58564\ /// 
2000, 61895\ /// 
2001, 65064\ /// 
2002, 66167\ /// 
2003, 66218\ /// 
2004, 67597\ /// 
2005, 69052)
svmat internal_matrix, names(vars)
gen internal_income = vars2[_n+1]
la var internal_income "From internal data"
la var income "From public use"




**# Correcting WID data for inflation 
import delimited "/Users/lc/Dropbox/Distributional_Dynamics/2_Data_processing/validation/WID/income_quantiles_WID.csv", stringcols(1) clear 

gen ydate2 = yearly(year, "Y")

* Everything is in 2021 dollars
foreach var in bottom40 bottom50 next40 next40q top10 top20 {
	qui replace `var' = 0.943609023 * `var' if !missing(`var') 
}


keep year bottom40 bottom50 next40 next40q top10 top20
export delimited using "/Users/lc/Dropbox/Distributional_Dynamics/2_Data_processing/validation/WID/income_quantiles_WID_test.csv", replace

* Now for wealth 
import delimited "/Users/lc/Dropbox/Distributional_Dynamics/2_Data_processing/validation/WID/wealth_quantiles_WID.csv", stringcols(1) clear 

gen ydate2 = yearly(year, "Y")

* Everything is in 2021 dollars
foreach var in bottom50 next40 top10 {
	qui replace `var' = 0.943609023 * `var' if !missing(`var') 
}


keep year bottom50 next40 top10
export delimited using "/Users/lc/Dropbox/Distributional_Dynamics/2_Data_processing/validation/WID/wealth_quantiles_WID.csv", replace


**# Correcting some FRED data for inflation 
import delimited "/Users/lc/Downloads/B701RC1Q027SBEA.csv", stringcols(1) clear 
gen date2 = date(date, "YMD", 2020)
gen qdate = qofd(date2)
format qdate %tq
gen id = _n
drop if id < 17
drop if id > 292

gen year = year(date2)
gen quarter = quarter(date2)

mat input inflation_matrix = ( ///
1951,	8.615560641\ ///
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
2019,	1)

svmat inflation_matrix, names(vars)
rename vars1 matrix_year 
rename vars2 CPI

foreach four_digit_year of numlist 1947(1)2019 {
		qui summ CPI if matrix_year == `four_digit_year' 
		qui replace b701rc1q027sbea = r(mean) * b701rc1q027sbea if !missing(b701rc1q027sbea) & year == `four_digit_year' 
}
* Multiply by 9 zeros to get billion 
rename b701rc1q027sbea hh_gdp 
replace hh_gdp = hh_gdp * 1000000000

drop CPI id matrix_year qdate date2 id quarter year
export delimited using "/Users/lc/Dropbox/Distributional_Dynamics/2_Data_processing/HH_GDP.csv", replace

**# Importing replicate weights, export to CSV for Julia 
global rep_weight_path "/Users/lc/Dropbox/Distributional_Dynamics/1_Data/SCF+/replicate_weights"
foreach year of numlist 1950(3)1971 1977 1983 1989(3)2016{
	* Import the dta 
	use "$rep_weight_path/replicate_weights_`year'.dta", clear 
	drop impnum yearmerge 
	export delimited using "$rep_weight_path/replicate_weights_`year'.csv", replace 
}
