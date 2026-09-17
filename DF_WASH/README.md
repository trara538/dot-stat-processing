# UNICEF WASH SDMX Data Processing Shiny Application

## Overview

The **UNICEF WASH SDMX Data Processing Shiny Application** is an R Shiny application designed to download, process, validate, combine, and export **Water, Sanitation and Hygiene (WASH)** data from the UNICEF SDMX API.

The application processes three UNICEF WASH SDMX dataflows for selected Pacific Island countries:

* `WASH_HOUSEHOLDS`
* `WASH_SCHOOLS`
* `WASH_HEALTHCARE_FACILITY`

The processed data is transformed into the required SPC `DF_WASH` SDMX format and can be downloaded directly from the application as a CSV file.

The application also automatically writes the final CSV output to the SPC DotStat `REFDB/DF_WASH` OneDrive directory.

---

## Features

The application provides the following functionality:

* Downloads WASH data from the UNICEF SDMX API.
* Processes data for 17 Pacific Island countries.
* Processes three separate WASH dataflows.
* Applies common WASH filters.
* Applies dataflow-specific filters.
* Tracks failed downloads and processing errors.
* Displays processing progress.
* Provides separate data previews for:

  * WASH Households
  * WASH Schools
  * WASH Healthcare Facilities
* Displays a combined final dataset.
* Displays a summary of the number of observations processed.
* Provides a failed-downloads report.
* Generates a final SPC `DF_WASH` dataset.
* Automatically saves the final dataset to the configured OneDrive folder.
* Allows users to download the final CSV directly from the Shiny application.

---

## Data Source

The application retrieves data using the R [`rsdmx`](https://cran.r-project.org/package=rsdmx) package and the UNICEF SDMX API.

The following provider is used:

```r
providerId = "UNICEF"
```

Data is retrieved using the configured SDMX dataflow and country code:

```r
readSDMX(
  providerId = "UNICEF",
  resource = "data",
  flowRef = flow,
  key = ctry
)
```

---

## Countries

The application is currently configured to process the following 17 Pacific Island countries and territories:

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

The country list is defined in the application source code:

```r
country <- c(
  "COK", "FJI", "FSM", "KIR", "MHL", "NRU", "NIU", "PNG", "PCN",
  "PLW", "SLB", "TKL", "TON", "TUV", "VUT", "WLF", "WSM"
)
```

To add or remove countries, modify this vector.

---

## Dataflows

Three UNICEF WASH dataflows are processed:

```r
dataflows <- c(
  "WASH_HOUSEHOLDS",
  "WASH_SCHOOLS",
  "WASH_HEALTHCARE_FACILITY"
)
```

### 1. WASH Households

Dataflow:

```text
WASH_HOUSEHOLDS
```

Additional filter:

```text
WEALTH_QUINTILE = _T
```

This retains the total population across wealth quintiles.

---

### 2. WASH Schools

Dataflow:

```text
WASH_SCHOOLS
```

Additional filter:

```text
SCH_TYPE = _T
```

This retains the total across school types.

---

### 3. WASH Healthcare Facility

Dataflow:

```text
WASH_HEALTHCARE_FACILITY
```

Additional filter:

```text
HCF_TYPE = _T
```

This retains the total across healthcare facility types.

---

## Common Data Filters

All three dataflows are filtered using the following common dimensions.

### Service Type

Only the following WASH service types are retained:

```text
HYG
SAN
WAT
```

These correspond to:

* `HYG` — Hygiene
* `SAN` — Sanitation
* `WAT` — Water

The filtering is performed using:

```r
filter(
  SERVICE_TYPE %in% c(
    "HYG",
    "SAN",
    "WAT"
  ),
  RESIDENCE == "_T"
)
```

### Residence

Only the total residence category is retained:

```text
RESIDENCE = _T
```

---

## Processing Workflow

When the **Process Data** button is selected, the application performs the following workflow:

```text
Start
  │
  ▼
Reset application data
  │
  ▼
Loop through each UNICEF WASH dataflow
  │
  ├── WASH_HOUSEHOLDS
  ├── WASH_SCHOOLS
  └── WASH_HEALTHCARE_FACILITY
  │
  ▼
Loop through each configured country
  │
  ▼
Download UNICEF SDMX data
  │
  ├── Successful
  │      │
  │      ▼
  │   Apply common filters
  │      │
  │      ▼
  │   Apply dataflow-specific filter
  │      │
  │      ▼
  │   Append data
  │
  └── Failed
         │
         ▼
      Record error
  │
  ▼
Create individual WASH datasets
  │
  ▼
Select required variables
  │
  ▼
Combine all three datasets
  │
  ▼
Merge with country reference file
  │
  ▼
Create SPC DF_WASH structure
  │
  ▼
Write CSV to OneDrive
  │
  ▼
Display results in Shiny
  │
  ▼
Complete
```

---

## Required Input File

The application requires a file named:

```text
country.csv
```

The file must be located in the same directory as the Shiny application.

The application constructs the path using:

```r
country_file <- file.path(
  repository,
  "country.csv"
)
```

The country reference file must contain a column named:

```text
COU
```

This column is used to merge the UNICEF country code with the SPC country reference information.

The country reference file is expected to contain a mapping that allows the application to create the final:

```text
GEO_PICT
```

variable.

---

## R Package Requirements

The application requires the following R packages:

```r
library(shiny)
library(rsdmx)
library(dplyr)
library(DT)
library(readr)
```

Install the required packages with:

```r
install.packages(c(
  "shiny",
  "rsdmx",
  "dplyr",
  "DT",
  "readr"
))
```

---

## System Requirements

Recommended environment:

* Windows
* R
* RStudio
* Internet access
* Access to the UNICEF SDMX API
* Access to the SPC OneDrive directory if automatic output saving is required

The application uses the Windows environment variable:

```r
USERNAME
```

to determine the current Windows username:

```r
username <- Sys.getenv("USERNAME")
```

---

## Running the Application

Place the following files in the same directory:

```text
DF_WASH/
├── app.R
├── country.csv
└── README.md
```

Open `app.R` in RStudio and run:

```r
shiny::runApp()
```

Alternatively, run the application directly from RStudio using the **Run App** button.

---

## User Interface

The application contains a sidebar and five main tabs.

### Sidebar

The sidebar provides:

* Processing information
* Number of configured countries
* Number of configured dataflows
* **Process Data** button
* **Download Final CSV** button
* Processing status

---

### Summary

The **Summary** tab displays:

1. Processing summary
2. Number of rows retrieved from each dataflow
3. Final combined number of observations
4. Preview of the final `DF_WASH` dataset

---

### WASH Households

Displays the raw filtered data retrieved from:

```text
WASH_HOUSEHOLDS
```

The table supports:

* Column filtering
* Pagination
* Horizontal scrolling

---

### WASH Schools

Displays the raw filtered data retrieved from:

```text
WASH_SCHOOLS
```

---

### WASH Healthcare

Displays the raw filtered data retrieved from:

```text
WASH_HEALTHCARE_FACILITY
```

---

### Failed Downloads

Displays any country/dataflow combinations that could not be processed.

The table contains:

| Column     | Description                 |
| ---------- | --------------------------- |
| `DATAFLOW` | UNICEF WASH dataflow        |
| `COUNTRY`  | Country code                |
| `ERROR`    | Error or validation message |

Examples of recorded errors include:

* HTTP/API download errors
* Missing required columns
* Missing dataflow-specific dimensions
* Other processing errors

---

## Final Data Structure

The application creates the final SPC `DF_WASH` dataset with the following columns:

```text
DATAFLOW
FREQ
GEO_PICT
INDICATOR
TIME_PERIOD
OBS_VALUE
UNIT_MEASURE
UNIT_MULT
OBS_STATUS
DATA_SOURCE
OBS_COMMENT
```

### Column descriptions

| Column         | Description                        |
| -------------- | ---------------------------------- |
| `DATAFLOW`     | SPC SDMX dataflow identifier       |
| `FREQ`         | Frequency of observation           |
| `GEO_PICT`     | SPC Pacific country/territory code |
| `INDICATOR`    | WASH indicator code                |
| `TIME_PERIOD`  | Observation period                 |
| `OBS_VALUE`    | Observation value                  |
| `UNIT_MEASURE` | Unit of measurement                |
| `UNIT_MULT`    | Unit multiplier                    |
| `OBS_STATUS`   | Observation status                 |
| `DATA_SOURCE`  | Original data source               |
| `OBS_COMMENT`  | Observation comment                |

The application sets:

```r
DATAFLOW = "SPC:DF_WASH(1.0)"
```

and:

```r
FREQ = "A"
```

The unit of measurement is standardised to:

```r
UNIT_MEASURE = "PERCENT"
```

---

## Final CSV

The application creates a CSV file using the following naming convention:

```text
DF_WASH_YYYYMMDD.CSV
```

For example:

```text
DF_WASH_20260917.CSV
```

The CSV can be downloaded directly using the **Download Final CSV** button.

---

## OneDrive Output

After processing is completed, the application automatically creates a timestamped folder in the SPC DotStat OneDrive directory.

The configured base directory is:

```text
C:/Users/<USERNAME>/OneDrive - SPC/DotStat/REFDB/DF_WASH
```

A new folder is created using the following naming convention:

```text
YYYYMMDD_HHMMSS_data_Update
```

For example:

```text
20260917_155730_data_Update
```

The final CSV is written as:

```text
DF_WASH_data.CSV
```

The resulting structure is therefore:

```text
DF_WASH/
└── 20260917_155730_data_Update/
    └── DF_WASH_data.CSV
```

---

## Error Handling

The application uses `tryCatch()` when downloading UNICEF data.

If a country/dataflow download fails, processing continues with the next country rather than terminating the entire application.

The error is recorded in the failed-downloads dataset:

```text
DATAFLOW
COUNTRY
ERROR
```

This allows successful countries and dataflows to continue processing even when individual downloads fail.

The application also validates required dimensions before filtering.

For example, every dataflow must contain:

```text
SERVICE_TYPE
RESIDENCE
```

If these columns are missing, the country/dataflow combination is recorded as a failure.

Dataflow-specific dimensions are also validated:

| Dataflow                   | Required dimension |
| -------------------------- | ------------------ |
| `WASH_HOUSEHOLDS`          | `WEALTH_QUINTILE`  |
| `WASH_SCHOOLS`             | `SCH_TYPE`         |
| `WASH_HEALTHCARE_FACILITY` | `HCF_TYPE`         |

---

## Processing Statistics

The application reports:

```text
WASH_HOUSEHOLDS: <number> rows
WASH_SCHOOLS: <number> rows
WASH_HEALTHCARE_FACILITY: <number> rows

FINAL DATA: <number> rows

FAILED DOWNLOADS: <number>
```

The status is displayed in the application sidebar after processing.

---

## Important Configuration

### Adding a Country

Modify the `country` vector:

```r
country <- c(
  "COK",
  "FJI",
  "FSM",
  ...
)
```

The country code must correspond to the UNICEF SDMX country code.

---

### Adding a Dataflow

Modify:

```r
dataflows <- c(
  "WASH_HOUSEHOLDS",
  "WASH_SCHOOLS",
  "WASH_HEALTHCARE_FACILITY"
)
```

If a new dataflow is added, additional processing logic may be required, particularly if it uses dimensions different from the existing three dataflows.

---

### Changing the Output Location

The OneDrive output path is defined by:

```r
oneDrivePath <- paste0(
  "C:/Users/",
  username,
  "/OneDrive - SPC/DotStat/REFDB/DF_WASH"
)
```

Modify this path if the SPC OneDrive directory is located elsewhere.

---

## Dataflow-Specific Processing Summary

| Dataflow                   | Common Filters                                 | Additional Filter      | Final Output |
| -------------------------- | ---------------------------------------------- | ---------------------- | ------------ |
| `WASH_HOUSEHOLDS`          | `SERVICE_TYPE = HYG/SAN/WAT`, `RESIDENCE = _T` | `WEALTH_QUINTILE = _T` | `DF_WASH`    |
| `WASH_SCHOOLS`             | `SERVICE_TYPE = HYG/SAN/WAT`, `RESIDENCE = _T` | `SCH_TYPE = _T`        | `DF_WASH`    |
| `WASH_HEALTHCARE_FACILITY` | `SERVICE_TYPE = HYG/SAN/WAT`, `RESIDENCE = _T` | `HCF_TYPE = _T`        | `DF_WASH`    |

---

## Data Transformation

For each dataflow, the application initially retrieves the UNICEF SDMX dataset and then retains the following variables for the final combined dataset:

```text
REF_AREA
INDICATOR
SERVICE_TYPE
UNIT_MEASURE
TIME_PERIOD
OBS_VALUE
DATA_SOURCE
```

The `REF_AREA` variable is renamed:

```text
REF_AREA → COU
```

The country reference file is then merged using:

```r
merge(
  wash_combine,
  countries,
  by = "COU"
)
```

Country reference columns that are not required in the final SDMX dataset are subsequently removed.

The final dataset is then standardised to the SPC `DF_WASH` structure.

---

## Application Output

The application produces three levels of output:

### 1. Individual WASH datasets

```text
wash_HH
wash_Schools
wash_Health
```

### 2. Combined dataset

```text
wash_combine_final
```

### 3. Final SPC SDMX dataset

```text
wash_final
```

The final dataset is both:

* displayed in the application, and
* written to CSV.

---

## Troubleshooting

### `country.csv` not found

If the application reports:

```text
Country reference file not found
```

ensure that `country.csv` exists in the same directory as `app.R`.

Expected structure:

```text
app.R
country.csv
```

---

### UNICEF API download failure

A failed UNICEF download does not necessarily stop the application.

Check the **Failed Downloads** tab to identify:

* dataflow
* country
* error message

The failed country/dataflow can then be investigated separately.

---

### Missing column errors

If an error reports:

```text
Required columns missing
```

or:

```text
WEALTH_QUINTILE column not found
```

```text
SCH_TYPE column not found
```

```text
HCF_TYPE column not found
```

the UNICEF SDMX response may have changed or the selected dataflow may not contain the expected dimension.

Check the current UNICEF SDMX dataflow structure before modifying the filtering logic.

---

### OneDrive output failure

If the final CSV cannot be written, verify that:

1. OneDrive is installed and synchronised.
2. The `DotStat/REFDB/DF_WASH` directory exists or can be created.
3. The Windows user has write permissions.
4. The username returned by:

```r
Sys.getenv("USERNAME")
```

corresponds to the expected Windows account.

---

## Maintenance

When updating the application, review the following components:

1. UNICEF SDMX dataflow availability.
2. UNICEF dimension names.
3. UNICEF country codes.
4. WASH indicator definitions.
5. `country.csv` mappings.
6. SPC `DF_WASH` DSD requirements.
7. Output directory structure.
8. Required R packages.

Particular attention should be given to changes in the UNICEF SDMX dataflows because dimension names and code lists may change between releases.

---

## Recommended Project Structure

```text
DF_WASH/
│
├── app.R
├── country.csv
├── README.md
│
└── output/
```

The `output` directory is optional because the current application writes the production CSV directly to the configured OneDrive location.

---

## Author / Maintenance

This application is intended for WASH data processing within the **Pacific Community (SPC) / DotStat data preparation workflow**.

The application retrieves source data from UNICEF and transforms it into the SPC `DF_WASH` SDMX structure for downstream processing and dissemination.

---

## Version

**Application:** UNICEF WASH SDMX Data Processing Shiny Application

**Output Dataflow:**

```text
SPC:DF_WASH(1.0)
```

**Data Provider:**

```text
UNICEF
```

**Processing Framework:**

```text
R + Shiny + SDMX
```
