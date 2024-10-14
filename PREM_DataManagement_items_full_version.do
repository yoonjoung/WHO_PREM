*****C.6. Label values 
	
	*****************************	
	* Section 1 
	*****************************
	
	#delimit;	
	global varlist_5 "
		     q102 q103      q105 
		q106 q107 q108 q109 q110 
		               q114 q115 
		q116 q117 q118 q119 q120
		q121 q122 q123 q124 q125
			 q127 q128 q129 q130
		q131 q132 q133 
		" ;
		#delimit cr
		
	global varlist_5na "q104 q111 q112 q113" /*RESPONSE OPTION FOR "N/A" like */
	global varlist_rate5 "q134"
	global varlist_rate5na "q126"
	
	sum $varlist_5
	sum $varlist_5na
	sum $varlist_rate5
	sum $varlist_rate5na
			
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
	
	lab define varlist_rate5na
		1 "1.Very bad"
		2 "2.Bad"
		3 "3.Moderate"
		4 "4.Good"
		5 "5.Very good"
		6 "6.N/A"
		;
	foreach var of varlist $varlist_rate5na {;		
	lab values `var' varlist_rate5na; 
	};		
		
	#delimit cr

*****E.1. Construct analysis variables 
	
	*****************************
	* Section 1: Items 
	*****************************
	
	***** 1. [First contact] 
	
		gen y_fc_soon = q102
		gen y_fc_notdiff_rev = q103
			/*REVERSE ORDER*/			
			recode y_fc_notdiff_rev (1=5) (2=4) (3=3) (4=2) (5=1)
		gen y_fc_pc = q104
			/*RECODE NA*/
			*I do not have a usual primary care professional 6
			recode y_fc_pc 6=.
		gen y_fc_cost_rev = q133 
			/*REVERSE ORDER*/			
			recode y_fc_cost_rev (1=5) (2=4) (3=3) (4=2) (5=1) 
			
		sum y_fc_*
		
	***** 2. [Continuity]
	
		gen y_cont_usual = q105
		gen y_cont_familiar = q106
		gen y_cont_allinfo = q107
		gen y_cont_follow = q108
		
		sum y_cont_*
					
	***** 3. [Comprehensiveness]
	
		gen y_comp_info = q109
		gen y_comp_emo = q110
		gen y_comp_home = q111
			/*RECODE NA*/
			*I did not need any home visit 6
			recode y_comp_home 6=.
			
		sum y_comp_*			
			
	***** 4. [Coordination]

		gen y_coor_other = q112
			/*RECODE NA*/
			*Not applicable, I did not receive care from other professionals 6
			recode y_coor_other 6=.		
		gen y_coor_allinfo = q113
			/*RECODE NA*/
			*Not applicable, I was never referred to other professionals………………………...6
			recode y_coor_allinfo 6=.			

		sum y_coor_*		
						
	***** 5. [Patient centred care]
	
		gen y_pcc_choiceclinic = q114
		gen y_pcc_choicepcp = q115
		gen y_pcc_convtime = q116
		gen y_pcc_confidence = q117
		gen y_pcc_confi = q118
		gen y_pcc_privacy = q119
		gen y_pcc_respect = q120
		gen y_pcc_care = q121
		gen y_pcc_enoughtime = q122
		gen y_pcc_considerall = q123
		gen y_pcc_involve = q124
		gen y_pcc_others = q125
		gen y_pcc_env = q126
			/*RECODE NA*/
			*I have not visited a primary care clinic in the previous 12 months 6
			recode y_pcc_env 6=.
			
		sum y_pcc_*
	
	***** 6. [Care planning]
	
		gen y_cp_agree = q127
		gen y_cp_follow = q128
		gen y_cp_goal = q129
	
		sum y_cp_*
	
	***** 6. [Professional competence]
		gen y_prof_understand = q130
		gen y_prof_lang = q131
		gen y_prof_skills = q132
				
		sum y_prof_*

	***** 8. [Overall experience]
	
		gen y_overall = q134
	
		sum y_overall

*END OF DO FILE FOR PREMs ITEMS		
