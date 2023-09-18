clear
clear matrix
clear mata
capture log close
set more off
numlabel, add

*This code creates "Model" datasets for the PREMs data. 
*	Country name = EXAMPLE
*	To test Q version: Questionnaire_8SEPT2023_WORKING
* 	https://worldhealthorg-my.sharepoint.com/:w:/r/personal/banicag_who_int/_layouts/15/Doc.aspx?sourcedoc=%7BA1DE21BB-2BD1-4F22-B36B-4B4EBC0AE145%7D&file=Questionnaire_8SEPT2023_WORKING.docx&action=default&mobileredirect=true

**************************************************************
* Part A. SETTING 
**************************************************************

*** Directory for this do file 
cd "~/Dropbox/0iSquared/iSquared_WHO/PREM/Methods/4_DataAnalysis/"
*** Define the Downloaded CSV folderes 
global downloadcsvdir "~/Dropbox/0iSquared/iSquared_WHO/PREM/Methods/4_DataAnalysis/ExportedCSV_FromLimeSurvey/"

**************************************************************
* Part B. Create observartions and duplicates
**************************************************************

*** 700 unique observations = 600 interviews + 100 lost phone sample 

	set obs 700

    egen id = seq(), f(1) t(700)	
	
	gen submitdate=""
	foreach var of varlist submitdate{		
	set seed 38
		generate random = runiform()
		replace `var' = "2023-05-16 23:59:15" if random<=0.10
		replace `var' = "2023-05-17 23:59:15" if random>0.10 & random<=0.20
		replace `var' = "2023-05-18 23:59:15" if random>0.20 & random<=0.30
		replace `var' = "2023-05-19 23:59:15" if random>0.30 & random<=0.40
		replace `var' = "2023-05-22 23:59:15" if random>0.40 & random<=0.50
		replace `var' = "2023-05-23 23:59:15" if random>0.50 & random<=0.60
		replace `var' = "2023-05-24 23:59:15" if random>0.60 & random<=0.70
		replace `var' = "2023-05-25 23:59:15" if random>0.70 & random<=0.80
		replace `var' = "2023-05-26 23:59:15" if random>0.80 & random<=0.90
		replace `var' = "2023-05-29 23:59:15" if random>0.90 
		drop random 
	}
		
		codebook id
	
*** CREATE a duplicate 

	expand 2 if id==20
	expand 3 if id==30
	
		codebook id
		egen temp=count(id), by(id)
				
	sort id temp
	list id submitdate if temp>1

		replace submitdate = "2023-05-16 23:59:15" if temp>1
		replace submitdate = "2023-05-17 23:59:15" if temp>1 & id==id[_n-1]
		replace submitdate = "2023-05-18 23:59:15" if temp>1 & id==id[_n-2]
		
		tab temp submitdate, m		
		drop temp
	
		codebook id
		
**************************************************************
* Part C. Create variables
**************************************************************

***** COVER 

/*
A004 	DISTRICT CODE
A005 	FACILITY CODE 
A006 	SERVICE AREA CODE 
A007	SERIAL NUMBER OF THE CLIENT 
*/
		
			gen a = .
			gen b = .
			gen c = .
			
			*district
			foreach var of varlist a {		
			set seed 1	
				generate random = runiform()
				replace `var' = 1 if random<=29 /*phone district*/
				replace `var' = 2 if random>0.29 & random<=0.50
				replace `var' = 3 if random>0.50 & random<=0.79 /*phone district*/
				replace `var' = 4 if random>0.79
				drop random 
			}	
			
			*type
			foreach var of varlist b {		
			set seed 2	
				generate random = runiform()
				replace `var' = 1 if random<=33
				replace `var' = 2 if random>0.33 & random<=0.66
				replace `var' = 3 if random>0.66
				drop random 
			}
			
			*service area
			foreach var of varlist c {		
			set seed 3
				generate random = runiform()
				replace `var' = 1 if random<=33
				replace `var' = 2 if random>0.33 & random<=0.66
				replace `var' = 3 if random>0.66
				drop random 
			}						

	gen A001 =.
		replace A001 = 1 if a==1 | a==3 /*Phone*/
		replace A001 = 2 if a==2 | a==4 /*FTF*/
				
	gen A002 = ""
	gen A003 = ""
							
	gen A004 = a
	
	gen A005 = a*100 + b*10 + c	

	gen A006 = . 
	foreach var of varlist A006{		
	set seed 38	
		generate random = runiform()
		replace `var' = 1 if random<=33
		replace `var' = 2 if random>0.33 & random<=0.66
		replace `var' = 3 if random>0.66
		drop random 
	}	
		replace A006 = 0 if b==3 
	
	gen A007 = round(100000*runiform(), 1)
	codebook A007

	drop a b c
	
***** COVER for phone interviews who participated

	gen A008=. 
	gen A009=.
	gen A010=.
	gen A011=.
	
	capture drop random 	
	foreach var of varlist A008{
	set seed 101	
		generate random = runiform() if A001==1
		replace `var' = 1 if A001==1 & random<=0.50 
		replace `var' = 2 if A001==1 & random>0.50 & random<=0.80
		replace `var' = 3 if A001==1 & random>0.80
	}
	
	capture drop random 	
	foreach var of varlist A009{
	set seed 102	
		generate random = runiform() if A001==1
		replace `var' = 1 if A001==1 & random<=0.80
		replace `var' = 2 if A001==1 & random>0.80
	}
	
	capture drop random 	
	foreach var of varlist A010{
	set seed 103	
		generate random = runiform() if A001==1 & A009==1
		replace `var' = 1 if A001==1 & A009==1 & random<=0.90
		replace `var' = 2 if A001==1 & A009==1 & random>0.90
	}
			
		replace A011 = 1 if A009==1 & A010==1
		replace A011 = 4 if A009==1 & A010==2
	
	capture drop random 	
	foreach var of varlist A011{
	set seed 104	
		generate random = runiform() if A001==1 & A009==2
		replace `var' = 2 if A001==1 & A009==2 & random<=0.30
		replace `var' = 3 if A001==1 & A009==2 & random>0.30 & random<=0.60
		replace `var' = 5 if A001==1 & A009==2 & random>0.60 & random<=0.80
		replace `var' = 6 if A001==1 & A009==2 & random>0.80		
	}
	
	tab A011 A001, m
	
		replace A008 = 1 if A011==5
		replace A008 = 1 if A011==6
	
	bysort A001: tab A011 A008, m
	
***** INFORMED CONSENT 
	
	global itemlist "Q001"
	foreach item in $itemlist{	
		gen `item' = . 
		}
	
	global itemlist "Q002"
	foreach item in $itemlist{	
		gen `item' = "NAME" 
		}
		
	capture drop random
	
	foreach var of varlist Q001 {
	set seed 38	
		generate random = runiform()
		replace `var' = 1 if random<=0.99
		replace `var' = 2 if random>0.99
		drop random 
	}			
				
***** SECTION 1

	#delimit;	
	global itemlist "
		Q100A Q100B 
		Q101 Q102 Q103 Q104 Q105 Q106 Q107 Q108 Q109 Q110 
		Q111 Q112 Q113 Q114 Q115 Q116 Q117 Q118 Q119 Q120
		Q121 Q122 Q123 Q124 Q125 Q126 Q127 Q128 Q129 Q130 
		Q131 Q132 Q133 Q134 Q135 Q136 Q137
		" ;
		#delimit cr
	foreach item in $itemlist{	
		gen `item' = . 
		}

	foreach var of varlist Q100A {
	set seed 38	
		generate random = runiform()
		replace `var' = 1 if random<=0.70
		replace `var' = 2 if random>0.70 & random<=0.98
		replace `var' = 3 if random>0.98
		drop random 
	}

	foreach var of varlist Q100B {
	set seed 83
		generate random = runiform()
		replace `var' = 1 if random<=0.70
		replace `var' = 2 if random>0.70 & random<=0.98
		replace `var' = 3 if random>0.98
		drop random 
	}
		
		tab Q100A Q100B, m
		replace Q100A = 1 if Q100A!=1 & Q100B!=1
		tab Q100A Q100B, m
	
	foreach var of varlist Q101 {
	set seed 38	
		generate random = runiform()
		replace `var' = 1 if random<=0.05
		replace `var' = 2 if random>0.05 & random<=0.50
		replace `var' = 3 if random>0.50 & random<=0.80
		replace `var' = 4 if random>0.80 & random<=0.90
		replace `var' = 5 if random>0.90 
		drop random 
	}				
	
	foreach var of varlist Q102 {
	set seed 38	
		generate random = runiform()
		replace `var' = 1 if random<=0.50
		replace `var' = 2 if random>0.50 & random<=0.65
		replace `var' = 3 if random>0.65
		drop random 
	}					
	
	#delimit;	
	global varlist_5 "
		          Q103 Q104 Q105 Q106 Q107 Q108 Q109 Q110 
		Q111                Q115 Q116 Q117 Q118 Q119 Q120
		Q121 Q122 Q123 Q124 Q125 Q126 Q127 Q128 Q129 
		Q131 Q132 Q133                Q137
		" ;
		#delimit cr
		
	global varlist_5na "Q112 Q113 Q114 "		
	global varlist_rate5 "Q136"	
	global varlist_rate5na "Q130"	
	global varlist_yesnonanotsure "Q134 Q135"
				
	foreach var of varlist $varlist_5 $varlist_rate5 {		
	set seed 38	
		generate random = runiform()
		replace `var' = 1 if random<=0.05
		replace `var' = 2 if random>0.05 & random<=0.15
		replace `var' = 3 if random>0.15 & random<=0.35
		replace `var' = 4 if random>0.35 & random<=0.75
		replace `var' = 5 if random>0.75 
		drop random 
	}					
	
	foreach var of varlist $varlist_5na $varlist_rate5na {		
	set seed 38	
		generate random = runiform()
		replace `var' = 1 if random<=0.05
		replace `var' = 2 if random>0.05 & random<=0.15
		replace `var' = 3 if random>0.15 & random<=0.35
		replace `var' = 4 if random>0.35 & random<=0.75
		replace `var' = 5 if random>0.75 & random<=0.90
		replace `var' = 6 if random>0.90 
		drop random 
	}	
	
	foreach var of varlist $varlist_yesnonanotsure {		
	set seed 38	
		generate random = runiform()
		replace `var' = 1 if random<=0.70
		replace `var' = 2 if random>0.70 & random<=0.90
		replace `var' = 3 if random>0.90 & random<=0.95
		replace `var' = 4 if random>0.95
		drop random 
	}		

***** SECTION 2
	
	#delimit;	
	global who5 "
		Q201 Q202 Q203 Q204 Q205
		" ;
		#delimit cr
	foreach item in $who5{	
		gen `item' = . 
		}
			
	foreach var of varlist $who5{		
	set seed 38	
		generate random = runiform()
		replace `var' = 5 if random<=0.10
		replace `var' = 4 if random>0.10 & random<=0.25
		replace `var' = 3 if random>0.25 & random<=0.50
		replace `var' = 2 if random>0.50 & random<=0.80
		replace `var' = 1 if random>0.80 & random<=0.90
		replace `var' = 0 if random>0.90
		drop random 
	}		
	
***** SECTION 3
	
	gen Q301 = round(rnormal(40, 10), 1)	
		replace Q301=18 if Q301<18
		
	gen Q302 = . 
	foreach var of varlist Q302{		
	set seed 97	
		generate random = runiform()
		replace `var' = 1 if random<=0.40
		replace `var' = 2 if random>0.40 & random<=0.95
		replace `var' = 3 if random>0.95 & random<=0.97
		replace `var' = 4 if random>0.97
		drop random 
	}		
	
	gen Q303 = . 
	foreach var of varlist Q303{		
	set seed 95	
		generate random = runiform()
		replace `var' = 1 if random<=0.15
		replace `var' = 2 if random>0.15 & random<=0.50
		replace `var' = 3 if random>0.50 & random<=0.80
		replace `var' = 4 if random>0.80
		drop random 
	}		
	
***** SECTION 4

	gen Q402=.
		replace Q402=1 if A004==1 | A004==2 /*ENGLISH district*/
		replace Q402=2 if A004==3 | A004==4 /*COUNTRY LANGUAGE district*/
	
	gen Q403a = . 
		replace Q403a = 1 if A001==2 & Q001==1
		replace Q403a = 2 if A001==2 & Q001==2

	capture drop random 	
	set seed 57	
		generate random = runiform() if A001==2  
		replace Q403a = 3 if A001==2 & Q403a == 1 & random>0.97
		drop random
		
		tab Q403a A001, m
		
	gen Q403b = . 
		replace Q403b = 1 if A001==1 & A011==1 & Q001==1
		replace Q403b = 2 if A001==1 & A011==1 & Q001==2

	capture drop random 	
	set seed 211	
		generate random = runiform() if A001==1 & A011==1 & Q001==1
		replace Q403b = 3 if A001==1 & A011==1 & Q001==1 & random>0.94 
		replace Q403b = 4 if A001==1 & A011==1 & Q001==1 & random>0.97
		replace Q403b = 5 if A001==1 & A011==1 & Q001==1 & random>0.98
		replace Q403b = 6 if A001==1 & A011==1 & Q001==1 & random>0.99
		drop random			

		bysort A001: tab Q403b A011, m 
	
**************************************************************
* Part E. Check duplicates 
**************************************************************
	
	sort id submitdate
	duplicates tag id, gen(duplicate) 			
	
	list duplicate id submitdate A* if duplicate!=0  
		
	foreach var of varlist A* {
		replace `var' = `var'[_n-1] if id==id[_n-1]& duplicate!=0  
		}		
	list duplicate id submitdate A* if duplicate!=0  
				
		gen str3 st_facilityid = string(A005,"%03.0f")
		gen str1 st_service = string(A006,"%01.0f")
		gen str4 st_listingnumber = string(A007, "%04.0f")
		
		codebook A005 A006 A007 st_*

		gen clientid = st_facilityid + "_" + st_service + "_" + st_listingnumber 		
		
	codebook id clientid
	
	capture drop duplicate 
	duplicates tag clientid, gen(duplicate) 		
	list duplicate id submitdate clientid if duplicate!=0  	

	drop clientid st_* duplicate
	
**************************************************************
* Part F. Replace with missing for lost phone interviews 
**************************************************************

foreach var of varlist Q001 Q1* Q2* Q3* Q402 { 
	replace `var'=. if A001==1 & A011!=1
}

bysort A001: tab Q403b A011, m

**************************************************************
* Part G. Export in CSV
**************************************************************
	
export delimited using "$downloadcsvdir/LimeSurvey_PREM_EXAMPLE.csv", replace

END OF CREATION	
		
/*	
**************************************************************
* Part H. Create another version with different submitdate with seconds
**************************************************************

import delimited "$downloadcsvdir/LimeSurvey_CombinedHFA_EXAMPLE_R3.csv", case(preserve) clear
	
	gen seconds = runiformint(10, 59)	
	tostring seconds, replace 
	gen test = submitdate + ":" + seconds
	*list submitdate seconds test
	replace submitdate = test
	*list submitdate seconds test
	drop seconds test
	
export delimited using "$downloadcsvdir/LimeSurvey_CombinedHFA_EXAMPLE_R3_V2.csv", replace
	
END OF DO FILE 
