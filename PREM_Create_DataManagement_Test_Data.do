clear
clear matrix
clear mata
capture log close
set more off
numlabel, add

* Date of the PREM questionniare version: Questionnaire_8SEPT2023_WORKING
*	https://worldhealthorg-my.sharepoint.com/:w:/r/personal/banicag_who_int/_layouts/15/Doc.aspx?sourcedoc=%7BA1DE21BB-2BD1-4F22-B36B-4B4EBC0AE145%7D&file=Questionnaire_8SEPT2023_WORKING.docx&wdLOR=c2F996D4A-4A15-9D4B-A8F6-4242767CAB35&action=default&mobileredirect=true
* Date of last code update: 12/07/2023
*	https://github.com/yoonjoung/WHO_PREM
*	https://github.com/yoonjoung/WHO_PREM/blob/main/PREM_Pilot_DataManagement_WORKING.do

*This code creates practice datasets for PREMs analysis 

*  DATA IN:	
*		1. CSV file daily downloaded from Limesurvey for Ghana

*  DATA OUT: 
*		1. CSV file daily downloaded for practice 

**************************************************************
* A. SETTING 
**************************************************************

*** Directory for this do file 
global mydir "~/Dropbox/0iSquared/iSquared_WHO/PREM/Methods/4_DataAnalysis/"
cd $mydir

*** Directory for downloaded CSV data (can be same or different from the main directory)
global downloadcsvdir "$mydir/PilotExportedCSV_FromLimeSurvey/"

*** Directory for ghana 
global ghanamydir "~/Dropbox/0iSquared/iSquared_WHO/PREM/Methods/4_DataAnalysis/Workshop/PREM_DM_Pilot_Workshop_Ghana/"

*** Directory for ghana downloaded CSV data (can be same or different from the main directory)
global ghanadownloadcsvdir "$ghanamydir/PilotExportedCSV_FromLimeSurvey/"
dir $ghanadownloadcsvdir

**************************************************************
* B. CREATE TEST DATASETS
**************************************************************

*****B.1. Import raw data from LimeSurvey which was doanlowded as CSV. Save that as a test data 

*********** COUNTRY LANGUAGE 1
import delimited "$ghanadownloadcsvdir/LimeSurvey_PREM_Ghana_RP_ENGLISH_3Jan2024.csv", case(preserve) clear 
	
	d, short		
	d Q001 Q4*
	tab Q001 Q401, m
		
	drop Q100a Q100b Q100ab Q102 Q134 Q135 Q2* Q401
	{
		rename  Q103  Q102
		rename  Q104  Q103
		rename  Q105  Q104
		rename  Q106  Q105
		rename  Q107  Q106
		rename  Q108  Q107
		rename  Q109  Q108
		rename  Q110  Q109
		rename  Q111  Q110
		rename  Q112  Q111
		rename  Q113  Q112
		rename  Q114  Q113
		rename  Q115  Q114
		rename  Q116  Q115
		rename  Q117  Q116
		rename  Q118  Q117
		rename  Q119  Q118
		rename  Q120  Q119
		rename  Q121  Q120
		rename  Q122  Q121
		rename  Q123  Q122
		rename  Q124  Q123
		rename  Q125  Q124

		rename  Q129  Q129OLD
		rename  Q130  Q130OLD
		rename  Q126  Q126OLD
		rename  Q127  Q127OLD
		rename  Q128  Q128OLD
		
		rename  Q129OLD  Q125
		rename  Q130OLD  Q126
		rename  Q126OLD  Q127
		rename  Q127OLD  Q128
		rename  Q128OLD  Q129
		
		rename  Q132  Q130
		rename  Q131  Q131
		rename  Q133  Q132
		rename  Q136  Q133
		rename  Q137  Q134
		
		rename Q301 Q201
		rename Q302 Q202 
		rename Q303 Q203 
		rename Q402 Q301
		rename Q403a Q302a
		rename Q403b Q302b
	}

	replace Q105 ="A5" if Q105 =="A6"
	replace Q119 ="A5" if Q119 =="A6"
	
	replace A006 = A005
	
	duplicates tag A004 A005 A007, gen(duplicate) 
			
		gen double submitdatetemp 	= clock(submitdate, "YMD hms") 
		format submitdatetemp %tc 
	
		egen double submitdatelatest  = max(submitdatetemp) if duplicate!=0, by(A004 A005 A007) /*LATEST TIME WITHIN EACH DUPLICATE*/	
			*format %tcnn/dd/ccYY_hh:MM submitdatelatest /*"format line without seconds*/
			format %tcnn/dd/ccYY_hh:MM:SS submitdatelatest /*"format line with seconds*/
			sort A004 A005 A007 submitdate			
			*list A004 A005 A007 submitdate* if duplicate!=0  						
			
	drop if duplicate!=0  & submitdatetemp!=submitdatelatest 
	
	drop duplicate submitdatetemp submitdatelatest
	
export delimited using "$downloadcsvdir/LimeSurvey_PREM_EXAMPLE_R1_Lang1.csv", replace

********** COUNTRY LANGUAGE 2
import delimited "$ghanadownloadcsvdir/LimeSurvey_PREM_Ghana_RP_Twi_3Jan2024.csv", case(preserve) clear 

	d, short
	d Q001 Q4*	
	tab Q001 Q401, m
	
		/* IF THERE IS A FORMAT DIFFERENCE*/ 		
		foreach var of varlist Q001 Q401 {	
			replace `var' = usubinstr(`var', "A", "", 1) 
			destring `var', replace 
			recode `var' 2=0 
			}
		/* EDIT ENDS*/ 	
	
	drop Q100a Q100b Q100ab Q102 Q134 Q135 Q2* Q401
	{
		rename  Q103  Q102
		rename  Q104  Q103
		rename  Q105  Q104
		rename  Q106  Q105
		rename  Q107  Q106
		rename  Q108  Q107
		rename  Q109  Q108
		rename  Q110  Q109
		rename  Q111  Q110
		rename  Q112  Q111
		rename  Q113  Q112
		rename  Q114  Q113
		rename  Q115  Q114
		rename  Q116  Q115
		rename  Q117  Q116
		rename  Q118  Q117
		rename  Q119  Q118
		rename  Q120  Q119
		rename  Q121  Q120
		rename  Q122  Q121
		rename  Q123  Q122
		rename  Q124  Q123
		rename  Q125  Q124

		rename  Q129  Q129OLD
		rename  Q130  Q130OLD
		rename  Q126  Q126OLD
		rename  Q127  Q127OLD
		rename  Q128  Q128OLD
		
		rename  Q129OLD  Q125
		rename  Q130OLD  Q126
		rename  Q126OLD  Q127
		rename  Q127OLD  Q128
		rename  Q128OLD  Q129
		
		rename  Q132  Q130
		rename  Q131  Q131
		rename  Q133  Q132
		rename  Q136  Q133
		rename  Q137  Q134
		
		rename Q301 Q201
		rename Q302 Q202 
		rename Q303 Q203 
		rename Q402 Q301
		rename Q403a Q302a
		rename Q403b Q302b
	}

	replace Q105 ="A5" if Q105 =="A6"
	replace Q119 ="A5" if Q119 =="A6"
	
	replace A006 = A005
	
	duplicates tag A004 A005 A007, gen(duplicate) 
			
		gen double submitdatetemp 	= clock(submitdate, "YMD hms") 
		format submitdatetemp %tc 
	
		egen double submitdatelatest  = max(submitdatetemp) if duplicate!=0, by(A004 A005 A007) /*LATEST TIME WITHIN EACH DUPLICATE*/	
			*format %tcnn/dd/ccYY_hh:MM submitdatelatest /*"format line without seconds*/
			format %tcnn/dd/ccYY_hh:MM:SS submitdatelatest /*"format line with seconds*/
			sort A004 A005 A007 submitdate			
			*list A004 A005 A007 submitdate* if duplicate!=0  						
			
	drop if duplicate!=0  & submitdatetemp!=submitdatelatest 
	
	drop duplicate submitdatetemp submitdatelatest

export delimited using "$downloadcsvdir/LimeSurvey_PREM_EXAMPLE_R1_Lang2.csv", replace
		
END OF DATA CLEANING AND MANAGEMENT 
