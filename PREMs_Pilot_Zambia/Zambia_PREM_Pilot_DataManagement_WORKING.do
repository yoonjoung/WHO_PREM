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

*This code 
*1) imports and cleans dataset from Lime Survey, and 
*2) creates indicator estimate data for dashboards and chartbook. 
*		=====> First PURPLE Tab in Chartbook: "PREMs_estimates"
*3) conducts minimum data quality check 

*  DATA IN:	
*		1. CSV file daily downloaded from Limesurvey 	
*		2. facility sample information in Chartbook (ORANGE TAB)

*  DATA OUT: 
*		1. raw data (as is, downloaded from Limesurvey) 
*			=> CSV, dta, and GREEN TAB in Chartbook   	
*		2. cleaned data with additional analytical variables in Chartbook and, 
*			for further analyses, as a datafile 
*			=> CSV, dta, and BLUE TAB in Chartbook 
*		3. summary estimates of indicators in Chartbook and as a datafile 	
*			=> CSV, dta, and the first PURPLE TAB in Chartbook 

*  NOTE OUT (log file for minimum data quality check)  
*		1. DataCheck_CombinedCOVID19HFA_`country'_R`round'_$date.log


/* TABLE OF CONTENTS*/

* A. SETTING <<<<<<<<<<========== MUST BE ADAPTED: directories and local macro

* B. Import and drop duplicate cases
*****B.1. Import raw data from LimeSurvey 
*****B.2. Export/save the data daily in CSV form with date 
*****B.3. Export Raw Respondent-level data to chartbook (GREEN TAB)
*****B.4. Drop duplicate cases 

* C. Cleaning - variables
*****C.1. Change var names to lowercase
*****C.2. Assess and drop timestamp data, as needed 
*****C.3. Change var names 
*****C.4. Consolidate interview result variable Q403
*****C.5. Find non-numeric variables and desting 
*****C.6. Label values 
*****C.7. Prepare for merge with facility information  

* D. Merge with facility information 
*****D.1. Merge with facility information 
*****D.2. More cleaning 

* D.A. Expand and scramble the mock data <<<<<<<<<<== DELETE THIS SECTION WHEN WORKING WITH REAL DATA

* E. Create analytical variables 
*****E.0. Drop data that were entered for practice and test <<<<<<<<<<== ACTIVATE THIS SECTION
*****E.1. Construct analysis variables 
*****E.2. Export Clean Respondent-level data to chartbook (BLUE TAB)

* F. Create and export indicator estimate data 
*****F.1. Calculate estimates 
*****F.2. Export indicator estimate data to chartbook (PURPLE TAB) and for dashboard

* G. MINIMUM data quality check 

**************************************************************
* A. SETTING 
**************************************************************

*** Directory for this do file 
global mydir "~/Dropbox/0iSquared/iSquared_WHO/PREM/Methods/4_DataAnalysis/Workshop/PREM_DM_Zambia/"
cd $mydir

*** Directory for downloaded CSV data (can be same or different from the main directory)
global downloadcsvdir "$mydir/PilotExportedCSV_FromLimeSurvey/"

*** Define a directory for the chartbook (can be same or different from the main directory)
global chartbookdir "$mydir"

*** Define a directory for processed data files (can be same or different from the main directory)
global datadir "$mydir/PilotDataProduced/"

*** Define a directory for stata log files (can be same or different from the main directory)
global datanotedir "$mydir/PilotDataNote/"

*** Define local macro for the survey 
local country	 		 Zambia /*country name*/	
local round 			 P /*round*/		
local year 			 	 2023 /*year of the mid point in data collection*/	
local month 			 12 /*month of the mid point in data collection*/	

local surveyid_EN 		 189817 /*LimeSurvey survey ID for ENGLISH form*/
local surveyid_CL 		 469495 /*LimeSurvey survey ID for BEMBA form*/

local startdate 	 	 20231216 /*First date of the actual interview - in YYYYMMDD */ 

*** Define local macro for response options specific to the country 

local countrylanguage1	 Bemba /*Country language 1*/

/*Study district names: must match with district code in ORANGE tab*/
local geoname1	 		 Lusaka
local geoname2	 		 Chilanga
local geoname3	 		 Kapiri Mposhi
local geoname4	 		 Mkushi

/*Facility type: must match with facility_type numeric code in ORANGE tab*/
local type1 			 District Hospital /*Facility type*/
local type2 			 Health Center 
local type3 			 Health Post
		
*** local macro for analysis (no change needed)  
local today		= c(current_date)
local c_today	= "`today'"
global date		= subinstr("`c_today'", " ", "",.)

**************************************************************
* B. Import and drop duplicate cases
**************************************************************

*****B.1. Import raw data from LimeSurvey 
import delimited using "https://extranet.who.int/dataformv3/index.php/plugins/direct?plugin=CountryOverview&docType=1&sid=`surveyid_EN'&language=en&function=createExport", case(preserve) clear
export delimited using "$downloadcsvdir/LimeSurvey_PREM_`country'_R`round'_ENGLISH_$date.csv", replace

	d, short	
	d Q001 Q4*
	tab Q001 Q401, m
	gen limesurveyform = "English"	
	save temp.dta, replace

import delimited using "https://extranet.who.int/dataformv3/index.php/plugins/direct?plugin=CountryOverview&docType=1&sid=`surveyid_CL'&language=en&function=createExport", case(preserve) clear
export delimited using "$downloadcsvdir/LimeSurvey_PREM_`country'_R`round'_BEMBA_$date.csv", replace
	
	d, short
	d Q001 Q4*	
	tab Q001 Q401, m
	gen limesurveyform = "`countrylanguage1'"
	
		/* ZAMBIA SPECIFIC EDIT STARTS*/ 
		*change format if Q001
		foreach var of varlist Q001 Q401 {	
			replace `var' = usubinstr(`var', "A", "", 1) 
			destring `var', replace 
			recode `var' 2=0 
			}
		/* EDIT ENDS*/ 	
			
	append using temp.dta, 
	
		tab limesurveyform, m
		tab limesurveyform Q001, m
		bysort limesurveyform: tab Q001 Q403a, m	
		
*****B.2. Export/save the data daily in CSV form with date 	

* export delimited using "$downloadcsvdir/LimeSurvey_PREM_`country'_R`round'_$date.csv", replace
* See above, now we export dataset by language 12/18/2023

* EDIT 1/4/2024: previously section E.0.	
*****B.3.A. Drop data that were entered for practice and test <= ACTIVATE THIS SECTION WHEN WORKING WITH REAL DATA

	codebook A002
	gen double interviewdate 	= dofc(clock(A002, "YMD hms")) 
	format interviewdate  %td
	
		tab interviewdate, m
		
	drop if interviewdate < date("`startdate'","YMD") 
		tab interviewdate, m

* EDIT 1/4/2024: new section
*****B.3.B. Edit data 
/* 
Background: 
Sample-number (A007) was not unique anymore in cases from 
the ADDITIONAL listing/sampling done after the first phase of data collection. UGH...
This CAN incorrectly determine unique case as a duplicate 

Suggested solution:
After further investigation (see Zambia_PREM_Pilot_PREP_FOR_DATAEIT.do), 
once combined with district and facilityid, 
we could save 17 by replacing sample_number (A007 = A007 + 9000, something outside the current range).

Action: 
Identification and recoding is done in a separate do file. 

Limitations: 
This approach is a bandage first aid, rather than systematic fix - which would take 
much longer time but still would have uncertainty. 
It focuses on not losing completed interviews. 

Note: this does not mean the FINAL total number of completed interviews will go up by 17,  
because we lose some during the merge process - due to data entry errors in facilityid 
*/

egen temp=concat(A004 A005 A007)
codebook A007 temp
drop temp

do Zambia_PREM_Pilot_DataManagement_WORKING_DATAEDIT.do

egen temp=concat(A004 A005 A007)
codebook A007 temp
drop temp

*****B.3. Export the data to chartbook  	

	/*MASK idenitifiable information for respondents/interviewers.*/
	*Interviewer name 
	foreach var of varlist Q002SQ001comment {
		replace `var'=""
		}		
		
export excel using "$chartbookdir/Zambia_PREM_Pilot_Chartbook_WORKING.xlsx", sheet("Client_raw_data") sheetreplace firstrow(variables) nolabel

	/*
	This data would have all sampled cases:
	For FTF, the dataset will grow as list/enrollment is going 
	For Phone interviews, the dataset will have all sampled cases -
	even when interviewers have not called them yet or 
	even when interviewers refused to participate 
	
	check against limesurvey. see how it will be structured...
	*/
		
*****B.4. Drop duplicate cases 

	* B.4.1 check variables with "id" in their names
		lookfor *id
		
		*****CHECK HERE: 
		codebook *id 	
		*	this is an ID variable generated by LimeSurvey, not client ID
		*	do not use it for analysis 
		*	still there should be no missing	
	
	* B.4.2 check rows with all missing values
		ds
		egen nvarmiss = rowmiss(`r(varlist)')
		d, short	
		gen allmissing = nvarmiss==`r(k)'
		*****CHECK HERE: 
		tab allmissing, m
		*	there should be 0, but
		*	drop if any rows that are completely missing 
		drop if allmissing==1
		drop nvarmiss allmissing
	
	* B.4.3 check duplicates, based on unique ID variables for clients
		duplicates tag A004 A005  A007, gen(duplicate) 
		
		*****CHECK HERE: 	
		tab duplicate, m		
		*	there should be no 1 or higher 
		* 	if there is any, 
		*	the following will identify the latest entry for the duplicates
		*	In the mock dataset, 
		*	there are two clients that have three data entries for practice purpose. 
			
			/* 
			* must check string value "mask" in the "clock" line for submitdate, 
			*		depending on the format/structure of the string var submitdate 
			*		use the correct specification
			* REFERENCE: https://www.stata.com/manuals13/u24.pdf
			* REFERENCE: https://www.stata.com/manuals13/ddatetime.pdf#ddatetime
			*/
			
			*** 1. check specification
			rename submitdate submitdate_string	/*rename to str*/		
			codebook submitdate_string /*identify format/structure of the string*/
			
			*** 2. clock
			gen double submitdate 	= clock(submitdate_string, "YMD hms") 
			*gen double submitdate 	= clock(submitdate_string, "MD20Y hms") /*if 2-digit year*/ 
			*gen double submitdate 	= clock(submitdate_string, "MDY hm") /*if no second*/ 
			
			*** 3. format
			format submitdate %tc 
			list submitdate* in 1/5			
				
		sort A004 A005  A007 submitdate
		list A004 A005  A007 submitdate if duplicate!=0  
		*****CHECK HERE: 
		*	check submitdate within each repeated client, 
		*	Again, in the mock dataset, 
		*	there are two clients that have three data entries for practice purpose. 

		*****drop duplicates before the latest submission 
		egen double submitdatelatest = max(submitdate) if duplicate!=0, ///
			by(A004 A005  A007) /*LATEST TIME WITHIN EACH DUPLICATE*/					
						
			*format %tcnn/dd/ccYY_hh:MM submitdatelatest /*"format line without seconds*/
			format %tcnn/dd/ccYY_hh:MM:SS submitdatelatest /*"format line with seconds*/
			
			sort A004 A005  A007 submitdate
			list A004 A005  A007 submitdate* if duplicate!=0  
			
	* B.4.f drop duplicates
	
		drop if duplicate!=0  & submitdate!=submitdatelatest 
		
		*****confirm there's no duplicate cases, based on facility code
		duplicates report A004 A005  A007,
		*****CHECK HERE: 
		*	Now there should be no duplicate, yay!!   

		drop duplicate submitdatelatest

**************************************************************
* C. Data cleaning - variables 
**************************************************************

*****C.1. Change var names to lowercase
 
	rename *, lower

*****C.2. Assess and drop timestamp data, as needed 

	capture drop *time* 
	*interviewtime is availabl in dataset only when directly downloaded from the server, not via export plug-in used in this code
	*So, just do not deal with interview time for now. 

*****C.3. Change var names 

	*to drop odd elements "y" "sq" - because of Lime survey's naming convention 

	/*
	rename (*sq*) (*_*) 		
	rename (q201_*_a1) (q201_*_a)
	rename (q201_*_a2) (q201_*_b)
	rename (q503*) (q503_0*)
		
	lookfor sq
	lookfor a
	lookfor b
	
	lookfor other /* We have only two questions where text entry for other is allowed*/ 
	*/

*****C.4. Consolidate interview result variable Q403 - 

	gen q403=""
		*replace q403 = q403b if a001=="A1" /*PHONE*/
		*replace q403 = q403a if a001=="A2" /*FTF*/
		replace q403 = q403a 
		
*****C.5. Find non-numeric variables and desting 

	*****************************
	* Cover
	*****************************
	sum a*

	foreach var of varlist a010 a011 {	
	*foreach var of varlist a001 a010 a011 {	
		replace `var' = usubinstr(`var', "A", "", 1) 
		replace `var' = "88" if `var'=="-oth-"
		destring `var', replace 
		}

	sum a*

	*****************************
	* Section 0
	*****************************
	sum q0*
	/*
	foreach var of varlist q001 {	
		replace `var' = usubinstr(`var', "A", "", 1) 
		destring `var', replace 
		}
	*/
	sum q001		
	
	*****************************
	* Section 1
	*****************************
	sum q1*
	
	drop q100ab /*drop lime survey internal variable to check errors*/

	foreach var of varlist q1* {	
		replace `var' = usubinstr(`var', "A", "", 1) 
		destring `var', replace 
		}

	sum q1*			

	*****************************	
	* Section 2
	*****************************
	sum q2*	
		
	foreach var of varlist q2*  {	
		replace `var' = usubinstr(`var', "A", "", 1) 
		destring `var', replace 
		}	
		
	sum q2*		
	
	*****************************	
	* Section 3
	*****************************
	sum q3*	
		
	foreach var of varlist q302 q303 q304  {	
		replace `var' = usubinstr(`var', "A", "", 1) 
		destring `var', replace 
		}	
		
	sum q3*		

	*****************************	
	* Section 4
	*****************************
	sum q4*

	foreach var of varlist q402 q403a q403  {	
		replace `var' = usubinstr(`var', "A", "", 1) 
		destring `var', replace 
		}		
		
	sum q4*
		
*****C.6. Label values 

	*****************************	
	* Cover
	*****************************
	/*
	#delimit;	
	
	lab define mode
		1 "1.Phone"
		2 "2.Face-to-face"
		;
	lab values a001 mode; 
	*/
	*****************************	
	* Section 1
	*****************************
	
	#delimit;	
	global varlist_5 "
		          q103 q104           q107 q108 q109 q110 
		q111                q115 q116 q117 q118 q119 
		q121 q122 q123 q124 q125 q126 q127 q128 q129 
		q131 q132 q133 	         q136
		" ;
		#delimit cr
		
	global varlist_5na "q105 q106 q112 q114 q120"		
		/*
		RESPONSE OPTION FOR "N/A"
		Q105: I do not have a usual primary care professional…….6 
		Q106: I do not have a usual doctor/nurse…..6 
		Q112: I did not need any home visit	6 
		Q114: I was not referred to other professionals………………...6 
		Q120: I was not examined.……..6 
		*/
	global varlist_5dk "q113 "		
	global varlist_rate5 "q137"	
	global varlist_rate5na "q130"	
		/*
		RESPONSE OPTION FOR "N/A"
		Q130: I have not visited a primary care clinic in the previous 12 months……….... 6 
		*/
	global varlist_yessometimesnonanotsure "q134"
	global varlist_yesnonotsure "q135"
	global varlist_yesnodk "q100a q100b q102 q113"
	
	sum $varlist_5
	sum $varlist_5na
	sum $varlist_5dk
	sum $varlist_rate5
	sum $varlist_rate5na
	sum $varlist_yessometimesnonanotsure
	sum $varlist_yesnonotsure
	sum $varlist_yesnodk
		
	#delimit;	
	
	lab define howmany
		1 "1.Once"
		2 "2.Twice"
		3 "3.Three times"
		4 "4.Four times"
		5 "5.Five times or more"	
		;
	lab values q101 howmany; 
	
	lab define yesnodk
		1 "1.Yes"
		2 "2.No"
		3 "3.Don't know"
		;
	foreach var of varlist $varlist_yesnodk {;		
	lab values `var' varlist_yesnodk; 
	};
	
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
	
	lab define varlist_5dk
		1 "1.Never"
		2 "2.Rarely"
		3 "3.Sometimes"
		4 "4.Often"
		5 "5.Always"
		6 "6.Don't know"
		;
	foreach var of varlist $varlist_5dk {;		
	lab values `var' varlist_5dk; 
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
	
	lab define yessometimesnonanotsure 
		1"1.Yes" 
		2"2.Sometimes" 
		3"3.No"
		4"4.N/A"
		5"5.Not sure"
		; 
	foreach var of varlist $varlist_yessometimesnonanotsure {;
	lab values `var' yessometimesnonanotsure; 
	};	
	
	lab define yesnonotsure 
		1"1.Yes" 
		2"2.No"
		3"3.Not sure"
		; 
	foreach var of varlist $varlist_yesnonotsure  {;
	lab values `var' yesnonotsure ; 
	};		
	
	#delimit cr

	*****************************	
	* Section 2
	*****************************
		
	global varlist_who5 "q201 q202 q203 q204 q205" 
	sum $varlist_who5		
		
	#delimit;	
	
	lab define who5
		5 "All of the time"
		4 "Most of the time"
		3 "More than half of the time"
		2 "Less than half of the time"
		1 "Some of the time"
		0 "At no time"
		;
	foreach var of varlist $varlist_who5 {;		
	lab values `var' who5; 
	};	
	
	#delimit cr
		
	*****************************	
	* Section 3
	*****************************	
	
	#delimit;	
		
	lab define gender
		1 "1.Male"
		2 "2.Female"
		3 "3.Other"
		4 "4.Prefer not to respond"
		;
	lab values q302 gender; 
	
	lab define education
		1 "Never attended school"
		2 "Primary school"
		3 "Middle school" 
		4 "JSS/JHS"
		5 "SSS/SHS"
		6 "Vocational/technical"
		7 "Tertiary"
		;
	lab values q303 education; 

	#delimit cr
	
	*****************************	
	* Section 4
	*****************************
	
	#delimit;	

	lab define language
		1 "1.ENGLISH"
		2 "`countrylanguage1'"
		;
	lab values q402 language; 
	
	lab define result
		1 "1.Completed"
		2 "2.Refused"
		3 "3.Partly completed"
		4 "4.POSTPONED"
		5 "5.PARTLY COMPLETED AND RESCHEDULED"
		6 "6.CALL DROPPED"
		;
	lab values q403 result; 

	#delimit cr

*****C.7. Prepare for merge with facility information 
			
	rename a005 facilityid 
	rename a007 samplenumber 	
	
	sort facilityid 	
	save temp.dta, replace

**************************************************************
* D. Merge with facility information 
**************************************************************
 
*****D.1. Merge with facility information 

import excel "$chartbookdir/Zambia_PREM_Pilot_Chartbook_WORKING.xlsx", sheet("Facility_sample") firstrow clear 
		
	rename *, lower

		capture drop target_sample_size 
		d

		/* this worksheet has background characteristics of the sentinel facilites.
		PREMs team in the country will provide this information
		
		Contains data
		  obs:            36                          
		 vars:             4                          
		 size:           180                          
		------------------------------------------------------------------------------------------
					  storage   display    value
		variable name   type    format     label      variable label
		------------------------------------------------------------------------------------------
		facilityid      int     %10.0g                facilityid
		district        byte    %10.0g                district
		facility_type   byte    %10.0g                facility_type
		managing_auth~y byte    %10.0g                managing_authority
		mode_design     str5    %9s                   mode_design
		language_design str7    %9s                   language_design
		------------------------------------------------------------------------------------------
		Sorted by: 

		*/ 
	
		codebook facilityid /*this is assigned for the study, same with A005 in PREMs*/ 
	
	sort facilityid	
	merge facilityid using temp.dta, 
	
		tab _merge
		
		*****CHECK HERE: 
		*	all should be 3 (i.e., match) by the end of the data collection*/
		*	below is the distribution with mock data
		*	no one from one facility has been interviewed yet
		/*
			.                 tab _merge

				 _merge |      Freq.     Percent        Cum.
			------------+-----------------------------------
					  1 |          1        0.06        0.06
					  3 |      1,543       99.94      100.00
			------------+-----------------------------------
				  Total |      1,544      100.00
		*/
				
		keep if _merge==3
		
		drop _merge*
		
*****D.2. More cleaning 
	
	rename facility_type type
	rename managing_authority sector
		
	#delimit;	
  
	lab define geoname
		1 "`geoname1'"
		2 "`geoname2'"
		3 "`geoname3'"
		4 "`geoname4'"
		;
	lab values district geoname;
	
	lab define type
		1 "`type1'"
		2 "`type2'"
		3 "`type3'"
		;
	lab values type type; 	
	
	lab define sector
		1 "`sector1'"
		2 "`sector2'" 
		;
	lab values sector sector; 		

	#delimit cr

**************************************************************
* D.A Expand and scramble the mock data <= DELETE THIS SECTION WHEN WORKING WITH REAL DATA
**************************************************************

**************************************************************
* E. Create analytical variables 
**************************************************************

***** E.0 Drop data that were entered for practice and test <= ACTIVATE THIS SECTION WHEN WORKING WITH REAL DATA
* EDIT 1/4/2024: Now moved up to B.3.A 

*****E.1. Construct analysis variables 

* give prefix z for background characteristics, which can be used as analysis strata     
* give prefix x for binary variables, which will be used to calculate percentage   
* give prefix y for integer/continuous variables, which will be used to calculate total

	*****************************
	* Cover  
	*****************************
		
		/*
		* a005 has been renamed as facilityid
		lab var facilityid "facility ID from sample list" 
		*/
		
		gen str4 st_facilityid = string(facilityid,"%04.0f")
		gen str4 st_samplenumber = string(samplenumber,"%04.0f")
		
		codebook st_*
		
		gen clientid = st_facilityid + "_" + st_samplenumber 
		
		codebook *id
		
		gen country = "`country'"
		gen round 	= "`round'"
		gen month	=`month'
		gen year	=`year'
		
		gen mode 	= "Phone"
		/*
		gen mode 	= ""
			replace mode = "Phone" if a001==1
			replace mode = "FTF" if a001==2
		*/
		gen language = ""
			replace language = "English" if language_design=="English"
			replace language = "`countrylanguage1'" if language_design=="`countrylanguage1'"
			*replace language = "English" if q402==1
			*replace language = "`countrylanguage1'" if q402==2

	*****************************
	* Cover + Section 3 + q100a/B
	*****************************
	
	***** basic variables for disaggregated analysis 
		
		gen zcare = .
			replace zcare = 1 if q100a==1 & q100b==1 
			replace zcare = 2 if q100a==1 & q100b!=1
			replace zcare = 3 if q100a!=1 & q100b==1
			tabstat q100a q100b, by(zcare) stats(min max)
			lab define zcare 1 "both patient & caregiver" 2 "only patient" 3 "only caregiver"
			lab values zcare zcare
			
		egen zage = cut(q301), at(18 40 99)
			codebook zage
			tabstat q301, by(zage) stats(min max)
			recode zage (18=1) (40=2)
			lab define zage 1 "18-39" 2 "40+" 
			lab values zage zage
		
		gen zgender = q302
			recode zgender 4=3
			lab define zgender 1 "Male" 2 "Female" 3 "Other/NoResponse"
			lab values zgender zgender
			
		gen byte zedu = q303>=3 & q303!=.
			lab define zedu 0 "primary or less" 1 "secondary or higher"
			lab values zedu zedu
		
		gen zdistrict = district
		gen ztype = type
		gen zsector = sector 
			lab values zdistrict geoname
			lab values ztype type 	
			lab values zsector sector 		
				
	*****************************
	* Section 1: Items 
	*****************************
	
	* for NEGATIVELY phrased questions, responses are recoded here 
	* so that for all questions, the higher the better
	* QUESTIONS TO CHEMA, 
	* 1. HOW DO WE HANDLE NA? GIVE THE MAX SCORE OR MISSING??
	* 2. HOW DO WE HANDLE binary questions? Please clear below. 
	
	***** 1. [First contact] 
	
		gen y_fc_soon = q103
		gen y_fc_notdiff = q104 
			/*REVERSE ORDER*/
			recode y_fc_notdiff (0=5) (1=4) (2=3) (3=2) (4=1) (5=0)
		gen y_fc_pc = q105
		gen y_fc_cost = q136 
			/*REVERSE ORDER*/
			recode y_fc_cost (0=5) (1=4) (2=3) (3=2) (4=1) (5=0)		
			
		sum y_fc_*
			
	***** 2. [Continuity]
	
		gen y_cont_usual = q106
		gen y_cont_familiar = q107
		gen y_cont_allinfo = q108
		gen y_cont_follow = q109
		
		sum y_cont_*
					
	***** 3. [Comprehensiveness]
	
		gen y_comp_info = q110
		gen y_comp_emo = q111
		gen y_comp_home = q112
			/*RECODE NA*/
			recode y_comp_home 6=.
			
		sum y_comp_*			
			
	***** 4. [Coordination]

		gen y_coor_other = q113
			/*RECODE DON'T KNOW*/
			/*Do not know*/
			recode y_coor_other 6=.		
		gen y_coor_allinfo = q114
			/*RECODE NA*/
			/*Not applicable, I was never referred to other professionals*/
			recode y_coor_allinfo 6=.			

		sum y_coor_*		
						
	***** 5. [Patient centred care]
	
		gen y_pcc_choiceclinic = q115
		gen y_pcc_choicepcp = q116
		gen y_pcc_convtime = q117
		gen y_pcc_confidence = q118
		gen y_pcc_confi = q119
		gen y_pcc_privacy = q120
		gen y_pcc_respect = q121
		gen y_pcc_care = q122
		gen y_pcc_enoughtime = q123
		gen y_pcc_considerall = q124
		gen y_pcc_involve = q125
		gen y_pcc_cpagree = q126
		gen y_pcc_cpfollow = q127
		gen y_pcc_cpgoal = q128
		gen y_pcc_others = q129
		gen y_pcc_env = q130	
		gen y_pcc_lang = q131
		gen y_pcc_understand = q132
		
		sum y_pcc_*
		
	***** 6. [Professional competence]

		gen y_prof_skills = q133
		
		sum y_prof_*
				
	***** 7. [Safety]
	
		gen x_safe_hand = q134==1
		gen x_safe_notworse = q135==2		
		
		sum x_safe_*		

	***** 8. [Overall experience]
	
		gen y_overall = q137
	
		sum y_overall
		
	***** catch any N/As not recoded to missing yet /*Edit 1/3/2024*/	
	sum y_*
	foreach var of varlist y_*{
		recode `var' 6=0
	}
	sum y_*		
		
	*****************************
	* Section 1: Scale
	*****************************			
		
	***** Domain specific average score (0-100)	
		global itemlist "fc cont comp coor pcc prof overall"
		foreach item in $itemlist{	
			egen yy_`item' = rowmean(y_`item'*)
			replace yy_`item' = ((yy_`item' -1)/ 4)*100 /*5-category response options: 1-5*/ 
			}	
			
		global itemlist "safe"			
		foreach item in $itemlist{	
			egen yy_`item' = rowmean(x_`item'*)
			replace yy_`item' = (yy_`item')*100 /*binary response option*/ 
			}
			
	***** Overall score (0-100)
	
	/*
	The first draft version of the instrument includes 37 items across 8 domains (Figure 1).  
	The instrument will translate the questionnaire responses to a 0-100 range for 
	each of the core domains of primary care, patients perceived professional competency, 
	as well as an overall weighted score including the additional items of patient safety 
	and overall experience. 
	
	The score of 100 will represent the best experience and 0 the worst experience of primary care.
	*/	
		
		egen yyy_w = rowmean(yy_*)
		
		#delimit; 
		gen yyy_uw = (yy_fc*4 + 
						yy_cont*4 + 
						yy_comp*3 + 
						yy_coor*2 + 
						yy_pcc*18 + 
						yy_prof*1 + 
						yy_overall*1 + 
						yy_safe*2 ) / 35
		;
		#delimit cr
		
		sum yyy_*

	*****************************
	* Section 2: WHO-5 Well-being 
	*****************************

	/*
	https://www.corc.uk.net/outcome-experience-measures/the-world-health-organisation-five-well-being-index-who-5/
	https://karger.com/pps/article/84/3/167/282903/The-WHO-5-Well-Being-Index-A-Systematic-Review-of#ref1
	*/
		
		gen y_well_cheerful = q201
		gen y_well_calm = q202
		gen y_well_active = q203
		gen y_well_fresh = q204
		gen y_well_interst = q205
		
		/*REVISION 2/1/2024 STARTS*/
		foreach var of varlist y_well_*{
		replace `var' = `var' - 1
		}		
		/*REVISION 2/1/2024 ENDS*/		
		
		egen yy_wellbeing = rowtotal(y_well*)
			replace yy_wellbeing = yy_wellbeing*4 
			
		gen byte zdepression = yy_wellbeing<=50
		
		xtile z_wellbeing5 = yy_wellbeing, nq(5)
		
	*****************************
	* Interview results
	*****************************
		
		gen xcomplete= q001==1 & q403==1
		
			tab xcomplete language, m
			/*
				.         tab xcomplete language, m

					   |       language
			 xcomplete |     Bemba    English |     Total
			-----------+----------------------+----------
					 0 |        92        136 |       228 
					 1 |       238        232 |       470 
			-----------+----------------------+----------
				 Total |       330        368 |       698 
			*/
	
		tab q403 zdistrict, m
		bysort zdistrict: tab mode language, m
	
*****E.2. Export clean facility-level data to chart book 
	
	sort clientid
	save "$datadir/PREM_`country'_R`round'.dta", replace 		

	export delimited "$datadir/PREM_`country'_R`round'", replace 

	export excel using "$chartbookdir/Zambia_PREM_Pilot_Chartbook_WORKING.xlsx", sheet("Client_clean_data") sheetreplace firstrow(variables) nolabel
		
**************************************************************
* F. Create indicator estimate data 
**************************************************************

use "$datadir/PREM_`country'_R`round'.dta", clear

	***** To get the total number of observations per relevant part 
	
	gen obs=1 	
	
	tab xcomplete, m
	keep if xcomplete==1
	drop xcomplete	
	
	save temp.dta, replace 
	
*****F.1. Calculate estimates - 

*** Overall

		use temp.dta, clear
		collapse (count) obs (mean) x* (mean) y_* yy_* yyy_* , ///
			by(country round month year  )
			
			gen mode="All modes"
			gen language="All languages"
		
			save "$datadir/summary_PREM_`country'_R`round'.dta", replace 	

*** By language AND mode (study arm): overall and by subgroup			

		use temp.dta, clear
		collapse (count) obs (mean) x* (mean) y_* yy_* yyy_* , ///
			by(country language mode round month year )
	
			append using "$datadir/summary_PREM_`country'_R`round'.dta"	, force	
			save "$datadir/summary_PREM_`country'_R`round'.dta", replace 

		use temp.dta, clear				
		foreach subgroupvar of varlist zcare zage zgender zedu zdepression {
		
		preserve
		drop if `subgroupvar'==.
		collapse (count) obs (mean) x* (mean) y_* yy_* yyy_*, ///
			by(country language mode round month year `subgroupvar')
		
			append using "$datadir/summary_PREM_`country'_R`round'.dta"	, force	
			save "$datadir/summary_PREM_`country'_R`round'.dta", replace 

			save "$datadir/summary_PREM_`country'_R`round'.dta", replace 
		restore
		}
		
*** By district: overall and by subgroup			
	
		use temp.dta, clear
		collapse (count) obs (mean) x* (mean) y_* yy_* yyy_* , ///
			by(country language mode zdistrict round month year )
			
			append using "$datadir/summary_PREM_`country'_R`round'.dta"	, force	
			save "$datadir/summary_PREM_`country'_R`round'.dta", replace 
				
		use temp.dta, clear		
		foreach subgroupvar of varlist zcare zage zgender zedu zdepression {
		
		preserve
		drop if `subgroupvar'==.
		collapse (count) obs (mean) x* (mean) y_* yy_* yyy_*, ///
			by(country language mode zdistrict round month year `subgroupvar')
			
			append using "$datadir/summary_PREM_`country'_R`round'.dta"	, force	
			save "$datadir/summary_PREM_`country'_R`round'.dta", replace 

			save "$datadir/summary_PREM_`country'_R`round'.dta", replace 
		restore
		}		
		
	use "$datadir/summary_PREM_`country'_R`round'.dta", clear
		
			*replace language = "All languages" if language=="" & mode!=""
			*replace mode = "All modes" if language!="" & mode==""
		
		gen group="All"
		gen grouplabel="All"
			
			replace group="Clients' care seeking" if zcare!=.
			replace group="Clients' Age" if zage!=.
			replace group="Clients' Gender" if zgender!=.
			replace group="Clients' Education" if zedu!=.
			replace group="WHO-5 wellbeing score" if zdepression!=.
					
			replace group="District_" + group if zdistrict!=. & group!="All" /*by subgroup within district*/
			replace group="District" if zdistrict!=. & group=="All" 
		
			replace grouplabel="Both patient & caregiver" 	if zcare==1
			replace grouplabel="Only patient" 	if zcare==2
			replace grouplabel="Only caregiver" 	if zcare==3
			
			replace grouplabel="18-39" 	if zage==1
			replace grouplabel="40+" 	if zage==2

			replace grouplabel="Male" 				if zgender==1
			replace grouplabel="Female" 			if zgender==2
			replace grouplabel="Other/NoResponse" 	if zgender==3

			replace grouplabel="Primary or less" 	 if zedu==0
			replace grouplabel="Secondary or higher" if zedu==1			

			replace grouplabel="WHO-5 score <=50"	if zdepression==0
			replace grouplabel="WHO-5 score >50" 	if zdepression==1			

			replace grouplabel="`geoname1'_" + grouplabel if zdistrict==1 & grouplabel!="All" /*by subgroup within district*/
			replace grouplabel="`geoname2'_" + grouplabel if zdistrict==2 & grouplabel!="All" /*by subgroup within district*/
			replace grouplabel="`geoname3'_" + grouplabel if zdistrict==3 & grouplabel!="All" /*by subgroup within district*/
			replace grouplabel="`geoname4'_" + grouplabel if zdistrict==4 & grouplabel!="All" /*by subgroup within district*/
			
			replace grouplabel="`geoname1'" if zdistrict==1 & grouplabel=="All"
			replace grouplabel="`geoname2'" if zdistrict==2 & grouplabel=="All"
			replace grouplabel="`geoname3'" if zdistrict==3 & grouplabel=="All"
			replace grouplabel="`geoname4'" if zdistrict==4 & grouplabel=="All"
				
		keep obs country language mode round month year  group* x*  y_* yy_* yyy_* z*
				
	***** convert proportion to %		
		foreach var of varlist x* {
			replace `var'=round(`var'*100, 1)	
			}
		
	***** trim decimal points 
		foreach var of varlist y_* {
			replace `var'=round(`var', 0.1)	
			format `var' %2.1f
			}		
			
		foreach var of varlist yy_* yyy_* {
			replace `var'=round(`var', 1)	
			format `var' %2.0f
			}				

	***** assess n, and suppress if estimates are based on small n
	* We will pick an acceptable and widely used but still arbitrary number. 
	* 25 as used in the DHS final report
	* https://dhsprogram.com/data/Guide-to-DHS-Statistics/Analyzing_DHS_Data.htm
	
		*****CHECK HERE: 
		sum obs, detail
		histogram obs, w(5)	freq ///
			xline(`r(p50)', lcolor(red)) xline(25, lcolor(blue)) ///
			title("Distribution of denominator size") ///
			xtitle("Number of observations in denominator") ///
			note("Red vertical line: median" "Blue vertical line: 25")
		*	Check the distribution. Figure out what rows that have a small N

		list mode language group grouplabel obs if regexm(grouplabel, "Other/NoResponse")
		list mode language group grouplabel obs if regexm(grouplabel, "Only")
		list mode language group grouplabel obs if obs<25
				
		foreach var of varlist x_* y_* yy_* yyy_* {
			replace `var' =. if obs<25
		}
				
	***** replace grouplabel and check duplicates
	
		replace grouplabel = language + "_" + mode + "_" + group + "_" + grouplabel 
			
		*****CHECK HERE: 
		duplicates tag grouplabel, gen(duplicate)
		tab duplicate
		* 	Ensure grouplabel is unique for every row 
		* 	There will be duplicate if each districts has a unique study arm (e.g., Ghana) 
		*	YJ to experiment with a simplier design...???
				
			sort grouplabel
			list language mode grouplabel z* obs if duplicate>0
					
			* Drop duplicates: 
			drop if grouplabel == grouplabel[_n-1]
			codebook grouplabel
			drop duplicate
			drop z*
				
	***** order columns
		order country round year month language mode group grouplabel obs 
	
	***** sort rows
		sort country round year month language mode group grouplabel 
		
save "$datadir/summary_PREM_`country'_R`round'.dta", replace 
		
export delimited using "$datadir/summary_PREM_`country'_R`round'.csv", replace 

erase temp.dta	
*****F.2. Export indicator estimate data to chartbook AND dashboard

use "$datadir/summary_PREM_`country'_R`round'.dta", clear

	gen updatedate = "$date"

	local time=c(current_time)
	gen updatetime=""
	replace updatetime="`time'"

export excel using "$chartbookdir/Zambia_PREM_Pilot_Chartbook_WORKING.xlsx", sheet("PREMs_estimates") sheetreplace firstrow(variables) nolabel keepcellfmt

**************************************************************
* G. MINIMUM data quality check 
**************************************************************

capture log close
log using "$datanotedir/DataCheck_PREM_`country'_R`round'_$date.log", replace

*** Minimum red-flag indicators will be listed. So, the shorter log, the better.  

*** 1. Estimates exceeding boundaries 

*WHAT DO THEY SUGGEST? Error(s) in analysis code. 
*ACTION: review and revise the code

use "$datadir/summary_PREM_`country'_R`round'.dta", clear	
	
	/*
	Estimates for percent or score (0-100) that exceed boundaris.  
	For example, xdrug_100 MUST BE BETWEEN 0 and 100.  
	*/
	
	sort group grouplabel

			foreach var of varlist x* {
				list group grouplabel `var' if `var'<0 | (`var'>100 & `var'!=.)
			}			
	
*** 2. Excessive missing/NA

*WHAT DO THEY SUGGEST? Data entry error by interviewers or respodent's poor partcipation 
*ACTION: monitor and improve interviewer performance 
	
use "$datadir/PREM_`country'_R`round'.dta", clear
log off

	/*count number of missing responses*/
	keep if xcomplete==1

			foreach var of varlist q100a q100b q301 q302 q303 {
				gen byte mbasic`var' = `var'==.
			}						
			foreach var of varlist q103 - q137 {
				gen byte mprem`var' = `var'==.
			}
			
				/* fix for Q127 which is asked only when Q126 is not never*/
				replace mpremq127 = 0 if q126==1 			
			
			foreach var of varlist q2* {
				gen byte mwho5`var' = `var'==.
			}			
			global itemlist "basic prem who5"
			foreach item in $itemlist{	
				egen totalm`item'= rowtotal(m`item'*)
				}				
			egen totalm = rowtotal(mbasic* mprem* mwho5*)
			gen byte evermissing = totalm>=1
			
			gen obs=1

log on
 			
	*QUESTION: 
	*1. What proportion of respondents have at least one missing responses? 
	preserve	
	collapse (count) obs (mean) evermissing, by(country language mode)
	list
	restore
	
	*2. What is the average number of missing responses in an interview? 
	preserve
	collapse (count) obs (mean) totalm* , by(country language mode)
	list 
	restore
	
	*QUESTION: 
	*3. Is missing concentrated in particular respondents? 
	*4. What is the highest number of missing responses in an interview? 
	preserve
	collapse (count) obs (max) totalm*, by(country language mode)
	list
	restore
	
	*QUESTION: 
	*5. Are there particular questions that drive missing responses?  	
	*6. What is the total number of missing responses in each question? 
	collapse (count) obs (sum) mbasic* mprem* mwho5*, by(country language mode)
	bysort language mode: list
	
*** 3. Inconsistency between study language and reported interview language

*WHAT DO THEY SUGGEST? Data entry error by interviewers, or actual deviation from the study design  
*ACTION: 
*	1. Investigate if it's actual deviation or an error.
*	2. Monitor and improve interviewer performance.  
 	
use "$datadir/PREM_`country'_R`round'.dta", clear
log off
	
	/*count number of mistmatch*/
	keep if xcomplete==1

		tab district language, m
		tab a004 q402, m
		bysort a004: sum q402
			
		egen langmode = mode(q402), by(district) 
		bysort a004: sum q402 langmode
			
		gen byte il = q402!=langmode
						
		gen obs=1

log on
		
	collapse (count) obs (sum) il* , by(country district)
	list		
	
log close
	
*END OF DATA CLEANING AND MANAGEMENT 
