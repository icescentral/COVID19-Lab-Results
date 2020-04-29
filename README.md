# COVID19-Lab-Results


BACKGROUND
----------
This program was created at ICES (Institute for Clinical Evaluative Sciences), an Ontario-based not-for-profit health institute, for the purpose of parsing lab results pertaining to SARS-CoV-2 (causes COVID-19) and other respiratory viruses. We used Jupyter Notebook and designed the algorithm based on laboratory text data from OLIS (Ontario Laboratories Information System), but respiratory virus test results are likely to be reported in a similar fashion elsewhere. Our goal is to create an efficient method to accurately interpret large amounts of incoming COVID-19 data so that it can be used for research purposes as quickly as possible. 

USAGE
-----
This script first cleans the text using some string manipulation and regular expressions, then employs tokenization to split the strings into smaller units (tokens). These tokens are labelled using a dictionary-based approach, in order to act as inputs to our in-house algorithm, which ultimately outputs an interpretation of the COVID-19 lab results.

The input file for this script is a SAS dataset (.sasb7bdat) containing order IDs, lab names, test request codes, observation codes (LOINC), test result release times, test result statuses, and test result free-text. The output file of this script is a csv with the input columns alongside an exclude_flag variable (whether the test result was withdrawn) and interpreted results (Positive [P]/Presumptive-positive [S]/Negative [N]/Indeterminate [I]/Pending [D]/Rejected [R]/Cancelled [C]) in multiple columns (one for each virus).

Note that we differentiate between COVID-19 (**covid** variable) and seasonal coronaviruses (**coronavirus** variable). Please consider doing manual review of the results to ensure that the text is interpreted accurately. Modifications may be required depending on how the texts of lab results are structured. This file is still a work in progress and will be updated frequently.

Our analysis is applied at the TEST RESULT level, and each observation that is part of the test result will have the same output. Before any downstream analysis, the output csv of the python script should be "rolled up" into more clinically relevant units of analysis (e.g., test request, lab report, testing episode). We will post a SAS script here shortly that will output results at a "testing episode" level.

ADDITIONAL INFORMATION
----------------------
An additional xlsx file is provided to assign additional information when there is an unidentified virus or test type in the text. This file can be updated as new LOINCs and test request codes are used. The script also creates a .pkl file in the directory to track distinct records in a pandas dataframe, so that review of new distinct records is easier and faster. 

EXAMPLES (TEXT CLEANING)
------------------------
**Example 1**:

Input string:
COVID-19 Virus Detection:\.br\COVID-19 virus RdRp gene:           Not detected\.br\COVID-19 virus Envelope gene:       Not detected\.br\COVID-19 virus Nucleocapsid gene:   Detected\.br\Interpretation:\.br\[COVID-19] virus DETECTED by real-time PCR based on …

Cleaned string:
covid 19 virus detection covid 19 virus rdrp gene not detected covid 19 virus envelope gene not detected covid 19 virus nucleocapsid gene detected interpretation covid 19 virus detected by real time pcr based on …

Tokens with labels:
['v_covid', 'connecting', 'v_unk', None, 'v_covid', 'connecting', 'v_unk', None, 't_pcr', 'r_neg', 'r_pos', 'v_covid', 'connecting', 'v_unk', 'v_covid', 'v_covid', 'r_neg', 'r_pos', 'v_covid', 'connecting', 'v_unk', 'v_covid', 'v_covid', 'r_pos', 'final', 'v_covid', 'connecting', 'v_unk', 'r_pos', 'v_unk', 'connecting', None, 't_pcr', None, None]
Initial result [virus, result, test, final?]:
[['v_covid', 'r_neg', 't_pcr', False], ['v_covid', 'r_neg', 't_pcr', False], 
['v_covid', 'r_pos', 't_pcr', False], ['v_covid', 'r_pos', 't_pcr', True]]

Final result:
covid = ‘P’

Interpretation (at the test result level):
Tested positive for COVID-19.

**Example 2**:

Input string:
\.br\SPECIMEN DESCRIPTION: NASOPHARYNGEAL SWAB\.br\ADDITIONAL INFO.: NONE\.br\PCR TEST: NO VIRUS DETECTED\.br\(note)\.br\This specimen was tested for Influenza A,\.br\Influenza B, Respiratory Syncytial Virus\.br\(RSV), Adenovirus, Human metapneumovirus,\.br\Parainfluenza virus type 1, Parainfluenza\.br\virus type 3, Rhinovirus/Enterovirus and\.br\COVID-19 virus by real time RT-PCR.\.br\A negative result does not preclude the\.br\presence of the above viruses …

Cleaned string:
specimen description nasopharyngeal swab additional info none pcr test no virus detected note this specimen was tested for influenza a influenza b respiratory syncytial virus rsv adenovirus human metapneumovirus parainfluenza virus type 1 parainfluenza virus type 3 rhinovirus enterovirus and covid 19 virus by real time rt pcr a negative result does not preclude the presence of the above viruses …

Tokens with labels:
['v_unk', None, None, None, None, None, None, 't_pcr', 'connecting', 'r_neg', 'v_unk', 'r_pos', 'stop', None, 'v_unk', None, None, 'connecting', 'v_flu_a', 'v_flu_a', 'v_flu_b', 'v_flu_b', 'v_rsv', 'v_rsv', 'v_rsv', 'v_rsv', 'v_adenovirus', None, 'v_hmv', 'v_para_1', 'v_para_1', 'v_para_1', 'v_para_1', 'v_para_3', 'v_para_3', 'v_para_3', 'v_para_3', 'v_entero_rhino', 'v_entero_rhino', None, 'v_covid', 'connecting', 'v_unk', 'v_unk', 'connecting', None, None, 't_pcr', 'connecting', 'r_neg', 'connecting', 'skip', 'skip', 'stop', None, 'connecting', 'connecting', None, None, 'v_unk']

Initial result [virus, result, test, final?]:
[['v_unk', 'r_neg', 't_pcr', False], ['v_flu_a', 'r_neg', 't_pcr', False], 
['v_flu_b', 'r_neg', 't_pcr', False], ['v_rsv', 'r_neg', 't_pcr', False], 
['v_adenovirus', 'r_neg', 't_pcr', False], ['v_hmv', 'r_neg', 't_pcr', False], 
['v_para_1', 'r_neg', 't_pcr', False], ['v_para_3', 'r_neg', 't_pcr', False], 
['v_entero_rhino', 'r_neg', 't_pcr', False], ['v_covid', 'r_neg', 't_pcr', False]]

Final result:
covid = 'N', adenovirus = ‘N’, flu = ‘N’, flu_a = ‘N’, flu_b = ‘N’, entero_rhino = ‘N’, hmv = ‘N’, para = ‘N’, rsv = ‘N’

Interpretation (at the test result level):
Tested for COVID-19, adenovirus, influenza, entero/rhinovirus, human metapneumovirus, parainfluenza, and respiratory syncytial virus, and negative for all viruses tested for.

LICENSE
-------
Distributed under the GNU Affero General Public License v3.0. See LICENSE for more information.

CONTACT
-------
Please email Branson Chen [branson.chen@ices.on.ca] for any specific questions about the code and Mahmoud Azimaee [mahmoud.azimaee@ices.on.ca] for any other inquiries.

ACKNOWLEDGEMENTS
----------------
We would like to acknowledge contributions from Ontario’s Ministry of Health, Health Analytics and Insights branch and Health Data Science branch.
