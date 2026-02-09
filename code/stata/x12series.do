clear all	
cd /Users/lc/Dropbox/Distributional_Dynamics/2_Data_processing
adopath + "/Users/lc/Dropbox/Distributional_Dynamics/2_Data_processing"
// adopath + "/Users/lc/Dropbox/Distributional_Dynamics/2_Data_processing/x12a.exe"
cd C:\Users\Jrxz12\Dropbox\Distributional_Dynamics\2_Data_processing\x12
adopath + "cd C:\Users\Jrxz12\Dropbox\Distributional_Dynamics\2_Data_processing\x12\x12a.exe"
cd C:\Users\Jrxz12\Dropbox\Distributional_Dynamics\2_Data_processing
import delimited "x12_series.csv", stringcols(62) clear
gen qdate = qofd(date(date, "YMD", 2021))
format qdate %tq
tsset qdate, quarterly
gen id = _n
drop if id <=33 

cd /Users/lc/Dropbox/Distributional_Dynamics/2_Data_processing/x12/output
// cd C:\Users\Jrxz12\Dropbox\Distributional_Dynamics\2_Data_processing\x12\output



foreach var in cdcabshno bogz1lm152010005q bogz1lm155111005q bogz1lm154022005q bogz1lm153061105q bogz1lm153062005q bogz1lm153063005q bogz1fl153069005q bogz1lm152090205q cclbshno blneclbshno cpi_inflation avg_duration_unemp avg_weekly_hours corp_bond_premia businesscondition12months businesscondition5years buyingconditions currentindex hnoremv hoorevlmhmv hnola hnocea hnomfsa hnopfaq027s hmlbshno hnoll duliplbshno gov_state_local gov_defense gov_nondefense gdp durable_consumption gs5 gs1 expectedindex tabshno tsdabshno tfaabshno mabshno lirabshno maabshno tlbshno olalbshno tnwbshno mvloas ind_prod sp500 tb3ms shiller_price_index private_investment nonresidential_investment residential_investment nondurable_consumption services_consumption unemployment_rate real_personal_income non_farm_emp sp_div_yield personalfinancecurrent personalfinanceexpected {
	sax12 `var', satype(single) /// 
	transfunc(log) /// 
	ammaxlag(4 2)    /// p, P
	ammaxdiff(2 1)   /// d, D 
	ammaxback(0) ///
	outauto(ao ls tc) /// automatic outlier detection of 
	regaic(td, tdnolpyear, tdstock, td1coef, td1nolpyear, easter) /// 
	x11trend() ///
	x11seas() ///
	x11final(ao ls tc) ///
	x11mode(add) ///
	inpref(`var') ///
	outpref(`var')
	
}
// 	ammaxlead(0) /// 


sax12im gdp, ext(d11) tunit(quarterly)
tsline var var_d11

outsheet using x12_series.csv, comma replace
/*Export to .csv*/

!/Users/lc/Dropbox/Distributional_Dynamics/5_Code/x.py x12_series.csv x12_series-sa.csv
* Use x.py as: x.py infile outfile

insheet using unemp-sa.csv, clear
/*Load in seasonally adjusted data.*/

gen date2 = date(date,"YMD")
format date2 %tdMon-CCYY
drop date
rename date2 date
* Turn the date string from the .csv into a stata date
