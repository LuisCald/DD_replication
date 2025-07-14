rename V99 intquarter67
rename V553 intquarter68
rename V1236 intquarter69
rename V1939 intquarter70
rename V2539 intquarter71
rename V3092 intquarter72

rename V3505 intquarter73
rename V3918 intquarter74
rename V4433 intquarter75
rename V5347 intquarter76
rename V5847 intquarter77 
rename V6459 intquarter78
rename V7064 intquarter79 // until here, PSID uses 1-9 scale, 9 = NA
rename V7655 intquarter80 // here, they start using the 4 digit code 
rename V8349 intquarter81
rename V8958 intquarter82

rename V10416 intquarter83
rename V11600 intquarter84
rename V13008 intquarter85
rename V14111 intquarter86
rename V15127 intquarter87
rename V16628 intquarter88
rename V18046 intquarter89
rename V19346 intquarter90
rename V20648 intquarter91
rename V22403 intquarter92

rename ER2005 intquarter93
rename ER5004 intquarter94
rename ER7004 intquarter95

rename ER10005 intmonth96
rename ER13006 intmonth98
rename ER17009 intmonth2000
rename ER21012 intmonth2002
rename ER25012 intmonth2004
rename ER36012 intmonth2006
rename ER42012 intmonth2008
rename ER47312 intmonth2010
rename ER53012 intmonth2012
rename ER60012 intmonth2014
rename ER66012 intmonth2016
rename ER72012 intmonth2018
rename ER78012 intmonth2020

rename ER10007 intyear96
rename ER13008 intyear98
rename ER17011 intyear2000
rename ER21014 intyear2002
rename ER25014 intyear2004
rename ER36014 intyear2006
rename ER42014 intyear2008
rename ER47314 intyear2010
rename ER53014 intyear2012
rename ER60014 intyear2014
rename ER66014 intyear2016
rename ER72014 intyear2018
rename ER78014 intyear2020

* Convert the month to quarter
foreach num of numlist 96 98 2000(2)2020 {
	gen intquarter`num' = . 
	replace intquarter`num' = 1 if intmonth`num' <= 3
	replace intquarter`num' = 2 if intmonth`num' > 3 & intmonth`num' <= 6
	replace intquarter`num' = 3 if intmonth`num' > 6 & intmonth`num' <= 9
	replace intquarter`num' = 4 if intmonth`num' > 9 & intmonth`num' <= 12
}

replace intquarter96 = 3 if intquarter96 == 4
replace intquarter98 = 3 if intquarter98 == 4

replace intquarter2012 = 4 if intquarter2012 == 1 & intyear2012 == 2014
replace intyear2012 = 2013 if !missing(intyear2012)

replace intquarter2016 = 4 if intquarter2016 == 1 & intyear2016 == 2018
replace intyear2016 = 2017 if !missing(intyear2016)

replace intquarter2018 = 4 if intquarter2018 == 1 & intyear2018 == 2020
replace intyear2018 = 2019 if !missing(intyear2018)

replace intquarter2020 = 4 if intquarter2020 == 1 & intyear2020 == 2022
replace intyear2020 = 2021 if !missing(intyear2020)


* Create dates (from numbers)
foreach num of numlist 67 70(1)78 {
	replace intquarter`num' = 1 if intquarter`num' <= 2 & !missing(intquarter`num')
	replace intquarter`num' = 2 if intquarter`num' > 2 & !missing(intquarter`num')
	
	
}

// forvalues i=1(1)9 {
// 	if `i' <= 2 {
// 		replace intquarter67 = 1 if intquarter67
// 		replace intquarter70 = 1
// 		replace intquarter71 = 1
// 		replace intquarter72 = 1
// 		replace intquarter73 = 1
// 		replace intquarter74 = 1
// 		replace intquarter75 = 1
// 		replace intquarter76 = 1
// 		replace intquarter77 = 1
// 		replace intquarter78 = 1
// 	}
// 	else {
// 		replace intquarter67 = 2
// 		replace intquarter70 = 2
// 		replace intquarter71 = 2
// 		replace intquarter72 = 2
// 		replace intquarter73 = 2
// 		replace intquarter74 = 2
// 		replace intquarter75 = 2
// 		replace intquarter76 = 2
// 		replace intquarter77 = 2
// 		replace intquarter78 = 2
// 	}
// }


replace intquarter68 = 1 if intquarter68 <=3 & !missing(intquarter68)
replace intquarter69 = 1 if intquarter69 <=3 & !missing(intquarter69)

replace intquarter68 = 2 if intquarter68 > 3 & !missing(intquarter68)
replace intquarter69 = 2 if intquarter69 > 3 & !missing(intquarter69)


forvalues i = 79(1)95 {
		gen testmonth = cond(length(string(intquarter`i', "%12.0g")) == 4, ///
    real(substr(string(intquarter`i', "%12.0g"), 1, 2)), ///
    real(substr(string(intquarter`i', "%12.0g"), 1, 1)))
	
	replace testmonth = 4 if  intquarter`i' == 9999 | intquarter`i' == 6  // assign obs. to Q2 if unknown date
		
	gen testqtr = .
	replace testqtr = 1 if testmonth <= 3
	replace testqtr = 2 if testmonth > 3 &  testmonth <= 6
	replace testqtr = 3 if testmonth > 6 &  testmonth <= 9
	replace testqtr = 4 if testmonth > 9 &  testmonth <= 12
	
	replace intquarter`i' = testqtr
	
	drop testmonth testqtr

}

* Re-assigning quarters if very littler variation in quarter 
foreach num of numlist 79 85 90 94 96 98 {
	replace intquarter`num' = 3 if intquarter`num' == 4
}

replace intquarter95 = 2 if intquarter95 == 3
replace intquarter88 = . if intquarter88 == 3
replace intquarter88 = . if intquarter88 == 4

replace intquarter86 = 2 if intquarter86 == 3

replace intquarter84 = 2 if  intquarter84 == 1
replace intquarter84 = 3 if  intquarter84 == 4

replace intquarter83 = 2 if  intquarter83 == 3
replace intquarter83 = 2 if  intquarter83 == 4

replace intquarter82 = 3 if intquarter82 == 4
replace intquarter81 = 2 if intquarter81 == 3

replace intquarter80 = 2 if intquarter80 == 3
replace intquarter80 = 2 if intquarter80 == 4

* Create year dates 
foreach num of numlist 67(1)95 {
	gen intyear`num' = .
	replace intyear`num' = 1900 + `num' if !missing(intquarter`num')
	
	replace intyear`num' = intyear`num' + 1 // I add it back later. Just to have everything consistent. 

}

* Create quarter year dates 
foreach num of numlist 67(1)96 98 2000(2)2020{
	gen intdate`num' = yq(intyear`num', intquarter`num')
	format intdate`num' %tq
}



