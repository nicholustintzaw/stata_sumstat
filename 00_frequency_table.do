/*******************************************************************************
Purpose				:	generate sum-stat table			
Author				:	Nicholus Tint Zaw
Date				: 	10/31/2022
Modified by			:

*******************************************************************************/
//set trace on

gen var_name = ""
	label var var_name "Indicator (Label)"
	
	
gen var_df = ""
	label var var_df "Variable Name"

foreach var in  total_N percent_mean sd mean_sd /*median iqr*/ {
	gen `var' = 0
	label var `var' "`var'"
}

local i = 1
foreach var of global outcomes {
    
	di "`var' going to make label assignment"
	
	local label : variable label `var'
	
	di "`var' finish label assignment"
	di "`var' going to replace label assignment"

	
	tab  var_name, m 
	di "`label'"
	di `i'
	
	replace var_name = "`label'" in `i'
	
	replace var_df 		= "`var'" in `i'
	
	di "`var' going finish label assignment"
		
	count if !mi(`var')	
	if `r(N)' > 0 {
		
		di "`var' start summary"
		
		* Use svy: mean for weighted mean
        quietly svy: mean `var'
        matrix m = e(b)
        scalar MEAN = m[1,1]
		
		global total_N 			= `e(N)'
		replace total_N			= $total_N in `i'
	
		global percent_mean 	= round(MEAN, 0.0001)
		replace percent_mean 	= $percent_mean in `i'
		
        * SD using estat sd
        quietly svy: mean `var'
		quietly estat sd
        matrix s = r(sd)
        scalar SD = s[1,1]

		global sd 				= round(SD, 0.0001)
		replace sd 				= $sd in `i'
		
		* Quantile 
		// got error: . epctile per_fatsat_OH , p(25 50 75) svy
		// estimates post: matrix has missing values

		/*
		epctile `var', p(25 50 75) svy
        matrix p = e(b)
		
        scalar p25 = p[1,1]
		scalar p50 = p[1,2]
		scalar p75 = p[1,3]

		global median			= round(p50, 0.01)
		replace median			= $median in `i'
		
		global iqr				= round((p75 - p25), 0.01)
		replace iqr				= $iqr in `i'
		*/
			
		global mean_str 		= string($percent_mean, "%8.2f")
		global sd_str 			= string($sd, "%8.2f")
		
		tostring mean_sd, replace 
		global mean_sd			= "$mean_str" + " ± " + "$sd_str"
		replace mean_sd			= "$mean_sd" in `i'
	
	}
	
	
	local i = `i' + 1
	di "`var' finished"
	
}
		* white space correction
		
		foreach indicator in  total_N percent_mean sd {
			
			replace `indicator' = .m  if var_df == "white_space"
		}
		
		replace mean_sd		= "" if var_df == "white_space"
		replace var_df 		= "" if var_df == "white_space"

drop if total_N == 0     // get rid of extra raws
global export_table var_df var_name total_N percent_mean sd mean_sd 


