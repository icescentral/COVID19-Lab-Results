
/*========================================================================  

© 2021 Institute for Clinical Evaluative Sciences. All rights reserved.

TERMS OF USE:
 
##Not for distribution.## This code and data is provided to the user solely for its own non-commercial use by individuals and/or not-for-profit corporations. User shall not distribute without express written permission from the Institute for Clinical Evaluative Sciences.

##Not-for-profit.## This code and data may not be used in connection with profit generating activities.

##No liability.## The Institute for Clinical Evaluative Sciences makes no warranty or representation regarding the fitness, quality or reliability of this code and data. 

##No Support.## The Institute for Clinical Evaluative Sciences will not provide any technological, educational or informational support in connection with the use of this code and data. 

##Warning.## By receiving this code and data, user accepts these terms, and uses the code and data, solely at its own risk. 

========================================================================*/


***************************************************************************************************
Project:	Data Quality - OLISC19 Symptoms dataset

Description:
- This program is used to create OLISC19 Symptoms Dataset
- The script first extracts symptom information from two areas of OLIS and creates a table text_symptoms:
    1. “observationvalue” field with observation code (i.e., LOINC) XON13543-4 [Patient symptoms]
    2. “patientnoteclinicalinformation” field for all records in the COVID-19 OLIS feed
- Next, it imports the Excel sheet of the symptom list which contains unique potential symptoms (1=symptomatic, 2=asymptomatic, 3=uncategorized)
- Two tables are created: symptoms_list which contains all flag 1, and asymptoms_list which has all flag 2
- The text_symptoms table is cleaned and compared with symptoms_list and asymptoms_list
- Lastly, the episode is created and outputs the final symptom dataset 
- Each testing episode will have addition variables to denote:
	- Symptomatic = Y [Symptomatic], N [Asymptomatic]
	- Symptoms = comma-deliminted list of vetted text-strings that matched with symptomatic terms in the list
	- Num_symptoms = Number of symptomatic text-string found in the original OLIS record

Datasets to use: Daily cumulative OLIS file
- 

Datasets created: covid19_symptoms
- 

Date of last update: 	Mar 11, 2022

Overview:
1. Set up
2. Data pulling
3. Filter symptoms and set symptomatic flag
4. Dataset creation

***************************************************************************************************;

options compress=binary;
/*input the path for the newest cumulative OLIS file*/
libname in '//'; 
/*input a temporary location to store text_symptoms*/
libname temp '//'; 

*1. Set up ;

	%let patientnotefile = ; /*use the newest cumulative OLIS file*/
	%let input_patientid = ikn; /*Please replace ikn and ikn_resolved with patientid and patientid_resolved variable in input dataset*/
	%let patientid_resolved = ikn_resolved;


*2. Pull data from two areas of OLIS: “observationvalue” under XON13543-4 and “patientnoteclinicalinformation”;

	/*observationcode ='XON13543-4'*/
	proc sql; 
	create table temp.a as 
	select coalesce(ikn_resolved, ikn) as ikn, ordersid, 
		reportinglaborgname, performinglaborgname, specimencollectororgname,
		datepart(observationdatetime) format=date9. as observationdate,
		upcase(observationvalue) as value, 
		'observationvalue' as source length=35
	from in.&patientnotefile.
	where observationcode = 'XON13543-4';
	quit;

	/*patientnoteclinicalinformation*/
	proc sql;
	create table temp.text_symptoms as
	select coalesce(ikn_resolved, ikn) as ikn, ordersid, 
		reportinglaborgname, performinglaborgname, specimencollectororgname,
		datepart(observationdatetime) format=date9. as observationdate,
		upcase(patientnoteclinicalinformation) as value, 
		'patientnoteclinicalinformation' as source length=35
	from in.&patientnotefile.
	where patientnoteclinicalinformation ^= '';
	quit;


	/*apppend the two datasets and remove duplicates*/
	proc append base=temp.text_symptoms data=temp.a force;
	run;
	proc sort data=temp.text_symptoms nodupkey;
	by _all_;
	run;


	/*import the symptom list - **UPDATED BY ICES monthly. Please check the GitHub page for the lastest updated version.*/
	libname fl XLSX '.xlsx';


	/*flag: 1=symptomatic, 2=asymptomatic,3=uncategorized*/
	    data final_list(keep=symptoms flag);
	    set fl.Sheet1;
	    run;
	/*create two datasets: symptoms_list with flag 1, and asymptoms_list with flag 2*/
	    data symptoms_list(keep=symptoms) asymptoms_list(keep=symptoms);
	    set final_list;
	    if flag=1 then output symptoms_list;
	    else if flag=2 then output asymptoms_list;
	    run;

	/*remove leading and trailing blanks and add double quotation marks. Store into macro variable*/
	    proc sql noprint;
	    select quote(strip(symptoms)) into :symptoms_list separated by ' '
	    from symptoms_list;
	    quit;

	    proc sql noprint;
	    select quote(strip(symptoms)) into :asymptoms_list separated by ' '
	    from asymptoms_list;
	    quit;  



*3. Filter symptoms and set symptomatic flag;

	data symptomatic (drop= i symptom numwords);
		length symptomatic $1 symptoms $300 symptom $100 num_symptoms 3;
		set temp.text_symptoms;
		/*clean puntuaction and other text */
		value = tranwrd(value, 'CLINICAL INFORMATION:',' ');
		value = tranwrd(value, 'OTHER:',' ');
		value = tranwrd(value, '\.BR\',';');
		value = tranwrd(value, 'SYMP-','SYMP,');
		value = tranwrd(value, 'SYMP -','SYMP,');
		value = tranwrd(value, 'SYMPTOMATIC -','SYMPTOMATIC,');
		value = tranwrd(value, 'SYMPTOMATIC-','SYMPTOMATIC,');
		value = tranwrd(value, 'SYMPTOMATIC:','SYMPTOMATIC,');
		value = tranwrd(value, '0SYMPTOMATIC:','SYMPTOMATIC,');
		value = tranwrd(value, 'SYMPTOMATIC.','SYMPTOMATIC,');
		value = tranwrd(value, 'SYMPTOMATICL:','SYMPTOMATIC,');
		value = tranwrd(value, 'SYMPTOMATICP:','SYMPTOMATIC,');
		value = tranwrd(value, 'SYMPTOMATOC -','SYMPTOMATIC,');

		/*if a term is stated “symptomatic” or “asymptomatic”, flag the event as Y or N, respectively*/
		if index(value,'SYMPTOMA') or index(value,'SYMTOMA') or index(value,'SYMPOTMA') 
			or value in ('SYM','Y','YES') or prxmatch('/.*SYMP\)?$/',strip(value))
			or index(value,'ASYM') or index(value,'NOSYMP') or index(value,'AWSYM') 
		    or index(value,'ASSYM') or index(value,'ONSET') then do;
			if index(value,'ASYM') or index(value,'NOSYMP') or index(value,'AWSYM') 
		    or index(value,'ASSYM') then symptomatic = 'N';
			else do; symptomatic = 'Y';end; 
		end;

		/*num_symptoms = Number of symptomatic text-string*/
		num_symptoms = 0;
		symptoms='';
		numwords = countw(value,',/;&');

		/*compare each piece to the vetted symptoms list, 
		flag the event as symptomatic=’Y’ or asymptomatic=’N’  if there is any match*/
		do i = 1 to numwords;
			symptom = upcase(strip(scan(value,i,',/;&')));
			if symptom in (&asymptoms_list.) then do;
				if symptomatic = '' then symptomatic = 'N';
			end;
			else if symptom in (&symptoms_list.) then do;
				symptomatic = 'Y';
				num_symptoms = num_symptoms + 1;
				if symptoms = '' then symptoms = symptom;
				else  symptoms = catx(', ',symptoms, symptom);
			end;
		end;
		if symptomatic ^= '' and &input_patientid. ^= '';

		run;



*4. Dataset creation;

/*make episode level*/

	proc sort data=symptomatic;
		by &input_patientid. observationdate descending symptomatic descending num_symptoms symptoms;
		run;

	proc sort data=symptomatic out=symptomatic2 nodupkey;
		by &input_patientid. observationdate;
		run;

/*output symptoms file only*/

	proc sql;
		create table covid19_symptoms as
		select &input_patientid., observationdate, symptomatic, symptoms, num_symptoms from symptomatic2;
		quit;

