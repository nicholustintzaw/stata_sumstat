	/*******************************************************************************
	Purpose     : Generic svy: regression table generator for 2, 3, or 4 comparison groups
	Author      : Nicholus Tint Zaw
	Updated     : 2025-03-27
	*******************************************************************************/
	//set trace on

	* Determine number of distinct groups
	distinct group_var
	global grp_level = r(ndistinct)

	* Calculate number of pairwise comparisons (n choose 2)
	local n_comp = `= $grp_level * ($grp_level - 1) / 2'
	
	* Initialize output vars
	gen var_df = ""
	label var var_df "Variable Name"
	
	gen var_name = ""
	label var var_name "Indicator (Label)"

	foreach var in total_N f_test f_prob r_squ {
		gen `var' = 0
		label var `var' "`var'"
	}

	forvalues c_g = 1/`n_comp' {
		foreach var in coef pval ci_95 {
			gen `var'_`c_g' = 0
			label var `var'_`c_g' "`var'_`c_g'"
		}
	}

	order f_test f_prob r_squ, after(ci_95_`n_comp')

	* Main loop over outcomes
	local i = 1
	foreach var of global outcomes {

		count if !mi(`var') 

			if `r(N)' > 0 {

			* di "`var' going to make label assignment"
			local label : variable label `var'

			*di "`var' finish label assignment"
			*di "`var' going to replace label assignment"
			*tab  var_name, m 
			*di "`label'"
			*di `i'
			
			replace var_name = "`label'" in `i'
			
			replace var_df 		= "`var'" in `i'

			* di "`var' going finish label assignment"

			* di "`var' start summary"

			* Use svy: mean for weighted mean
			* Run regression
			quietly svy: reg `var' i.group_var

			* Store model diagnostics
			replace total_N			= `e(N)' in `i'
			
			replace f_test			= round(`e(F)', 0.0001) in `i'
 
			replace f_prob			= round(`e(p)', 0.0001) in `i'

			replace r_squ			= round(`e(r2)', 0.0001) in `i'

			* Marginal effects with pairwise comparison
			* extract coefficient and p-values
			margins group_var, pwcompare(effects) post

			matrix m = r(table_vs)
				
				forvalues c_g = 1/`n_comp' {

				scalar beta		= m[1,`c_g']
				scalar p_val	= m[4,`c_g']
				scalar lb 		= m[5,`c_g']
				scalar ub 		= m[6,`c_g']

				* output table assignment
				replace coef_`c_g' 		= round(beta, 0.01) in `i'

				replace pval_`c_g' 		= round(p_val, 0.0001) in `i'
					
				global lb_str 			= string(lb, "%8.2f")
				global ub_str			= string(ub, "%8.2f")

				tostring ci_95_*, replace 
				replace ci_95_`c_g'			= "($lb_str" + " , " + "$ub_str)" in `i'
				* replace ci_95_`c_g' = "(" + string(lb, "%8.2f") + " , " + string(ub, "%8.2f") + ")" in `i'
			}


		* white space correction
		replace var_df 		= "" if var_df == "white_space"
		
		}


	local i = `i' + 1
	*di "`var' finished"

	}

	drop if total_N == 0     // get rid of extra raws
	keep var_df var_name total_N - f_test f_prob r_squ
	