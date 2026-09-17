# UIS Data and Metadata Processing Shiny Application

## Overview

The **UIS Data and Metadata Processing Shiny Application** is an R Shiny application developed to download, process, transform, and export education statistics from the **UNESCO Institute for Statistics (UIS)** API.

The application performs two related processing tasks:

1. Downloads UIS indicator data for selected Pacific Island countries and territories.
2. Downloads and processes indicator metadata, including glossary terms and definitions.

The resulting data is transformed into the SPC `DF_UIS` SDMX structure and can be downloaded directly from the application.

The application also automatically saves both the processed UIS data and metadata to the SPC DotStat `REFDB/DF_UIS` OneDrive directory.

---

## Main Features

The application provides:

* UIS education data retrieval using the `uisapi` R package.
* UIS indicator metadata retrieval through the UIS public API.
* Processing for 17 Pacific Island countries and territories.
* Processing of a configured list of UIS indicators.
* Data extraction for the period **2000–2026**.
* Indicator code transformation for SPC naming conventions.
* Country-code mapping using a local `country.csv` reference file.
* UIS indicator metadata extraction.
* Glossary metadata extraction and expansion.
* Interactive data previews using `DT`.
* Processing status and progress indicators.
* Summary statistics.
* Separate data and metadata downloads.
* Combined ZIP download containing both files.
* Automatic creation of timestamped OneDrive output folders.

---

# Data Sources

## UIS Data API

UIS indicator observations are retrieved using the `uisapi` package:

```r
uis_get(
  entities = country,
  indicators = indicatorCode,
  start_year = 2000,
  end_year = 2026
)
```

The application therefore relies on the current availability and structure of the UIS public data API.

---

## UIS Metadata API

Indicator metadata is retrieved from the UIS public definitions API:

```text
https://api.uis.unesco.org/api/public/definitions/indicators
```

The request includes:

```text
disaggregations=true
glossaryTerms=true
```

This allows the application to retrieve indicator definitions together with disaggregation and glossary information.

---

# Countries

The application is configured to process 17 Pacific Island countries and territories.

| Code | Country/Territory              |
| ---- | ------------------------------ |
| COK  | Cook Islands                   |
| FJI  | Fiji                           |
| FSM  | Federated States of Micronesia |
| KIR  | Kiribati                       |
| MHL  | Marshall Islands               |
| NRU  | Nauru                          |
| NIU  | Niue                           |
| PNG  | Papua New Guinea               |
| PCN  | Pitcairn                       |
| PLW  | Palau                          |
| SLB  | Solomon Islands                |
| TKL  | Tokelau                        |
| TON  | Tonga                          |
| TUV  | Tuvalu                         |
| VUT  | Vanuatu                        |
| WLF  | Wallis and Futuna              |
| WSM  | Samoa                          |

The country list is defined in the application as:

```r
country <- c(
  "COK",
  "FJI",
  "FSM",
  "KIR",
  "MHL",
  "NRU",
  "NIU",
  "PNG",
  "PCN",
  "PLW",
  "SLB",
  "TKL",
  "TON",
  "TUV",
  "VUT",
  "WLF",
  "WSM"
)
```

To add or remove countries, modify this vector.

---

# UIS Indicators

The application is configured with a predefined list of UIS indicator codes.

These include indicators covering areas such as:

* Learning outcomes
* Completion rates
* Gross enrolment ratios
* Net enrolment rates
* Literacy
* Qualification and teacher indicators
* Out-of-school populations
* School infrastructure
* WASH in schools
* Scholarships
* Pupil/teacher ratios
* Transition rates
* Other education-related indicators

The complete indicator list is stored in the `indicatorCode` vector in `app.R`.

The application currently processes the configured indicator list, rather than dynamically discovering indicators from UIS.

To add or remove indicators, modify:

```r
indicatorCode <- c(
  ...
)
```

---

# Data Period

The application retrieves UIS observations from:

```text
2000 to 2026
```

This is configured using:

```r
start_year = 2000
end_year = 2026
```

The data period should be reviewed when updating the application for future UIS releases.

---

# Application Workflow

The overall processing workflow is:

```text
Start
  │
  ▼
Reset application data
  │
  ▼
Read country.csv
  │
  ▼
Download UIS indicator data
  │
  ▼
Transform UIS observations
  │
  ├── Add SPC dataflow fields
  ├── Rename UIS variables
  ├── Standardise indicator codes
  └── Round observation values
  │
  ▼
Merge with SPC country reference
  │
  ▼
Create DF_UIS dataset
  │
  ▼
Download UIS indicator metadata
  │
  ├── Indicator metadata
  └── Glossary metadata
  │
  ▼
Create OneDrive output folder
  │
  ├── DF_UIS_data.CSV
  └── UIS_metadata.CSV
  │
  ▼
Display data and metadata
  │
  ▼
Enable downloads
```

---

# UIS Data Processing

## 1. Download UIS Data

UIS data is retrieved using:

```r
data <- uis_get(
  entities = country,
  indicators = indicatorCode,
  start_year = 2000,
  end_year = 2026
)
```

The API response contains UIS observation data for the configured countries, indicators, and years.

---

## 2. Add SPC Fields

The retrieved data is transformed by adding SPC SDMX fields:

```r
DATAFLOW = "SPC:DF_UIS(1.0)"
FREQ = "A"
UNIT_MEASURE = ""
UNIT_MULT = ""
OBS_STATUS = ""
DATA_SOURCE = ""
OBS_COMMENT = ""
```

---

## 3. Rename UIS Variables

The UIS variables are renamed to the SPC SDMX naming convention:

| UIS Variable   | SPC Variable  |
| -------------- | ------------- |
| `entity_id`    | `COU`         |
| `year`         | `TIME_PERIOD` |
| `indicator_id` | `INDICATOR`   |
| `value`        | `OBS_VALUE`   |

---

## 4. Standardise Indicator Codes

Indicator codes returned by UIS use periods as separators.

For example:

```text
AIR.1.GLAST
```

is converted to:

```text
AIR_1_GLAST
```

This is performed using:

```r
INDICATOR = gsub(
  "\\.",
  "_",
  INDICATOR
)
```

This ensures that indicator identifiers conform to the naming convention required by the downstream SPC processing workflow.

---

## 5. Standardise Observation Values

Observation values are converted to numeric and rounded to two decimal places:

```r
OBS_VALUE = round(
  as.numeric(OBS_VALUE),
  2
)
```

---

# Country Reference Mapping

The application requires a local country reference file:

```text
country.csv
```

The file must be located in the same directory as `app.R`.

The application checks for this file using:

```r
country_file <- file.path(
  repository,
  "country.csv"
)
```

If the file cannot be found, UIS data processing is stopped.

---

## Country Reference File

The reference file is used to map UIS country codes to SPC country codes.

The application merges the UIS data using:

```r
merge(
  data_final_temp,
  countries,
  by = "COU"
)
```

The country reference file is expected to provide the `GEO_PICT` variable used in the final SPC dataset.

The following reference columns are removed after the merge:

```text
COU
ctyCur
Region
Country
REF_AREA
```

---

# Final DF_UIS Data Structure

The final UIS data is structured as:

```text
DATAFLOW
FREQ
TIME_PERIOD
GEO_PICT
INDICATOR
OBS_VALUE
UNIT_MEASURE
UNIT_MULT
OBS_STATUS
DATA_SOURCE
OBS_COMMENT
```

## Column Descriptions

| Column         | Description                        |
| -------------- | ---------------------------------- |
| `DATAFLOW`     | SPC SDMX dataflow identifier       |
| `FREQ`         | Observation frequency              |
| `TIME_PERIOD`  | Observation year                   |
| `GEO_PICT`     | SPC Pacific country/territory code |
| `INDICATOR`    | UIS indicator identifier           |
| `OBS_VALUE`    | Indicator observation              |
| `UNIT_MEASURE` | Unit of measurement                |
| `UNIT_MULT`    | Unit multiplier                    |
| `OBS_STATUS`   | Observation status                 |
| `DATA_SOURCE`  | Source of the observation          |
| `OBS_COMMENT`  | Observation comment                |

The dataflow is set to:

```text
SPC:DF_UIS(1.0)
```

and the frequency is:

```text
A
```

representing annual observations.

---

# Metadata Processing

The application includes a separate metadata-processing function called:

```r
metadata_function()
```

This function retrieves indicator metadata from the UIS definitions API.

The API request is:

```text
https://api.uis.unesco.org/api/public/definitions/indicators?disaggregations=true&glossaryTerms=true
```

---

# Indicator Metadata

The application extracts the following indicator-level metadata:

| Field                       | Description                      |
| --------------------------- | -------------------------------- |
| `indicatorCode`             | UIS indicator identifier         |
| `name`                      | Indicator name                   |
| `theme`                     | UIS indicator theme              |
| `lastDataUpdate`            | Date of the latest data update   |
| `lastDataUpdateDescription` | Description of the latest update |

Nested metadata fields such as `dataAvailability`, `disaggregations`, and `glossaryTerms` are initially retrieved but removed from the indicator-level table after their required information has been processed.

---

# Glossary Metadata

Glossary information is extracted and expanded into a separate tabular structure.

The metadata processing includes fields such as:

```text
indicatorCode
termId
termName
language
definition
definitionSource
purpose
calculationMethod
dataRequired
dataSource
typesOfDisaggregation
interpretation
qualityStandards
limitations
themes
```

This converts nested JSON glossary structures into a flat table suitable for CSV export and further processing.

---

# Glossary Themes

Where an individual glossary term contains multiple themes, the themes are combined into a semicolon-separated value.

For example:

```text
Theme A; Theme B; Theme C
```

This is performed using:

```r
paste(
  unlist(
    g$themes %||% list()
  ),
  collapse = "; "
)
```

---

# Metadata Selection

The metadata API may return definitions for indicators beyond those configured for the application.

The application therefore filters the metadata to the requested `indicatorCode` list.

This ensures that the resulting metadata file corresponds to the indicators being processed by the application.

---

# Shiny User Interface

The application contains a sidebar and three primary tabs.

## Sidebar

The sidebar displays:

* UIS processing information
* Number of configured PICTs
* Number of configured indicators
* Data period
* Process Data button
* Download UIS Data button
* Download Metadata button
* Download Both Files button
* Processing status

---

# Summary Tab

The **Summary** tab provides a processing overview.

The summary includes:

| Item             | Description                      |
| ---------------- | -------------------------------- |
| Countries        | Number of configured countries   |
| Indicators       | Number of configured indicators  |
| UIS observations | Number of processed observations |
| Data columns     | Number of final data columns     |
| Metadata records | Number of metadata records       |
| Metadata columns | Number of metadata columns       |

A preview of the first 100 UIS observations is also displayed.

---

# UIS Data Tab

The **UIS Data** tab displays the complete processed `DF_UIS` dataset.

The table provides:

* Column filtering
* Pagination
* Horizontal scrolling
* Automatic column sizing

Up to 25 rows are displayed per page by default.

---

# Metadata Tab

The **Metadata** tab displays the processed UIS indicator metadata.

The table provides:

* Column filtering
* Pagination
* Horizontal scrolling
* Automatic column sizing

Up to 25 rows are displayed per page by default.

---

# Download Options

The application provides three download options.

## 1. Download UIS Data

The final UIS data is downloaded using the filename:

```text
DF_UIS_data_YYYYMMDD.CSV
```

For example:

```text
DF_UIS_data_20260917.CSV
```

---

## 2. Download Metadata

The metadata file is downloaded using:

```text
UIS_metadata_YYYYMMDD.CSV
```

For example:

```text
UIS_metadata_20260917.CSV
```

---

## 3. Download Both Files

The **Download Both Files** option creates a ZIP archive containing:

```text
DF_UIS_data.CSV
UIS_metadata.CSV
```

The ZIP filename follows:

```text
UIS_data_and_metadata_YYYYMMDD.zip
```

For example:

```text
UIS_data_and_metadata_20260917.zip
```

---

# OneDrive Output

After successful processing, the application automatically creates a timestamped output directory under:

```text
C:/Users/<USERNAME>/OneDrive - SPC/DotStat/REFDB/DF_UIS
```

The Windows username is obtained automatically using:

```r
username <- Sys.getenv("USERNAME")
```

---

## Output Folder Naming

The output folder follows the naming convention:

```text
YYYYMMDD_HHMMSS_UIS_data_Update
```

For example:

```text
20260917_155730_UIS_data_Update
```

---

## Output Files

Each processing run creates:

```text
DF_UIS_data.CSV
UIS_metadata.CSV
```

The resulting structure is:

```text
DF_UIS/
└── 20260917_155730_UIS_data_Update/
    ├── DF_UIS_data.CSV
    └── UIS_metadata.CSV
```

Each processing run creates a new timestamped directory rather than overwriting a previous processing run.

---

# Required R Packages

The application requires the following packages:

```r
library(shiny)
library(uisapi)
library(httr2)
library(jsonlite)
library(dplyr)
library(tidyr)
library(purrr)
library(tibble)
library(readr)
library(DT)
```

Install them with:

```r
install.packages(c(
  "shiny",
  "uisapi",
  "httr2",
  "jsonlite",
  "dplyr",
  "tidyr",
  "purrr",
  "tibble",
  "readr",
  "DT"
))
```

---

# Project Structure

The recommended project structure is:

```text
DF_UIS/
│
├── app.R
├── country.csv
└── README.md
```

The application does not require manually created output directories because the required OneDrive directory and timestamped processing directory are created by the application.

---

# Running the Application

Open `app.R` in RStudio and run:

```r
shiny::runApp()
```

Alternatively, click **Run App** in RStudio.

Once the application starts:

1. Confirm that the configured countries and indicators are displayed.
2. Click **Process Data**.
3. Wait for UIS data processing to complete.
4. Wait for metadata processing to complete.
5. Review the **Summary** tab.
6. Review the **UIS Data** tab.
7. Review the **Metadata** tab.
8. Download the required files.

---

# Processing Status

The application displays the current processing state in the sidebar.

Examples include:

```text
Waiting for processing to start...
```

```text
Downloading UIS data from UIS API...
```

```text
Downloading UIS indicator metadata...
```

```text
Metadata processing complete.
```

After successful processing, the status includes:

* Number of UIS observations
* Number of UIS data columns
* Number of metadata records
* Number of metadata columns
* Output folder
* UIS data file path
* Metadata file path

---

# Error Handling

The application uses `tryCatch()` around both major processing operations.

## UIS Data Errors

If the UIS data request fails, the application:

1. Captures the error message.
2. Updates the processing status.
3. Displays a Shiny error notification.
4. Stops further processing.

Example:

```text
UIS data download failed: <error message>
```

---

## Metadata Errors

If metadata retrieval or processing fails, the application:

1. Captures the error.
2. Updates the status.
3. Displays an error notification.
4. Stops the output-writing stage.

---

## Output File Errors

The application also uses error handling when creating the OneDrive output directory and writing the two CSV files.

If writing fails, the application reports:

```text
ERROR writing output files:
```

followed by the relevant error message.

---

# Troubleshooting

## `country.csv` Not Found

If the application reports:

```text
Country reference file not found
```

verify that:

```text
country.csv
```

is located in the same directory as `app.R`.

Expected structure:

```text
app.R
country.csv
README.md
```

---

## UIS API Failure

If UIS data cannot be downloaded:

* Check that the computer has internet access.
* Check that the UIS API is available.
* Confirm that the configured indicator codes are valid.
* Confirm that the requested year range is supported.
* Check the error displayed in the application status.

---

## Metadata API Failure

If metadata cannot be retrieved:

* Check internet connectivity.
* Check that the UIS definitions API is available.
* Confirm that the configured indicator codes are valid.
* Check the error displayed in the application status.

---

## Missing Country Mapping

If observations disappear during the country-reference merge, check `country.csv`.

The UIS `COU` values must correspond to the country codes in the reference file.

The reference file should provide the corresponding `GEO_PICT` value required by the SPC dataset.

---

## OneDrive Output Failure

If the application cannot write the output files, check:

1. OneDrive is installed and running.
2. The `DotStat/REFDB/DF_UIS` directory is accessible.
3. The current Windows user has write permissions.
4. The Windows username is correctly returned by:

```r
Sys.getenv("USERNAME")
```

5. The OneDrive directory is available locally rather than cloud-only.

---

# Updating the Indicator List

The indicator list is maintained directly in `app.R`.

To add an indicator:

```r
indicatorCode <- c(
  ...
  "NEW.INDICATOR"
)
```

To remove an indicator, remove its code from the vector.

After modifying the list, test the application to ensure that:

* UIS data is available.
* Metadata exists.
* The indicator is returned by the UIS API.
* The indicator is correctly transformed into the final `INDICATOR` field.

---

# Updating the Country List

The country vector can be modified as required:

```r
country <- c(
  "COK",
  "FJI",
  "FSM",
  ...
)
```

Any newly added country must:

1. Be supported by the UIS API.
2. Have a corresponding entry in `country.csv`.
3. Have a valid `GEO_PICT` mapping.

---

# Important Data Transformation Rules

The following rules are applied to UIS data before export:

| Transformation               | Result                |
| ---------------------------- | --------------------- |
| `entity_id` → `COU`          | UIS country code      |
| `year` → `TIME_PERIOD`       | Observation year      |
| `indicator_id` → `INDICATOR` | Indicator identifier  |
| `value` → `OBS_VALUE`        | Numeric observation   |
| `.` in indicator codes       | `_`                   |
| Observation values           | Rounded to 2 decimals |
| Frequency                    | `A`                   |
| Dataflow                     | `SPC:DF_UIS(1.0)`     |

---

# Metadata Transformation Rules

The metadata processing performs the following:

1. Retrieves all available indicator definitions from the UIS metadata API.
2. Extracts indicator-level metadata.
3. Extracts glossary terms.
4. Expands nested glossary records.
5. Converts multiple glossary themes into semicolon-separated text.
6. Removes nested metadata columns from the indicator-level dataset.
7. Joins indicator metadata with glossary metadata.
8. Restricts the result to the configured indicator list.
9. Produces a flat CSV-compatible metadata dataset.

---

# Output Summary

A successful processing run produces two primary datasets.

## UIS Data

```text
DF_UIS_data.CSV
```

Contains processed UIS observations in the SPC `DF_UIS` structure.

## UIS Metadata

```text
UIS_metadata.CSV
```

Contains indicator definitions and glossary metadata associated with the configured UIS indicators.

---

# Maintenance Checklist

When updating the application, review the following:

* [ ] UIS API availability
* [ ] `uisapi` package compatibility
* [ ] UIS indicator codes
* [ ] UIS country codes
* [ ] UIS metadata API structure
* [ ] Indicator metadata fields
* [ ] Glossary metadata fields
* [ ] `country.csv` mappings
* [ ] SPC `DF_UIS` dataflow structure
* [ ] OneDrive output path
* [ ] Requested data period
* [ ] R package versions

Particular attention should be given to changes in the UIS API response structure. Changes to field names or nested metadata structures may require modifications to the data and metadata processing functions.

---

# Application Architecture

The application consists of three main components:

### 1. Configuration

Defines:

* Countries
* Indicators
* Data period
* Output location

### 2. Data Processing

Uses `uis_get()` to retrieve UIS observations and transforms them into the SPC `DF_UIS` format.

### 3. Metadata Processing

Uses the UIS public definitions API to retrieve and flatten indicator and glossary metadata.

The Shiny interface then provides interactive previews and download functionality for the resulting datasets.

---

# Intended Use

This application is intended to support the **SPC / DotStat data preparation workflow** by providing a repeatable process for retrieving UIS education indicators and associated metadata for Pacific Island countries and territories.

The final data can be used as an input to subsequent SPC SDMX validation, processing, and dissemination workflows.

---

# Version Information

**Application:** UIS Data and Metadata Processing Shiny Application

**Source Provider:** UNESCO Institute for Statistics (UIS)

**Output Dataflow:**

```text
SPC:DF_UIS(1.0)
```

**Data Period:**

```text
2000–2026
```

**Geographic Coverage:**

```text
17 Pacific Island countries and territories
```

**Processing Framework:**

```text
R + Shiny + UIS API + SDMX
```
