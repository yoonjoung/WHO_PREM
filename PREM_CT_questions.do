clear
clear matrix
clear mata
capture log close
set more off
numlabel, add

* Date of the PREM COGNITIVE TEST questionniare version: 
*	Cognitive test questionnaire for_Observer_5Oct2023_track.docx
* 	https://worldhealthorg-my.sharepoint.com/:w:/r/personal/banicag_who_int/_layouts/15/Doc.aspx?sourcedoc=%7B1606E60E-3CC1-41E2-89D7-8F6B8762AABF%7D&file=Cognitive%20test%20questionnaire%20for_Observer_5Oct2023_track.docx&action=default&mobileredirect=true
*	https://github.com/yoonjoung/WHO_PREM

*This code 
*1) imports and cleans MOCK interview dataset from Lime Survey, and 
*2) reshape and export data in excel for easier review 
*3) creates summary note with figures in word

*  DATA IN:	
*		1. Cognitive test data directly downloaded from Limesurvey 	

*  DATA OUT: 
*		1. raw data downloaded from Limesurvey, saved in CSV as is 
*		2. reshaped (long) data for question-by-question review
*		3. cleaned data with additional analytical/assessment variables
*		4. summary estimates of overview measures 

*  NOTE OUT 
*		1. WORD DOC with summary figures

/* TABLE OF CONTENTS*/

* A. SETTING <<<<<<<<<<========== MUST BE ADAPTED: directories and local macro

* B. Import and drop duplicate cases
*****B.1. Import raw data from LimeSurvey 
*****B.2. Export/save the data daily in CSV form with date 
*****B.4. Drop duplicate cases 

* C. Cleaning - variables
*****C.1. Change var names to lowercase
*****C.2. Assess and drop timestamp data, as needed 
*****C.3. Change var names 
*****C.4. Consolidate interview result variable Q403
*****C.5. Find non-numeric variables and desting 
*****C.6. Label values 

* D. Expand and scramble the mock data <= DELETE THIS SECTION WHEN WORKING WITH REAL DATA

* E. Create analytical variables 
*****E.1. Construct analysis variables 
*****E.2. Export clean person-level data to excel 
*****E.3. Reshpae to LONG person-question level data 
*****E.4. Export LONG person-question level data to excel 

* F. Create and export indicator estimate data 
*****F.1. Calculate estimates 

* G. Generate report

**************************************************************
* A. SETTING 
**************************************************************

*** Directory for this do file 
global mydir "~/Dropbox/0iSquared/iSquared_WHO/PREM/Methods/5_DataAnalysisCognitiveTest/"
cd $mydir

**************************************************************
* B. Import and drop duplicate cases
**************************************************************

*****B.1. Import questions 
import excel "Cognitive test questionnaire for_Observer_5Oct2023_track.xlsx", sheet("Sheet1") firstrow clear
	
	d, short

	keep q*
	
		rename qual3 qual5
		rename qual2 qual4
		rename qual1 qual3
		rename qual0 qual2
		rename question qual1

*****B.2. Reshape 
reshape long qual , i(q_num) j(q_numsub)

		*replace q_num  = strtrim(q_num) 
		rename qual question

	drop if question==""
			
			capture drop temp*
			/*
			gen temp1  = substr(question, 1, strpos(question, "?"))  
			gen temp2  = substr(question, 1, strpos(question, "."))  
			
			codebook question
			replace question = temp1 if temp1!=""
			replace question = temp2 if temp1==""
			codebook question
			*/
		gen q_sub = ""
			replace q_sub = "" if q_numsub==1
			replace q_sub = "qual" if q_numsub==2
			replace q_sub = "qual1" if q_numsub==3
			replace q_sub = "qual2" if q_numsub==4
			replace q_sub = "qual3" if q_numsub==5
		
			capture drop temp*
			gen temp1 = "q"
			gen temp2 = "_"
		egen qnum = concat(temp1 q_num temp2 q_sub)

	
			capture drop temp*
			gen temp1 = substr(qnum, -1, .) 
			tab temp1		
			gen temp2 = substr(qnum, 1, strlen(qnum) - 1)
		replace qnum = temp2 if temp1=="_"
		
	drop if strpos(qnum, "Inst")>0	
	drop if strpos(qnum, "comment")>0	
		
	keep qnum question
	order qnum question
	
	browse

export excel using "Cognitive test questionnaire for_Observer_5Oct2023_track.xlsx", sheet("Sheet2") sheetreplace firstrow(variables)

save PREM_CT_questions.dta, replace

END OF DO FILE
