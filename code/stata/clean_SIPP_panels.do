clear
set more off

global filepath="/Users/lc/Dropbox/Master_Thesis/5_Code/do_files"
cd /Users/lc/Dropbox/Distributional_Dynamics/1_Data/SIPP


* Some notes: these variables appear in the first, but not the last dataset 
// hhtwlth: total wealth of the household
// hhdebt: unsecured + secured debt 
// hhtnw: hhtwlth - unsecured 
// hhscdbt: secured debt 
// hhusdbt: unsecured debt 

				* CREATE REVISED PANELS WITH POPULATION OF STUDY *
				* ---------------------------------------------- *
				
								* 1984 *
								* ---- *
use 84_panel, clear

*West-Virginia (57) becomes Missisipi. NM, SD (58) become AL,ID,MO,WY (63)
replace state = 28 if state==57
replace state = 62 if state==19
replace state = 63 if state==58
replace state = 61 if state==50
replace state = 63 if state==30
replace state = 61 if state==23


replace caidcov = caidcov==1
rename h_year year
rename h_month month
rename panel panel_year
rename h_wgt weight
egen hh_id = group(su_id h_add panel_year)

*****CREATE CALENDAR MONTH/YEAR*****************************
gen     quarter=1 if month>=1 & month<=3
replace quarter=2 if month>=4 & month<=6
replace quarter=3 if month>=7 & month<=9
replace quarter=4 if month>=10 & month<=12


bysort hh_id year quarter: gen check_month = _N

keep if check_month == 3

*******Aggregate to quarter *******
bysort hh_id year quarter: replace h_totinc  = sum(h_totinc)
keep if month==3 |month==6 | month==9| month==12

gen yq = yq(year, quarter)
format yq %tq
// gen qtr = (year-1984)*4 + quarter

keep h_totinc yq weight hh_id


save 84_panel_revised, replace

								* 1985 *
								* ---- *

use 85_panel, clear
replace caidcov = caidcov==1
rename h_year year
rename h_month month
rename panel panel_year
rename h_wgt weight
egen hh_id = group(su_id h_add panel_year)

*****CREATE CALENDAR MONTH/YEAR*****************************
gen     quarter=1 if month>=1 & month<=3
replace quarter=2 if month>=4 & month<=6
replace quarter=3 if month>=7 & month<=9
replace quarter=4 if month>=10 & month<=12


bysort hh_id year quarter: gen check_month = _N

keep if check_month == 3

*******Aggregate to quarter *******
bysort hh_id year quarter: replace h_totinc  = sum(h_totinc)
keep if month==3 |month==6 | month==9| month==12

gen yq = yq(year, quarter)
format yq %tq
// gen qtr = (year-1984)*4 + quarter

keep h_totinc yq weight hh_id

save 85_panel_revised, replace

								* 1986 *
								* ---- *

use 86_panel, clear
replace caidcov = caidcov==1
rename h_year year
rename h_month month
rename panel panel_year
rename h_wgt weight
egen hh_id = group(su_id h_add panel_year)

*****CREATE CALENDAR MONTH/YEAR*****************************
gen     quarter=1 if month>=1 & month<=3
replace quarter=2 if month>=4 & month<=6
replace quarter=3 if month>=7 & month<=9
replace quarter=4 if month>=10 & month<=12


bysort hh_id year quarter: gen check_month = _N

keep if check_month == 3

*******Aggregate to quarter *******
bysort hh_id year quarter: replace h_totinc  = sum(h_totinc)
keep if month==3 |month==6 | month==9| month==12

gen yq = yq(year, quarter)
format yq %tq
// gen qtr = (year-1984)*4 + quarter

keep h_totinc yq weight hh_id

save 86_panel_revised, replace

								* 1987 *
								* ---- *

use 87_panel, clear
replace caidcov = caidcov==1
rename h_year year
rename h_month month
rename panel panel_year
rename h_wgt weight
egen hh_id = group(su_id h_add panel_year)


*****CREATE CALENDAR MONTH/YEAR*****************************
gen     quarter=1 if month>=1 & month<=3
replace quarter=2 if month>=4 & month<=6
replace quarter=3 if month>=7 & month<=9
replace quarter=4 if month>=10 & month<=12


bysort hh_id year quarter: gen check_month = _N

keep if check_month == 3

*******Aggregate to quarter *******
bysort hh_id year quarter: replace h_totinc  = sum(h_totinc)
keep if month==3 |month==6 | month==9| month==12

gen yq = yq(year, quarter)
format yq %tq
// gen qtr = (year-1984)*4 + quarter

keep h_totinc yq weight hh_id

save 87_panel_revised, replace

								* 1988 *
								* ---- *

use 88_panel, clear
replace caidcov = caidcov==1
rename h_year year
rename h_month month
rename panel panel_year
rename h_wgt weight
egen hh_id = group(su_id h_add panel_year)


*****CREATE CALENDAR MONTH/YEAR*****************************
gen     quarter=1 if month>=1 & month<=3
replace quarter=2 if month>=4 & month<=6
replace quarter=3 if month>=7 & month<=9
replace quarter=4 if month>=10 & month<=12


bysort hh_id year quarter: gen check_month = _N

keep if check_month == 3

*******Aggregate to quarter *******
bysort hh_id year quarter: replace h_totinc  = sum(h_totinc)
keep if month==3 |month==6 | month==9| month==12

gen yq = yq(year, quarter)
format yq %tq
// gen qtr = (year-1984)*4 + quarter

keep h_totinc yq weight hh_id

save 88_panel_revised, replace

								* 1989 *
								* ---- *

use 89_panel, clear
replace caidcov = caidcov==1
rename h_year year
rename h_month month
rename panel panel_year
rename h_wgt weight
egen hh_id = group(su_id h_add panel_year)

*****CREATE CALENDAR MONTH/YEAR*****************************
gen     quarter=1 if month>=1 & month<=3
replace quarter=2 if month>=4 & month<=6
replace quarter=3 if month>=7 & month<=9
replace quarter=4 if month>=10 & month<=12


bysort hh_id year quarter: gen check_month = _N

keep if check_month == 3

*******Aggregate to quarter *******
bysort hh_id year quarter: replace h_totinc  = sum(h_totinc)
keep if month==3 |month==6 | month==9| month==12

gen yq = yq(year, quarter)
format yq %tq
// gen qtr = (year-1984)*4 + quarter

keep h_totinc yq weight hh_id

save 89_panel_revised, replace

								* 1990 *
								* ---- *

use 90_panel, clear
replace caidcov = caidcov==1
rename h_year year
rename h_month month
rename panel panel_year
rename h_wgt weight
egen hh_id = group(su_id h_add panel_year)

*****CREATE CALENDAR MONTH/YEAR*****************************
gen     quarter=1 if month>=1 & month<=3
replace quarter=2 if month>=4 & month<=6
replace quarter=3 if month>=7 & month<=9
replace quarter=4 if month>=10 & month<=12


bysort hh_id year quarter: gen check_month = _N

keep if check_month == 3

*******Aggregate to quarter *******
bysort hh_id year quarter: replace h_totinc  = sum(h_totinc)
keep if month==3 |month==6 | month==9| month==12

gen yq = yq(year, quarter)
format yq %tq
// gen qtr = (year-1984)*4 + quarter

keep h_totinc yq weight hh_id

save 90_panel_revised, replace

								* 1991 *
								* ---- *

use 91_panel, clear
replace caidcov = caidcov==1
cap rename fnlwght_ fnlwgt_
cap rename h_add h_addid
destring h_addid, replace
rename h_year year
rename h_month month
rename panel panel_year
rename h_wgt weight
egen hh_id = group(su_id h_add panel_year)

*****CREATE CALENDAR MONTH/YEAR*****************************
gen     quarter=1 if month>=1 & month<=3
replace quarter=2 if month>=4 & month<=6
replace quarter=3 if month>=7 & month<=9
replace quarter=4 if month>=10 & month<=12


bysort hh_id year quarter: gen check_month = _N

keep if check_month == 3

*******Aggregate to quarter *******
bysort hh_id year quarter: replace h_totinc  = sum(h_totinc)
keep if month==3 |month==6 | month==9| month==12

gen yq = yq(year, quarter)
format yq %tq
// gen qtr = (year-1984)*4 + quarter

keep h_totinc yq weight hh_id

save 91_panel_revised, replace

								* 1992 *
								* ---- *


use 92_panel, clear
replace caidcov = caidcov==1
cap rename fnlwgt fnlwgt_
tostring pp_pnum, replace
tostring pp_entry, replace
cap rename h_add h_addid
destring h_addid, replace
rename h_year year
rename h_month month
rename panel panel_year
rename h_wgt weight
egen hh_id = group(su_id h_add panel_year)

*****CREATE CALENDAR MONTH/YEAR*****************************
gen     quarter=1 if month>=1 & month<=3
replace quarter=2 if month>=4 & month<=6
replace quarter=3 if month>=7 & month<=9
replace quarter=4 if month>=10 & month<=12


bysort hh_id year quarter: gen check_month = _N

keep if check_month == 3

*******Aggregate to quarter *******
bysort hh_id year quarter: replace h_totinc  = sum(h_totinc)
keep if month==3 |month==6 | month==9| month==12

gen yq = yq(year, quarter)
format yq %tq
// gen qtr = (year-1984)*4 + quarter

keep h_totinc yq weight hh_id


save 92_panel_revised, replace

								* 1993 *
								* ---- *

use 93_panel, clear
replace caidcov = caidcov==1
cap rename fnlwgt fnlwgt_
cap tostring pp_pnum, replace
tostring pp_entry, replace
cap rename h_add h_addid
destring h_addid, replace
rename h_year year
rename h_month month
rename panel panel_year
rename h_wgt weight
egen hh_id = group(su_id h_add panel_year)


*****CREATE CALENDAR MONTH/YEAR*****************************
gen     quarter=1 if month>=1 & month<=3
replace quarter=2 if month>=4 & month<=6
replace quarter=3 if month>=7 & month<=9
replace quarter=4 if month>=10 & month<=12


bysort hh_id year quarter: gen check_month = _N

keep if check_month == 3

*******Aggregate to quarter *******
bysort hh_id year quarter: replace h_totinc  = sum(h_totinc)
keep if month==3 |month==6 | month==9| month==12

gen yq = yq(year, quarter)
format yq %tq
// gen qtr = (year-1984)*4 + quarter

keep h_totinc yq weight hh_id

save 93_panel_revised, replace

								* 1996 *
								* ---- *

use 96_panel, clear
replace state = 63 if state==2
replace state = 63 if state==16
replace state = 63 if state==30
replace state = 62 if state==19
replace caidcov = caidcov==1
cap rename higrade grade
cap rename grd_cmp grd_comp
cap rename p_wgt_ fnlwgt_
cap tostring pp_pnum, replace
tostring pp_entry, replace
cap rename h_add h_addid
destring h_addid, replace
rename h_year year
rename h_month month
rename panel panel_year
rename h_wgt weight
egen hh_id = group(su_id h_add panel_year)

*****CREATE CALENDAR MONTH/YEAR*****************************
gen     quarter=1 if month>=1 & month<=3
replace quarter=2 if month>=4 & month<=6
replace quarter=3 if month>=7 & month<=9
replace quarter=4 if month>=10 & month<=12


bysort hh_id year quarter: gen check_month = _N

keep if check_month == 3

*******Aggregate to quarter *******
bysort hh_id year quarter: replace h_totinc  = sum(h_totinc)
keep if month==3 |month==6 | month==9| month==12

gen yq = yq(year, quarter)
format yq %tq
// gen qtr = (year-1984)*4 + quarter

keep h_totinc yq weight hh_id


save 96_panel_revised, replace

								* 2001 *
								* ---- *

use 2001_panel, clear
cap drop _merge
replace state = 63 if state==2
replace state = 63 if state==16
replace state = 63 if state==30
replace state = 62 if state==19
replace caidcov = caidcov==1
replace h_povd = h_povd*12
cap rename higrade grade
cap rename grd_cmp grd_comp
cap rename p_wgt_ fnlwgt_
cap tostring pp_pnum, replace
tostring pp_entry, replace
cap rename h_add h_addid
destring h_addid, replace
rename h_year year
rename h_month month
rename panel panel_year
rename h_wgt weight
egen hh_id = group(su_id h_add panel_year)

*****CREATE CALENDAR MONTH/YEAR*****************************
gen     quarter=1 if month>=1 & month<=3
replace quarter=2 if month>=4 & month<=6
replace quarter=3 if month>=7 & month<=9
replace quarter=4 if month>=10 & month<=12


bysort hh_id year quarter: gen check_month = _N

keep if check_month == 3

*******Aggregate to quarter *******
bysort hh_id year quarter: replace h_totinc  = sum(h_totinc)
keep if month==3 |month==6 | month==9| month==12

gen yq = yq(year, quarter)
format yq %tq
// gen qtr = (year-1984)*4 + quarter

keep h_totinc yq weight hh_id

save 2001_panel_revised, replace

								* 2004 *
								* ---- *

use 2004_panel, clear
cap drop _merge
cap rename state_ state
replace state = 63 if state==2
replace state = 63 if state==16
replace state = 63 if state==30
replace state = 63 if state==56
replace state = 62 if state==19
replace state = 62 if state==38
replace state = 62 if state==46
replace state = 62 if state==19
replace state = 61 if state==23
replace state = 61 if state==50
replace caidcov = caidcov==1
replace h_povd = h_povd*12
cap rename higrade grade
cap rename ws1_amt ws1_am
cap rename ws2_amt ws2_am
cap rename grd_cmp grd_comp
cap rename p_wgt_ fnlwgt_
cap rename h_metro_  h_metro
cap tostring pp_pnum, replace
tostring pp_entry, replace
cap rename h_add h_addid
destring h_addid, replace
rename h_year year
rename h_month month
rename panel panel_year
rename h_wgt weight
egen hh_id = group(su_id h_add panel_year)


*****CREATE CALENDAR MONTH/YEAR*****************************
gen     quarter=1 if month>=1 & month<=3
replace quarter=2 if month>=4 & month<=6
replace quarter=3 if month>=7 & month<=9
replace quarter=4 if month>=10 & month<=12


bysort hh_id year quarter: gen check_month = _N

keep if check_month == 3

*******Aggregate to quarter *******
bysort hh_id year quarter: replace h_totinc  = sum(h_totinc)
keep if month==3 |month==6 | month==9| month==12

gen yq = yq(year, quarter)
format yq %tq
// gen qtr = (year-1984)*4 + quarter

keep h_totinc yq weight hh_id

save 2004_panel_revised, replace

								* 2008 *
								* ---- *

use 2008_panel, clear
cap drop _merge
cap rename state_ state
replace state = 63 if state==2
replace state = 63 if state==16
replace state = 63 if state==30
replace state = 63 if state==56
replace state = 62 if state==19
replace state = 62 if state==38
replace state = 62 if state==46
replace state = 62 if state==19
replace state = 61 if state==23
replace state = 61 if state==50
replace caidcov = caidcov==1
replace h_povd = h_povd*12
cap rename higrade grade
cap rename ws1_amt ws1_am
cap rename ws2_amt ws2_am
cap rename grd_cmp grd_comp
cap rename p_wgt_ fnlwgt_
cap rename h_metro_  h_metro
cap tostring pp_pnum, replace
tostring pp_entry, replace
cap rename h_add h_addid
destring h_addid, replace
rename h_year year
rename h_month month
rename panel panel_year
rename h_wgt weight
egen hh_id = group(su_id h_add panel_year)


*****CREATE CALENDAR MONTH/YEAR*****************************
gen     quarter=1 if month>=1 & month<=3
replace quarter=2 if month>=4 & month<=6
replace quarter=3 if month>=7 & month<=9
replace quarter=4 if month>=10 & month<=12


bysort hh_id year quarter: gen check_month = _N

keep if check_month == 3

*******Aggregate to quarter *******
bysort hh_id year quarter: replace h_totinc  = sum(h_totinc)
keep if month==3 |month==6 | month==9| month==12

gen yq = yq(year, quarter)
format yq %tq
// gen qtr = (year-1984)*4 + quarter

keep h_totinc yq weight hh_id

save 2008_panel_revised, replace




