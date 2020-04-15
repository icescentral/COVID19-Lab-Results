# COVID19-Lab-Results


BACKGROUND
----------
This program was created at ICES (Institute of Clinical Evaluative Sciences), an Ontario-based not-for-profit health institute, for the purpose of parsing lab results pertaining to SARS-CoV-2 (causes COVID-19) and other respiratory viruses. We designed the algorithm based on laboratory text data from OLIS (Ontario Laboratories Information System), but respiratory virus test results are likely to be reported in a similar fashion elsewhere. Our goal is to create an efficient method to accurately interpret large amounts of incoming COVID-19 data so that it can be used for research purposes as quickly as possible. 

USAGE
-----
The input file for this script is a SAS dataset (.sasb7bdat) containing lab names, test request codes, observation codes (LOINC), and test result texts. The output file of this script is a csv with test results (Positive [P]/Negative [N]/Indeterminate [I]/Pending [D]/Cancelled [C]/Rejected [R]) in multiple columns (one for each virus), and in the same order as the input dataset. Note that we differentiate between COVID-19 and seasonal coronaviruses. Please consider doing manual review of the results to ensure that results are accurate. Modifications may be required depending on how the texts of lab results are structured. This file is still a work in progress and will be updated frequently.

ADDITIONAL INFORMATION
----------------------
An additional xlsx file is provided to assign additional information when there is an unidentified virus or test type in the text. This file can be updated as new LOINCs and test request codes are used. The script also creates a .pkl file in the directory to track distinct records in a pandas dataframe, so that review of new distinct records is easier and faster. 

LICENSE
-------
Distributed under the GNU Affero General Public License v3.0. See LICENSE for more information.

CONTACT
-------
Please email Branson Chen [branson.chen@ices.on.ca] for any specific questions about the code and Mahmoud Azimaee [mahmoud.azimaee@ices.on.ca] for any other inquiries.

ACKNOWLEDGEMENTS
----------------
We would like to acknowledge contributions from Ontario’s Ministry of Health, Health Analytics and Insights branch and Health Data Science branch.
