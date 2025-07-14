**# Import WID data -> convert from 2023 to 2019 dollars 
foreach meas in income wealth {
	import delimited "/Users/lc/Dropbox/Distributional_Dynamics/2_Data_processing/`meas' Data WID.csv", clear 
	cap drop workingagepopulation
	cap drop  realtotalpretax`meas'
	cap drop realtotal`meas'
	cap drop  realpretax`meas'share
	cap drop  real`meas'share
	cap drop householdpopulation
	cap drop adultpopulation
	drop  unit

	* Create the date column 
	gen date = yq(year, quarter)
	format date %tq

	encode group, gen(enc_group)
	drop year quarter  group *growth 
	reshape wide real* inflationdeflator, i(date) j(enc_group)

	rename *`meas'perunit3 top10
	rename *`meas'perunit2 next40
	rename *`meas'perunit1 bottom50

	* Deflate using the average
	summ inflationdeflator1 if date >= tq(2019q1) &  date <= tq(2019q4)
	gen infldef2019 = r(mean)

	foreach var in top10 next40 bottom50 {
		replace `var' = `var' * infldef2019
	}

	drop infl*	
	rename date time
	
	* Export the dataset 
	export delimited "/Users/lc/Dropbox/Distributional_Dynamics/2_Data_processing/validation/WIDq/`meas'_quantiles_WID.csv", replace 
}
