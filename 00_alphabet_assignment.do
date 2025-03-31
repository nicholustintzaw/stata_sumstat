	****************************************************************************
	** Algorithm to apply alphabet letters to table results **
	****************************************************************************
	/* 
	Developed by Nicholus Tint Zaw
	Last update: 3 30 2025 
	
	Note: 
	Please note that this algorithm did not account for the missing p-value in the significant alphabet assignment.
	
	*/
	****************************************************************************
	****************************************************************************
	
	* Determine number of distinct groups
	//distinct group_var
	//local grp_level = r(ndistinct)

	* 2 levels group category 
	if $grp_level == 2 {
		
		*(1) Step - 1: Initial comparision - A vs B
		gen a_1 = "a"

		gen b_1 = cond(pval_1 >= 0.05, "a", "b")

	}
	
	* 3 levels group category 
	else if $grp_level == 3 {
		
		*(1) Step - 1: Initial comparision - A vs all
		gen a_1 = "a"

		gen b_1 = cond(pval_1 >= 0.05, "a", "b")
		gen c_1 = cond(pval_2 >= 0.05, "a", "c")
		
		
		*(2) Step - 2: Second round comparision - B Vs C
		
		* B vs C
		* Update B
		gen b_2 = ""
		replace b_2 = "a, b" 	if pval_3 < 0.05 & b_1 == "a"
		replace b_2 = "b, b" 	if pval_3 < 0.05 & b_1 == "b"
		
		replace b_2 = "a, b" 	if pval_3 >= 0.05 & b_1 == "a"
		replace b_2 = "b, b" 	if pval_3 >= 0.05 & b_1 == "b"

		
		* Update C
		gen c_2 = ""
		replace c_2 = "a, c" 	if pval_3 < 0.05 & c_1 == "a" // & b_2 == "a, a" 
		// same result for all b_2 condition
		
		replace c_2 = "c, c" 	if pval_3 < 0.05 & c_1 == "c" // & b_2 == "a, a"
		// same result for all b_2 condition
		
		
		replace c_2 = "a, b" 	if pval_3 >= 0.05 & c_1 == "a" & b_2 == "a, b"
		replace c_2 = "a, b" 	if pval_3 >= 0.05 & c_1 == "a" & b_2 == "b, b"
		
		replace c_2 = "c, b" 	if pval_3 >= 0.05 & c_1 == "c" & b_2 == "a, b"
		replace c_2 = "c, b" 	if pval_3 >= 0.05 & c_1 == "c" & b_2 == "b, b"
		

		
		* order variable 
		order b_2 c_2, after(a_1)
		
		* reduced simplify form 
		foreach var of varlist a_1 b_2 c_2 {
			
			replace `var' = "a" if `var' == "a, a"
			replace `var' = "b" if `var' == "b, b"
			replace `var' = "c" if `var' == "c, c"
		}
		
		* reconcile b_2 and c_2 
		gen b2_c2_same = (b_2 == c_2)
		
		replace b_2 = "a" if b2_c2_same == 1
		replace c_2 = "a" if b2_c2_same == 1
		
		
		* assignment for export table 
		drop b_1 - b2_c2_same

	}
	
	* 4 levels group category  
	else if $grp_level == 4 {
		
		*(1) Step - 1: Initial comparision - A vs all
		gen a_1 = "a"

		gen b_1 = cond(pval_1 >= 0.05, "a", "b")
		gen c_1 = cond(pval_2 >= 0.05, "a", "c")
		gen d_1 = cond(pval_3 >= 0.05, "a", "d")
		
		
		*(2) Step - 2: Second round comparision - B Vs C and D
		
		* B vs C
		* Update B
		gen b_2 = ""
		replace b_2 = "a, b" 	if pval_4 < 0.05 & b_1 == "a"
		replace b_2 = "b, b" 	if pval_4 < 0.05 & b_1 == "b"
		
		replace b_2 = "a, a" 	if pval_4 >= 0.05 & b_1 == "a"
		replace b_2 = "b, a" 	if pval_4 >= 0.05 & b_1 == "b"

		
		* Update C
		gen c_2 = ""
		replace c_2 = "a, c" 	if pval_4 < 0.05 & c_1 == "a" // & b_2 == "a, a" 
		// same result for all b_2 condition
		/*
		replace c_2 = "a, c" 	if pval_4 < 0.05 & c_1 == "a" & b_2 == "a, a" 
		replace c_2 = "a, c" 	if pval_4 < 0.05 & c_1 == "a" & b_2 == "a, b" 
		replace c_2 = "a, c" 	if pval_4 < 0.05 & c_1 == "a" & b_2 == "b, a" 
		replace c_2 = "a, c" 	if pval_4 < 0.05 & c_1 == "a" & b_2 == "b, b" 
		*/
		
		replace c_2 = "c, c" 	if pval_4 < 0.05 & c_1 == "c" // & b_2 == "a, a"
		// same result for all b_2 condition
		/*
		replace c_2 = "c, c" 	if pval_4 < 0.05 & c_1 == "c" & b_2 == "a, a"
		replace c_2 = "c, c" 	if pval_4 < 0.05 & c_1 == "c" & b_2 == "a, b"
		replace c_2 = "c, c" 	if pval_4 < 0.05 & c_1 == "c" & b_2 == "b, a"
		replace c_2 = "c, c" 	if pval_4 < 0.05 & c_1 == "c" & b_2 == "b, b"
		*/
		
		
		replace c_2 = "a, a" 	if pval_4 >= 0.05 & c_1 == "a" & b_2 == "a, a"
		replace c_2 = "a, a" 	if pval_4 >= 0.05 & c_1 == "a" & b_2 == "b, a"
		replace c_2 = "a, b" 	if pval_4 >= 0.05 & c_1 == "a" & b_2 == "a, b"
		replace c_2 = "a, b" 	if pval_4 >= 0.05 & c_1 == "a" & b_2 == "b, b"
		
		replace c_2 = "c, a" 	if pval_4 >= 0.05 & c_1 == "c" & b_2 == "a, a"
		replace c_2 = "c, a" 	if pval_4 >= 0.05 & c_1 == "c" & b_2 == "b, a"
		replace c_2 = "c, b" 	if pval_4 >= 0.05 & c_1 == "c" & b_2 == "a, b"
		replace c_2 = "c, b" 	if pval_4 >= 0.05 & c_1 == "c" & b_2 == "b, b"
		
		* B vs D
		* Update B
		gen b_3 = ""
		replace b_3 = "a, a, b" if pval_5 < 0.05 & b_2 == "a, a"
		replace b_3 = "a, b, b" if pval_5 < 0.05 & b_2 == "a, b"
		replace b_3 = "b, a, b" if pval_5 < 0.05 & b_2 == "b, a"
		replace b_3 = "b, b, b" if pval_5 < 0.05 & b_2 == "b, b"
		
		replace b_3 = "a, a, a" if pval_5 >= 0.05 & b_2 == "a, a"
		replace b_3 = "a, b, a" if pval_5 >= 0.05 & b_2 == "a, b"
		replace b_3 = "b, a, a" if pval_5 >= 0.05 & b_2 == "b, a"
		replace b_3 = "b, b, a" if pval_5 >= 0.05 & b_2 == "b, b"
		
		* Update D
		gen d_2 = ""
		replace d_2 = "a, d" 	if pval_5 < 0.05 & d_1 == "a" // & b_3 == "a, a, a" 
		// same result for all b_3 condition
		/*
		replace d_2 = "a, d" 	if pval_5 < 0.05 & d_1 == "a" & b_3 == "a, a, a" 
		replace d_2 = "a, d" 	if pval_5 < 0.05 & d_1 == "a" & b_3 == "a, a, b" 
		replace d_2 = "a, d" 	if pval_5 < 0.05 & d_1 == "a" & b_3 == "a, b, b" 
		replace d_2 = "a, d" 	if pval_5 < 0.05 & d_1 == "a" & b_3 == "a, b, a" 
		replace d_2 = "a, d" 	if pval_5 < 0.05 & d_1 == "a" & b_3 == "b, b, b" 
		replace d_2 = "a, d" 	if pval_5 < 0.05 & d_1 == "a" & b_3 == "b, b, a" 
		replace d_2 = "a, d" 	if pval_5 < 0.05 & d_1 == "a" & b_3 == "b, a, a" 
		replace d_2 = "a, d" 	if pval_5 < 0.05 & d_1 == "a" & b_3 == "b, a, b" 
		*/
		
		replace d_2 = "d, d" 		if pval_5 < 0.05 & d_1 == "d"  // & b_3 == "a" 
		// same result for all b_3 condition
		
		replace d_2 = "a, a" 	if pval_5 >= 0.05 & d_1 == "a" & b_3 == "a, a, a" 
		replace d_2 = "a, b" 	if pval_5 >= 0.05 & d_1 == "a" & b_3 == "a, a, b" 
		replace d_2 = "a, b" 	if pval_5 >= 0.05 & d_1 == "a" & b_3 == "a, b, b" 
		replace d_2 = "a, a" 	if pval_5 >= 0.05 & d_1 == "a" & b_3 == "a, b, a" 
		replace d_2 = "a, b" 	if pval_5 >= 0.05 & d_1 == "a" & b_3 == "b, b, b" 
		replace d_2 = "a, a" 	if pval_5 >= 0.05 & d_1 == "a" & b_3 == "b, b, a" 
		replace d_2 = "a, a" 	if pval_5 >= 0.05 & d_1 == "a" & b_3 == "b, a, a" 
		replace d_2 = "a, b" 	if pval_5 >= 0.05 & d_1 == "a" & b_3 == "b, a, b" 
		
		replace d_2 = "d, a" 	if pval_5 >= 0.05 & d_1 == "d" & b_3 == "a, a, a" 
		replace d_2 = "d, b" 	if pval_5 >= 0.05 & d_1 == "d" & b_3 == "a, a, b" 
		replace d_2 = "d, b" 	if pval_5 >= 0.05 & d_1 == "d" & b_3 == "a, b, b" 
		replace d_2 = "d, a" 	if pval_5 >= 0.05 & d_1 == "d" & b_3 == "a, b, a" 
		replace d_2 = "d, b" 	if pval_5 >= 0.05 & d_1 == "d" & b_3 == "b, b, b" 
		replace d_2 = "d, a" 	if pval_5 >= 0.05 & d_1 == "d" & b_3 == "b, b, a" 
		replace d_2 = "d, a" 	if pval_5 >= 0.05 & d_1 == "d" & b_3 == "b, a, a" 
		replace d_2 = "d, b" 	if pval_5 >= 0.05 & d_1 == "d" & b_3 == "b, a, b" 

		*(3) Step - 3" Third round comparision - C Vs D
		
		* C vs D
		* Update C
		gen c_3 = ""
		replace c_3 = "a, a, c" if pval_6 < 0.05 & c_2 == "a, a"
		replace c_3 = "a, b, c" if pval_6 < 0.05 & c_2 == "a, b"
		replace c_3 = "a, c, c" if pval_6 < 0.05 & c_2 == "a, c"
		replace c_3 = "c, a, c" if pval_6 < 0.05 & c_2 == "c, a"
		replace c_3 = "c, b, c" if pval_6 < 0.05 & c_2 == "c, b"
		replace c_3 = "c, c, c" if pval_6 < 0.05 & c_2 == "c, c"

		
		replace c_3 = "a, a, a" if pval_6 >= 0.05 & c_2 == "a, a"
		replace c_3 = "a, b, a" if pval_6 >= 0.05 & c_2 == "a, b"
		replace c_3 = "a, c, a" if pval_6 >= 0.05 & c_2 == "a, c"
		replace c_3 = "c, a, a" if pval_6 >= 0.05 & c_2 == "c, a"
		replace c_3 = "c, b, a" if pval_6 >= 0.05 & c_2 == "c, b"
		replace c_3 = "c, c, a" if pval_6 >= 0.05 & c_2 == "c, c"
		
		* Update D
		gen d_3 = ""
		replace d_3 = "a, a, d" if pval_6 < 0.05 & d_2 == "a, a" // same for all c_3 condition 
		replace d_3 = "a, b, d" if pval_6 < 0.05 & d_2 == "a, b"	
		replace d_3 = "a, d, d" if pval_6 < 0.05 & d_2 == "a, d" 
		replace d_3 = "d, a, d" if pval_6 < 0.05 & d_2 == "d, a"
		replace d_3 = "d, b, d" if pval_6 < 0.05 & d_2 == "d, b"
		replace d_3 = "d, d, d" if pval_6 < 0.05 & d_2 == "d, d"  	
		
		
		replace d_3 = "a, a, a" if pval_6 >= 0.05 & d_2 == "a, a"  // same for all c_3 condition 
		replace d_3 = "a, b, a" if pval_6 >= 0.05 & d_2 == "a, b" 
		replace d_3 = "a, d, a" if pval_6 >= 0.05 & d_2 == "a, d" 
		replace d_3 = "d, a, a" if pval_6 >= 0.05 & d_2 == "d, a" 
		replace d_3 = "d, b, a" if pval_6 >= 0.05 & d_2 == "d, b" 
		replace d_3 = "d, d, a" if pval_6 >= 0.05 & d_2 == "d, d" 

		
		* order variable 
		order b_3 c_3 d_3, after(a_1)
		
		* reduced simplify form 
		foreach var of varlist a_1 b_3 c_3 d_3 {
			
			replace `var' = "a" if `var' == "a, a, a"
			replace `var' = "b" if `var' == "b, b, b"
			replace `var' = "c" if `var' == "c, c, c"
			replace `var' = "d" if `var' == "d, d, d"
		}
		
		* assignment for export table 
		drop b_1 - d_2

	}
	
	
	

	
