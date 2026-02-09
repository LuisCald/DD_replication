clear
cd /Users/lc/Dropbox/Distributional_Dynamics/1_Data/SIPP

foreach year of numlist 84(1)93 96 2001 2004 2008{
	use `year'_panel, clear

	rename h_year year
	egen hh_id = group(su_id h_add panel)

	* Aggregate to yearly
	bysort hh_id year: egen income = sum(h_totinc)
	bysort hh_id year: egen wealth = sum(hhtwlth)
	bysort hh_id year: gen temp_weight = h_wgt if h_month == 12 & (rrp == 1 | rrp == 2)
	
	bysort hh_id year: gen weight = max(temp_weight)
	save `year'_panel_revised, replace
	
}



figure out weight stuff 
counting number of adults and children using age 
panel year vs year


								


