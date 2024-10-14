*****C.6. Label values 
	
	*****************************	
	* Section 1 
	*****************************
	
	#delimit;	
	global varlist_5 "
		     q102      q104 q105 
		q106 q107           q110 
		q111 q112 q113 q114 q115
		" ;
		#delimit cr
		
	global varlist_5na "q103 q108 q109" /*RESPONSE OPTION FOR "N/A" like */
	global varlist_rate5 "q116"
	
	sum $varlist_5
	sum $varlist_5na
	sum $varlist_rate5
			
	#delimit;		
	lab define howmany
		1 "1.None"
		2 "2.Once"
		3 "3.Twice"
		4 "4.Three times"
		5 "5.Four times"
		6 "6.Five times or more"	
		;
	lab values q101 howmany; 
	
	lab define varlist_5
		1 "1.Never"
		2 "2.Rarely"
		3 "3.Sometimes"
		4 "4.Often"
		5 "5.Always"
		;
	foreach var of varlist $varlist_5 {;		
	lab values `var' varlist_5; 
	};
	
	lab define varlist_5na
		1 "1.Never"
		2 "2.Rarely"
		3 "3.Sometimes"
		4 "4.Often"
		5 "5.Always"
		6 "6.N/A"
		;
	foreach var of varlist $varlist_5na {;		
	lab values `var' varlist_5na; 
	};
	
	lab define varlist_rate5
		1 "1.Very bad"
		2 "2.Bad"
		3 "3.Moderate"
		4 "4.Good"
		5 "5.Very good"
		;
	foreach var of varlist $varlist_rate5 {;		
	lab values `var' varlist_rate5; 
	};	
		
	#delimit cr

*****E.1. Construct analysis variables 
	
	*****************************
	* Section 1: Items 
	*****************************
	
	***** 1. [First contact] 
	
		gen y_fc_soon = q102
		gen y_fc_pc = q103
			/*RECODE NA*/
			*I do not have a usual primary care professional 6
			recode y_fc_pc 6=.
			
		sum y_fc_*
		
	***** 2. [Continuity]

		gen y_cont_familiar = q104
		gen y_cont_allinfo = q105
		
		sum y_cont_*
					
	***** 3. [Comprehensiveness]
	
		gen y_comp_info = q106
		gen y_comp_emo = q107
			
		sum y_comp_*			
			
	***** 4. [Coordination]

		gen y_coor_other = q108
			/*RECODE NA*/
			*Not applicable, I did not receive care from other professionals 6
			recode y_coor_other 6=.		
		gen y_coor_allinfo = q109
			/*RECODE NA*/
			*Not applicable, I was never referred to other professionals………………………...6
			recode y_coor_allinfo 6=.			

		sum y_coor_*		
						
	***** 5. [Patient centred care]

		gen y_pcc_respect = q110
		gen y_pcc_care = q111
			
		sum y_pcc_*
	
	***** 6. [Care planning]
	
		gen y_cp_agree = q112
		gen y_cp_follow = q113
	
		sum y_cp_*
	
	***** 6. [Professional competence]
		gen y_prof_understand = q114
		gen y_prof_lang = q115
				
		sum y_prof_*

	***** 8. [Overall experience]
	
		gen y_overall = q116
	
		sum y_overall

*END OF DO FILE FOR PREMs ITEMS		
