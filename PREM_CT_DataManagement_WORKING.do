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

*** Directory for downloaded CSV data (can be same or different from the main directory)
global downloadcsvdir "~/Dropbox/0iSquared/iSquared_WHO/PREM/Methods/5_DataAnalysisCognitiveTest/ExportedCSV_FromLimeSurvey/"

*** Define a directory for processed data files (can be same or different from the main directory)
global datadir "~/Dropbox/0iSquared/iSquared_WHO/PREM/Methods/5_DataAnalysisCognitiveTest/"

*** Define local macro for the survey 

local country	 		 EXAMPLE /*country name*/	
local round 			 1 /*round*/		
local year 			 	 2023 /*year of the mid point in data collection*/	
local month 			 6 /*month of the mid point in data collection*/	

local surveyid 			 751181 /*LimeSurvey survey ID for cognitive interview*/

*** Define local macro for response options specific to the country 

local countrylanguage	 Country_Language /*Country language*/
		
*** local macro for analysis (no change needed)  
local today		= c(current_date)
local c_today	= "`today'"
global date		= subinstr("`c_today'", " ", "",.)

**************************************************************
* B. Import and drop duplicate cases
**************************************************************

*****B.1. Import raw data from LimeSurvey 
import delimited using "https://extranet.who.int/dataformv3/index.php/plugins/direct?plugin=CountryOverview&docType=1&sid=`surveyid'&language=en&function=createExport", case(preserve) clear
	
		d, short

*****B.2. Export/save the data daily in CSV form with date 	

export delimited using "$downloadcsvdir/LimeSurvey_PREM_CT_EXAMPLE_$date.csv", replace
* We need the next line until there are more data entry in the mock link....
import delimited "$downloadcsvdir/LimeSurvey_PREM_CT_EXAMPLE_16Oct2023.csv", case(preserve) clear 

*****B.3. Check and drop odd rows

drop if submitdate==""
		
*****B.4. Check and drop duplicate cases 
*
	* B.4.1 check variables with "id" in their names
		lookfor id
		
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
		duplicates tag A003 A004 A005, gen(duplicate) 

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
			*list submitdate* in 1/2		
				
		sort A003 A004 A005 submitdate
		list A003 A004 A005 submitdate if duplicate!=0  
		*****CHECK HERE: 
		*	check submitdate within each repeated client, 
		*	Again, in the mock dataset, 
		*	there are two clients that have three data entries for practice purpose. 

		*****drop duplicates before the latest submission 
		egen double submitdatelatest = max(submitdate) if duplicate!=0, ///
			by(A003 A004 A005) /*LATEST TIME WITHIN EACH DUPLICATE*/					
						
			*format %tcnn/dd/ccYY_hh:MM submitdatelatest /*"format line without seconds*/
			format %tcnn/dd/ccYY_hh:MM:SS submitdatelatest /*"format line with seconds*/
			
			sort A003 A004 A005 submitdate
			list A003 A004 A005 submitdate* if duplicate!=0  
			
	* B.4.f drop duplicates
	
		drop if duplicate!=0  & submitdate!=submitdatelatest 
		
		*****confirm there's no duplicate cases, based on facility code
		duplicates report A003 A004 A005,
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

	rename (*greysq001) (*_rep) 
	rename (*greysq002) (*_cla) 
	rename (*greysq003) (*_opt) 
	rename (*greysq004) (*_ans)
	rename (q*comqt)	(q*_comqt) 
	rename (q*retqt)	(q*_retqt) 
	rename (q*judqt)	(q*_judqt) 
	rename (q*respqt)	(q*_respqt)

*****C.4. Consolidate interview result variable Q403 - 

	* OPTION 1: if both modes are used in a country 

	gen q403=q403a /*all cognitive test interviews are FTF*/
		*replace q403 = q403b if a001==1 /*PHONE*/ 
		*replace q403 = q403a if a001==2 /*FTF*/
		
*****C.5. Find non-numeric variables and destring 

	*****************************
	* Cognitive testing questions 
	*****************************
	sum q*rep q*cla q*opt q*ans q*comqt q*retqt q*judqt q*respqt
	
		/* JUST FOR THE MOCK DATA STARTS*/
		tostring q120_rep, replace /* JUST FOR THE MOCK DATA*/
		replace q120_rep = "A2" /* JUST FOR THE MOCK DATA*/
		/* JUST FOR THE MOCK DATA ENDS*/
	
	foreach var of varlist q*rep q*cla q*opt q*ans q*comqt q*retqt q*judqt q*respqt {	
		replace `var' = usubinstr(`var', "A", "", 1) 
		destring `var', replace 
		}
		
	sum q*rep q*cla q*opt q*ans q*comqt q*retqt q*judqt q*respqt
	
	*****************************
	* Main questions 
	*****************************
	
	/*
	drop q*rep q*cla q*opt q*ans q*comqt q*retqt q*judqt q*respqt
	drop *qual* *consolidation *txt *disagqt inst*
	keep q1* q2* q3* q4*
	drop q301
	d 
	sum `r(varlist)'
	*/
	
	#delimit;
	global mainvarlist "
		q100a q100b 
		q101 q102 q103 q104 q105 q106 q107 q108 q109 q110
		q111 q112 q113 q114 q115 q116 q117 q118 q119 q120 
		q121 q122 q123 q124 q125 q126 q127 q128 q129 q130 
		q131 q132 q133 q134 q135 q136 q137    
		q201 q202 q203 q204 q205      
		q302 q303 q402 q403a q403      
	" ;
	global mainvarnumlist "
		100a 100b 
		101 102 103 104 105 106 107 108 109 110
		111 112 113 114 115 116 117 118 119 120 
		121 122 123 124 125 126 127 128 129 130 
		131 132 133 134 135 136 137    
		201 202 203 204 205       
	" ;	
	#delimit cr
	
	sum $mainvarlist
	
	foreach var of varlist $mainvarlist {	
		replace `var' = usubinstr(`var', "A", "", 1) 
		destring `var', replace 
		}
	
	sum $mainvarlist
		
*****C.6. Label values 

	*****************************	
	* Cognitive testing variables
	*****************************	
	
	#delimit;
	lab define yesno
		1 "1.Yes"
		2 "2.No"
		;
	foreach var of varlist q*rep q*cla q*opt q*ans {;		
	lab values `var' yesno; 
	};
	
	lab define yesnocannot
		1 "1.Yes"
		2 "2.No"
		3 "3.Cannot be established"
		;
	foreach var of varlist q*comqt q*retqt q*judqt q*respqt {;		
	lab values `var' yesnocannot; 
	};	
	#delimit cr	
	*****************************
	* Main questions 
	*****************************
	
	* Not the focus of CT analysis. Not included here. 
	
**************************************************************
* D. Expand and scramble the mock data <= DELETE THIS SECTION WHEN WORKING WITH REAL DATA
**************************************************************

	*
	expand 15 
	
	foreach varnum in $mainvarnumlist {		
	set seed 410	
		generate random = runiform()
		foreach item in rep cla  {	
		recode q`varnum'_`item' (2=1) if random>0.30 /*good*/
		recode q`varnum'_`item' (1=2) (2=1) if random>0.70
		recode q`varnum'_`item' (1=2) (2=1) if random>0.80
		recode q`varnum'_`item' (1=2) if random>0.90 /*bad*/
		}
		foreach item in comqt retqt {	
		recode q`varnum'_`item' (1=2) (3=2) if random>0.30 /*good*/
		recode q`varnum'_`item' (1=2) (2=3) (3=1) if random>0.70
		recode q`varnum'_`item' (1=2) (2=3) (3=1) if random>0.80
		recode q`varnum'_`item' (1=2) if random>0.90 /*bad*/
		}
		drop random 
	set seed 315		
		generate random = runiform()
		foreach item in opt ans {	
		recode q`varnum'_`item' (2=1) if random>0.30 /*good*/
		recode q`varnum'_`item' (1=2) (2=1) if random>0.70
		recode q`varnum'_`item' (1=2) (2=1) if random>0.80
		recode q`varnum'_`item' (1=2) if random>0.90 /*bad*/
		}
		foreach item in judqt respqt {	
		recode q`varnum'_`item' (1=2) (3=2) if random>0.30 /*good*/
		recode q`varnum'_`item' (1=2) (2=3) (3=1) if random>0.70
		recode q`varnum'_`item' (1=2) (2=3) (3=1) if random>0.80
		recode q`varnum'_`item' (1=2) if random>0.90 /*bad*/
		}
		drop random 		
	}
		set seed 5		
		generate random = runiform()		
		recode q402 (1=2) if random<=0.45
		recode q402 (2=1) if random>0.45
		drop random
*/		
	
**************************************************************
* E. Create analytical variables 
**************************************************************

*****E.1. Construct analysis variables 

* give prefix z for background characteristics, which can be used as analysis strata     
* give prefix x for binary variables, which will be used to calculate percentage   

	*****************************
	* Cover  
	*****************************
		
		egen clientid = concat(a005 a003 a004)
	
		gen country = "`country'"
		
		gen mode = "FTF"
		
		gen language = ""
			replace language = "English" if q402==1
			replace language = "`countrylanguage'" if q402==2
			
	*****************************
	* Cover + Section 3 + q100a/B
	*****************************
	
	***** basic variables for disaggregated analysis 
		
		gen care = .
			replace care = 1 if q100a==1 & q100b==1 
			replace care = 2 if q100a==1 & q100b!=1
			replace care = 3 if q100a!=1 & q100b==1
			tabstat q100a q100b, by(care) stats(min max)
			lab define care 1 "both patient & caregiver" 2 "only patient" 3 "only caregiver"
			lab values care care
			
		egen age = cut(q301), at(18 40 99)
			codebook age
			tabstat q301, by(age) stats(min max)
			recode age (18=1) (40=2)
			lab define age 1 "18-39" 2 "40+" 
			lab values age age
		
		gen gender = q302
			recode gender 4=3
			lab define gender 1 "Male" 2 "Female" 3 "Other/NoResponse"
			lab values gender gender
			
		gen byte edu = q303>=3 & q303!=.
			lab define edu 0 "primary or less" 1 "secondary or higher"
			lab values edu edu
			
	*****************************	
	* Cognitive testing variables
	*****************************
	
		foreach var of varlist *rep *cla *opt *ans {		
			gen xobs`var' = `var'==2
		}
		
		foreach var of varlist q*comqt q*retqt q*judqt q*respqt {		
			gen xpost`var' = `var'==1 | `var'==3  
		}	

		sum xobs*
		sum xpost*

			foreach varnum in $mainvarnumlist{	
				egen temp = rowtotal(xobsq`varnum'_*)
				tab temp, m
				gen xobsq`varnum'__any = temp>=1
				drop temp
				}		

			foreach varnum in $mainvarnumlist{	
				egen temp = rowtotal(xpostq`varnum'_*)
				tab temp, m
				gen xpostq`varnum'__any = temp>=1
				drop temp
				}					
				
		sum xobs*any
		sum xpost*any
		
		egen yobs__any = rowtotal(xobs*__any)
		egen ypost__any = rowtotal(xpost*__any)

		sum y*
	
	*****************************
	* Interview results
	*****************************

		gen xcomplete=q403==1
		
		tab mode language, m

*****E.2. Export clean person-level data to excel 
	
	***** order columns
	order clientid country language care age gender edu	/*bring these to the front*/
	order Ãid - q002sq001comment, last /*move these to the end*/
	
	***** sort rows
	sort clientid
	
	save "$datadir/PREM_CT_`country'.dta", replace 		
	
		gen updatedate = "$date"

		local time=c(current_time)
		gen updatetime=""
		replace updatetime="`time'"

	export excel using "$datadir/PREM_CT_`country'.xlsx", ///
		sheet("Wide_Person") sheetreplace firstrow(variables) 
		
*****E.3. Reshpae to LONG person-question level data 

	save temp.dta, replace
	
	use temp.dta, clear
	***** drop 
		drop x* y* /*assessment variables created for summary report*/
		drop Ãid - q002sq001comment q3* q4* country mode submitdate update* /*interview level data*/
	
	***** rename variables for reshape 
		foreach varnum in $mainvarnumlist{	
			rename q`varnum' answer`varnum'
			
			rename q`varnum'_rep obs_rep`varnum'
			rename q`varnum'_cla obs_cla`varnum'
			rename q`varnum'_opt obs_opt`varnum'
			rename q`varnum'_ans obs_ans`varnum'
			
			rename (q`varnum'qual*) (qual*_`varnum')
			
			rename q`varnum'consolidation	con`varnum'

			rename q`varnum'_comqt	post_com`varnum'         
			rename q`varnum'comtxt  post_comtxt`varnum'
			rename q`varnum'_retqt  post_ret`varnum'               
			rename q`varnum'rettxt	post_rettxt`varnum' 	     
			rename q`varnum'_judqt  post_jud`varnum'                 
			rename q`varnum'judtxt	post_judtxt`varnum'      
			rename q`varnum'_respqt	post_resp`varnum'                                               
			rename q`varnum'resptxt	post_resptxt`varnum'     

			rename q`varnum'sumtxt		post_sumtxt`varnum'      
			rename q`varnum'disagqt		post_disag`varnum'     
			rename q`varnum'disagtxt	post_disagtxt`varnum'    
		}
	
			rename inst1a answerinst1a
			rename inst1b answerinst1b
			rename inst2  answerinst2
			rename inst3  answerinst3  
			rename inst4  answerinst4  
			rename inst5  answerinst5
	
	***** check and convert variable type 
	* Lime survey thinks a text variables is numeric, if it's missing in ALL rows
		
		foreach var of varlist qual* post*txt*{
		tostring `var', replace
		}
		
		foreach var of varlist answer*{
		tostring `var', replace
		}		
	
	***** check clientid is unique 
		
		codebook clientid
			
			*
			gen n = _n 
			tostring n, replace		
			egen temp = concat(n clientid) 
			replace clientid = temp
			capture drop n temp
			*/
			
		codebook clientid
	
	***** reshape 
	
		reshape long ///
			answer obs_rep obs_cla obs_opt obs_ans ///
			qual_ qual1_ qual2_ con ///
			post_com post_comtxt post_ret post_rettxt post_jud post_judtxt post_resp post_resptxt ///
			post_sumtxt post_disag post_disagtxt , i(clientid) j(question) string
			
		tab question, m
		
		rename (qual*_) (qual*) /*clean var name*/
	
	***** label variables
		
		foreach var of varlist obs_* post_disag {		
			lab values `var' yesno 
			}
	
		lab define postyesnocannot ///
			1 "1.Yes, there is an issue" ///
			2 "2.No issue" ///
			3 "3.Cannot be established"
		foreach var of varlist post_com post_ret post_jud post_resp {		
			lab values `var' postyesnocannot 
			}	
		
	***** order columns
		order clientid language care age gender edu	/*bring these to the front*/
		
	***** sort rows
		sort clientid
	
*****E.4. Export LONG person-question level data to excel 
		
	export excel using "$datadir/PREM_CT_`country'.xlsx", ///
		sheet("Long_Person_Question") sheetreplace firstrow(variables) 
	
**************************************************************
* F. Create indicator estimate data 
**************************************************************

use "$datadir/PREM_CT_`country'.dta", clear

	***** To get the total number of observations per relevant part 
	
	gen obs=1 	
	
	tab xcomplete, m
	keep if xcomplete==1
	drop xcomplete	
	
	save temp.dta, replace 
	
*****F.1. Calculate estimates - 

*** Overall

		use temp.dta, clear
		collapse (count) obs (mean) x*, by(country)
			
			gen language="All"
		
			save "$datadir/summary_PREM_CT_`country'.dta", replace 	

*** By language: overall and by subgroup

		use temp.dta, clear
		collapse (count) obs (mean) x*, by(country language)
			
			append using "$datadir/summary_PREM_CT_`country'.dta", force	
			save "$datadir/summary_PREM_CT_`country'.dta", replace 
				
	***** convert proportion to %		
		foreach var of varlist x* {
			replace `var'=round(`var'*100, 1)	
			}
	
	***** order columns
		order country language obs 
	
	***** sort rows
		sort country language obs 
		
save "$datadir/summary_PREM_CT_`country'.dta", replace 

*END OF DATA CLEANING AND MANAGEMENT 

************************************************************************
* G. Generate report
************************************************************************

use "$datadir/summary_PREM_CT_`country'.dta", clear
		
capture putdocx clear 
putdocx begin
	
putdocx paragraph
putdocx text ("Daily summary of PREMs cognitive test in `country'"), bold linebreak
putdocx text ("(last updated on `today')"),  linebreak	
	sum obs if language=="All"
putdocx text ("- Total number of completed interviews (all languages): `r(mean)'"),  linebreak	
	sum obs if language=="English"
putdocx text ("- Total number of completed interviews conducted in English: `r(mean)'"),  linebreak	
	sum obs if language=="`countrylanguage'"
putdocx text ("- Total number of completed interviews conducted in `countrylanguage': `r(mean)'"),  linebreak	

putdocx text (""), linebreak 
putdocx text ("There are three parts in this summary:"), linebreak 
putdocx text ("1. Problem questions"), linebreak 
putdocx text ("--- Question: are there particular questions that respondents had issues with?"), linebreak	
putdocx text ("2. Type of issues by question"), linebreak 
putdocx text ("--- Question: what are specific type of issues in each question?"), linebreak	
putdocx text ("3. Problem respondents"), linebreak	
putdocx text ("--- Question: are there particular respondents who drive the 'problem question' pattern?"), linebreak	

putdocx pagebreak	
putdocx paragraph
putdocx text ("1. Problem questions by interview language - questions ranked by the number of respondents who had issues agreed post-consolidation"), bold linebreak 

global languagelist "English `countrylanguage'"
foreach language in $languagelist{
	
	preserve
	
		keep if language=="`language'"
		keep xpost*__any
			xpose, clear varname	
			replace _varname = subinstr(_varname, "xpost", "",.) 
			replace _varname = subinstr(_varname, "__any", "",.) 
			lab var v1 "Percent of respondents who had any issues"
		
		#delimit;
		graph hbar v1, 
			over(_varname, 
				sort(1) descending 
				label(labsize(vsmall)))				
			ytitle("Percent of respondents")	
			title("`language'", size(large))
			xsize(3.5) ysize(4) ylab(0(20)100)
			bar(1, color(cranberry*2)) 
		;
		#delimit cr
		
	restore
	
graph save Graph "temp.gph", replace
graph export "temp.png", replace	

putdocx paragraph
putdocx image "temp.png", height(3.8) width(3.5)
	
}

putdocx pagebreak	
putdocx paragraph
putdocx text ("2. Type of issues by question and interview language: observed and agreed post-consolidation"), bold linebreak	
	
		gen dummy=.
		drop if language=="All"

	foreach varnum in $mainvarnumlist{		
	#delimit;
	graph bar xobsq`varnum'* dummy xpostq`varnum'*,  
		by(language, 
			row(1) 
			title("Issues observed and agreed after consolidation: Q`varnum'", size(large)) 
			note("", 
				 size(vsmall)) 
			)
		ytitle("Percent of CT interviews", size(vsmall)) ylabel(0 (20) 100)
		ylabel(0 (20) 100)
		legend( 
			pos(6) size(vsmall) stack row(2)
			label(1 "Repeat")
			label(2 "Clarification")
			label(3 "Inapp. responses")
			label(4 "Unable to answer" )
			label(5 "Any of the problems observed" )
			
			label(6 "")
			
			label(7 "Comprehension")
			label(8 "Retrieval")
			label(9 "Judgement")
			label(10 "Response" )
			label(11 "Any of the problems post-consolidation" )
			)
		bar(1, color(navy*0.4)) 
		bar(2, color(navy*0.6)) 
		bar(3, color(navy*0.8)) 
		bar(4, color(navy*1.0)) 
		bar(5, color(navy*2)) 				
		bar(6, color(white)) 				
		bar(7, color(cranberry*0.4)) 
		bar(8, color(cranberry*0.6)) 
		bar(9, color(cranberry*0.8)) 
		bar(10, color(cranberry*1.0)) 
		bar(11, color(cranberry*2)) 		
		ysize(3) xsize(6)	
		;
		#delimit cr

graph save Graph "temp.gph", replace
graph export "temp.png", replace	

putdocx paragraph
putdocx image "temp.png", height(3) width(6)		
}
	
putdocx pagebreak	
putdocx paragraph
putdocx text ("3. Problem respondents"), bold linebreak	
putdocx text (""), linebreak	
putdocx text ("Question: are there particular respondents who drive the 'problem question' pattern?"), linebreak	
putdocx text ("We calculate the total number of 'problem questions' per each respondent "), 
putdocx text ("where the respondent had at least one issue - ")
putdocx text ("during observation and post consolidation"), linebreak
putdocx text ("Below histograms show the distribution of the total number of problem questions by respondent."), linebreak
 
use "$datadir/PREM_CT_`country'.dta", clear

	sum yobs__any

	#delimit; 
	histogram yobs__any, 
		by(language,
			title("During observation, by language") 
			note("", size(vsmall)))
		w(1) start(0) frequency barwidth(0.9) discrete xlab(0(1) `r(max)', labsize(vsmall))
		 
		ytitle("Number of respondents")
		xtitle("Total number of questions with any issue during observation")
		;
		#delimit cr

graph save Graph "temp.gph", replace
graph export "temp.png", replace	

putdocx paragraph
putdocx image "temp.png", height(3) width(6)

	sum ypost__any
	
	#delimit; 
	histogram ypost__any, 
		by(language,
			title("Post consolidation, by language")
			note("", size(vsmall)))
		w(1) start(0) frequency barwidth(0.9) discrete xlab(0(1) `r(max)', labsize(vsmall))
		ytitle("Number of respondents")
		xtitle("Total number of questions with any issue post-consolidation")
		;
		#delimit cr

graph save Graph "temp.gph", replace
graph export "temp.png", replace	

putdocx paragraph
putdocx image "temp.png", height(3) width(6)
		
putdocx save Report_PREMs_CognitiveTest_`country'_$date.docx, replace

***CLEAN UP***

local datafiles: dir "$mydir" files "temp*.*"

foreach datafile of local datafiles {
        rm `datafile'
}

END OF THE NOTE

*https://www.stata.com/manuals/rptputexcel.pdf
sum yobs__any
return list
sum yobs__any ypost__any
return list
