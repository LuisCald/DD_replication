* Append all the panels together
clear 
cd /Users/lc/Dropbox/Distributional_Dynamics/1_Data/SIPP
use 84_panel_revised.dta

foreach year of numlist 85(1)93 96 2001 2004 2008 {
	append using "`year'_panel_revised"
	}

save full_sipp, replace
