### COVID19_symptoms ###
### Input and output ###
The input file for the COVID19_symptoms script is a SAS dataset (.sasb7bdat) containing patient IDs, order IDs, lab names, test request codes, observation codes (LOINC), test result release times, test result statuses, and test result free-text. The script extracts symptom information from two columns of OLIS:
-	“observationvalue” field with observation code (i.e., LOINC) XON13543-4
-	“patientnoteclinicalinformation” field
The output file of this script is the covid19_symptoms dataset, a SAS dataset (.sasb7bdat) which contains the variables patientid, observationdate, symptomatic, symptoms and num_symptoms. 
### Dataset Variables: ### 
The COVID19_symptoms dataset contains the following columns.
-	Patientid: Patient ID
-	Observationdate: Date of specimen collection
-	Symptomatic: Y = symptomatic; N = asymptomatic
-	Symptoms: comma-delimited list of vetted text-strings that matched with symptomatic terms in the list
-	Num_symptoms: Number of symptomatic text-strings found in the original OLIS record
### Data processing ###
The script uses the text fields as described above, parses into text strings, and compares each component to the list of symptoms terms. Strings that match with any of the “symptomatic” terms from the list (see below) are flagged as symptomatic=’Y’. Similarly, strings that match with any of the “asymptomatic” terms are flagged as symptomatic=’N’. If a record has both symptomatic and asymptomatic terms, it was classified as “symptomatic”. The output dataset is filtered on records with non-null symptomatic status (i.e., symptomatic=”Y” or symptomatic=”N”) and a patientid, and then rolled-up into unique testing episodes (patientid + observationdate). Records with invalid patientids and records that did not contain any information to extract using this script are not included in the output dataset.
(NOTE: COVID-19 testing episodes that do not contain information about symptomatic status should not be assumed to be asymptomatic at the time of testing. Symptoms might not be recorded in OLIS, despite the individuals presenting with symptoms.)
### Symptoms List ### 
The list is created by parsing the “observationvalue” and “patientnoteclinicalinformation” field into individual text-string components, which generates a list of unique potential symptoms to be reviewed. This list is reviewed by subject matter experts at ICES. Text-strings that appear less frequently (i.e., 25 instances) were excluded and not reviewed.
