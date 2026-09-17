# ADB Key Indicators Processing Shiny Application

## 1. Overview

The **ADB Key Indicators Processing Shiny Application** is an R Shiny application designed to download, process, standardise, and prepare Asian Development Bank (ADB) Key Indicators data for Pacific Island countries.

The application retrieves ADB Key Indicators data through the ADB SDMX API, processes the configured indicators and countries, maps ADB economy codes to SPC PICT codes using a local `country.csv` reference file, standardises the resulting data structure, and produces the final dataset for the SPC DotStat REFDB.

The primary output dataset is:

```text
DF_ADBKI-data.CSV
```

The application also provides interactive data previews, processing summaries, a processing log, and a download function.

---

# 2. Purpose

The application provides a repeatable workflow for obtaining ADB Key Indicators data and preparing it for use within the SPC DotStat environment.

The application performs the following tasks:

1. Defines the Pacific Island countries to be downloaded.
2. Defines the ADB indicators required for the dataset.
3. Validates the local `country.csv` mapping file.
4. Creates an ADB SDMX API country query.
5. Downloads each configured indicator separately.
6. Converts downloaded fields to consistent data types.
7. Maps ADB economy codes to SPC PICT codes.
8. Standardises ADB unit information.
9. Renames and standardises selected ADB metadata fields.
10. Rounds observations according to the ADB `DECIMALS` field.
11. Combines all successfully downloaded indicators.
12. Saves the final dataset to the SPC DotStat REFDB.
13. Provides interactive tables for validation.
14. Provides a downloadable copy of the final dataset.

---

# 3. Application Structure

The application is implemented as a single R Shiny script.

The main components are:

```text
ADB Key Indicators Shiny Application
│
├── Required libraries
├── Working directory
├── Country configuration
├── Indicator configuration
├── Country API query
├── Shiny user interface
├── Shiny server
│   ├── Country validation
│   ├── Country mapping
│   ├── ADB API downloads
│   ├── Data standardisation
│   ├── Data combination
│   ├── Output generation
│   ├── Summary table
│   ├── Data preview
│   ├── Full data table
│   ├── Processing log
│   └── Download handler
└── Application launch
```

---

# 4. Required R Packages

The application requires the following R packages:

```r
library(shiny)
library(readr)
library(dplyr)
library(tibble)
library(DT)
```

The packages are used as follows:

| Package  | Purpose                                 |
| -------- | --------------------------------------- |
| `shiny`  | Application user interface and server   |
| `readr`  | Reading ADB SDMX-CSV API results        |
| `dplyr`  | Data transformation and standardisation |
| `tibble` | Data-frame/tibble handling              |
| `DT`     | Interactive data tables                 |

---

# 5. Working Directory

The application determines its current working directory using:

```r
repository <- normalizePath(
  ".",
  winslash = "/",
  mustWork = TRUE
)
```

The application therefore expects the supporting reference file to be available relative to the directory from which the application is launched.

---

# 6. Country Configuration

The application is configured to download data for 22 Pacific Island economies.

The configured PICT codes are:

```text
ASM
COO
FIJ
FSM
GUM
KIR
MNP
NAU
NCL
NIU
PCN
PLW
PNG
PYF
RMI
SAM
SOL
TKL
TON
TUV
VAN
WLF
```

The country list is stored in the `country` vector.

The application reports the number of configured countries in the user interface.

---

# 7. ADB Indicator Configuration

The application contains a predefined list of ADB Key Indicators.

The configured indicators cover areas including:

* Gross domestic product
* Gross value added by economic activity
* Industry
* Services
* Energy
* Consumer prices
* Consumer price components
* Other macroeconomic indicators

The complete indicator list configured in the application is:

```text
NGDPVA_R_ISIC4_A_XDC
NGDPVA_R_ISIC4_B_XDC
NGDPVA_R_ISIC4_C_XDC
NGDPVA_R_ISIC4_D_XDC
NGDPVA_R_ISIC4_E_XDC
NGDPVA_R_ISIC4_F_XDC
NGDPVA_WT_R_XDC_PS
NGDPVA_RT_R_XDC_PS
NGDPVA_R_ISIC4_G_XDC
NGDPVA_R_ISIC4_I_XDC
NGDPVA_R_ISIC4_H_XDC
NGDPVA_R_ISIC4_J_XDC
NGDPVA_R_ISIC4_K_XDC
NGDPVA_R_ISIC4_L_XDC
NGDPVA_R_ISIC4_M_XDC
NGDPVA_R_ISIC4_N_XDC
NGDPVA_R_ISIC4_O_XDC
NGDPVA_R_ISIC4_P_XDC
NGDPVA_R_ISIC4_Q_XDC
NGDPVA_R_ISIC4_R_XDC
NGDPVA_OSA_R_XDC_PS
NGDPVA_R_ISIC4_T_XDC
NGDPVA_R_ISIC4_U_XDC
NGDPVA_R_XDC
NGDP_R_PTX_PS
NGDPVA_R_ISIC4_A_PC_CP_A_PT
NGDPVA_IND_R_PTX_PS
NGDPVA_SER_R_PTX_PS
ENEL_PR_PS
ENEL_CS_PS
PCPI_IX
PCPI_CP_01_IX
PCPI_CP_02_IX
PCPI_CP_03_IX
PCPI_CP_04_IX
PCPI_CP_05_IX
PCPI_CP_06_IX
PCPI_CP_07_IX
PCPI_CP_08_IX
PCPI_CP_09_IX
PCPI_CP_10_IX
PCPI_CP_11_IX
PCPI_CP_13_IX
```

The number of configured indicators is displayed in the application.

---

# 8. Data Period

The application is configured to request data beginning in:

```text
2000
```

The API request uses:

```text
startPeriod=2000
```

No `endPeriod` parameter is currently applied, meaning the API returns the available observations from 2000 onward.

The user interface describes the configured data period as:

```text
2000 to 2026
```

The actual observations returned depend on the data currently available from the ADB API.

---

# 9. ADB SDMX API

The application retrieves data from the ADB Key Indicators SDMX API.

The API endpoint is constructed using:

```text
https://kidb.adb.org/api/v5/sdmx/data/
```

The dataflow used is:

```text
ADB,DF_KIDB
```

The query structure is:

```text
ADB,DF_KIDB/A.<INDICATOR>.<COUNTRIES>?version=3.0&format=sdmx-csv&startPeriod=2000
```

The application requests SDMX-CSV format:

```text
format=sdmx-csv
```

---

# 10. Country Query

The configured PICT codes are combined into a single API query:

```r
countries <- paste(
  country,
  collapse = "+"
)
```

The resulting query has the form:

```text
ASM+COO+FIJ+FSM+GUM+...
```

This country query is inserted into each indicator API request.

---

# 11. Country Reference File

The application requires a local reference file:

```text
country.csv
```

The expected location is:

```text
<application directory>/country.csv
```

The application checks that this file exists before beginning the download process.

If the file is missing, processing stops and the application displays an error.

---

# 12. Country Mapping

The `country.csv` file must contain at least the following fields:

```text
GEO_PICT
REF_AREA
```

The application reads these fields and renames `REF_AREA` to:

```text
ECONOMY_CODE
```

The mapping is created using:

```r
select(
  GEO_PICT,
  REF_AREA
) |>
rename(
  ECONOMY_CODE = REF_AREA
)
```

This mapping is used to convert ADB economy codes into SPC PICT codes.

---

# 13. Country Validation

Before downloading data, the application checks whether all configured PICT codes are present in the country mapping.

The check is performed using:

```r
missing_countries <- setdiff(
  country,
  economy$ECONOMY_CODE
)
```

If any country is missing, processing stops and the missing codes are displayed in the status and processing log.

This prevents the application from producing a dataset with incomplete PICT mapping.

---

# 14. Indicator Download Process

The application downloads each configured indicator separately.

For every indicator:

1. The indicator code is selected.
2. The API URL is constructed.
3. The current download progress is displayed.
4. The API is queried.
5. The returned SDMX-CSV data is read.
6. The data types are standardised.
7. PICT mapping is applied.
8. Observations are rounded.
9. The final fields are selected.
10. The processed indicator dataset is stored in a list.

Each successful dataset is stored using the indicator code as its list element name:

```r
downloaded_data[[ind]] <- data
```

---

# 15. Download Error Handling

Each API request is wrapped in `tryCatch()`.

If an individual indicator fails to download, the application:

* Records the error in the processing log.
* Skips that indicator.
* Continues downloading the remaining indicators.

For example:

```text
ERROR downloading <indicator>:
<error message>
```

This allows one failed indicator to be handled without automatically terminating the entire download process.

---

# 16. Empty API Results

If the API returns zero observations for an indicator, the application records:

```text
No data returned for <indicator>
```

The indicator is then skipped.

Only indicators with successfully returned observations are added to the final dataset.

---

# 17. Data Type Standardisation

The application explicitly standardises important fields before combining the indicator datasets.

This is important because ADB API responses may return fields such as `BASE_YEAR` with different data types between indicators.

The application converts fields to consistent types including:

```text
DATAFLOW
FREQ
INDICATOR
ECONOMY_CODE
TIME_PERIOD
OBS_VALUE
UNIT_MEASURE
UNIT_MULT
DECIMALS
FOOTNOTE
OBS_STATUS
REF_YEAR
BASE_PER
OBS_DATA_SOURCE
METHODOLOGY
OBS_COMMENT
```

For example:

```r
OBS_VALUE = as.numeric(OBS_VALUE)
```

and:

```r
BASE_PER = as.character(BASE_YEAR)
```

This prevents `bind_rows()` errors caused by inconsistent data types.

---

# 18. Dataflow

All observations are assigned to:

```text
SPC:DF_ADBKI(1.2)
```

The assignment is performed using:

```r
DATAFLOW = as.character(
  "SPC:DF_ADBKI(1.2)"
)
```

This standardises the dataset for the SPC DotStat environment.

---

# 19. Unit Standardisation

The ADB API provides the original unit in the `UNIT` field.

The application converts:

```text
PCT
```

to:

```text
PERCENT
```

using:

```r
UNIT_MEASURE = as.character(
  ifelse(
    UNIT == "PCT",
    "PERCENT",
    UNIT
  )
)
```

The original `UNIT` field is subsequently removed.

---

# 20. Economy Code Removal

After the country mapping is applied, the original ADB:

```text
ECONOMY_CODE
```

field is removed.

The corresponding SPC:

```text
GEO_PICT
```

field is retained.

The final dataset therefore uses the SPC PICT country dimension rather than the ADB economy code.

---

# 21. Observation Rounding

The application uses the ADB `DECIMALS` field to determine the number of decimal places for `OBS_VALUE`.

The calculation is:

```r
OBS_VALUE = round(
  OBS_VALUE,
  as.numeric(DECIMALS)
)
```

If `OBS_VALUE` is missing, it remains `NA`.

This preserves the precision specified by the ADB source data.

---

# 22. Final Data Fields

The final ADB dataset contains 16 fields:

```text
DATAFLOW
FREQ
GEO_PICT
INDICATOR
TIME_PERIOD
OBS_VALUE
METHODOLOGY
BASE_PER
OBS_DATA_SOURCE
UNIT_MEASURE
UNIT_MULT
OBS_STATUS
OBS_COMMENT
DECIMALS
FOOTNOTE
REF_YEAR
```

These fields are selected in this order before the individual indicator datasets are combined.

---

# 23. Metadata Field Standardisation

Several ADB metadata fields are renamed or standardised.

| ADB Source Field | Final Field                   |
| ---------------- | ----------------------------- |
| `BASE_YEAR`      | `BASE_PER`                    |
| `DATA_SOURCE`    | `OBS_DATA_SOURCE`             |
| `UNIT`           | `UNIT_MEASURE`                |
| `REF_AREA`       | `ECONOMY_CODE` during mapping |
| `ECONOMY_CODE`   | Removed after mapping         |
| `GEO_PICT`       | SPC PICT identifier           |

The application also creates:

```text
OBS_COMMENT
```

as a blank field.

---

# 24. Missing Values

The application replaces missing values with blank strings for all fields except:

```text
OBS_VALUE
```

This is performed using:

```r
mutate(
  across(
    -OBS_VALUE,
    ~ replace(
      .x,
      is.na(.x),
      ""
    )
  )
)
```

`OBS_VALUE` remains numeric so that the final observation values retain their numeric structure.

---

# 25. Combining Indicators

Each successfully downloaded indicator is stored in:

```r
downloaded_data
```

After all requested indicators have been processed, the individual datasets are combined using:

```r
final_data <- bind_rows(
  downloaded_data
)
```

The resulting dataset contains all successfully downloaded ADB indicators and their observations for the configured PICTs.

---

# 26. Handling Complete Download Failure

If no indicators are successfully downloaded:

```r
length(downloaded_data) == 0
```

the application does not create an output dataset.

The status is changed to:

```text
No ADB data were successfully downloaded.
```

The processing log records that no data were downloaded.

---

# 27. Output Directory

The final data is saved under the user's SPC DotStat OneDrive directory:

```text
C:/Users/<USERNAME>/OneDrive - SPC/DotStat/REFDB/DF_ADBKI/
```

The Windows username is obtained dynamically using:

```r
username <- Sys.getenv("USERNAME")
```

This avoids hard-coding the Windows username.

---

# 28. Timestamped Output Folder

Each successful processing run creates a new timestamped folder.

The folder naming convention is:

```text
YYYYMMDD_HHMMSS_data_Update
```

For example:

```text
20260917_153045_data_Update
```

The output structure is therefore:

```text
DF_ADBKI
│
└── 20260917_153045_data_Update
    │
    └── DF_ADBKI-data.CSV
```

Each processing run produces a separate folder, preserving previous outputs.

---

# 29. Output File

The application creates:

```text
DF_ADBKI-data.CSV
```

The file contains the combined ADB Key Indicators data after processing and standardisation.

The same dataset can also be downloaded directly from the Shiny application.

---

# 30. Shiny Download File

The application's download button generates a filename using the current date:

```text
DF_ADBKI-data_YYYYMMDD.CSV
```

For example:

```text
DF_ADBKI-data_20260917.CSV
```

The downloaded file contains the current processed dataset.

---

# 31. User Interface

The application uses standard Shiny components:

```r
fluidPage()
sidebarLayout()
sidebarPanel()
mainPanel()
tabsetPanel()
```

The application does not require `shinydashboard`.

---

# 32. Sidebar

The sidebar contains the following sections.

## ADB Data Processing

Provides a description of the application's purpose.

## Countries

Displays the number of configured countries.

## Indicators

Displays the number of configured ADB indicators.

## Data Period

Displays:

```text
2000 to 2026
```

## Process Data

The main processing button:

```text
Process Data
```

starts the ADB API download and processing workflow.

## Download ADB Data

The download button:

```text
Download ADB Data
```

downloads the processed dataset after successful processing.

## Status

Displays the current processing status, including:

* Download progress
* Number of countries
* Number of indicators
* Number of observations
* Number of columns
* Output folder

---

# 33. Application Tabs

The main panel contains three tabs:

```text
Summary
ADB Data
Processing Log
```

---

# 34. Summary Tab

The Summary tab contains:

1. Processing Summary
2. Final ADB Data preview

The Processing Summary provides information such as:

```text
Countries configured
Indicators configured
Countries in downloaded data
Indicators in downloaded data
ADB observations
Data columns
```

---

# 35. Final Data Preview

The Summary tab displays the first 100 observations from the final dataset.

The preview includes:

* Column filtering
* Pagination
* Horizontal scrolling
* Copy
* CSV export
* Excel export

Only the first 100 rows are displayed in the Summary preview.

---

# 36. ADB Data Tab

The ADB Data tab displays the complete processed dataset.

The table supports:

* Column filtering
* Pagination
* Horizontal scrolling
* Vertical scrolling
* Copy
* CSV export
* Excel export

The table is configured with:

```text
25 rows per page
```

and a vertical scroll area of approximately:

```text
600px
```

---

# 37. Processing Log Tab

The Processing Log tab displays the processing history for the current run.

The log records:

* Processing start time
* Downloaded indicators
* Number of rows returned for each indicator
* Indicators that failed
* Indicators returning no data
* Number of successful downloads
* Total rows
* Total columns
* Output file location

This provides a convenient audit trail for each processing run.

---

# 38. Progress Indicator

The application provides a progress bar during the indicator download process.

Progress is updated for each indicator:

```r
incProgress(
  1 / length(indicatorCode)
)
```

The progress detail identifies the current indicator and its position in the download sequence.

For example:

```text
Downloading 5 of 44: NGDPVA_R_ISIC4_E_XDC
```

The exact total depends on the number of indicators configured in the script.

---

# 39. API Request Delay

A two-second delay is inserted between indicator API requests:

```r
Sys.sleep(2)
```

This introduces a pause between requests and reduces the frequency of consecutive API calls.

---

# 40. Processing Workflow

The complete workflow is:

```text
Start Application
       │
       ▼
Load Country Configuration
       │
       ▼
Load country.csv
       │
       ▼
Validate PICT Country Mapping
       │
       ▼
Create ADB Country Query
       │
       ▼
For Each Indicator
       │
       ├── Build API URL
       │
       ├── Download SDMX-CSV
       │
       ├── Validate Response
       │
       ├── Standardise Data Types
       │
       ├── Map ADB Economy Code
       │
       ├── Standardise Units
       │
       ├── Round OBS_VALUE
       │
       ├── Select Final Fields
       │
       └── Store Dataset
       │
       ▼
Combine Successful Downloads
       │
       ▼
Save Final Dataset
       │
       ▼
Create Timestamped Output Folder
       │
       ▼
Write DF_ADBKI-data.CSV
       │
       ▼
Display Summary and Data
```

---

# 41. Processing Status

At the beginning of processing, the application displays:

```text
Starting ADB data processing...
```

During downloading, the status identifies the current indicator:

```text
Downloading indicator X of Y

<indicator code>
```

After successful processing, the status displays:

```text
Processing completed successfully.
```

It also provides:

```text
Countries
Indicators
Observations
Columns
Output folder
```

---

# 42. Processing Log Example

A successful processing log follows the general structure:

```text
ADB processing started at 2026-09-17 15:30:45

Downloaded 100 rows for INDICATOR_1.

Downloaded 120 rows for INDICATOR_2.

Downloaded 98 rows for INDICATOR_3.

========================================
DOWNLOAD COMPLETED
========================================

Indicators requested: 44
Indicators successfully downloaded: 44
Countries configured: 22
Total rows downloaded: ...
Total columns: 16

Output file:
C:/Users/<USERNAME>/OneDrive - SPC/DotStat/REFDB/DF_ADBKI/...
```

The actual counts depend on the current ADB API response.

---

# 43. Error Handling

The application handles errors at several stages.

## Missing `country.csv`

Processing stops if the reference file cannot be found.

## Invalid Country Mapping

Processing stops if a configured PICT code is not found in the mapping.

## Indicator Download Failure

A failed indicator is logged and skipped.

## Empty Indicator Response

An indicator returning zero rows is logged and skipped.

## Data Combination Error

If `bind_rows()` fails, the application reports:

```text
ERROR combining downloaded data.
```

The error is recorded in the processing log.

---

# 44. Troubleshooting

## `country.csv was not found`

Ensure that:

```text
country.csv
```

exists in:

```text
<application directory>/country.csv
```

---

## Missing Country Codes

Check that `country.csv` contains all configured ADB economy codes in the `REF_AREA` column.

The expected codes include:

```text
ASM
COO
FIJ
FSM
GUM
KIR
MNP
NAU
NCL
NIU
PCN
PLW
PNG
PYF
RMI
SAM
SOL
TKL
TON
TUV
VAN
WLF
```

---

## API Download Failure

Possible causes include:

* No internet connection
* ADB API unavailable
* ADB API endpoint changed
* Temporary network problem
* Proxy or firewall restrictions
* Invalid indicator code
* API query restrictions

The Processing Log should be checked to identify the affected indicator.

---

## No Data Returned

If an indicator returns no observations, the application logs:

```text
No data returned for <indicator>
```

The indicator is excluded from the final dataset.

---

## `bind_rows()` Data-Type Error

The application explicitly standardises several fields to avoid common errors such as:

```text
Can't combine ... <character> and ... <double>
```

In particular, fields such as:

```text
BASE_YEAR
REF_YEAR
DECIMALS
UNIT_MULT
```

are converted to consistent types before the datasets are combined.

---

# 45. Data Validation

After processing, the following checks should be performed.

## Countries

Confirm that the expected PICTs are represented in:

```text
GEO_PICT
```

## Indicators

Compare the number of successfully downloaded indicators with the number requested.

## Observations

Review the total number of observations.

## Frequencies

Check the values in:

```text
FREQ
```

## Time Period

Review:

```text
TIME_PERIOD
```

to confirm that the expected observations are available from 2000 onward.

## Observation Values

Check:

```text
OBS_VALUE
```

for numeric values and appropriate decimal precision.

## Units

Review:

```text
UNIT_MEASURE
```

to ensure the units have been standardised correctly.

## Metadata

Review:

```text
METHODOLOGY
BASE_PER
OBS_DATA_SOURCE
OBS_STATUS
DECIMALS
FOOTNOTE
REF_YEAR
```

where applicable.

---

# 46. Final Data Structure

The final dataset follows this structure:

| Column            | Description                     |
| ----------------- | ------------------------------- |
| `DATAFLOW`        | SPC DotStat dataflow identifier |
| `FREQ`            | Observation frequency from ADB  |
| `GEO_PICT`        | SPC PICT country code           |
| `INDICATOR`       | ADB Key Indicator code          |
| `TIME_PERIOD`     | Observation period              |
| `OBS_VALUE`       | Numeric observation             |
| `METHODOLOGY`     | ADB methodology information     |
| `BASE_PER`        | Base period/year                |
| `OBS_DATA_SOURCE` | Observation data source         |
| `UNIT_MEASURE`    | Observation unit                |
| `UNIT_MULT`       | Unit multiplier                 |
| `OBS_STATUS`      | Observation status              |
| `OBS_COMMENT`     | Observation comment             |
| `DECIMALS`        | Number of decimal places        |
| `FOOTNOTE`        | ADB footnote information        |
| `REF_YEAR`        | Reference year                  |

---

# 47. Important Maintenance Considerations

## ADB API

The application depends on the ADB Key Indicators API.

If the API endpoint, version, query structure, or response format changes, the API URL construction and processing logic may need to be updated.

The current endpoint uses:

```text
https://kidb.adb.org/api/v5/sdmx/data/
```

---

## Indicator List

The `indicatorCode` vector controls which ADB indicators are downloaded.

To add or remove indicators, update this vector.

---

## Country List

The `country` vector controls which PICTs are requested.

To add or remove countries, update this vector and ensure the corresponding mapping exists in `country.csv`.

---

## Dataflow Version

The application currently assigns:

```text
SPC:DF_ADBKI(1.2)
```

If the SPC DotStat dataflow version changes, update the `DATAFLOW` assignment accordingly.

---

## Output File Name

The production output is currently:

```text
DF_ADBKI-data.CSV
```

Changes to the required REFDB naming convention should be reflected in the output section of the script.

---

# 48. Required Supporting File

The application requires:

```text
country.csv
```

A typical application directory is:

```text
<application directory>
│
├── <ADB Shiny application>.R
└── country.csv
```

The application does not require the user to manually download the ADB data files because the data is retrieved directly from the ADB SDMX API.

---

# 49. Running the Application

## Step 1: Open RStudio

Open the ADB Key Indicators Shiny application script.

## Step 2: Check `country.csv`

Confirm that:

```text
country.csv
```

is in the application directory.

## Step 3: Check Internet Access

The application requires internet access to connect to the ADB API.

## Step 4: Start the Application

Run the complete R script.

The Shiny application should open in the RStudio Viewer or a web browser.

## Step 5: Process Data

Select:

```text
Process Data
```

The application will download the configured ADB indicators.

## Step 6: Review Results

Review:

* Summary
* Final ADB Data
* Processing Log

## Step 7: Confirm Output

Check the generated folder under:

```text
C:/Users/<USERNAME>/OneDrive - SPC/DotStat/REFDB/DF_ADBKI/
```

## Step 8: Download if Required

Use:

```text
Download ADB Data
```

to download a copy of the final dataset.

---

# 50. Recommended Processing Procedure

Before each production run:

* [ ] Confirm `country.csv` exists.
* [ ] Confirm all required PICT codes are present.
* [ ] Confirm the ADB API is accessible.
* [ ] Review the configured indicator list.
* [ ] Start the Shiny application.
* [ ] Select **Process Data**.
* [ ] Monitor the progress indicator.
* [ ] Review the Processing Log.
* [ ] Check the number of successfully downloaded indicators.
* [ ] Check the number of countries in the downloaded data.
* [ ] Check the total number of observations.
* [ ] Review the Final ADB Data table.
* [ ] Check `OBS_VALUE` values.
* [ ] Check `TIME_PERIOD`.
* [ ] Check `UNIT_MEASURE`.
* [ ] Confirm the final CSV was created.
* [ ] Confirm the output is in the correct REFDB directory.
* [ ] Download the final CSV if required.

---

# 51. Output Validation Checklist

The final `DF_ADBKI-data.CSV` should be checked for:

### Dataflow

```text
SPC:DF_ADBKI(1.2)
```

### Country Dimension

```text
GEO_PICT
```

should contain the expected SPC PICT codes.

### Indicator Dimension

```text
INDICATOR
```

should contain the requested ADB indicator codes that successfully returned data.

### Frequency

```text
FREQ
```

should reflect the frequency supplied by ADB.

### Time Period

```text
TIME_PERIOD
```

should contain observations from 2000 onward where available.

### Observation Value

```text
OBS_VALUE
```

should be numeric and rounded according to `DECIMALS`.

### Unit

```text
UNIT_MEASURE
```

should contain the standardised unit.

### Metadata

The following fields should be reviewed where applicable:

```text
METHODOLOGY
BASE_PER
OBS_DATA_SOURCE
UNIT_MULT
OBS_STATUS
OBS_COMMENT
DECIMALS
FOOTNOTE
REF_YEAR
```

---

# 52. Versioning and Output Management

Every successful processing run creates a new timestamped output folder.

The folder format is:

```text
YYYYMMDD_HHMMSS_data_Update
```

For example:

```text
20260917_153045_data_Update
```

This provides basic versioning of ADB Key Indicators updates and prevents subsequent processing runs from overwriting previous output files.

Previous output folders should be retained or archived according to the applicable SPC data-management procedures.

---

# 53. Processing Logic Summary

| Stage                   | Processing                               |
| ----------------------- | ---------------------------------------- |
| Country configuration   | 22 PICT codes                            |
| Indicator configuration | Predefined ADB Key Indicators            |
| Reference file          | `country.csv`                            |
| API source              | ADB Key Indicators SDMX API              |
| API format              | SDMX-CSV                                 |
| Start period            | 2000                                     |
| Country mapping         | `REF_AREA` → `ECONOMY_CODE` → `GEO_PICT` |
| Dataflow                | `SPC:DF_ADBKI(1.2)`                      |
| Unit standardisation    | `PCT` → `PERCENT`                        |
| Observation rounding    | According to `DECIMALS`                  |
| Missing metadata        | Blank strings                            |
| Failed indicators       | Logged and skipped                       |
| Empty indicators        | Logged and skipped                       |
| Combination             | `bind_rows()`                            |
| Output format           | CSV                                      |
| Output filename         | `DF_ADBKI-data.CSV`                      |
| Output location         | SPC DotStat REFDB                        |
| Versioning              | Timestamped folders                      |

---

# 54. Application Dependencies

The application depends on:

* R
* RStudio
* Shiny
* ADB Key Indicators SDMX API
* Internet access
* `country.csv`
* Access to the user's SPC OneDrive directory

The application does **not** require:

```text
shinydashboard
```

It uses standard Shiny components.

---

# 55. Summary

The **ADB Key Indicators Processing Shiny Application** provides a repeatable process for downloading ADB Key Indicators data for Pacific Island countries and preparing the results for SPC DotStat.

The application:

* Downloads ADB data directly from the SDMX API.
* Processes multiple indicators automatically.
* Covers the configured Pacific Island economies.
* Uses `country.csv` to map ADB economy codes to SPC PICT codes.
* Standardises data types across indicators.
* Standardises ADB units.
* Rounds observations according to ADB decimal metadata.
* Produces a standardised 16-column dataset.
* Provides interactive summary and data tables.
* Maintains a processing log.
* Creates timestamped output directories.
* Saves the production dataset to the SPC DotStat REFDB.
* Provides a downloadable CSV from the Shiny interface.

The primary production output is:

```text
DF_ADBKI-data.CSV
```

stored under:

```text
C:/Users/<USERNAME>/OneDrive - SPC/DotStat/REFDB/DF_ADBKI/
```
