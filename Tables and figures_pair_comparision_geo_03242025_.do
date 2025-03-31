	/*
	This do file prepares the revised tables for the adolescent eating out paper
	Prepared on: 13 September 2024
	Revised on: 17 March 2025
	Prepared by: Soyra Gune
	Last revised on: 19 February 2025 by Gabi

	- Update as pair-coparision on geo category by Nicholus on - 03 24 2025
	*/

	****************************************************************************
	****************************************************************************
	* Project directory set-up	
	local  hostname "`c(hostname)'"

	else if "`hostname'" == "IFPRI-CS20002"  { // Nichous 
		
		global wp1		 	"C:\Users\NTZaw\OneDrive - CGIAR\All SHiFT files\WP1"
		global do			"$wp1\Vietnam\Data\Dofiles\24h recall\5. Analysis\P3. Diet eating locations"
		global dta			"$wp1\Vietnam\Data\Data\24h recall\5. Analysis\P3. Diet eating locations"
		global output		"$wp1\Vietnam\Data\Results\P3. Diet eating locations paper"
		
	}
	
	if "`hostname'" == "IFPRI-CS16487"  { // Gabi 
					
		global wp1		 	"C:\Users\GFretes\OneDrive - CGIAR\All SHiFT files\WP1"
		global dta			"$wp1\Vietnam\Data\Data\24h recall\5. Analysis\P3. Diet eating locations"
		global output		"$wp1\Vietnam\Data\Results\P3. Diet eating locations paper"
	
	}
	
	if "`hostname'" == "" { //  
		
		global wp1		 	""
		
	}

	****************************************************************************
	****************************************************************************
	
	** Use analysis prepared dataset ** 
	use "$dta\Adol GDQS nutrients EOH.dta", clear


	**Setting survey design 
	svyset school_id

	**# Table 1: Adolescent characteristics 
	**Changed to account for clustering 
	*Adolescent age 
	svy: mean ado_age
	svy: mean ado_age, over(district)
	estat sd
	*Sex 
	mean ado_sex, over(district)
	*Adolescents consumed prepared food partially or entirely prepared at home 
	gen adol_prep_AH=0 if in_energy!=.
	replace adol_prep_AH=1 if in_energy_AH>0 & in_energy_AH!=.
	mean adol_prep_AH
	mean adol_prep_AH, over(district)
	*Adolescent consumed food entirely prepared outside home 
	gen adol_prep_OH=0 if in_energy!=.
	replace adol_prep_OH=1 if in_energy_OH>0 & in_energy_OH!=.
	mean adol_prep_OH
	mean adol_prep_OH, over(district)
	*Adolescent consumed food at home 
	gen con_energy_AH=in_energy_AH_AH+in_energy_OH_AH
	gen adol_loc_AH=0 if in_energy!=.
	replace adol_loc_AH=1 if con_energy_AH>0 & con_energy_AH!=.
	mean adol_loc_AH 
	mean adol_loc_AH, over(district)
	*Adolescent consumed food outside home 
	gen con_energy_OH=in_energy_AH_OH+in_energy_OH_OH
	gen adol_loc_OH=0 if in_energy!=.
	replace adol_loc_OH=1 if con_energy_OH>0 & con_energy_OH!=.
	mean adol_loc_OH 
	mean adol_loc_OH, over(district)
	*Adolescent received pocket money 
	mean adol_pock_money, over(district)
	*Amount received my adolescent in pocket money 
	mean adol_pock_mon_amt
	estat sd 
	mean adol_pock_mon_amt, over(district)
	estat sd 
	**SD extremely large for rural town. Check distribution
	sum adol_pock_mon_amt, detail
	histogram adol_pock_mon_amt, bin (30) normal
	graph box adol_pock_mon_amt
	graph box adol_pock_mon_amt, over (district) // there are 2 outliers in the rural town which contribute to the large SD
	svy: mean adol_pock_mon_amt if adol_pock_mon_amt<=3000
	estat sd 
	mean adol_pock_mon_amt if adol_pock_mon_amt<=3000, over(district)
	estat sd 

	** Export Sum-stat and Regression Table **
	gen ado_female = (ado_sex == 2)
	replace ado_female = .m if mi(ado_sex)
	lab var ado_female "Ado: Female"
	
	global outcomes	ado_age ado_female ///
					adol_pock_money adol_pock_mon_amt ///
					adol_prep_AH adol_prep_OH ///
					adol_loc_AH adol_loc_OH ///
					
	
	* Sumstat by Geo Breakdown
	levelsof district, local(geo)
	
	foreach x in `geo' {
		
		preserve 
					
			keep if district == `x'
			
			keep $outcomes school_id
			
			do "$do/00_frequency_table"


			export excel $export_table 	using "$output/sumstat_output/SUMSTAT_Outputs.xlsx",  /// 
										sheet("tab_1 `x'") firstrow(varlabels) keepcellfmt sheetreplace 	
		
		restore 
		
	}
	
	* Prepare for regression model 		
	preserve 
		
		gen group_var = district 
		
		keep $outcomes school_id group_var
		
		do "$do/00_regression_table_with_svy.do"
		
		do "$do/00_alphabet_assignment.do"

		export excel using "$output/sumstat_output/SUMSTAT_Outputs.xlsx",  /// 
							sheet("model_tab_1") firstrow(varlabels) keepcellfmt sheetreplace 	
	
	restore 

	
	**# Table 2- Energy and nutrient intake by residence 
	*Percentage of energy consumption at home 
	gen per_energy_AH=(in_energy_AH/in_energy)*100
	*Percentage of energy consumed outside home 
	gen per_energy_OH=(in_energy_OH/in_energy)*100

	lab var per_energy_AH "Percentage of energy from food prepared at home"
	lab var per_energy_OH "Percnetage of energy from food prepared outside home" 
	*Energy intake
	svy: mean in_energy, over(district)
	svy: mean in_energy_AH, over(district)
	svy: mean in_energy_OH, over(district)
	*Percentage energy intake
	svy: mean per_energy_AH, over(district)
	svy: mean per_energy_OH, over(district)

	**Running regressions to test mean differences
	*Total energy intake 
	svy: reg in_energy i.district 
	svy: reg in_energy ib2.district
	*Energy prepared at home 
	svy: reg in_energy_AH i.district 
	svy: reg in_energy_AH ib2.district
	*Energy prepared outside home 
	svy: reg in_energy_OH i.district 
	svy: reg in_energy_OH ib2.district
	*Percentage of intake at home 
	svy: reg per_energy_AH i.district 
	svy: reg per_energy_AH ib2.district
	*Percentage of intake outside home 
	svy: reg per_energy_OH i.district 
	svy: reg per_energy_OH ib2.district

	**Protein intake 
	egen in_protein=rowtotal(in_protein_AH in_protein_OH)
	mean in_protein in_protein_AH in_protein_OH 
	mean in_protein in_protein_AH in_protein_OH, over(district)
	*Protein intake
	svy: mean in_protein, over(district)
	svy: mean in_protein_AH, over(district)
	svy: mean in_protein_OH, over(district)

	**Protein % of intake
	gen per_protein_AH=(in_protein_AH/in_protein)*100
	gen per_protein_OH=(in_protein_OH/in_protein)*100
	lab var per_protein_AH "Percentage of protein from food prepared at home"
	lab var per_protein_OH "Percentage of protein from food prepared outside home"
	svy: mean per_protein_AH per_protein_OH, over (district)

	**Running regressions to test for mean differences 
	*Total protein intake 
	svy: reg in_protein i.district 
	svy: reg in_protein ib2.district
	*Protein intake prepared at home 
	svy: reg in_protein_AH i.district 
	svy: reg in_protein_AH ib2.district
	*Protein intake prepared outside home 
	svy: reg in_protein_OH i.district 
	svy: reg in_protein_OH ib2.district
	*% of protein intake prepared at home 
	svy: reg per_protein_AH i.district 
	svy: reg per_protein_AH ib2.district
	*% of protein intake prepared outside home 
	svy: reg per_protein_OH i.district 
	svy: reg per_protein_OH ib2.district

	*Carbohydrate intake 
	egen in_carbo=rowtotal(in_carbo_AH in_carbo_OH)
	svy: mean in_carbo, over(district) 
	svy: mean in_carbo_AH, over(district) 
	svy: mean in_carbo_OH, over(district)

	**Carbohydrate % of intake 
	gen per_carbo_AH=(in_carbo_AH/in_carbo)*100
	gen per_carbo_OH=(in_carbo_OH/in_carbo)*100
	lab var per_carbo_AH "Percentage of carbohydrate from food prepared at home"
	lab var per_carbo_OH "Percentage of carbohydrate from food prepared outside home"
	svy: mean per_carbo_AH per_carbo_OH, over (district)

	*Running regression to test for mean differences 
	*Total carbohydrate intake 
	svy: reg in_carbo i.district 
	svy: reg in_carbo ib2.district
	*Carbo intake prepared at home 
	svy: reg in_carbo_AH i.district 
	svy: reg in_carbo_AH ib2.district
	*Carbo intake prepared outside home 
	svy: reg in_carbo_OH i.district 
	svy: reg in_carbo_OH ib2.district
	*% of carbo intake prepared at home 
	svy: reg per_carbo_AH i.district 
	svy: reg per_carbo_AH ib2.district
	*% of carbo intake prepared outside home 
	svy: reg per_carbo_OH i.district 
	svy: reg per_carbo_OH ib2.district

	*Fat intake 
	egen in_lipid=rowtotal(in_lipid_AH in_lipid_OH)

	svy: mean in_lipid, over(district)
	svy: mean in_lipid_AH, over(district)
	svy: mean in_lipid_OH, over(district)
	**Fat % of intake 
	gen per_lipid_AH=(in_lipid_AH/in_lipid)*100
	gen per_lipid_OH=(in_lipid_OH/in_lipid)*100
	lab var per_lipid_AH "Percentage of lipid from food prepared at home"
	lab var per_lipid_OH "Percentage of lipid from food prepared outside home"
	svy: mean per_lipid_AH per_lipid_OH, over (district)

	*Running regression to test for mean differences
	*Total fat intake 
	svy: reg in_lipid i.district 
	svy: reg in_lipid ib2.district
	*Fat intake- PAH 
	svy: reg in_lipid_AH i.district 
	svy: reg in_lipid_AH ib2.district
	*Fat intake- POH 
	svy: reg in_lipid_OH i.district 
	svy: reg in_lipid_OH ib2.district
	*% of fat intake PAH 
	svy: reg per_lipid_AH i.district 
	svy: reg per_lipid_AH ib2.district
	*% of fat intake POH 
	svy: reg per_lipid_OH i.district 
	svy: reg per_lipid_OH ib2.district

	*Saturated fat 
	mean in_fatsat in_fatsat_AH in_fatsat_OH
	svy: mean in_fatsat, over(district)
	svy: mean in_fatsat_AH, over(district)
	svy: mean in_fatsat_OH, over(district)
	**Saturated fat % of intake 
	gen per_fatsat_AH=(in_fatsat_AH/in_fatsat)*100
	gen per_fatsat_OH=(in_fatsat_OH/in_fatsat)*100
	lab var per_fatsat_AH "Percentage of saturated fat from food prepared at home"
	lab var per_fatsat_OH "Percentage of saturated fat from food prepared outside home"
	svy: mean per_fatsat_AH per_fatsat_OH, over (district)

	**Running regressions to test mean differences 
	*Total saturated fat intake 
	svy: reg in_fatsat i.district 
	svy: reg in_fatsat ib2.district
	*Saturated fat: PAH 
	svy: reg in_fatsat_AH i.district 
	svy: reg in_fatsat_AH ib2.district
	*Saturated fat: POH 
	svy: reg in_fatsat_OH i.district 
	svy: reg in_fatsat_OH ib2.district
	*% of saturated fat PAH 
	svy: reg per_fatsat_AH i.district 
	svy: reg per_fatsat_AH ib2.district
	*% of saturated fat POH 
	svy: reg per_fatsat_OH i.district 
	svy: reg per_fatsat_OH ib2.district


	*Sodium 
	svy: mean in_na, over(district)
	svy: mean in_na_AH, over(district)
	svy: mean in_na_OH, over(district)
	**Sodium % of intake 
	gen per_na_AH=(in_na_AH/in_na)*100
	gen per_na_OH=(in_na_OH/in_na)*100
	lab var per_na_AH "Percentage of sodium from food prepared at home"
	lab var per_na_OH "Percentage of sodium from food prepared outside home"
	svy: mean per_na_AH per_na_OH, over (district)

	**Running regressions to test mean differences 
	*Total sodium intake 
	svy: reg in_na i.district 
	svy: reg in_na ib2.district
	*Sodium intake PAH 
	svy: reg in_na_AH i.district 
	svy: reg in_na_AH ib2.district
	*Sodium intake POH 
	svy: reg in_na_OH i.district 
	svy: reg in_na_OH ib2.district
	*% of soidum PAH 
	svy: reg per_na_AH i.district 
	svy: reg per_na_AH ib2.district
	*% of sodium POH 
	svy: reg per_na_OH i.district 
	svy: reg per_na_OH ib2.district
	
	** Export Sum-stat and Regression Table **
	global outcomes	per_energy_AH per_energy_OH per_protein_AH per_protein_OH per_carbo_AH per_carbo_OH ///
					per_lipid_AH per_lipid_OH per_fatsat_AH per_fatsat_OH per_na_AH per_na_OH 
	
	* Sumstat by Geo Breakdown
	levelsof district, local(geo)
	
	foreach x in `geo' {
		
		preserve 
					
			keep if district == `x'
			
			keep $outcomes school_id
			
			do "$do/00_frequency_table"


			export excel $export_table 	using "$output/sumstat_output/SUMSTAT_Outputs.xlsx",  /// 
										sheet("tab_2 `x'") firstrow(varlabels) keepcellfmt sheetreplace 	
		
		restore 
		
	}
	
	* Prepare for regression model 		
	preserve 
		
		gen group_var = district 
		
		keep $outcomes school_id group_var
		
		do "$do/00_regression_table_with_svy.do"
		
		do "$do/00_alphabet_assignment.do"

		export excel using "$output/sumstat_output/SUMSTAT_Outputs.xlsx",  /// 
							sheet("model_tab_2") firstrow(varlabels) keepcellfmt sheetreplace 	
	
	restore 


	**#Suppl Table 2 - Energy and nutrient by sex
	*Energy 
	svy: mean in_energy, over(ado_sex)
	svy: mean in_energy_AH, over(ado_sex)
	svy: mean in_energy_OH, over(ado_sex)
	svy: mean per_energy_AH, over(ado_sex)
	svy: mean per_energy_OH, over(ado_sex)

	**Running regressions to test mean differences 
	*Total energy intake 
	svy: reg in_energy i.ado_sex
	*Energy intake PAH 
	svy: reg in_energy_AH i.ado_sex
	*Energy intake POH 
	svy: reg in_energy_OH i.ado_sex
	*% of energy PAH 
	svy: reg per_energy_AH i.ado_sex
	*% of energy POH 
	svy: reg per_energy_OH i.ado_sex

	*Protein 
	svy: mean in_protein, over(ado_sex)
	svy: mean in_protein_AH, over(ado_sex)
	svy: mean in_protein_OH, over(ado_sex)
	svy: mean per_protein_AH, over(ado_sex)
	svy: mean per_protein_OH, over(ado_sex)


	*Running regressions to test mean differences 
	*Total protein intake 
	svy: reg in_protein i.ado_sex
	*Protein intake PAH 
	svy: reg in_protein_AH i.ado_sex
	*Protein intake POH 
	svy: reg in_protein_OH i.ado_sex
	*% of protein PAH 
	svy: reg per_protein_AH i.ado_sex
	*% of protein POH 
	svy: reg per_protein_OH i.ado_sex

	*Carbohydrate intake
	svy: mean in_carbo, over(ado_sex)
	svy: mean in_carbo_AH, over(ado_sex)
	svy: mean in_carbo_OH, over(ado_sex)
	svy: mean per_carbo_AH, over(ado_sex)
	svy: mean per_carbo_OH, over(ado_sex)

	*Running regressions to test mean differences 
	*Total carbohydrate intake 
	svy: reg in_carbo i.ado_sex
	*Carbohydrate intake PAH 
	svy: reg in_carbo_AH i.ado_sex
	*Carbohydrate intake POH 
	svy: reg in_carbo_OH i.ado_sex
	*% of carbohydrate PAH 
	svy: reg per_carbo_AH i.ado_sex
	*% of carbohydrate POH 
	svy: reg per_carbo_OH i.ado_sex

	*Fat intake
	svy: mean in_lipid, over(ado_sex)
	svy: mean in_lipid_AH, over(ado_sex)
	svy: mean in_lipid_OH, over(ado_sex)
	svy: mean per_lipid_AH, over(ado_sex)
	svy: mean per_lipid_OH, over(ado_sex)

	*Running regressions to test mean differences 
	*Total fat intake 
	svy: reg in_lipid i.ado_sex
	*Fat intake PAH 
	svy: reg in_lipid_AH i.ado_sex
	*Fat intake POH 
	svy: reg in_lipid_OH i.ado_sex
	*% of fat PAH 
	svy: reg per_lipid_AH i.ado_sex
	*% of fat POH 
	svy: reg per_lipid_OH i.ado_sex

	*Saturated fat
	svy: mean in_fatsat, over(ado_sex)
	svy: mean in_fatsat_AH, over(ado_sex)
	svy: mean in_fatsat_OH, over(ado_sex)
	svy: mean per_fatsat_AH, over(ado_sex)
	svy: mean per_fatsat_OH, over(ado_sex)

	*Running regressions to test mean differences 
	*Total saturated fat intake 
	svy: reg in_fatsat i.ado_sex
	*Saturated fat intake PAH 
	svy: reg in_fatsat_AH i.ado_sex
	*Saturated fat intake POH 
	svy: reg in_fatsat_OH i.ado_sex
	*% of saturated fat PAH 
	svy: reg per_fatsat_AH i.ado_sex
	*% of saturated fat POH 
	svy: reg per_fatsat_OH i.ado_sex

	*Sodium
	svy: mean in_na, over(ado_sex)
	svy: mean in_na_AH, over(ado_sex)
	svy: mean in_na_OH, over(ado_sex)
	svy: mean per_na_AH, over(ado_sex)
	svy: mean per_na_OH, over(ado_sex)

	*Running regressions to test mean differences 
	*Total sodium intake 
	svy: reg in_na i.ado_sex
	*Sodium intake PAH 
	svy: reg in_na_AH i.ado_sex
	*Sodium intake POH 
	svy: reg in_na_OH i.ado_sex
	*% of sodium PAH 
	svy: reg per_na_AH i.ado_sex
	*% of sodium POH 
	svy: reg per_na_OH i.ado_sex

	*Percentage of energy consumed from different meals by sex 
	*Breakfast 
	gen per_bf_in_energy_AH=(bf_in_energy_AH/bf_in_energy)*100 
	gen per_bf_in_energy_OH=(bf_in_energy_OH/bf_in_energy)*100 
	svy: mean bf_in_energy bf_in_energy_AH bf_in_energy_OH , over(ado_sex)
	svy: mean per_bf_in_energy_AH per_bf_in_energy_OH , over(ado_sex)
	*Lunch
	gen per_ln_in_energy_AH=(ln_in_energy_AH/ln_in_energy)*100 
	gen per_ln_in_energy_OH=(ln_in_energy_OH/ln_in_energy)*100 
	svy: mean per_ln_in_energy_AH per_ln_in_energy_OH, over(ado_sex)
	svy: mean ln_in_energy ln_in_energy_AH ln_in_energy_OH , over(ado_sex)
	*Dinner 
	gen per_din_in_energy_AH=(din_in_energy_AH/din_in_energy)*100 
	gen per_din_in_energy_OH=(din_in_energy_OH/din_in_energy)*100 
	svy: mean per_din_in_energy_AH per_din_in_energy_OH, over(ado_sex)
	svy: mean din_in_energy din_in_energy_AH din_in_energy_OH , over(ado_sex)
	*Snack
	gen per_snack_in_energy_AH=(snack_in_energy_AH/snack_in_energy)*100 
	gen per_snack_in_energy_OH=(snack_in_energy_OH/snack_in_energy)*100
	svy: mean per_snack_in_energy_AH per_snack_in_energy_OH, over(ado_sex)
	svy: mean snack_in_energy snack_in_energy_AH snack_in_energy_OH , over(ado_sex)

	*Running regressions to test mean differences
	*Total breakfast 
	svy: reg bf_in_energy i.ado_sex 
	*Breakfast PAH 
	svy: reg bf_in_energy_AH i.ado_sex 
	svy: reg per_bf_in_energy_AH i.ado_sex 
	*Breakfast POH 
	svy: reg bf_in_energy_OH i.ado_sex 
	svy: reg per_bf_in_energy_OH i.ado_sex 

	*Total lunch 
	svy: reg ln_in_energy i.ado_sex 
	*Lunch PAH 
	svy: reg ln_in_energy_AH i.ado_sex 
	svy: reg per_ln_in_energy_AH i.ado_sex
	*Lunch POH 
	svy: reg ln_in_energy_OH i.ado_sex 
	svy: reg per_ln_in_energy_OH i.ado_sex

	*Total dinner 
	svy: reg din_in_energy i.ado_sex 
	*Dinner PAH 
	svy: reg din_in_energy_AH i.ado_sex 
	svy: reg per_din_in_energy_AH i.ado_sex 
	*Dinner POH 
	svy: reg din_in_energy_OH i.ado_sex 
	svy: reg per_din_in_energy_OH i.ado_sex 

	*Total snack 
	svy: reg snack_in_energy i.ado_sex 
	*Snack PAH 
	svy: reg snack_in_energy_AH i.ado_sex 
	svy: reg per_snack_in_energy_AH i.ado_sex 
	*Snack POH 
	svy: reg snack_in_energy_OH i.ado_sex 
	svy: reg per_snack_in_energy_OH i.ado_sex

	** Export Sum-stat and Regression Table **
	gen white_space = .m 
	
	global outcomes		per_energy_AH per_energy_OH ///
						per_protein_AH per_protein_OH ///
						per_carbo_AH per_carbo_OH ///
						per_lipid_AH per_lipid_OH ///
						per_fatsat_AH per_fatsat_OH ///
						per_na_AH per_na_OH ///
						white_space ///
						in_energy in_energy_AH in_energy_OH ///
						in_protein in_protein_AH in_protein_OH ///
						in_carbo in_carbo_AH in_carbo_OH ///
						in_lipid in_lipid_AH in_lipid_OH ///
						in_fatsat in_fatsat_AH in_fatsat_OH ///
						in_na in_na_AH in_na_OH ///
						white_space ///
						bf_in_energy_AH bf_in_energy_OH ///
						ln_in_energy_AH ln_in_energy_OH ///
						din_in_energy_AH din_in_energy_OH ///
						snack_in_energy_AH snack_in_energy_OH ///
						white_space ///
						per_bf_in_energy_AH per_bf_in_energy_OH ///
						per_ln_in_energy_AH per_ln_in_energy_OH ///
						per_din_in_energy_AH per_din_in_energy_OH ///
						per_snack_in_energy_AH per_snack_in_energy_OH 
	
	* Sumstat by Geo Breakdown
	levelsof ado_sex, local(grp)
	
	foreach x in `grp' {
		
		preserve 
					
			keep if ado_sex == `x'
			
			keep $outcomes school_id
			
			do "$do/00_frequency_table"


			export excel $export_table 	using "$output/sumstat_output/SUMSTAT_Outputs.xlsx",  /// 
										sheet("s_tab_2 `x'") firstrow(varlabels) keepcellfmt sheetreplace 	
		
		restore 
		
	}
	
	* Prepare for regression model 		
	preserve 
		
		gen group_var = ado_sex 
		
		keep $outcomes school_id group_var
		
		do "$do/00_regression_table_with_svy.do"
		
		do "$do/00_alphabet_assignment.do"

		export excel using "$output/sumstat_output/SUMSTAT_Outputs.xlsx",  /// 
							sheet("model_s_tab_2") firstrow(varlabels) keepcellfmt sheetreplace 	
	
	restore 
	
	**#Figure 1
	*Percentage of energy consumed from different meals by residence 
	*Breakfast
	svy: mean per_bf_in_energy_AH per_bf_in_energy_OH, over(district)
	svy: mean bf_in_energy, over(district)
	svy: mean bf_in_energy_AH, over(district)
	svy: mean bf_in_energy_OH, over(district)
	*Lunch 
	svy: mean per_ln_in_energy_AH per_ln_in_energy_OH, over(district)
	svy: mean ln_in_energy, over(district)
	svy: mean ln_in_energy_AH, over(district)
	svy: mean ln_in_energy_OH, over(district)
	*Dinner 
	svy: mean per_din_in_energy_AH per_din_in_energy_OH, over(district)
	svy: mean din_in_energy, over(district)
	svy: mean din_in_energy_AH, over(district)
	svy: mean din_in_energy_OH, over(district)
	*Snack 
	svy: mean per_snack_in_energy_AH per_snack_in_energy_OH, over(district)
	svy: mean snack_in_energy, over(district)
	svy: mean snack_in_energy_AH, over(district)
	svy: mean snack_in_energy_OH, over(district)

	/*won't present this information
	**# Location of consumption 
	//egen con_energy_AH=rowtotal(in_energy_AH_AH in_energy_OH_AH)
	lab var con_energy_AH "Energy consumed at home"
	//egen con_energy_OH=rowtotal(in_energy_AH_OH in_energy_OH_OH)
	lab var con_energy_OH "Energy consumed outside home"
	*Percent of energy consumed at home 
	gen per_con_energy_AH=(con_energy_AH/in_energy)*100
	mean per_con_energy_AH 
	mean per_con_energy_AH, over(district)
	oneway per_con_energy_AH district, tab bonferroni 
	oneway per_con_energy_AH ado_sex, tab bonferroni 
	*Percent consumed outside home 
	gen per_con_energy_OH=(con_energy_OH/in_energy)*100
	mean per_con_energy_OH 
	mean per_con_energy_OH, over(district)
	oneway per_con_energy_OH district, tab bonferroni 
	oneway per_con_energy_OH ado_sex, tab bonferroni 
	*Percent prepared and consumed at home 
	gen per_con_energy_AH_AH=(in_energy_AH_AH/in_energy)*100 
	mean per_con_energy_AH_AH 
	mean per_con_energy_AH_AH, over(district)
	oneway per_con_energy_AH_AH district, tab bonferroni 
	oneway per_con_energy_AH_AH ado_sex, tab bonferroni 
	*Percent prepared at home and consumed outside home  
	gen per_con_energy_AH_OH=(in_energy_AH_OH/in_energy)*100 
	mean per_con_energy_AH_OH 
	mean per_con_energy_AH_OH, over(district)
	oneway per_con_energy_AH_OH district, tab bonferroni 
	oneway per_con_energy_AH_OH ado_sex, tab bonferroni 
	*Percent prepared and consumed outside home 
	gen per_con_energy_OH_OH=(in_energy_OH_OH/in_energy)*100 
	mean per_con_energy_OH_OH 
	mean per_con_energy_OH_OH, over(district)
	oneway per_con_energy_OH_OH district, tab bonferroni 
	oneway per_con_energy_OH_OH ado_sex, tab bonferroni 
	*Percent prepared outside home and consumed at home 
	gen per_con_energy_OH_AH=(in_energy_OH_AH/in_energy)*100 
	mean per_con_energy_OH_AH 
	mean per_con_energy_OH_AH, over(district)
	oneway per_con_energy_OH_AH district, tab bonferroni
	oneway per_con_energy_OH_AH ado_sex, tab bonferroni
	*Kcal by eating out location 
	mean con_energy_AH con_energy_OH 
	mean con_energy_AH con_energy_OH, over(district)
	mean con_energy_AH con_energy_OH, over(ado_sex)
	oneway con_energy_AH district, tab bonferroni 
	oneway con_energy_OH district, tab bonferroni 
	oneway con_energy_AH ado_sex, tab bonferroni 
	oneway con_energy_OH ado_sex, tab bonferroni 
	mean in_energy_AH_AH 
	mean in_energy_AH_AH, over(district)
	oneway in_energy_AH_AH district, tab bonferroni 
	mean in_energy_AH_AH, over(ado_sex)
	oneway in_energy_AH_AH ado_sex, tab bonferroni 
	mean in_energy_OH_AH 
	mean in_energy_OH_AH, over(district)
	mean in_energy_OH_AH, over(ado_sex)
	oneway in_energy_OH_AH district, tab bonferroni 
	oneway in_energy_OH_AH ado_sex, tab bonferroni 
	mean in_energy_AH_OH 
	mean in_energy_AH_OH, over(district)
	mean in_energy_AH_OH, over(ado_sex)
	oneway in_energy_AH_OH district, tab bonferroni
	oneway in_energy_AH_OH ado_sex, tab bonferroni
	mean in_energy_OH_OH 
	mean in_energy_OH_OH, over(district)
	mean in_energy_OH_OH, over(ado_sex)
	oneway in_energy_OH_OH district, tab bonferroni
	oneway in_energy_OH_OH ado_sex, tab bonferroni

	*Percent of energy consumed at home 
	mean per_con_energy_AH per_con_energy_OH, over(ado_sex)
	*Percent prepared and consumed at home  
	mean per_con_energy_AH_AH, over(ado_sex)
	*Percent prepared at home and consumed outside home   
	mean per_con_energy_AH_OH, over(ado_sex)
	*Percent prepared and consumed outside home 
	mean per_con_energy_OH_OH, over(ado_sex)
	*Percent prepared outside home and consumed at home 
	mean per_con_energy_OH_AH, over(ado_sex)

	*Kcal by eating out location 
	mean con_energy_AH con_energy_OH, over(ado_sex)
	mean in_energy_AH_AH, over(ado_sex)
	mean in_energy_OH_AH, over(ado_sex)
	mean in_energy_AH_OH, over(ado_sex)
	mean in_energy_OH_OH, over(ado_sex)


	**# GDQS-preparation and consumption 
	*Overall GDQS score 
	mean gdqs gdqs_AH gdqs_OH
	mean gdqs gdqs_AH gdqs_OH, over(district)
	*Healthy score 
	mean gdqs_h gdqs_h_AH gdqs_h_OH
	mean gdqs_h gdqs_h_AH gdqs_h_OH, over(district)
	*Unhealth score 
	mean gdqs_u gdqs_u_AH gdqs_u_OH
	mean gdqs_u gdqs_u_AH gdqs_u_OH, over(district)

	*GDQS by location of food preparation and consumption 
	mean gdqs_AH_AH gdqs_AH_OH gdqs_OH_AH gdqs_OH_OH
	mean gdqs_h_AH_AH gdqs_h_AH_OH gdqs_h_OH_AH gdqs_h_OH_OH
	mean gdqs_u_AH_AH gdqs_u_AH_OH gdqs_u_OH_AH gdqs_u_OH_OH

	mean gdqs_AH_AH gdqs_AH_OH gdqs_OH_AH gdqs_OH_OH, over(district)
	mean gdqs_h_AH_AH gdqs_h_AH_OH gdqs_h_OH_AH gdqs_h_OH_OH, over(district)
	mean gdqs_u_AH_AH gdqs_u_AH_OH gdqs_u_OH_AH gdqs_u_OH_OH, over(district)

	**# GDQS by location and consumption (sex) 
	mean gdqs_AH_AH gdqs_AH_OH gdqs_OH_AH gdqs_OH_OH, over(ado_sex)
	mean gdqs_h_AH_AH gdqs_h_AH_OH gdqs_h_OH_AH gdqs_h_OH_OH, over(ado_sex)
	mean gdqs_u_AH_AH gdqs_u_AH_OH gdqs_u_OH_AH gdqs_u_OH_OH, over(ado_sex)

	*/

	**# Table 3 - Nutrient density by residence 
	svy: mean den_calc den_iron den_zinc den_vita den_thia den_ribo den_nia den_vitb6 den_folate den_vitb12 den_vitc, over(district)
	svy: mean den_calc_AH den_iron_AH den_zinc_AH den_vita_AH den_thia_AH den_ribo_AH den_nia_AH den_vitb6_AH den_folate_AH den_vitb12_AH den_vitc_AH, over(district)
	svy: mean den_calc_OH den_iron_OH den_zinc_OH den_vita_OH den_thia_OH den_ribo_OH den_nia_OH den_vitb6_OH den_folate_OH den_vitb12_OH den_vitc_OH, over(district)


	**# Testing means by residence
	**Calcium 
	*Total 
	svy: reg den_calc i.district 
	svy: reg den_calc ib2.district
	*PAH
	svy: reg den_calc_AH i.district 
	svy: reg den_calc_AH ib2.district
	*POH 
	svy: reg den_calc_OH i.district 
	svy: reg den_calc_OH ib2.district

	*Iron 
	*Total 
	svy: reg den_iron i.district 
	svy: reg den_iron ib2.district
	*PAH
	svy: reg den_iron_AH i.district 
	svy: reg den_iron_AH ib2.district
	*POH 
	svy: reg den_iron_OH i.district 
	svy: reg den_iron_OH ib2.district

	*Zinc 
	*Total 
	svy: reg den_zinc i.district 
	svy: reg den_zinc ib2.district
	*PAH
	svy: reg den_zinc_AH i.district 
	svy: reg den_zinc_AH ib2.district
	*POH 
	svy: reg den_zinc_OH i.district 
	svy: reg den_zinc_OH ib2.district

	*Vitamin A 
	*Total 
	svy: reg den_vita i.district 
	svy: reg den_vita ib2.district
	*PAH
	svy: reg den_vita_AH i.district 
	svy: reg den_vita_AH ib2.district
	*POH 
	svy: reg den_vita_OH i.district 
	svy: reg den_vita_OH ib2.district

	*Thiamin 
	*Total 
	svy: reg den_thia i.district 
	svy: reg den_thia ib2.district
	*PAH
	svy: reg den_thia_AH i.district 
	svy: reg den_thia_AH ib2.district
	*POH 
	svy: reg den_thia_OH i.district 
	svy: reg den_thia_OH ib2.district

	*Riboflavin 
	*Total 
	svy: reg den_ribo i.district 
	svy: reg den_ribo ib2.district
	*PAH
	svy: reg den_ribo_AH i.district 
	svy: reg den_ribo_AH ib2.district
	*POH 
	svy: reg den_ribo_OH i.district 
	svy: reg den_ribo_OH ib2.district

	*Niacin 
	*Total 
	svy: reg den_nia i.district 
	svy: reg den_nia ib2.district
	*PAH
	svy: reg den_nia_AH i.district 
	svy: reg den_nia_AH ib2.district
	*POH 
	svy: reg den_nia_OH i.district 
	svy: reg den_nia_OH ib2.district

	*Vit B6 
	*Total 
	svy: reg den_vitb6 i.district 
	svy: reg den_vitb6 ib2.district
	*PAH
	svy: reg den_vitb6_AH i.district 
	svy: reg den_vitb6_AH ib2.district
	*POH 
	svy: reg den_vitb6_OH i.district 
	svy: reg den_vitb6_OH ib2.district

	*Folate 
	*Total 
	svy: reg den_folate i.district 
	svy: reg den_folate ib2.district
	*PAH
	svy: reg den_folate_AH i.district 
	svy: reg den_folate_AH ib2.district
	*POH 
	svy: reg den_folate_OH i.district 
	svy: reg den_folate_OH ib2.district

	*Vit B12 
	*Total 
	svy: reg den_vitb12 i.district 
	svy: reg den_vitb12 ib2.district
	*PAH
	svy: reg den_vitb12_AH i.district 
	svy: reg den_vitb12_AH ib2.district
	*POH 
	svy: reg den_vitb12_OH i.district 
	svy: reg den_vitb12_OH ib2.district

	*Vitamin C 
	*Total 
	svy: reg den_vitc i.district 
	svy: reg den_vitc ib2.district
	*PAH
	svy: reg den_vitc_AH i.district 
	svy: reg den_vitc_AH ib2.district
	*POH 
	svy: reg den_vitc_OH i.district 
	svy: reg den_vitc_OH ib2.district
	
	** Export Sum-stat and Regression Table **
	global outcomes	den_calc	den_calc_AH	den_calc_OH ///
					den_iron	den_iron_AH	den_iron_OH ///
					den_zinc	den_zinc_AH	den_zinc_OH ///
					den_vita	den_vita_AH	den_vita_OH ///
					den_thia	den_thia_AH	den_thia_OH ///
					den_ribo	den_ribo_AH	den_ribo_OH ///
					den_nia	den_nia_AH	den_nia_OH ///
					den_vitb6	den_vitb6_AH	den_vitb6_OH ///
					den_folate	den_folate_AH	den_folate_OH ///
					den_vitb12	den_vitb12_AH	den_vitb12_OH ///
					den_vitc	den_vitc_AH	den_vitc_OH
					
	* sumstat by Geo Breakdown
	levelsof district, local(geo)
	
	foreach x in `geo' {
		
		preserve 
					
			keep if district == `x'
			
			keep $outcomes school_id
			
			do "$do/00_frequency_table"


			export excel $export_table 	using "$output/sumstat_output/SUMSTAT_Outputs.xlsx",  /// 
										sheet("tab_3 `x'") firstrow(varlabels) keepcellfmt sheetreplace 	
		
		restore 
		
	}
	
	* Regression model 
	preserve 
		
		gen group_var = district
		
		keep $outcomes school_id group_var
		
		do "$do/00_regression_table_with_svy.do"
		
		do "$do/00_alphabet_assignment.do"

		export excel using "$output/sumstat_output/SUMSTAT_Outputs.xlsx",  /// 
							sheet("model_tab_3") firstrow(varlabels) keepcellfmt sheetreplace 	
	
	restore 

	**# Suppl Table 3 - Nutrient density by sex 
	svy: mean den_calc den_iron den_zinc den_vita den_thia den_ribo den_nia den_vitb6 den_folate den_vitb12 den_vitc, over(ado_sex)
	svy: mean den_calc_AH den_iron_AH den_zinc_AH den_vita_AH den_thia_AH den_ribo_AH den_nia_AH den_vitb6_AH den_folate_AH den_vitb12_AH den_vitc_AH, over(ado_sex)
	svy: mean den_calc_OH den_iron_OH den_zinc_OH den_vita_OH den_thia_OH den_ribo_OH den_nia_OH den_vitb6_OH den_folate_OH den_vitb12_OH den_vitc_OH, over(ado_sex)


	**# Testing median by adolescent sex 
	*Calcium 
	svy: reg den_calc i.ado_sex
	svy: reg den_calc_AH i.ado_sex
	svy: reg den_calc_OH i.ado_sex
	*Iron 
	svy: reg den_iron i.ado_sex
	svy: reg den_iron_AH i.ado_sex
	svy: reg den_iron_OH i.ado_sex
	*Zinc 
	svy: reg den_zinc i.ado_sex
	svy: reg den_zinc_AH i.ado_sex
	svy: reg den_zinc_OH i.ado_sex
	*Vitamin A 
	svy: reg den_vita i.ado_sex
	svy: reg den_vita_AH i.ado_sex
	svy: reg den_vita_OH i.ado_sex
	*Thiamin 
	svy: reg den_thia i.ado_sex
	svy: reg den_thia_AH i.ado_sex
	svy: reg den_thia_OH i.ado_sex
	*Riboflavin 
	svy: reg den_ribo i.ado_sex
	svy: reg den_ribo_AH i.ado_sex
	svy: reg den_ribo_OH i.ado_sex
	*Niacin 
	svy: reg den_nia i.ado_sex
	svy: reg den_nia_AH i.ado_sex
	svy: reg den_nia_OH i.ado_sex
	*Vitamin B6 
	svy: reg den_vitb6 i.ado_sex
	svy: reg den_vitb6_AH i.ado_sex
	svy: reg den_vitb6_OH i.ado_sex
	*Folate 
	svy: reg den_folate i.ado_sex
	svy: reg den_folate_AH i.ado_sex
	svy: reg den_folate_OH i.ado_sex
	*Vitamin B12 
	svy: reg den_vitb12 i.ado_sex
	svy: reg den_vitb12_AH i.ado_sex
	svy: reg den_vitb12_OH i.ado_sex
	*Vitamin C 
	svy: reg den_vitc i.ado_sex
	svy: reg den_vitc_AH i.ado_sex
	svy: reg den_vitc_OH i.ado_sex

	** Export Sum-stat and Regression Table **
	global outcomes	den_calc den_calc_AH den_calc_OH ///
					den_iron den_iron_AH den_iron_OH ///
					den_zinc den_zinc_AH den_zinc_OH ///
					den_vita den_vita_AH den_vita_OH ///
					den_thia den_thia_AH den_thia_OH ///
					den_ribo den_ribo_AH den_ribo_OH ///
					den_nia den_nia_AH den_nia_OH ///
					den_vitb6 den_vitb6_AH den_vitb6_OH ///
					den_folate den_folate_AH den_folate_OH ///
					den_vitb12 den_vitb12_AH den_vitb12_OH ///
					den_vitc den_vitc_AH den_vitc_OH
					
	* sumstat by Geo Breakdown
	levelsof ado_sex, local(grp)
	
	foreach x in `grp' {
		
		preserve 
					
			keep if ado_sex == `x'
			
			keep $outcomes school_id
			
			do "$do/00_frequency_table"


			export excel $export_table 	using "$output/sumstat_output/SUMSTAT_Outputs.xlsx",  /// 
										sheet("s_tab_3 `x'") firstrow(varlabels) keepcellfmt sheetreplace 	
		
		restore 
		
	}
	
	* Regression model 
	preserve 
		
		gen group_var = ado_sex
		
		keep $outcomes school_id group_var
		
		do "$do/00_regression_table_with_svy.do"
		
		do "$do/00_alphabet_assignment.do"

		export excel using "$output/sumstat_output/SUMSTAT_Outputs.xlsx",  /// 
							sheet("s_model_tab_3") firstrow(varlabels) keepcellfmt sheetreplace 	
	
	restore 
	
	**# Suppl Table 7: proportion consuming different GDQS food groups by residence
	*Citrus fruits 
	*prepared at home
	gen citrus_AH=0 
	replace citrus_AH=1 if weight_citrus_AH>0 & weight_citrus_AH!=.
	svy: mean citrus_AH, over(district) 
	//Testing differences 
	svy: reg citrus_AH i.district 
	svy: reg citrus_AH ib2.district 
	*prepared outside hime 
	gen citrus_OH=0 
	replace citrus_OH=1 if weight_citrus_OH>0 & weight_citrus_OH!=.
	svy:mean citrus_OH 
	//Testing differences 
	svy: reg citrus_OH i.district 
	svy: reg citrus_OH ib2.district
	*Deep orange fruits 
	*prepared at home
	gen orangef_AH=0 
	replace orangef_AH=1 if weight_orangef_AH>0 & weight_orangef_AH!=.
	svy: mean orangef_AH, over(district) 
	//Testing differences 
	svy: reg orangef_AH i.district 
	svy: reg orangef_AH ib2.district 
	*prepared outside home 
	gen orangef_OH=0 
	replace orangef_OH=1 if weight_orangef_OH>0 & weight_orangef_OH!=.
	svy: mean orangef_OH, over(district) 
	//Testing differences 
	svy: reg orangef_OH i.district 
	svy: reg orangef_OH ib2.district 

	*Other fruits 
	*prepared at home 
	gen otherf_AH=0 
	replace otherf_AH=1 if weight_otherf_AH>0 & weight_otherf_AH!=.
	svy: mean otherf_AH, over(district) 
	//Testing differences 
	svy: reg otherf_AH i.district 
	svy: reg otherf_AH ib2.district 
	*prepared outside home 
	gen otherf_OH=0 
	replace otherf_OH=1 if weight_otherf_OH>0 & weight_otherf_OH!=.
	svy: mean otherf_OH, over(district) 
	//Testing differences 
	svy: reg otherf_OH i.district 
	svy: reg otherf_OH ib2.district

	*DGLV 
	*prepared at home 
	gen dglv_AH=0 
	replace dglv_AH=1 if weight_dglv_AH>0 & weight_dglv_AH!=.
	svy: mean dglv_AH, over(district) 
	//Testing differences 
	svy: reg dglv_AH i.district 
	svy: reg dglv_AH ib2.district 
	*prepared outside home 
	gen dglv_OH=0 
	replace dglv_OH=1 if weight_dglv_OH>0 & weight_dglv_OH!=.
	svy: mean dglv_OH, over(district) 
	//Testing differences 
	svy: reg dglv_OH i.district 
	svy: reg dglv_OH ib2.district

	*Cruciferous vegetable 
	*prepared at home 
	gen crucveg_AH=0 
	replace crucveg_AH=1 if weight_crucveg_AH>0 & weight_crucveg_AH!=.
	svy: mean crucveg_AH, over(district)
	//Testing differences 
	svy: reg crucveg_AH i.district 
	svy: reg crucveg_AH ib2.district  
	*prepared outside home 
	gen crucveg_OH=0 
	replace crucveg_OH=1 if weight_crucveg_OH>0 & weight_crucveg_OH!=.
	svy: mean crucveg_OH, over(district)
	//Testing differences 
	svy: reg crucveg_OH i.district 
	svy: reg crucveg_OH ib2.district

	*Orange vegetables 
	*prepared at home 
	gen orangeveg_AH=0 
	replace orangeveg_AH=1 if weight_orangeveg_AH>0 & weight_orangeveg_AH!=.
	svy: mean orangeveg_AH, over(district)
	//Testing differences 
	svy: reg orangeveg_AH i.district 
	svy: reg orangeveg_AH ib2.district 
	*prepared outside home 
	gen orangeveg_OH=0 
	replace orangeveg_OH=1 if weight_orangeveg_OH>0 & weight_orangeveg_OH!=.
	svy: mean orangeveg_OH, over(district) 
	//Testing differences 
	svy: reg orangeveg_OH i.district 
	svy: reg orangeveg_OH ib2.district

	*Other vegetables 
	*prepared at home 
	gen otherveg_AH=0 
	replace otherveg_AH=1 if weight_otherveg_AH>0 & weight_otherveg_AH!=.
	svy: mean otherveg_AH, over(district)
	//Testing differences 
	svy: reg otherveg_AH i.district 
	svy: reg otherveg_AH ib2.district 
	*prepared outside home 
	gen otherveg_OH=0 
	replace otherveg_OH=1 if weight_otherveg_OH>0 & weight_otherveg_OH!=.
	svy: mean otherveg_OH, over(district) 
	//Testing differences 
	svy: reg otherveg_OH i.district 
	svy: reg otherveg_OH ib2.district 

	*Legumes 
	*prepared at home 
	gen legume_AH=0 
	replace legume_AH=1 if weight_legume_AH>0 & weight_legume_AH!=.
	svy: mean legume_AH, over(district) 
	//Testing differences 
	svy: reg legume_AH i.district 
	svy: reg legume_AH ib2.district 
	*prepared outside home 
	gen legume_OH=0 
	replace legume_OH=1 if weight_legume_OH>0 & weight_legume_OH!=.
	svy: mean legume_OH, over(district) 
	//Testing differences 
	svy: reg legume_OH i.district 
	svy: reg legume_OH ib2.district 

	*Orange tubers 
	*prepared at home 
	gen orangetub_AH=0 
	replace orangetub_AH=1 if weight_orangetub_AH>0 & weight_orangetub_AH!=.
	svy: mean orangetub_AH, over(district) 
	//Testing differences 
	svy: reg orangetub_AH i.district 
	svy: reg orangetub_AH ib2.district
	*prepared outside home 
	gen orangetub_OH=0 
	replace orangetub_OH=1 if weight_orangetub_OH>0 & weight_orangetub_OH!=.
	svy: mean orangetub_OH, over(district) 
	//Testing differences 
	svy: reg orangetub_OH i.district 
	svy: reg orangetub_OH ib2.district

	*Nuts and seeds 
	*prepared at home 
	gen nuts_AH=0 
	replace nuts_AH=1 if weight_nuts_AH>0 & weight_nuts_AH!=.
	svy: mean nuts_AH, over(district) 
	//Testing differences 
	svy: reg nuts_AH i.district 
	svy: reg nuts_AH ib2.district
	*prepared outside home 
	gen nuts_OH=0 
	replace nuts_OH=1 if weight_nuts_OH>0 & weight_nuts_OH!=.
	svy: mean nuts_OH, over(district) 
	//Testing differences 
	svy: reg nuts_OH i.district 
	svy: reg nuts_OH ib2.district

	*Whole grains 
	*prepared at home 
	gen grain_AH=0 
	replace grain_AH=1 if weight_grain_AH>0 & weight_grain_AH!=.
	svy: mean grain_AH, over(district) 
	//Testing differences 
	svy: reg grain_AH i.district 
	svy: reg grain_AH ib2.district
	*prepared outside home 
	gen grain_OH=0 
	replace grain_OH=1 if weight_grain_OH>0 & weight_grain_OH!=.
	svy: mean grain_OH, over(district)
	//Testing differences 
	svy: reg grain_OH i.district 
	svy: reg grain_OH ib2.district 

	*Liquid oil 
	*prepared at home 
	gen liqoil_AH=0 
	replace liqoil_AH=1 if weight_liqoil_AH>0 & weight_liqoil_AH!=.
	svy: mean liqoil_AH, over(district) 
	//Testing differences 
	svy: reg liqoil_AH i.district 
	svy: reg liqoil_AH ib2.district
	*prepared outside home 
	gen liqoil_OH=0 
	replace liqoil_OH=1 if weight_liqoil_OH>0 & weight_liqoil_OH!=.
	svy: mean liqoil_OH, over(district) 
	//Testing differences 
	svy: reg liqoil_OH i.district 
	svy: reg liqoil_OH ib2.district

	*Fish and shellfish 
	*prepared at home 
	gen fish_AH=0
	replace fish_AH=1 if weight_fish_AH>0 & weight_fish_AH!=. 
	svy: mean fish_AH , over(district)
	//Testing differences 
	svy: reg fish_AH i.district 
	svy: reg fish_AH ib2.district
	*prepared outside home 
	gen fish_OH=0
	replace fish_OH=1 if weight_fish_OH>0 & weight_fish_OH!=. 
	svy: mean fish_OH , over(district)
	//Testing differences 
	svy: reg fish_OH i.district 
	svy: reg fish_OH ib2.district

	*Poultry and game meat 
	*prepared at home 
	gen meat_AH=0
	replace meat_AH=1 if weight_meat_AH>0 & weight_meat_AH!=. 
	svy: mean meat_AH, over(district) 
	//Testing differences 
	svy: reg meat_AH i.district 
	svy: reg meat_AH ib2.district 
	*prepared outside home 
	gen meat_OH=0
	replace meat_OH=1 if weight_meat_OH>0 & weight_meat_OH!=. 
	svy: mean meat_OH, over(district) 
	//Testing differences 
	svy: reg meat_OH i.district 
	svy: reg meat_OH ib2.district

	*Low fat dairy 
	*prepared at home 
	gen lowdairy_AH=0
	replace lowdairy_AH=1 if weight_lowdairy_AH>0 & weight_lowdairy_AH!=. 
	svy: mean lowdairy_AH , over(district)
	//Testing differences 
	svy: reg lowdairy_AH i.district 
	svy: reg lowdairy_AH ib2.district 
	*prepared outside home 
	gen lowdairy_OH=0
	replace lowdairy_OH=1 if weight_lowdairy_OH>0 & weight_lowdairy_OH!=. 
	svy: mean lowdairy_OH , over(district)
	//Testing differences 
	svy: reg lowdairy_OH i.district 
	svy: reg lowdairy_OH ib2.district 

	*Eggs 
	*prepared at home
	gen egg_AH=0
	replace egg_AH=1 if weight_egg_AH>0 & weight_egg_AH!=. 
	svy: mean egg_AH, over(district) 
	//Testing differences 
	svy: reg egg_AH i.district 
	svy: reg egg_AH ib2.district 
	*prepared outside home 
	gen egg_OH=0
	replace egg_OH=1 if weight_egg_OH>0 & weight_egg_OH!=. 
	svy: mean egg_OH , over(district)
	//Testing differences 
	svy: reg egg_OH i.district 
	svy: reg egg_OH ib2.district 

	*High fat dairy 
	*prepared at home 
	gen highdairy_AH=0
	replace highdairy_AH=1 if weight_highdairy_AH>0 & weight_highdairy_AH!=. 
	svy: mean highdairy_AH, over(district)
	//Testing differences 
	svy: reg highdairy_AH i.district 
	svy: reg highdairy_AH ib2.district 
	*prepared outside home 
	gen highdairy_OH=0
	replace highdairy_OH=1 if weight_highdairy_OH>0 & weight_highdairy_OH!=. 
	svy: mean highdairy_OH, over(district)
	//Testing differences 
	svy: reg highdairy_OH i.district 
	svy: reg highdairy_OH ib2.district 


	*Red meat 
	*prepared at home 
	gen redmeat_AH=0
	replace redmeat_AH=1 if weight_redmeat_AH>0 & weight_redmeat_AH!=. 
	svy: mean redmeat_AH, over(district) 
	//Testing differences 
	svy: reg redmeat_AH i.district 
	svy: reg redmeat_AH ib2.district
	*prepared outside home 
	gen redmeat_OH=0
	replace redmeat_OH=1 if weight_redmeat_OH>0 & weight_redmeat_OH!=. 
	svy: mean redmeat_OH, over(district) 
	//Testing differences 
	svy: reg redmeat_OH i.district 
	svy: reg redmeat_OH ib2.district

	*Processed meat 
	*prepared at home 
	gen procmeat_AH=0
	replace procmeat_AH=1 if weight_procmeat_AH>0 & weight_procmeat_AH!=. 
	svy: mean procmeat_AH, over(district)
	//Testing differences 
	svy: reg procmeat_AH i.district 
	svy: reg procmeat_AH ib2.district
	*prepared outside home 
	gen procmeat_OH=0
	replace procmeat_OH=1 if weight_procmeat_OH>0 & weight_procmeat_OH!=. 
	svy: mean procmeat_OH, over(district)
	//Testing differences 
	svy: reg procmeat_OH i.district 
	svy: reg procmeat_OH ib2.district

	*Refined grain 
	*prepared at home 
	gen refgrain_AH=0
	replace refgrain_AH=1 if weight_refgrain_AH>0 & weight_refgrain_AH!=. 
	svy: mean refgrain_AH, over(district)
	//Testing differences 
	svy: reg refgrain_AH i.district 
	svy: reg refgrain_AH ib2.district
	*prepared outside home 
	gen refgrain_OH=0
	replace refgrain_OH=1 if weight_refgrain_OH>0 & weight_refgrain_OH!=. 
	svy: mean refgrain_OH, over(district)
	//Testing differences 
	svy: reg refgrain_OH i.district 
	svy: reg refgrain_OH ib2.district

	*Sweets and ice cream 
	*prepared at home 
	gen sweet_AH=0
	replace sweet_AH=1 if weight_sweet_AH>0 & weight_sweet_AH!=. 
	svy: mean sweet_AH, over(district)
	//Testing differences 
	svy: reg sweet_AH i.district 
	svy: reg sweet_AH ib2.district
	*prepared outside home 
	gen sweet_OH=0
	replace sweet_OH=1 if weight_sweet_OH>0 & weight_sweet_OH!=. 
	svy: mean sweet_OH , over(district)
	//Testing differences 
	svy: reg sweet_OH i.district 
	svy: reg sweet_OH ib2.district

	*SSB 
	*prepared at home 
	gen ssb_AH=0
	replace ssb_AH=1 if weight_ssb_AH>0 & weight_ssb_AH!=. 
	svy: mean ssb_AH, over(district)
	//Testing differences 
	svy: reg ssb_AH i.district 
	svy: reg ssb_AH ib2.district
	*prepared outside home 
	gen ssb_OH=0
	replace ssb_OH=1 if weight_ssb_OH>0 & weight_ssb_OH!=. 
	svy: mean ssb_OH , over(district)
	//Testing differences 
	svy: reg ssb_OH i.district 
	svy: reg ssb_OH ib2.district

	*Juice 
	*prepared at home 
	gen juice_AH=0
	replace juice_AH=1 if weight_juice_AH>0 & weight_juice_AH!=. 
	svy: mean juice_AH, over(district)
	//Testing differences 
	svy: reg juice_AH i.district 
	svy: reg juice_AH ib2.district
	*prepared outside home 
	gen juice_OH=0
	replace juice_OH=1 if weight_juice_OH>0 & weight_juice_OH!=. 
	svy: mean juice_OH, over(district) 
	//Testing differences 
	svy: reg juice_OH i.district 
	svy: reg juice_OH ib2.district

	*White roots and tubers 
	*prepared at home 
	gen whitetub_AH=0
	replace whitetub_AH=1 if weight_whitetub_AH>0 & weight_whitetub_AH!=. 
	svy: mean whitetub_AH, over(district) 
	//Testing differences 
	svy: reg whitetub_AH i.district 
	svy: reg whitetub_AH ib2.district
	*prepared outside home 
	gen whitetub_OH=0
	replace whitetub_OH=1 if weight_whitetub_OH>0 & weight_whitetub_OH!=. 
	svy: mean whitetub_OH , over(district)
	//Testing differences 
	svy: reg whitetub_OH i.district 
	svy: reg whitetub_OH ib2.district

	*Deep fried foods 
	*prepared at home 
	gen deepfried_AH=0
	replace deepfried_AH=1 if weight_deepfried_AH>0 & weight_deepfried_AH!=. 
	svy: mean deepfried_AH, over(district) 
	//Testing differences 
	svy: reg deepfried_AH i.district 
	svy: reg deepfried_AH ib2.district
	*prepared outside home 
	gen deepfried_OH=0
	replace deepfried_OH=1 if weight_deepfried_OH>0 & weight_deepfried_OH!=. 
	svy: mean deepfried_OH, over(district)
	//Testing differences 
	svy: reg deepfried_OH i.district 
	svy: reg deepfried_OH ib2.district

	
	** Export Sum-stat and Regression Table **
	global outcomes	per_energy_AH per_energy_OH ///
					citrus_AH citrus_OH orangef_AH orangef_OH otherf_AH otherf_OH dglv_AH dglv_OH crucveg_AH crucveg_OH orangeveg_AH orangeveg_OH otherveg_AH otherveg_OH legume_AH legume_OH orangetub_AH orangetub_OH nuts_AH nuts_OH grain_AH grain_OH liqoil_AH liqoil_OH fish_AH fish_OH meat_AH meat_OH lowdairy_AH lowdairy_OH egg_AH egg_OH highdairy_AH highdairy_OH redmeat_AH redmeat_OH procmeat_AH procmeat_OH refgrain_AH refgrain_OH sweet_AH sweet_OH ssb_AH ssb_OH juice_AH juice_OH whitetub_AH whitetub_OH deepfried_AH deepfried_OH
					
	* sumstat by Geo Breakdown
	levelsof district, local(geo)
	
	foreach x in `geo' {
		
		preserve 
					
			keep if district == `x'
			
			keep $outcomes school_id
			
			do "$do/00_frequency_table"


			export excel $export_table 	using "$output/sumstat_output/SUMSTAT_Outputs.xlsx",  /// 
										sheet("tab_4 `x'") firstrow(varlabels) keepcellfmt sheetreplace 	
		
		restore 
		
	}
	
	* Regression model 
	preserve 
	
		gen group_var = district
		
		keep $outcomes school_id group_var
		
		do "$do/00_regression_table_with_svy.do"
		
		do "$do/00_alphabet_assignment.do"

		export excel using "$output/sumstat_output/SUMSTAT_Outputs.xlsx",  /// 
							sheet("model_tab_4") firstrow(varlabels) keepcellfmt sheetreplace 	
	
	restore 
	
	
	**# Suppl Table 8: proportion consuming different GDQS food groups by sex
	*Citrus fruits 
	*prepared at home
	svy: mean citrus_AH, over(ado_sex)
	svy: reg citrus_AH i.ado_sex 
	*prepared outside hime 
	svy: mean citrus_OH, over(ado_sex)
	svy: reg citrus_OH i.ado_sex 

	*Deep orange fruits 
	*prepared at home
	svy: mean orangef_AH, over(ado_sex)
	svy: reg orangef_AH i.ado_sex 
	*prepared outside home 
	svy: mean orangef_OH, over(ado_sex)
	svy: reg orangef_OH i.ado_sex

	*Other fruits 
	*prepared at home 
	svy: mean otherf_AH, over(ado_sex)
	svy: reg otherf_AH i.ado_sex 
	*prepared outside home 
	svy: mean otherf_OH, over(ado_sex)
	svy: reg otherf_OH i.ado_sex 

	*DGLV 
	*prepared at home 
	svy: mean dglv_AH, over(ado_sex)
	svy: reg dglv_AH i.ado_sex 
	*prepared outside home 
	svy: mean dglv_OH, over(ado_sex)
	svy: reg dglv_OH i.ado_sex

	*Cruciferous vegetable 
	*prepared at home 
	svy: mean crucveg_AH, over(ado_sex)
	svy: reg crucveg_AH i.ado_sex
	*prepared outside home 
	svy: mean crucveg_OH, over(ado_sex)
	svy: reg crucveg_OH i.ado_sex

	*Orange vegetables 
	*prepared at home 
	svy: mean orangeveg_AH, over(ado_sex)
	svy: reg orangeveg_AH i.ado_sex
	*prepared outside home 
	svy: mean orangeveg_OH, over(ado_sex)
	svy: reg orangeveg_OH i.ado_sex

	*Other vegetables 
	*prepared at home 
	svy: mean otherveg_AH, over(ado_sex)
	svy: reg otherveg_AH i.ado_sex
	*prepared outside home 
	svy: mean otherveg_OH, over(ado_sex)
	svy: reg otherveg_OH i.ado_sex

	*Legumes 
	*prepared at home 
	svy: mean legume_AH, over(ado_sex)
	svy: reg legume_AH i.ado_sex
	*prepared outside home 
	svy: mean legume_OH, over(ado_sex)
	svy: reg legume_OH i.ado_sex

	*Orange tubers 
	*prepared at home 
	svy: mean orangetub_AH, over(ado_sex)
	svy: reg orangetub_AH i.ado_sex
	*prepared outside home 
	svy: mean orangetub_OH, over(ado_sex)
	svy: reg orangetub_OH i.ado_sex

	*Nuts and seeds 
	*prepared at home 
	svy: mean nuts_AH, over(ado_sex)
	svy: reg nuts_AH i.ado_sex
	*prepared outside home 
	svy: mean nuts_OH, over(ado_sex)
	svy: reg nuts_OH i.ado_sex

	*Whole grains 
	*prepared at home 
	svy: mean grain_AH, over(ado_sex)
	svy: reg grain_AH i.ado_sex
	*prepared outside home 
	svy: mean grain_OH, over(ado_sex)
	svy: reg grain_OH i.ado_sex

	*Liquid oil 
	*prepared at home 
	svy: mean liqoil_AH, over(ado_sex)
	svy: reg liqoil_AH i.ado_sex
	*prepared outside home 
	svy: mean liqoil_OH, over(ado_sex)
	svy: reg liqoil_OH i.ado_sex

	*Fish and shellfish 
	*prepared at home 
	svy: mean fish_AH, over(ado_sex)
	svy: reg fish_AH i.ado_sex
	*prepared outside home 
	svy: mean fish_OH, over(ado_sex)
	svy: reg fish_OH i.ado_sex

	*Poultry and game meat 
	*prepared at home 
	svy: mean meat_AH, over(ado_sex)
	svy: reg meat_AH i.ado_sex
	*prepared outside home 
	svy: mean meat_OH, over(ado_sex)
	svy: reg meat_OH i.ado_sex

	*Low fat dairy 
	*prepared at home 
	svy: mean lowdairy_AH, over(ado_sex)
	svy: reg lowdairy_AH i.ado_sex
	*prepared outside home 
	svy: mean lowdairy_OH, over(ado_sex)
	svy: reg lowdairy_OH i.ado_sex

	*Eggs 
	*prepared at home
	svy: mean egg_AH, over(ado_sex)
	svy: reg egg_AH i.ado_sex
	*prepared outside home 
	svy: mean egg_OH, over(ado_sex)
	svy: reg egg_OH i.ado_sex

	*High fat dairy 
	*prepared at home 
	svy: mean highdairy_AH, over(ado_sex)
	svy: reg highdairy_AH i.ado_sex
	*prepared outside home 
	svy: mean highdairy_OH, over(ado_sex)
	svy: reg highdairy_OH i.ado_sex

	*Red meat 
	*prepared at home 
	svy: mean redmeat_AH, over(ado_sex)
	svy: reg redmeat_AH i.ado_sex
	*prepared outside home 
	svy: mean redmeat_OH, over(ado_sex)
	svy: reg redmeat_OH i.ado_sex

	*Processed meat 
	*prepared at home 
	svy: mean procmeat_AH, over(ado_sex)
	svy: reg procmeat_AH i.ado_sex
	*prepared outside home 
	svy: mean procmeat_OH, over(ado_sex)
	svy: reg procmeat_OH i.ado_sex

	*Refined grain 
	*prepared at home 
	svy: mean refgrain_AH, over(ado_sex)
	svy: reg refgrain_AH i.ado_sex
	*prepared outside home 
	svy: mean refgrain_OH, over(ado_sex)
	svy: reg refgrain_OH i.ado_sex

	*Sweets and ice cream 
	*prepared at home 
	svy: mean sweet_AH, over(ado_sex)
	svy: reg sweet_AH i.ado_sex
	*prepared outside home 
	svy: mean sweet_OH, over(ado_sex)
	svy: reg sweet_OH i.ado_sex

	*SSB 
	*prepared at home 
	svy: mean ssb_AH, over(ado_sex)
	svy: reg ssb_AH i.ado_sex
	*prepared outside home 
	svy: mean ssb_OH, over(ado_sex)
	svy: reg ssb_OH i.ado_sex

	*Juice 
	*prepared at home 
	svy: mean juice_AH, over(ado_sex)
	svy: reg juice_AH i.ado_sex
	*prepared outside home 
	svy: mean juice_OH, over(ado_sex)
	svy: reg juice_OH i.ado_sex

	*White roots and tubers 
	*prepared at home 
	svy: mean whitetub_AH, over(ado_sex)
	svy: reg whitetub_AH i.ado_sex
	*prepared outside home 
	svy: mean whitetub_OH, over(ado_sex)
	svy: reg whitetub_OH i.ado_sex

	*Deep fried foods 
	*prepared at home 
	svy: mean deepfried_AH, over(ado_sex)
	svy: reg deepfried_AH i.ado_sex
	*prepared outside home 
	svy: mean deepfried_OH, over(ado_sex)
	svy: reg deepfried_OH i.ado_sex

	** Export Sum-stat and Regression Table **
	global outcomes	per_energy_AH per_energy_OH ///
					citrus_AH citrus_OH orangef_AH orangef_OH otherf_AH otherf_OH dglv_AH dglv_OH crucveg_AH crucveg_OH orangeveg_AH orangeveg_OH otherveg_AH otherveg_OH legume_AH legume_OH orangetub_AH orangetub_OH nuts_AH nuts_OH grain_AH grain_OH liqoil_AH liqoil_OH fish_AH fish_OH meat_AH meat_OH lowdairy_AH lowdairy_OH egg_AH egg_OH highdairy_AH highdairy_OH redmeat_AH redmeat_OH procmeat_AH procmeat_OH refgrain_AH refgrain_OH sweet_AH sweet_OH ssb_AH ssb_OH juice_AH juice_OH whitetub_AH whitetub_OH deepfried_AH deepfried_OH
					
	* sumstat by Geo Breakdown
	levelsof ado_sex, local(grp)
	
	foreach x in `grp' {
		
		preserve 
					
			keep if ado_sex == `x'
			
			keep $outcomes school_id
			
			do "$do/00_frequency_table"


			export excel $export_table 	using "$output/sumstat_output/SUMSTAT_Outputs.xlsx",  /// 
										sheet("s_tab_8 `x'") firstrow(varlabels) keepcellfmt sheetreplace 	
		
		restore 
		
	}
	
	* Regression model 
	preserve 
		
		gen group_var = ado_sex
		
		keep $outcomes school_id group_var
		
		do "$do/00_regression_table_with_svy.do"
		
		do "$do/00_alphabet_assignment.do"

		export excel using "$output/sumstat_output/SUMSTAT_Outputs.xlsx",  /// 
							sheet("s_model_tab_8") firstrow(varlabels) keepcellfmt sheetreplace 	
	
	restore 

	**# Table 5. GDQS and eating outside home 
	*Creating categories of energy consumed outside the home 
	//Categories for those who consume outside 
	/*
	xtile energy_OH_any=in_energy_OH if in_energy_OH!=0, nq(3)
	gen energy_OH_prep_all_cat=1 if in_energy_OH==0
	replace energy_OH_prep_all_cat=2 if energy_OH_any==1 
	replace energy_OH_prep_all_cat=3 if energy_OH_any==2 
	replace energy_OH_prep_all_cat=4 if energy_OH_any==3
	lab define energy_OH_prep_all_cat 1 "No energy from outside" 2 "Low OH" 3 "Moderate OH" 4 "High OH" 
	lab values energy_OH_prep_all_cat energy_OH_prep_all_cat
	*/
	svy: mean gdqs gdqs_h gdqs_u, over(energy_OH_prep_all_cat)
	/*
	oneway gdqs energy_OH_prep_all_cat, tab bonferroni 
	oneway gdqs_h energy_OH_prep_all_cat, tab bonferroni 
	oneway gdqs_u energy_OH_prep_all_cat, tab bonferroni 
	*/
	*Overall GDQS 
	svy: reg gdqs i.energy_OH_prep_all_cat 
	svy: reg gdqs ib2.energy_OH_prep_all_cat
	svy: reg gdqs ib3.energy_OH_prep_all_cat
	*GDQS healthy 
	svy: reg gdqs_h i.energy_OH_prep_all_cat 
	svy: reg gdqs_h ib2.energy_OH_prep_all_cat
	svy: reg gdqs_h ib3.energy_OH_prep_all_cat
	*GDQS unhealthy 
	svy: reg gdqs_u i.energy_OH_prep_all_cat 
	svy: reg gdqs_u ib2.energy_OH_prep_all_cat
	svy: reg gdqs_u ib3.energy_OH_prep_all_cat

	*Add MAR means for each OH category
	svy: mean ado_mar, over(energy_OH_prep_all_cat)
	svy: reg ado_mar i.energy_OH_prep_all_cat 
	svy: reg ado_mar ib2.energy_OH_prep_all_cat
	svy: reg ado_mar ib3.energy_OH_prep_all_cat
	
	** Export Sum-stat and Regression Table **
	global outcomes	gdqs gdqs_h gdqs_u ado_mar
					
	* sumstat by interested group Breakdown
	levelsof energy_OH_prep_all_cat, local(grp)
	
	foreach x in `grp' {
		
		preserve 
					
			keep if energy_OH_prep_all_cat == `x'
			
			keep $outcomes school_id
			
			do "$do/00_frequency_table"


			export excel $export_table 	using "$output/sumstat_output/SUMSTAT_Outputs.xlsx",  /// 
										sheet("tab_5 `x'") firstrow(varlabels) keepcellfmt sheetreplace 	
		
		restore 
		
	}
	
	* Regression model 
	preserve 
	
		gen group_var = energy_OH_prep_all_cat
		
		keep $outcomes school_id group_var
		
		do "$do/00_regression_table_with_svy.do"
		
		do "$do/00_alphabet_assignment.do"

		export excel using "$output/sumstat_output/SUMSTAT_Outputs.xlsx",  /// 
							sheet("model_tab_5") firstrow(varlabels) keepcellfmt sheetreplace 	
	
	restore 
	
	
	**#Table 6. Determinants of eating outside home
	ologit energy_OH_any i.ado_sex i.district c.ado_age i.adol_pock_money, vce (cluster school_id) or 

	**Another way to present could be by describing each tertile
	*Age
	svy: mean ado_age, over (energy_OH_prep_all_cat)
	//Testing mean differences 
	svy: reg ado_age i.energy_OH_prep_all_cat 
	svy: reg ado_age ib2.energy_OH_prep_all_cat 
	svy: reg ado_age ib3.energy_OH_prep_all_cat 
	*Sex
	tab energy_OH_prep_all_cat ado_sex, col row
	svy: reg ado_sex i.energy_OH_prep_all_cat 
	svy: reg ado_sex ib2.energy_OH_prep_all_cat 
	svy: reg ado_sex ib3.energy_OH_prep_all_cat 
	*District
	tab energy_OH_prep_all_cat district, col row
	tab district, gen(dist)
	//Testing mean differences (rural)
	svy: reg dist1 i.energy_OH_prep_all_cat 
	svy: reg dist1 ib2.energy_OH_prep_all_cat 
	svy: reg dist1 ib3.energy_OH_prep_all_cat 
	//Testing mean differences (peri-urban)
	svy: reg dist2 i.energy_OH_prep_all_cat 
	svy: reg dist2 ib2.energy_OH_prep_all_cat 
	svy: reg dist2 ib3.energy_OH_prep_all_cat 
	//Testing mean differences (urban)
	svy: reg dist3 i.energy_OH_prep_all_cat 
	svy: reg dist3 ib2.energy_OH_prep_all_cat 
	svy: reg dist3 ib3.energy_OH_prep_all_cat
	*Pocket money
	tab energy_OH_prep_all_cat adol_pock_money , col row
	svy: reg adol_pock_money i.energy_OH_prep_all_cat 
	svy: reg adol_pock_money ib2.energy_OH_prep_all_cat 
	svy: reg adol_pock_money ib3.energy_OH_prep_all_cat

	** Export Sum-stat and Regression Table **
	global outcomes	ado_age ado_female dist1 dist2 dist3 adol_pock_money
					
	* sumstat by interested group Breakdown
	levelsof energy_OH_prep_all_cat, local(grp)
	
	foreach x in `grp' {
		
		preserve 
					
			keep if energy_OH_prep_all_cat == `x'
			
			keep $outcomes school_id
			
			do "$do/00_frequency_table"


			export excel $export_table 	using "$output/sumstat_output/SUMSTAT_Outputs.xlsx",  /// 
										sheet("tab_6 `x'") firstrow(varlabels) keepcellfmt sheetreplace 	
		
		restore 
		
	}
	
	* Regression model 
	preserve 
	
		gen group_var = energy_OH_prep_all_cat
		
		keep $outcomes school_id group_var
		
		do "$do/00_regression_table_with_svy.do"
		
		do "$do/00_alphabet_assignment.do"


		export excel using "$output/sumstat_output/SUMSTAT_Outputs.xlsx",  /// 
							sheet("model_tab_6") firstrow(varlabels) keepcellfmt sheetreplace 	
	
	restore 
	
	
	**# Table 7. Regression models 
	*Categorize var week_day
	tab week_day
	gen weekday=week_day
	replace weekday=1 if week_day==1
	replace weekday=1 if week_day==2
	replace weekday=1 if week_day==3
	replace weekday=1 if week_day==4
	replace weekday=1 if week_day==5
	replace weekday=2 if week_day==6
	replace weekday=2 if week_day==7
	lab define weekday 1 "Weekday" 2 "Weekend"
	lab values weekday
	tab weekday

	*Check if age and energy intake association is linear
	twoway (scatter in_energy ado_age) (lowess in_energy ado_age)

	*4 categories 
	foreach x of varlist in_energy ado_mar { 
	reg `x' i.energy_OH_prep_all_cat i.district c.ado_age##i.ado_sex i.weekday, vce (cluster school_id)
	}

	*Model without age for GDQS
	foreach x of varlist gdqs_u gdqs_h gdqs  { 
	reg `x' i.energy_OH_prep_all_cat i.district i.ado_sex i.weekday, vce (cluster school_id)
	}


	**# Suppl Table 9: Decision on purchasing and consuming food 
	mean adol_decision_alone_AH adol_decision_alone_OH adol_decision_someone_AH adol_decision_someone_OH adol_decision_parent_AH adol_decision_parent_OH adol_decision_friend_AH adol_decision_friend_OH adol_decision_other_AH adol_decision_other_OH 
	*Rural
	mean adol_decision_alone_AH adol_decision_alone_OH adol_decision_someone_AH adol_decision_someone_OH adol_decision_parent_AH adol_decision_parent_OH adol_decision_friend_AH adol_decision_friend_OH adol_decision_other_AH adol_decision_other_OH if district==1
	*Peri-urban 
	mean adol_decision_alone_AH adol_decision_alone_OH adol_decision_someone_AH adol_decision_someone_OH adol_decision_parent_AH adol_decision_parent_OH adol_decision_friend_AH adol_decision_friend_OH adol_decision_other_AH adol_decision_other_OH if district==2
	*Urban 
	mean adol_decision_alone_AH adol_decision_alone_OH adol_decision_someone_AH adol_decision_someone_OH adol_decision_parent_AH adol_decision_parent_OH adol_decision_friend_AH adol_decision_friend_OH adol_decision_other_AH adol_decision_other_OH if district==3

	** Export Sum-stat and Regression Table **
	global outcomes	adol_decision_alone_AH adol_decision_alone_OH adol_decision_someone_AH adol_decision_someone_OH adol_decision_parent_AH adol_decision_parent_OH adol_decision_friend_AH adol_decision_friend_OH adol_decision_other_AH adol_decision_other_OH 
					
	* sumstat by Geo Breakdown
	levelsof district, local(grp)
	
	foreach x in `grp' {
		
		preserve 
					
			keep if district == `x'
			
			keep $outcomes school_id
			
			do "$do/00_frequency_table"

			export excel $export_table 	using "$output/sumstat_output/SUMSTAT_Outputs.xlsx",  /// 
										sheet("s_tab_9 `x'") firstrow(varlabels) keepcellfmt sheetreplace 	
		
		restore 
		
	}
	
	* Regression model 
	preserve 
		
		gen group_var = district
		
		keep $outcomes school_id group_var
		
		do "$do/00_regression_table_with_svy.do"
		
		do "$do/00_alphabet_assignment.do"

		export excel using "$output/sumstat_output/SUMSTAT_Outputs.xlsx",  /// 
							sheet("s_model_tab_9") firstrow(varlabels) keepcellfmt sheetreplace 	
	
	restore 
	
	
	**# Supplemental Table 5: Adolescents' intake of GDQS food groups by place of preparation and residence
	*Citrus fruits 
	svy: mean energy_citrus_AH energy_citrus_OH, over(district)
	//Testing differences 
	*At home 
	svy: reg energy_citrus_AH i.district 
	svy: reg energy_citrus_AH ib2.district 
	*Outside home 
	svy: reg energy_citrus_OH i.district 
	svy: reg energy_citrus_OH ib2.district 

	*Orange fruits 
	svy: mean energy_orangef_AH energy_orangef_OH, over(district)
	//Testing differences 
	*At home 
	svy: reg energy_orangef_AH i.district 
	svy: reg energy_orangef_AH ib2.district 
	*Outside home 
	svy: reg energy_orangef_OH i.district 
	svy: reg energy_orangef_OH ib2.district

	*Other fruits 
	svy: mean energy_otherf_AH energy_otherf_OH, over(district)
	//Testing differences 
	*At home 
	svy: reg energy_otherf_AH i.district 
	svy: reg energy_otherf_AH ib2.district 
	*Outside home 
	svy: reg energy_otherf_OH i.district 
	svy: reg energy_otherf_OH ib2.district

	*DGLV 
	svy: mean energy_dglv_AH energy_dglv_OH, over(district)
	//Testing differences 
	*At home 
	svy: reg energy_dglv_AH i.district 
	svy: reg energy_dglv_AH ib2.district 
	*Outside home 
	svy: reg energy_dglv_OH i.district 
	svy: reg energy_dglv_OH ib2.district

	*Cruciferous vegetables 
	svy: mean energy_crucveg_AH energy_crucveg_OH, over(district)
	//Testing differences 
	*At home 
	svy: reg energy_crucveg_AH i.district 
	svy: reg energy_crucveg_AH ib2.district 
	*Outside home 
	svy: reg energy_crucveg_OH i.district 
	svy: reg energy_crucveg_OH ib2.district

	*Orange vegetables 
	svy: mean energy_orangeveg_AH energy_orangeveg_OH, over(district)
	//Testing differences 
	*At home 
	svy: reg energy_orangeveg_AH i.district 
	svy: reg energy_orangeveg_AH ib2.district 
	*Outside home 
	svy: reg energy_orangeveg_OH i.district 
	svy: reg energy_orangeveg_OH ib2.district

	*Other vegetables 
	svy: mean energy_otherveg_AH energy_otherveg_OH, over(district)
	//Testing differences 
	*At home 
	svy: reg energy_otherveg_AH i.district 
	svy: reg energy_otherveg_AH ib2.district 
	*Outside home 
	svy: reg energy_otherveg_OH i.district 
	svy: reg energy_otherveg_OH ib2.district

	*Legumes 
	svy: mean energy_legume_AH energy_legume_OH, over(district)
	//Testing differences 
	*At home 
	svy: reg energy_legume_AH i.district 
	svy: reg energy_legume_AH ib2.district 
	*Outside home 
	svy: reg energy_legume_OH i.district 
	svy: reg energy_legume_OH ib2.district

	*Orange tubers 
	svy: mean energy_orangetub_AH energy_orangetub_OH, over(district)
	//Testing differences 
	*At home 
	svy: reg energy_orangetub_AH i.district 
	svy: reg energy_orangetub_AH ib2.district 
	*Outside home 
	svy: reg energy_orangetub_OH i.district 
	svy: reg energy_orangetub_OH ib2.district

	*Nuts and seeds 
	svy: mean energy_nuts_AH energy_nuts_OH, over(district)
	//Testing differences 
	*At home 
	svy: reg energy_nuts_AH i.district 
	svy: reg energy_nuts_AH ib2.district 
	*Outside home 
	svy: reg energy_nuts_OH i.district 
	svy: reg energy_nuts_OH ib2.district

	*Whole grains 
	svy: mean energy_grain_AH energy_grain_OH, over(district)
	//Testing differences 
	*At home 
	svy: reg energy_grain_AH i.district 
	svy: reg energy_grain_AH ib2.district 
	*Outside home 
	svy: reg energy_grain_OH i.district 
	svy: reg energy_grain_OH ib2.district

	*Liquid oil 
	svy: mean energy_liqoil_AH energy_liqoil_OH, over(district)
	//Testing differences 
	*At home 
	svy: reg energy_liqoil_AH i.district 
	svy: reg energy_liqoil_AH ib2.district 
	*Outside home 
	svy: reg energy_liqoil_OH i.district 
	svy: reg energy_liqoil_OH ib2.district

	*Fish and shellfish 
	svy: mean energy_fish_AH energy_fish_OH, over(district)
	//Testing differences 
	*At home 
	svy: reg energy_fish_AH i.district 
	svy: reg energy_fish_AH ib2.district 
	*Outside home 
	svy: reg energy_fish_OH i.district 
	svy: reg energy_fish_OH ib2.district

	*Poultry
	svy: mean energy_meat_AH energy_meat_OH, over(district)
	//Testing differences 
	*At home 
	svy: reg energy_meat_AH i.district 
	svy: reg energy_meat_AH ib2.district 
	*Outside home 
	svy: reg energy_meat_OH i.district 
	svy: reg energy_meat_OH ib2.district

	*Low fat dairy 
	svy: mean energy_lowdairy_AH energy_lowdairy_OH, over(district)
	//Testing differences 
	*At home 
	svy: reg energy_lowdairy_AH i.district 
	svy: reg energy_lowdairy_AH ib2.district 
	*Outside home 
	svy: reg energy_lowdairy_OH i.district 
	svy: reg energy_lowdairy_OH ib2.district

	*Eggs 
	svy: mean energy_egg_AH energy_egg_OH, over(district)
	//Testing differences 
	*At home 
	svy: reg energy_egg_AH i.district 
	svy: reg energy_egg_AH ib2.district 
	*Outside home 
	svy: reg energy_egg_OH i.district 
	svy: reg energy_egg_OH ib2.district

	*High fat dairy 
	svy: mean energy_highdairy_AH energy_highdairy_OH, over(district)
	//Testing differences 
	*At home 
	svy: reg energy_highdairy_AH i.district 
	svy: reg energy_highdairy_AH ib2.district 
	*Outside home 
	svy: reg energy_highdairy_OH i.district 
	svy: reg energy_highdairy_OH ib2.district

	*Red meat 
	svy: mean energy_redmeat_AH energy_redmeat_OH, over(district)
	//Testing differences 
	*At home 
	svy: reg energy_redmeat_AH i.district 
	svy: reg energy_redmeat_AH ib2.district 
	*Outside home 
	svy: reg energy_redmeat_OH i.district 
	svy: reg energy_redmeat_OH ib2.district

	*Processed meat 
	svy: mean energy_procmeat_AH energy_procmeat_OH, over(district)
	//Testing differences 
	*At home 
	svy: reg energy_procmeat_AH i.district 
	svy: reg energy_procmeat_AH ib2.district 
	*Outside home 
	svy: reg energy_procmeat_OH i.district 
	svy: reg energy_procmeat_OH ib2.district

	*Refined grain 
	svy: mean energy_refgrain_AH energy_refgrain_OH, over(district)
	//Testing differences 
	*At home 
	svy: reg energy_refgrain_AH i.district 
	svy: reg energy_refgrain_AH ib2.district 
	*Outside home 
	svy: reg energy_refgrain_OH i.district 
	svy: reg energy_refgrain_OH ib2.district


	*Sweets 
	svy: mean energy_sweet_AH energy_sweet_OH, over(district)
	//Testing differences 
	*At home 
	svy: reg energy_sweet_AH i.district 
	svy: reg energy_sweet_AH ib2.district 
	*Outside home 
	svy: reg energy_sweet_OH i.district 
	svy: reg energy_sweet_OH ib2.district

	*SSB
	svy: mean energy_ssb_AH energy_ssb_OH, over(district)
	//Testing differences 
	*At home 
	svy: reg energy_ssb_AH i.district 
	svy: reg energy_ssb_AH ib2.district 
	*Outside home 
	svy: reg energy_ssb_OH i.district 
	svy: reg energy_ssb_OH ib2.district

	*Juice 
	svy: mean energy_juice_AH energy_juice_OH, over(district)
	//Testing differences 
	*At home 
	svy: reg energy_juice_AH i.district 
	svy: reg energy_juice_AH ib2.district 
	*Outside home 
	svy: reg energy_juice_OH i.district 
	svy: reg energy_juice_OH ib2.district

	*White roots and tubers 
	svy: mean energy_whitetub_AH energy_whitetub_OH, over(district)
	//Testing differences 
	*At home 
	svy: reg energy_whitetub_AH i.district 
	svy: reg energy_whitetub_AH ib2.district 
	*Outside home 
	svy: reg energy_whitetub_OH i.district 
	svy: reg energy_whitetub_OH ib2.district

	*Deep fried foods 
	svy: mean energy_deepfried_AH energy_deepfried_OH, over(district)
	//Testing differences 
	*At home 
	svy: reg energy_deepfried_AH i.district 
	svy: reg energy_deepfried_AH ib2.district 
	*Outside home 
	svy: reg energy_deepfried_OH i.district 
	svy: reg energy_deepfried_OH ib2.district 

	** Export Sum-stat and Regression Table **
	global outcomes	energy_citrus_AH energy_citrus_OH ///
					energy_orangef_AH energy_orangef_OH ///
					energy_otherf_AH energy_otherf_OH ///
					energy_dglv_AH energy_dglv_OH ///
					energy_crucveg_AH energy_crucveg_OH ///
					energy_orangeveg_AH energy_orangeveg_OH ///
					energy_otherveg_AH energy_otherveg_OH ///
					energy_legume_AH energy_legume_OH ///
					energy_orangetub_AH energy_orangetub_OH ///
					energy_nuts_AH energy_nuts_OH ///
					energy_grain_AH energy_grain_OH ///
					energy_liqoil_AH energy_liqoil_OH ///
					energy_fish_AH energy_fish_OH ///
					energy_meat_AH energy_meat_OH ///
					energy_lowdairy_AH energy_lowdairy_OH ///
					energy_egg_AH energy_egg_OH ///
					energy_highdairy_AH energy_highdairy_OH ///
					energy_redmeat_AH energy_redmeat_OH ///
					energy_procmeat_AH energy_procmeat_OH ///
					energy_refgrain_AH energy_refgrain_OH ///
					energy_sweet_AH energy_sweet_OH ///
					energy_ssb_AH energy_ssb_OH ///
					energy_juice_AH energy_juice_OH ///
					energy_whitetub_AH energy_whitetub_OH ///
					energy_deepfried_AH energy_deepfried_OH 
					
	* sumstat by Geo Breakdown
	levelsof district, local(grp)
	
	foreach x in `grp' {
		
		preserve 
					
			keep if district == `x'
			
			keep $outcomes school_id
			
			do "$do/00_frequency_table"


			export excel $export_table 	using "$output/sumstat_output/SUMSTAT_Outputs.xlsx",  /// 
										sheet("s_tab_5 `x'") firstrow(varlabels) keepcellfmt sheetreplace 	
		
		restore 
		
	}
	
	* Regression model 
	preserve 
		
		gen group_var = district
		
		keep $outcomes school_id group_var
		
		do "$do/00_regression_table_with_svy.do"
		
		do "$do/00_alphabet_assignment.do"

		export excel using "$output/sumstat_output/SUMSTAT_Outputs.xlsx",  /// 
							sheet("s_model_tab_5") firstrow(varlabels) keepcellfmt sheetreplace 	
	
	restore 
	
	**# Supplemental Table 6: Adolescents' energy intake (kcal/day) of GDQS food groups by place of preparation and sex
	*Citrus fruits 
	svy: mean energy_citrus_AH energy_citrus_OH, over(ado_sex)
	//Testing differences 
	*At home 
	svy: reg energy_citrus_AH i.ado_sex 
	*Outside home 
	svy: reg energy_citrus_OH i.ado_sex 

	*Orange fruits 
	svy: mean energy_orangef_AH energy_orangef_OH, over(ado_sex)
	//Testing differences 
	*At home 
	svy: reg energy_orangef_AH i.ado_sex 
	*Outside home 
	svy: reg energy_orangef_OH i.ado_sex 

	*Other fruits 
	svy: mean energy_otherf_AH energy_otherf_OH, over(ado_sex)
	//Testing differences 
	*At home 
	svy: reg energy_otherf_AH i.ado_sex 
	*Outside home 
	svy: reg energy_otherf_OH i.ado_sex 

	*DGLV 
	svy: mean energy_dglv_AH energy_dglv_OH, over(ado_sex)
	//Testing differences 
	*At home 
	svy: reg energy_dglv_AH i.ado_sex 
	*Outside home 
	svy: reg energy_dglv_OH i.ado_sex 

	*Cruciferous vegetables 
	svy: mean energy_crucveg_AH energy_crucveg_OH, over(ado_sex)
	//Testing differences 
	*At home 
	svy: reg energy_crucveg_AH i.ado_sex 
	*Outside home 
	svy: reg energy_crucveg_OH i.ado_sex 

	*Orange vegetables 
	svy: mean energy_orangeveg_AH energy_orangeveg_OH, over(ado_sex)
	//Testing differences 
	*At home 
	svy: reg energy_orangeveg_AH i.ado_sex 
	*Outside home 
	svy: reg energy_orangeveg_OH i.ado_sex 

	*Other vegetables 
	svy: mean energy_otherveg_AH energy_otherveg_OH, over(ado_sex)
	//Testing differences 
	*At home 
	svy: reg energy_otherveg_AH i.ado_sex 
	*Outside home 
	svy: reg energy_otherveg_OH i.ado_sex 

	*Legumes 
	svy: mean energy_legume_AH energy_legume_OH, over(ado_sex)
	//Testing differences 
	*At home 
	svy: reg energy_legume_AH i.ado_sex 
	*Outside home 
	svy: reg energy_legume_OH i.ado_sex 

	*Orange tubers 
	svy: mean energy_orangetub_AH energy_orangetub_OH, over(ado_sex)
	//Testing differences 
	*At home 
	svy: reg energy_orangetub_AH i.ado_sex 
	*Outside home 
	svy: reg energy_orangetub_OH i.ado_sex 

	*Nuts and seeds 
	svy: mean energy_nuts_AH energy_nuts_OH, over(ado_sex)
	//Testing differences 
	*At home 
	svy: reg energy_nuts_AH i.ado_sex 
	*Outside home 
	svy: reg energy_nuts_OH i.ado_sex 

	*Whole grains 
	svy: mean energy_grain_AH energy_grain_OH, over(ado_sex)
	//Testing differences 
	*At home 
	svy: reg energy_grain_AH i.ado_sex 
	*Outside home 
	svy: reg energy_grain_OH i.ado_sex 

	*Liquid oil 
	svy: mean energy_liqoil_AH energy_liqoil_OH, over(ado_sex)
	//Testing differences 
	*At home 
	svy: reg energy_liqoil_AH i.ado_sex 
	*Outside home 
	svy: reg energy_liqoil_OH i.ado_sex 

	*Fish and shellfish 
	svy: mean energy_fish_AH energy_fish_OH, over(ado_sex)
	//Testing differences 
	*At home 
	svy: reg energy_fish_AH i.ado_sex 
	*Outside home 
	svy: reg energy_fish_OH i.ado_sex 

	*Poultry
	svy: mean energy_meat_AH energy_meat_OH, over(ado_sex)
	//Testing differences 
	*At home 
	svy: reg energy_meat_AH i.ado_sex 
	*Outside home 
	svy: reg energy_meat_OH i.ado_sex 

	*Low fat dairy 
	svy: mean energy_lowdairy_AH energy_lowdairy_OH, over(ado_sex)
	//Testing differences 
	*At home 
	svy: reg energy_lowdairy_AH i.ado_sex 
	*Outside home 
	svy: reg energy_lowdairy_OH i.ado_sex 

	*Eggs 
	svy: mean energy_egg_AH energy_egg_OH, over(ado_sex)
	//Testing differences 
	*At home 
	svy: reg energy_egg_AH i.ado_sex 
	*Outside home 
	svy: reg energy_egg_OH i.ado_sex 

	*High fat dairy 
	svy: mean energy_highdairy_AH energy_highdairy_OH, over(ado_sex)
	//Testing differences 
	*At home 
	svy: reg energy_highdairy_AH i.ado_sex 
	*Outside home 
	svy: reg energy_highdairy_OH i.ado_sex 

	*Red meat 
	svy: mean energy_redmeat_AH energy_redmeat_OH, over(ado_sex)
	//Testing differences 
	*At home 
	svy: reg energy_redmeat_AH i.ado_sex 
	*Outside home 
	svy: reg energy_redmeat_OH i.ado_sex 

	*Processed meat 
	svy: mean energy_procmeat_AH energy_procmeat_OH, over(ado_sex)
	//Testing differences 
	*At home 
	svy: reg energy_procmeat_AH i.ado_sex 
	*Outside home 
	svy: reg energy_procmeat_OH i.ado_sex 

	*Refined grain 
	svy: mean energy_refgrain_AH energy_refgrain_OH, over(ado_sex)
	//Testing differences 
	*At home 
	svy: reg energy_refgrain_AH i.ado_sex 
	*Outside home 
	svy: reg energy_refgrain_OH i.ado_sex 

	*Sweets 
	svy: mean energy_sweet_AH energy_sweet_OH, over(ado_sex)
	//Testing differences 
	*At home 
	svy: reg energy_sweet_AH i.ado_sex 
	*Outside home 
	svy: reg energy_sweet_OH i.ado_sex  

	*SSB
	svy: mean energy_ssb_AH energy_ssb_OH, over(ado_sex)
	//Testing differences 
	*At home 
	svy: reg energy_ssb_AH i.ado_sex 
	*Outside home 
	svy: reg energy_ssb_OH i.ado_sex  

	*Juice 
	svy: mean energy_juice_AH energy_juice_OH, over(ado_sex)
	//Testing differences 
	*At home 
	svy: reg energy_juice_AH i.ado_sex 
	*Outside home 
	svy: reg energy_juice_OH i.ado_sex 

	*White roots and tubers 
	svy: mean energy_whitetub_AH energy_whitetub_OH, over(ado_sex)
	//Testing differences 
	*At home 
	svy: reg energy_whitetub_AH i.ado_sex 
	*Outside home 
	svy: reg energy_whitetub_OH i.ado_sex 

	*Deep fried foods 
	svy: mean energy_deepfried_AH energy_deepfried_OH, over(ado_sex)
	//Testing differences 
	*At home 
	svy: reg energy_deepfried_AH i.ado_sex 
	*Outside home 
	svy: reg energy_deepfried_OH i.ado_sex  
	
	
	** Export Sum-stat and Regression Table **
	global outcomes	energy_citrus_AH energy_citrus_OH ///
					energy_orangef_AH energy_orangef_OH ///
					energy_otherf_AH energy_otherf_OH ///
					energy_dglv_AH energy_dglv_OH ///
					energy_crucveg_AH energy_crucveg_OH ///
					energy_orangeveg_AH energy_orangeveg_OH ///
					energy_otherveg_AH energy_otherveg_OH ///
					energy_legume_AH energy_legume_OH ///
					energy_orangetub_AH energy_orangetub_OH ///
					energy_nuts_AH energy_nuts_OH ///
					energy_grain_AH energy_grain_OH ///
					energy_liqoil_AH energy_liqoil_OH ///
					energy_fish_AH energy_fish_OH ///
					energy_meat_AH energy_meat_OH ///
					energy_lowdairy_AH energy_lowdairy_OH ///
					energy_egg_AH energy_egg_OH ///
					energy_highdairy_AH energy_highdairy_OH ///
					energy_redmeat_AH energy_redmeat_OH ///
					energy_procmeat_AH energy_procmeat_OH ///
					energy_refgrain_AH energy_refgrain_OH ///
					energy_sweet_AH energy_sweet_OH ///
					energy_ssb_AH energy_ssb_OH ///
					energy_juice_AH energy_juice_OH ///
					energy_whitetub_AH energy_whitetub_OH ///
					energy_deepfried_AH energy_deepfried_OH 
					
	* sumstat by Geo Breakdown
	levelsof ado_sex, local(grp)
	
	foreach x in `grp' {
		
		preserve 
					
			keep if ado_sex == `x'
			
			keep $outcomes school_id
			
			do "$do/00_frequency_table"


			export excel $export_table 	using "$output/sumstat_output/SUMSTAT_Outputs.xlsx",  /// 
										sheet("s_tab_6 `x'") firstrow(varlabels) keepcellfmt sheetreplace 	
		
		restore 
		
	}
	
	* Regression model 
	preserve 
		
		gen group_var = district
		
		keep $outcomes school_id group_var
		
		do "$do/00_regression_table_with_svy.do"
		
		do "$do/00_alphabet_assignment.do"

		export excel using "$output/sumstat_output/SUMSTAT_Outputs.xlsx",  /// 
							sheet("s_model_tab_6") firstrow(varlabels) keepcellfmt sheetreplace 	
	
	restore 
