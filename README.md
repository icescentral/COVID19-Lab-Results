# COVID19-Lab-Results

BACKGROUND
----------

This set of scripts were created at ICES (Institute for Clinical Evaluative Sciences), an Ontario-based not-for-profit health institute, for the purpose of: **1)** parsing lab results pertaining to SARS-CoV-2 (causes COVID-19) and other respiratory viruses and **2)** rolling up the lab results into more clinically relevant "testing episodes". We used Jupyter Notebook (including Python libraries: pandas, numpy,  nltk,  re) and designed the algorithms based on laboratory data from OLIS (Ontario Laboratories Information System), but respiratory virus test results are likely to be reported in a similar fashion elsewhere. Our goal is to create an efficient method to accurately interpret large amounts of incoming COVID-19 data so that it can be used for research purposes as quickly as possible. 

USAGE
-----

### COVID19_processing ###

The COVID19_processing.ipynb script first cleans the text using some string manipulation and regular expressions, then employs tokenization to split the strings into smaller units (tokens). These tokens are labelled using a dictionary-based approach, in order to act as inputs to our in-house algorithm, which ultimately outputs an interpretation of the COVID-19 lab results. Please see the **Overview** section of this script for a more thorough description.

The input file for this script is a SAS dataset (.sasb7bdat) containing patient IDs, order IDs, lab names, test request codes, observation codes (LOINC), test result release times, test result statuses, and test result free-text. The output file of this script is a CSV file (.csv) with an exclude_flag variable (denoting whether the test result was withdrawn) and interpreted results ([P] Positive/[S] preSumptive-positive/[I] Indeterminate/[N] Negative/[D] penDing/[C] Cancelled/[R] Rejected) in multiple columns (one for each virus). There is an additional parameter, output_flag, in the **Input variables** section that can add on the original input columns or the key columns to the output file.

An Excel file (COVID19_Resp_codes_YYYYMMDD.xls) is provided to assign additional information in the first script when there is an unidentified virus or test type in the text. This file can be updated as new LOINCs and test request codes are used. The Jupyter Notebook also creates a Python pickle file (.pkl) in the directory to track unique records in a pandas dataframe, so that manual review of new unique records is easier and faster.

Note that we differentiate between COVID-19 (**covid** variable) and seasonal coronaviruses (**coronavirus** variable). Please consider doing manual review of the results to ensure that the text is interpreted accurately. Modifications may be required depending on how the texts of lab results are structured. This file is still a work in progress and will be updated frequently.

Our analysis is applied at the TEST RESULT level, and each observation that is part of the test result will have the same virus interpretations. Before any downstream analysis, the output file of the Python script should be "rolled up" into more clinically relevant units of analysis (e.g., test result --> test request --> lab report --> testing episode).

### COVID19_rollup ###

The COVID19_rollup.ipynb script rolls up interpretations from test results all the way up to "testing episodes", which we define as each unique combination of patientid and observationdate (i.e., specimen collection date). We created different hierarchies so that the most relevant COVID-related test results would take priority in the roll-up. Please see the **Overview** section of this script for a more thorough description.

The input file for this script is a CSV file (.csv) that contains COVID-19 interpretation flags along with multiple key columns (generated from previous script; please specify output_flag = 1 or 2). The output file of this script is a CSV file (.csv) that contains a COVID-19 result for each testing episode. There is additional information included, like all of the IDs of lab orders associated with the testing episode, observation release date, and a COVID test flag. Please see the **Data definitions** section of the script for more details on the output variables.

### COVID19_voc_processing ###

The COVID19_voc_processing.ipynb script specifically processes results pertaining to COVID 19 Variants of Concern (VOCs). The processing and rollup, similar to the two COVID 19 scripts above, is done within one script. DISCLAIMER: This script is still a work in progress in preliminary stages and is still undergoing validation and checks. 

The input file for this script is a subset of the SAS dataset used in the COVID 19 processing script. The dataset is subset by including records that fall under test request (TR) codes TR12952-8 (VOC screening) and TR12953-6 (VOC sequencing), as well as any records that contain words relating to VOCs (see script for more details). 

An intermediate output file of this script is a CSV file (.csv) with an exclude_flag variable (denoting whether the test result was withdrawn) and interpreted results ([P] Positive/[S] preSumptive-positive/[N] Negative/[I] Indeterminate/[D] penDing/[C] Cancelled/[R] Rejected) in multiple columns:
-	scr_voc: overall screening result, positive if at least one positive mutation result
-	scr_sgene_n501y/e484k: screening result for S gene mutations
-	seq_sgene_n501y/e484k/k417n: sequencing result for S gene mutations
-	seq_voc: overall sequencing result, positive if at least one positive VOC result
-	seq_voc_b117/b1351/p1/p2: sequencing result for identified VOCs

Having a mutation detected by sequencing or screening does not necessarily mean that a VOC is identified; the only definitive VOC identification is from sequencing and will be reported in the variables that start with seq_voc. Furthermore, results can mention a detection of VOC by sequencing but not contain the specific VOC identified (e.g., information systems are not set up to handle reporting of newly identified VOCs). Note that the file structure can change significantly and frequently due to changes in the screening/sequencing processes and reporting as new COVID-19 variants arise and public health priorities shift. Please interpret these results with caution and a good understanding of VOCs.

This script also uses the Excel file (COVID19_VOC_codes_YYYYMMDD.xls) to assign additional information in case of unidentified virus or test types. Similar to the previous script, a .pkl file is also created to track and review new records. Please consider doing manual review of the results to ensure that the text is interpreted accurately. Modifications may be required depending on how the texts of lab results are structured. This file is still a work in progress and will be updated frequently.

The second part of this script rolls up interpretations up to "testing episodes", which we define as each unique combination of patientid and observationdate (i.e., specimen collection date). The script assigns a result for the episode for each result column by taking the latest clear result (P>N>I>D) if there is one. Otherwise, the next latest result is taken.  Please see more details in the **Overview** section. 

The final output file of the script is a CSV file (.csv) that contains sequencing and screening result for each testing episode. There is additional information included, like a test completed flag for each test type. 

EXAMPLES (TEXT CLEANING)
------------------------

### Example 1: ###

**Input string:**
`COVID-19 Virus Detection:\.br\COVID-19 virus RdRp gene:           Not detected\.br\COVID-19 virus Envelope gene:       Not detected\.br\COVID-19 virus Nucleocapsid gene:   Detected\.br\Interpretation:\.br\[COVID-19] virus DETECTED by real-time PCR based on …`

**Cleaned string:**
`covid 19 virus detection covid 19 virus rdrp gene not detected covid 19 virus envelope gene not detected covid 19 virus nucleocapsid gene detected interpretation covid 19 virus detected by real time pcr based on …`

**Tokens with labels:**
`['v_covid', 'connecting', 'v_unk', None, 'v_covid', 'connecting', 'v_unk', None, 't_pcr', 'r_neg', 'r_pos', 'v_covid', 'connecting', 'v_unk', 'v_covid', 'v_covid', 'r_neg', 'r_pos', 'v_covid', 'connecting', 'v_unk', 'v_covid', 'v_covid', 'r_pos', 'final', 'v_covid', 'connecting', 'v_unk', 'r_pos', 'v_unk', 'connecting', None, 't_pcr', None, None]`

**Initial result [virus, result, test, final?]:**
`[['v_covid', 'r_neg', 't_pcr', False], ['v_covid', 'r_neg', 't_pcr', False], 
['v_covid', 'r_pos', 't_pcr', False], ['v_covid', 'r_pos', 't_pcr', True]]`

**Final result:**
`covid = ‘P’`

**Interpretation (at the test result level):**
Tested positive for COVID-19.

### Example 2: ###

**Input string:**
`\.br\SPECIMEN DESCRIPTION: NASOPHARYNGEAL SWAB\.br\ADDITIONAL INFO.: NONE\.br\PCR TEST: NO VIRUS DETECTED\.br\(note)\.br\This specimen was tested for Influenza A,\.br\Influenza B, Respiratory Syncytial Virus\.br\(RSV), Adenovirus, Human metapneumovirus,\.br\Parainfluenza virus type 1, Parainfluenza\.br\virus type 3, Rhinovirus/Enterovirus and\.br\COVID-19 virus by real time RT-PCR.\.br\A negative result does not preclude the\.br\presence of the above viruses …`

**Cleaned string:**
`specimen description nasopharyngeal swab additional info none pcr test no virus detected note this specimen was tested for influenza a influenza b respiratory syncytial virus rsv adenovirus human metapneumovirus parainfluenza virus type 1 parainfluenza virus type 3 rhinovirus enterovirus and covid 19 virus by real time rt pcr a negative result does not preclude the presence of the above viruses …`

**Tokens with labels:**
`['v_unk', None, None, None, None, None, None, 't_pcr', 'connecting', 'r_neg', 'v_unk', 'r_pos', 'stop', None, 'v_unk', None, None, 'connecting', 'v_flu_a', 'v_flu_a', 'v_flu_b', 'v_flu_b', 'v_rsv', 'v_rsv', 'v_rsv', 'v_rsv', 'v_adenovirus', None, 'v_hmv', 'v_para_1', 'v_para_1', 'v_para_1', 'v_para_1', 'v_para_3', 'v_para_3', 'v_para_3', 'v_para_3', 'v_entero_rhino', 'v_entero_rhino', None, 'v_covid', 'connecting', 'v_unk', 'v_unk', 'connecting', None, None, 't_pcr', 'connecting', 'r_neg', 'connecting', 'skip', 'skip', 'stop', None, 'connecting', 'connecting', None, None, 'v_unk']`

**Initial result [virus, result, test, final?]:**
`[['v_unk', 'r_neg', 't_pcr', False], ['v_flu_a', 'r_neg', 't_pcr', False], 
['v_flu_b', 'r_neg', 't_pcr', False], ['v_rsv', 'r_neg', 't_pcr', False], 
['v_adenovirus', 'r_neg', 't_pcr', False], ['v_hmv', 'r_neg', 't_pcr', False], 
['v_para_1', 'r_neg', 't_pcr', False], ['v_para_3', 'r_neg', 't_pcr', False], 
['v_entero_rhino', 'r_neg', 't_pcr', False], ['v_covid', 'r_neg', 't_pcr', False]]`

**Final result:**
`covid = 'N', adenovirus = ‘N’, flu = ‘N’, flu_a = ‘N’, flu_b = ‘N’, entero_rhino = ‘N’, hmv = ‘N’, para = ‘N’, rsv = ‘N’`

**Interpretation (at the test result level):**
Tested for COVID-19, adenovirus, influenza, entero/rhinovirus, human metapneumovirus, parainfluenza, and respiratory syncytial virus, and negative for all viruses tested for.

LICENSE
-------

Distributed under the GNU Affero General Public License v3.0. See LICENSE for more information.

CONTACT
-------

Please email Branson Chen [branson.chen@ices.on.ca] for any questions about the COVID19_processing or COVID19_voc_processing scripts, Kinwah Fung [kinwah.fung@ices.on.ca] and Hannah Chung [hannah.chung@ices.on.ca] for any questions about the COVID19_rollup script, and Mahmoud Azimaee [mahmoud.azimaee@ices.on.ca] for any other inquiries.

ACKNOWLEDGEMENTS
----------------

We would like to acknowledge contributions from Ontario’s Ministry of Health, Health Analytics and Insights branch and Health Data Science branch.
