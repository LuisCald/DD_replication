clear
set more off

global filepath = "/Users/lc/Dropbox/Distributional_Dynamics/5_Code/SIPP/do_files"
cd /Users/lc/Dropbox/Distributional_Dynamics/1_Data/SIPP
		
				* CREATE REVISED PANELS WITH POPULATION OF STUDY *
				* ---------------------------------------------- *
				
								* 1984 *
								* ---- *
forvalues i = 84 85 86 87 88 89 90 91 92 93 96 2001 2004 2008 { 
	use `i'_panel, clear
	 
	rename h_year year
	rename h_month month
	rename panel panel_year
	rename h_wgt weight
	egen hh_id = group(su_id h_add panel_year)
	drop if age < 17

	bysort hh_id year month: gen n_members=_N
	keep if n_members>1 & n_members<10

	gen     quarter=1 if month>=1 & month<=3
	replace quarter=2 if month>=4 & month<=6
	replace quarter=3 if month>=7 & month<=9
	replace quarter=4 if month>=10 & month<=12


	bysort hh_id year quarter: gen check_month = _N

	keep if mod(check_month, 3) == 0

	collapse (mean) hhusdbt hhscdbt hhdebt hhtwlth hhtnw weight (sum) h_totinc, by(hh_id year quarter)
	rename hhusdbt undebt
	rename hhscdbt scdebt
	rename hhdebt totdebt
	rename hhtwlth totwealth
	rename hhtnw wealth
	rename h_totinc income
	
	save /Users/lc/Dropbox/Distributional_Dynamics/2_Data_processing/sipp_revised/`i'_panel_dd_revised, replace
}
