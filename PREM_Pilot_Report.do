clear
clear matrix
clear mata
capture log close
set more off
numlabel, add

* Date of last code update: 5/25/2023
*   See Github for history of changes: 
*	https://github.com/yoonjoung/WHO_PREM
*	https://github.com/yoonjoung/WHO_PREM/blob/main/PREM_Pilot_DataManagement_WORKING.do

*This code 
*1) runs the data management do file **BOTH FILES MUST BE IN THE SAME DIRECTORY**
*2) calculates process metrics for evaluation of the PREMs pilot implementation 
*3) produces outputs 
*		=====> Second PURPLE TAB in Chartbook: "Pilot_Implementation"

*  DATA IN:	
*		1. PREMs summary data (i.e., the first PURPLE TAB in Chartbook) 
*		2. Implementation summary data (i.e., the second PURPLE TAB in Chartbook) 

*  DATA OUT: 
*		1. Word document describing Implementation summary data - i.e., the second PURPLE TAB in Chartbook 

/* TABLE OF CONTENTS*/

* A. SETTING <<<<<<<<<<========== MUST BE ADAPTED: directories and local macro

* B. Run the implementation do file, which includes data management do file 

* C. Report: Implementation results 

* D. Report: PREMs results 

**************************************************************
* A. SETTING 
**************************************************************

*** Directory for this do file 
cd "~/Dropbox/0iSquared/iSquared_WHO/PREM/Methods/4_DataAnalysis/"

*** Define a directory for the chartbook (can be same or different from the main directory)
global chartbookdir "~/Dropbox/0iSquared/iSquared_WHO/PREM/Methods/4_DataAnalysis/"

*** Define a directory for PROCESSED data files 
global datadir "~/Dropbox/0iSquared/iSquared_WHO/PREM/Methods/4_DataAnalysis/DataProduced/"

*** Define local macro for the survey 
local country	 		 EXAMPLE /*country name*/	
local round 			 1 /*round*/		
local year 			 	 2023 /*year of the mid point in data collection*/	
local month 			 6 /*month of the mid point in data collection*/	

local surveyid 			 259237 /*LimeSurvey survey ID*/

*** Define local macro for response options specific to the country 

local countrylanguage1	 Spanish /*Country language 1*/

local geoname1	 		 Anne Arundel /*Study district names*/
local geoname2	 		 Baltimore 
local geoname3	 		 Harford
local geoname4	 		 Somerset

local type1 			 District Hospital /*Facility type*/
local type2 			 Health Center 
local type3 			 Health Post

local sector1 			 Public /*Managing authority*/
local sector2 			 Non Public 		

local service1 			 Service A /*ServiceArea*/		
local service2 			 Service B
local service3 			 Service C 
		
*** local macro for analysis (no change needed)  
local today=c(current_date)
local c_today= "`today'"
global date=subinstr("`c_today'", " ", "",.)

**************************************************************
* B. Run the implementation do file, which includes data management do file 
**************************************************************

*do PREM_Pilot_Implementation.do

**************************************************************
* C. Report: Implementation results  
**************************************************************

use "$datadir/PREM_Pilot_Process_`country'_R`round'.dta", clear /*Second PURPLE tab*/
	
	*Review categorical variables for which implementatino progress is summarized
		sort group grouplabel
		list group grouplabel axis
		
	*Create studyarm variable 
		gen temp1 = substr(grouplabel, 1, strpos(grouplabel, "_")-1) 
		gen temp2 = substr(grouplabel, strpos(grouplabel, "_") + 1, .)
			replace temp2 = substr(temp2, 1, strpos(temp2, "_") )
		gen studyarm = temp2 + temp1 
		capture drop temp*

*****1.Overall summary 
{
capture putdocx clear 
putdocx begin
putdocx paragraph
putdocx text ("PREMs pilot in `country': Implementation progress summary"), bold linebreak
putdocx text ("(last updated on `today')"),  linebreak	
putdocx text (" "), linebreak
putdocx text ("1. Number of who were sampled, were contacted, gave consent, and responded"), bold linebreak

	preserve
		
		keep if group=="Study arm_District"
		d, short

		#delimit;
		graph bar num_samp num_cntsuccess num_resp num_comp50 num_comp,
			by(studyarm, 
				row(1)
				title("Contact and consent rates among those who are sampled", size(medium))
				note("Update as of: $date", size(vsmall)) )
			ytitle("Number") 
			legend( 
				pos(6) size(vsmall) stack row(1)
				label(1 "Sampled")
				label(2 "Contacted successfully")
				label(3 "Consented")
				label(4 "Responded 50% or more of the questions")
				label(5 "Completed interview*")
				)
			bar(1, color(cranberry*0.4)) 
			bar(2, color(cranberry*0.6)) 			
			bar(3, color(cranberry*0.8)) 
			bar(4, color(navy*0.6)) 
			bar(5, color(navy*0.8)) 
		;	
		#delimit cr	

		graph save Graph "temp.gph", replace
		graph export "temp.png", replace	

putdocx paragraph
putdocx image "temp.png", height(3) width(6)			
}

*****2.Rates of contact, consent, and response 
{
putdocx paragraph
putdocx text ("2. Rates of contact, consent, and response"), bold linebreak
		
		#delimit;
		graph bar rate_cnt rate_cntsuccess rate_coop ,
			by(studyarm, 
				row(1)
				title("Contact and consent rates among those who are sampled", size(medium))
				note("Update as of: $date", size(vsmall)) )
			ytitle("Response rate (%)") ylabel(0 (20) 100)
			legend( 
				pos(6) size(vsmall) row(1)
				label(1 "Contact, any")
				label(2 "Contact, success")
				label(3 "Cosent")
				)
			bar(1, color(cranberry*0.4)) 
			bar(2, color(cranberry*0.6)) 			
			bar(3, color(cranberry*0.8)) 			
		;	
		#delimit cr	
		
		graph save Graph "temp.gph", replace
		graph export "temp.png", replace	

putdocx paragraph
putdocx image "temp.png", height(3) width(6)			
		
		#delimit;
		graph bar rate_resp* ,
			by(studyarm, 
				row(1)
				title("Response rate among those who consented", size(medium))
				note("Update as of: $date", size(vsmall)) )
			ytitle("Response rate (%)") ylabel(0 (20) 100)
			legend( 
				pos(6) size(vsmall) row(1)
				label(1 "Partial response rate")
				label(2 "Response rate")
				)
			bar(1, color(navy*0.4)) 
			bar(2, color(navy*0.6)) 			
		;	
		#delimit cr	
		
		graph save Graph "temp.gph", replace
		graph export "temp.png", replace	

putdocx paragraph
putdocx image "temp.png", height(3) width(6)	

		keep if regexm(studyarm, "Phone")==1
		
		#delimit;
		graph hbar pct_ph_cntsuccess pct_ph_cntsoelse pct_ph_nocnt pct_ph_invwronum,
			stack
			by(studyarm, 
				col(1)
				title("Percent distribution among those sampled", size(medium))
				note("Update as of: $date", size(vsmall)) )
			ytitle("(%)") ylabel(0 (20) 100)
			legend( 
				pos(6) size(vsmall) row(1) stack
				label(1 "Contacted, respondent")
				label(2 "Contacted, respondent unavailable")
				label(3 "Not contacted")
				label(4 "Invalid/wrong number")
				)
			bar(1, color(cranberry*0.6)) 	
			bar(2, color(green*0.4)) 	
			bar(3, color(green*0.6)) 	
			bar(4, color(green*0.8)) 		
		;	
		#delimit cr	
		
		graph save Graph "temp.gph", replace
		graph export "temp.png", replace	

putdocx paragraph
putdocx image "temp.png", height(3) width(6)			

	restore
}
	
*****3.Progerss over time 
{
putdocx paragraph
putdocx text ("3. Cumulative number of completed interviews and calls made over time"), bold linebreak
			
	preserve 
	
		keep if regexm(group, "Date")==1

			*gen date variable 
				replace axis = axis + "/2023"
				gen date = date(axis, "MDY")
				format date %td
				
			*gen cumulative variable
				sort studyarm date 
				foreach var of varlist num_comp num_call{
					gen `var'cum = `var' 
					replace `var'cum = `var'cum + `var'cum[_n-1] ///
											if studyarm==studyarm[_n-1]										
				}
			
			*reshape
				keep studyarm date num_*cum 	
				reshape wide num_*cum, i(date) j(studyarm) string
			
		#delimit;
		graph twoway line num_compcum* date , 
			title("Cumulative number of completed interviews over time")
			note("Update as of: $date", size(vsmall)) 
			ytitle("Cumulative number") 		
			yline(150)
			legend( 
				pos(3) size(vsmall) stack col(1)
				label(1 "FTF_English")
				label(2 "FTF_`countrylanguage1'")
				label(3 "Phone_English")
				label(4 "Phone_`countrylanguage1'")
				)			
		;	
		#delimit cr
		
		graph save Graph "temp.gph", replace
		graph export "temp.png", replace	

putdocx paragraph
putdocx image "temp.png", height(3) width(6)		
			
		#delimit;
		graph twoway line num_callcumPhone* date , 
			title("Cumulative number of calls made over time")
			note("Update as of: $date", size(vsmall)) 
			ytitle("Cumulative number") 		
			yline(150)
			legend( 
				pos(3) size(vsmall) stack col(1)
				label(1 "Phone_English")
				label(2 "Phone_`countrylanguage1'")
				)			
		;	
		#delimit cr
		
		graph save Graph "temp.gph", replace
		graph export "temp.png", replace	

putdocx paragraph
putdocx image "temp.png", height(3) width(6)		

	restore 
}
	
putdocx save Report_PREMs_Pilot_Implementation_`country'_$date.docx, replace		

**************************************************************
* D. Report: PREMs results 
**************************************************************

use "$datadir/PREM_`country'_R`round'.dta", clear /*First PURPLE tab*/

