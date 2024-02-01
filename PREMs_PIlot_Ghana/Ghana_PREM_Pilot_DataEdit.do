* This do file edits data that were downloaded from the server 
* It focuses on fixing sample ID and facility ID issues 
* It is based on the excel files from Dennis. See below for details about the files 

/*
global mydir "~/Dropbox/0iSquared/iSquared_WHO/PREM/Methods/4_DataAnalysis/Workshop/PREM_DM_Pilot_Workshop_Ghana/"
cd $mydir
dir

*File sent on 1/24/2024
import excel "PREMs phone interviews(resolved sample numbers).xlsx", sheet("Sheet1") firstrow case(lower) clear
drop if samplenumberonlimesurvey==.
d, short /* 70 cases */
*/
	capture drop xdate flag
	gen xdate = substr(submitdate, 1, 16)		
		list submitdate xdate in 1/5	
		codebook xdate
		
	#delimit; 	
	gen byte flag = 							
		(	A005 ==	4101	& A007 ==	1	& xdate == "2023-12-22 11:12") |
		(	A005 ==	4101	& A007 ==	2	& xdate == "2023-12-22 11:28") |
		(	A005 ==	4101	& A007 ==	5	& xdate == "2023-12-22 12:41") |
		(	A005 ==	4202	& A007 ==	7	& xdate == "2023-12-22 13:00") |
		(	A005 ==	4306	& A007 ==	8	& xdate == "2023-12-22 13:44") |
		(	A005 ==	4203	& A007 ==	9	& xdate == "2023-12-22 14:47") |
		(	A005 ==	4203	& A007 ==	11	& xdate == "2023-12-22 15:10") |
		(	A005 ==	4101	& A007 ==	12	& xdate == "2023-12-22 15:35") |
		(	A005 ==	4101	& A007 ==	2	& xdate == "2023-12-23 11:43") |
		(	A005 ==	4202	& A007 ==	4	& xdate == "2023-12-23 11:59") |
		(	A005 ==	4101	& A007 ==	5	& xdate == "2023-12-23 12:43") |
		(	A005 ==	4306	& A007 ==	8	& xdate == "2023-12-23 13:06") |
		(	A005 ==	4203	& A007 ==	10	& xdate == "2023-12-23 13:28") |
		(	A005 ==	4101	& A007 ==	11	& xdate == "2023-12-23 13:53") |
		(	A005 ==	4101	& A007 ==	13	& xdate == "2023-12-23 14:19") |
		(	A005 ==	4202	& A007 ==	18	& xdate == "2023-12-23 15:24") |
		(	A005 ==	4101	& A007 ==	19	& xdate == "2023-12-23 17:42") |
		(	A005 ==	4203	& A007 ==	5	& xdate == "2023-12-23 18:03") |
		(	A005 ==	4101	& A007 ==	1	& xdate == "2023-12-24 17:37") |
		(	A005 ==	4101	& A007 ==	1	& xdate == "2023-12-22 10:14") |
		(	A005 ==	4101	& A007 ==	2	& xdate == "2023-12-22 10:38") |
		(	A005 ==	4203	& A007 ==	3	& xdate == "2023-12-22 11:31") |
		(	A005 ==	4101	& A007 ==	5	& xdate == "2023-12-22 15:45") |
		(	A005 ==	4203	& A007 ==	6	& xdate == "2023-12-22 16:04") |
		(	A005 ==	4203	& A007 ==	8	& xdate == "2023-12-22 17:10") |
		(	A005 ==	4101	& A007 ==	12	& xdate == "2023-12-22 18:23") |
		(	A005 ==	41101	& A007 ==	3	& xdate == "2023-12-23 11:28") |
		(	A005 ==	41101	& A007 ==	4	& xdate == "2023-12-23 11:59") |
		(	A005 ==	41101	& A007 ==	7	& xdate == "2023-12-23 12:19") |
		(	A005 ==	4203	& A007 ==	9	& xdate == "2023-12-23 15:53") |
		(	A005 ==	4203	& A007 ==	12	& xdate == "2023-12-23 16:18") |
		(	A005 ==	4101	& A007 ==	13	& xdate == "2023-12-23 16:25") |
		(	A005 ==	4203	& A007 ==	18	& xdate == "2023-12-23 16:53") |
		(	A005 ==	4202	& A007 ==	23	& xdate == "2023-12-23 17:19") |
		(	A005 ==	4306	& A007 ==	24	& xdate == "2023-12-23 17:30") |
		(	A005 ==	4203	& A007 ==	25	& xdate == "2023-12-23 17:49") |
		(	A005 ==	4202	& A007 ==	27	& xdate == "2023-12-23 17:59") |
		(	A005 ==	4203	& A007 ==	28	& xdate == "2023-12-23 18:14") |
		(	A005 ==	4101	& A007 ==	5	& xdate == "2023-12-24 12:24") |
		(	A005 ==	4101	& A007 ==	5	& xdate == "2023-12-24 12:45") |
		(	A005 ==	4203	& A007 ==	7	& xdate == "2023-12-24 13:05") |
		(	A005 ==	4101	& A007 ==	8	& xdate == "2023-12-24 13:11") |
		(	A005 ==	4305	& A007 ==	11	& xdate == "2023-12-24 13:18") |
		(	A005 ==	4203	& A007 ==	13	& xdate == "2023-12-24 17:37") |
		(	A005 ==	4202	& A007 ==	14	& xdate == "2023-12-24 17:48") |
		(	A005 ==	4203	& A007 ==	15	& xdate == "2023-12-24 17:54") |
		(	A005 ==	4101	& A007 ==	1	& xdate == "2023-12-27 15:55") |
		(	A005 ==	4101	& A007 ==	2	& xdate == "2023-12-27 16:01") |
		(	A005 ==	4101	& A007 ==	3	& xdate == "2023-12-27 16:08") |
		(	A005 ==	4203	& A007 ==	4	& xdate == "2023-12-27 16:12") |
		(	A005 ==	4202	& A007 ==	5	& xdate == "2023-12-27 16:34") |
		(	A005 ==	4304	& A007 ==	8	& xdate == "2023-12-27 16:41") |
		(	A005 ==	4202	& A007 ==	9	& xdate == "2023-12-27 17:32") |
		(	A005 ==	4306	& A007 ==	12	& xdate == "2023-12-28 13:49") |
		(	A005 ==	4202	& A007 ==	13	& xdate == "2023-12-28 13:56") |
		(	A005 ==	4101	& A007 ==	14	& xdate == "2023-12-28 14:01") |
		(	A005 ==	4101	& A007 ==	17	& xdate == "2023-12-28 14:08") |
		(	A005 ==	4202	& A007 ==	3	& xdate == "2023-12-30 09:25") |
		(	A005 ==	4304	& A007 ==	4	& xdate == "2023-12-31 12:29") |
		(	A005 ==	4101	& A007 ==	7	& xdate == "2023-12-31 13:04") |
		(	A005 ==	4202	& A007 ==	12	& xdate == "2023-12-31 13:27") |
		(	A005 ==	4203	& A007 ==	13	& xdate == "2023-12-31 13:33") |
		(	A005 ==	4203	& A007 ==	14	& xdate == "2023-12-31 13:41") |
		(	A005 ==	4101	& A007 ==	17	& xdate == "2023-12-31 13:51") |
		(	A005 ==	4203	& A007 ==	23	& xdate == "2023-12-31 14:23") |
		(	A005 ==	4101	& A007 ==	24	& xdate == "2023-12-31 14:29") |
		(	A005 ==	4101	& A007 ==	25	& xdate == "2023-12-31 14:36") |
		(	A005 ==	4203	& A007 ==	26	& xdate == "2023-12-31 14:42") |
		(	A005 ==	4101	& A007 ==	27	& xdate == "2023-12-31 14:49") |
		(	A005 ==	4101	& A007 ==	28	& xdate == "2023-12-31 15:04") 		
		;
		#delimit cr
		
tab flag, m
	
/*
.         tab flag, m

       flag |      Freq.     Percent        Cum.
------------+-----------------------------------
          0 |      1,037       98.02       98.02
          1 |         21        1.98      100.00
------------+-----------------------------------
      Total |      1,058      100.00
	   

*/	

list submitdate xdate A005 A007 if flag==1

recode A007	1	=	295	if	A005 ==	4101	& A007 ==	1	& xdate == "2023-12-22 11:12" 
recode A007	2	=	315	if	A005 ==	4101	& A007 ==	2	& xdate == "2023-12-22 11:28" 
recode A007	5	=	375	if	A005 ==	4101	& A007 ==	5	& xdate == "2023-12-22 12:41" 
recode A007	7	=	415	if	A005 ==	4202	& A007 ==	7	& xdate == "2023-12-22 13:00" 
recode A007	8	=	435	if	A005 ==	4306	& A007 ==	8	& xdate == "2023-12-22 13:44" 
recode A007	9	=	455	if	A005 ==	4203	& A007 ==	9	& xdate == "2023-12-22 14:47" 
recode A007	11	=	495	if	A005 ==	4203	& A007 ==	11	& xdate == "2023-12-22 15:10" 
recode A007	12	=	515	if	A005 ==	4101	& A007 ==	12	& xdate == "2023-12-22 15:35" 
recode A007	2	=	319	if	A005 ==	4101	& A007 ==	2	& xdate == "2023-12-23 11:43" 
recode A007	4	=	359	if	A005 ==	4202	& A007 ==	4	& xdate == "2023-12-23 11:59" 
recode A007	5	=	379	if	A005 ==	4101	& A007 ==	5	& xdate == "2023-12-23 12:43" 
recode A007	8	=	459	if	A005 ==	4306	& A007 ==	8	& xdate == "2023-12-23 13:06" 
recode A007	10	=	499	if	A005 ==	4203	& A007 ==	10	& xdate == "2023-12-23 13:28" 
recode A007	11	=	519	if	A005 ==	4101	& A007 ==	11	& xdate == "2023-12-23 13:53" 
recode A007	13	=	559	if	A005 ==	4101	& A007 ==	13	& xdate == "2023-12-23 14:19" 
recode A007	18	=	291	if	A005 ==	4202	& A007 ==	18	& xdate == "2023-12-23 15:24" 
recode A007	19	=	311	if	A005 ==	4101	& A007 ==	19	& xdate == "2023-12-23 17:42" 
recode A007	5	=	339	if	A005 ==	4203	& A007 ==	5	& xdate == "2023-12-23 18:03" 
recode A007	1	=	479	if	A005 ==	4101	& A007 ==	1	& xdate == "2023-12-24 17:37" 
recode A007	1	=	300	if	A005 ==	4101	& A007 ==	1	& xdate == "2023-12-22 10:14" 
recode A007	2	=	320	if	A005 ==	4101	& A007 ==	2	& xdate == "2023-12-22 10:38" 
recode A007	3	=	340	if	A005 ==	4203	& A007 ==	3	& xdate == "2023-12-22 11:31" 
recode A007	5	=	380	if	A005 ==	4101	& A007 ==	5	& xdate == "2023-12-22 15:45" 
recode A007	6	=	400	if	A005 ==	4203	& A007 ==	6	& xdate == "2023-12-22 16:04" 
recode A007	8	=	440	if	A005 ==	4203	& A007 ==	8	& xdate == "2023-12-22 17:10" 
recode A007	12	=	520	if	A005 ==	4101	& A007 ==	12	& xdate == "2023-12-22 18:23" 
recode A007	3	=	304	if	A005 ==	41101	& A007 ==	3	& xdate == "2023-12-23 11:28" 
recode A007	4	=	324	if	A005 ==	41101	& A007 ==	4	& xdate == "2023-12-23 11:59" 
recode A007	7	=	384	if	A005 ==	41101	& A007 ==	7	& xdate == "2023-12-23 12:19" 
recode A007	9	=	444	if	A005 ==	4203	& A007 ==	9	& xdate == "2023-12-23 15:53" 
recode A007	12	=	504	if	A005 ==	4203	& A007 ==	12	& xdate == "2023-12-23 16:18" 
recode A007	13	=	524	if	A005 ==	4101	& A007 ==	13	& xdate == "2023-12-23 16:25" 
recode A007	18	=	346	if	A005 ==	4203	& A007 ==	18	& xdate == "2023-12-23 16:53" 
recode A007	23	=	421	if	A005 ==	4202	& A007 ==	23	& xdate == "2023-12-23 17:19" 
recode A007	24	=	436	if	A005 ==	4306	& A007 ==	24	& xdate == "2023-12-23 17:30" 
recode A007	25	=	451	if	A005 ==	4203	& A007 ==	25	& xdate == "2023-12-23 17:49" 
recode A007	27	=	481	if	A005 ==	4202	& A007 ==	27	& xdate == "2023-12-23 17:59" 
recode A007	28	=	496	if	A005 ==	4203	& A007 ==	28	& xdate == "2023-12-23 18:14" 
recode A007	5	=	337	if	A005 ==	4101	& A007 ==	5	& xdate == "2023-12-24 12:24" 
recode A007	5	=	322	if	A005 ==	4101	& A007 ==	5	& xdate == "2023-12-24 12:45" 
recode A007	7	=	352	if	A005 ==	4203	& A007 ==	7	& xdate == "2023-12-24 13:05" 
recode A007	8	=	367	if	A005 ==	4101	& A007 ==	8	& xdate == "2023-12-24 13:11" 
recode A007	11	=	412	if	A005 ==	4305	& A007 ==	11	& xdate == "2023-12-24 13:18" 
recode A007	13	=	442	if	A005 ==	4203	& A007 ==	13	& xdate == "2023-12-24 17:37" 
recode A007	14	=	457	if	A005 ==	4202	& A007 ==	14	& xdate == "2023-12-24 17:48" 
recode A007	15	=	472	if	A005 ==	4203	& A007 ==	15	& xdate == "2023-12-24 17:54" 
recode A007	1	=	298	if	A005 ==	4101	& A007 ==	1	& xdate == "2023-12-27 15:55" 
recode A007	2	=	313	if	A005 ==	4101	& A007 ==	2	& xdate == "2023-12-27 16:01" 
recode A007	3	=	328	if	A005 ==	4101	& A007 ==	3	& xdate == "2023-12-27 16:08" 
recode A007	4	=	343	if	A005 ==	4203	& A007 ==	4	& xdate == "2023-12-27 16:12" 
recode A007	5	=	418	if	A005 ==	4202	& A007 ==	5	& xdate == "2023-12-27 16:34" 
recode A007	8	=	403	if	A005 ==	4304	& A007 ==	8	& xdate == "2023-12-27 16:41" 
recode A007	9	=	478	if	A005 ==	4202	& A007 ==	9	& xdate == "2023-12-27 17:32" 
recode A007	12	=	463	if	A005 ==	4306	& A007 ==	12	& xdate == "2023-12-28 13:49" 
recode A007	13	=	508	if	A005 ==	4202	& A007 ==	13	& xdate == "2023-12-28 13:56" 
recode A007	14	=	538	if	A005 ==	4101	& A007 ==	14	& xdate == "2023-12-28 14:01" 
recode A007	17	=	553	if	A005 ==	4101	& A007 ==	17	& xdate == "2023-12-28 14:08" 
recode A007	3	=	364	if	A005 ==	4202	& A007 ==	3	& xdate == "2023-12-30 09:25" 
recode A007	4	=	404	if	A005 ==	4304	& A007 ==	4	& xdate == "2023-12-31 12:29" 
recode A007	7	=	544	if	A005 ==	4101	& A007 ==	7	& xdate == "2023-12-31 13:04" 
recode A007	12	=	480	if	A005 ==	4202	& A007 ==	12	& xdate == "2023-12-31 13:27" 
recode A007	13	=	500	if	A005 ==	4203	& A007 ==	13	& xdate == "2023-12-31 13:33" 
recode A007	14	=	560	if	A005 ==	4203	& A007 ==	14	& xdate == "2023-12-31 13:41" 
recode A007	17	=	376	if	A005 ==	4101	& A007 ==	17	& xdate == "2023-12-31 13:51" 
recode A007	23	=	502	if	A005 ==	4203	& A007 ==	23	& xdate == "2023-12-31 14:23" 
recode A007	24	=	517	if	A005 ==	4101	& A007 ==	24	& xdate == "2023-12-31 14:29" 
recode A007	25	=	547	if	A005 ==	4101	& A007 ==	25	& xdate == "2023-12-31 14:36" 
recode A007	26	=	562	if	A005 ==	4203	& A007 ==	26	& xdate == "2023-12-31 14:42" 
recode A007	27	=	373	if	A005 ==	4101	& A007 ==	27	& xdate == "2023-12-31 14:49" 
recode A007	28	=	388	if	A005 ==	4101	& A007 ==	28	& xdate == "2023-12-31 15:04" 

drop flag xdate
