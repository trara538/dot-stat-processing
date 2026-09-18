# CPI Data Processing Shiny Application

## Overview

The **CPI Data Processing Shiny Application** is an interactive R Shiny application for processing Consumer Price Index (CPI) data for Pacific Island Countries and Territories (PICTs).

The application accepts CPI data in Excel format and supports two input frequencies:

* **M** — Monthly CPI data
* **Q** — Quarterly CPI data

Depending on the input frequency, the application calculates CPI indexes and inflation indicators at monthly, quarterly, and annual frequencies.

The application produces **one final CSV file** containing the processed CPI and inflation data.

---

## Features

The application provides:

* Excel CPI data upload
* Automatic detection of input frequency
* Support for monthly and quarterly CPI data
* Conversion of wide-format CPI data into long format
* Monthly CPI processing
* Monthly inflation calculation
* Quarterly CPI calculation from monthly data
* Quarterly inflation calculation
* Annual CPI calculation
* Annual inflation calculation
* Statistics office information appended to observations
* Interactive data tables
* Processing summary
* Final CSV download
* Validation of input structure and time periods
* Processing status and error messages

---

## Supported Input Frequencies

### Monthly Input

When the uploaded file contains:

```text
FREQ = M
```

the application produces:

1. Monthly CPI
2. Monthly inflation
3. Quarterly CPI
4. Quarterly inflation
5. Annual CPI
6. Annual inflation

The quarterly CPI is calculated as the average of the three monthly CPI observations within each quarter.

The annual CPI is calculated as the average of the four quarterly CPI observations within each year.

---

### Quarterly Input

When the uploaded file contains:

```text
FREQ = Q
```

the application produces:

1. Quarterly CPI
2. Quarterly inflation
3. Annual CPI
4. Annual inflation

The annual CPI is calculated as the average of the four quarterly CPI observations within each year.

---

## Input Excel File

The application expects an Excel workbook containing a worksheet named:

```text
cpi_data
```

The worksheet must contain the required metadata columns and CPI commodity columns.

### Required Columns

The following columns are required:

```text
DATAFLOW
FREQ
GEO_PICT
TIME_PERIOD
UNIT_MEASURE
UNIT_MULT
OBS_STATUS
BASE_PER
OBS_COMMENT
```

The input should also contain:

```text
INDICATOR
```

when applicable.

### Example Structure

A monthly input file may look similar to:

| DATAFLOW | FREQ | GEO_PICT | INDICATOR | TIME_PERIOD | UNIT_MEASURE | UNIT_MULT | OBS_STATUS | BASE_PER | OBS_COMMENT |    _T |  FOOD | HOUSING |
| -------- | ---- | -------- | --------- | ----------- | ------------ | --------- | ---------- | -------- | ----------- | ----: | ----: | ------: |
| DF_CPI   | M    | FJ       | IDX       | 2025-01     | INDEX        | 0         | A          | 2018     |             | 100.0 | 101.2 |    99.8 |
| DF_CPI   | M    | FJ       | IDX       | 2025-02     | INDEX        | 0         | A          | 2018     |             | 100.4 | 101.8 |   100.1 |

The commodity columns are converted from wide format into long format during processing.

---

## Input Data Transformation

The application expects CPI commodity values to be stored in separate columns in the Excel file.

For example:

```text
_T
FOOD
HOUSING
TRANSPORT
```

These columns are converted into:

```text
COMMODITY
OBS_VALUE
```

using `pivot_longer()`.

The resulting structure is approximately:

| GEO_PICT | TIME_PERIOD | COMMODITY | OBS_VALUE |
| -------- | ----------- | --------- | --------: |
| FJ       | 2025-01     | _T        |     100.0 |
| FJ       | 2025-01     | FOOD      |     101.2 |
| FJ       | 2025-01     | HOUSING   |      99.8 |

This allows the application to perform calculations consistently across commodities.

---

# CPI Processing Methodology

## Monthly CPI

For monthly input data:

```text
FREQ = M
INDICATOR = IDX
```

Monthly CPI observations are retained at their original monthly frequency.

The values are rounded to one decimal place.

---

## Monthly Inflation

Monthly inflation is calculated as:

```text
((Current Month CPI / Previous Month CPI) - 1) × 100
```

The resulting observations are assigned:

```text
INDICATOR = INF
UNIT_MEASURE = PERCENT
OBS_STATUS = E
FREQ = M
```

The result is rounded to one decimal place.

---

## Quarterly CPI from Monthly Data

For monthly input, quarterly CPI is calculated only when all three months of a quarter are available.

The calculation is:

```text
Quarterly CPI = Mean of the three monthly CPI values
```

For example:

```text
2025-Q1 =
mean(
  2025-01,
  2025-02,
  2025-03
)
```

If all three monthly observations are not available, the quarter is not produced.

The output uses:

```text
FREQ = Q
INDICATOR = IDX
```

---

## Quarterly Inflation

Quarterly inflation is calculated as:

```text
((Current Quarter CPI / Previous Quarter CPI) - 1) × 100
```

The output uses:

```text
FREQ = Q
INDICATOR = INF
UNIT_MEASURE = PERCENT
OBS_STATUS = E
```

---

## Annual CPI from Monthly Data

For monthly input, annual CPI is calculated from quarterly CPI.

An annual observation is produced only when all four quarters are available.

The calculation is:

```text
Annual CPI = Mean of the four quarterly CPI values
```

For example:

```text
2025 =
mean(
  2025-Q1,
  2025-Q2,
  2025-Q3,
  2025-Q4
)
```

The output uses:

```text
FREQ = A
INDICATOR = IDX
```

---

## Annual Inflation

Annual inflation is calculated from annual CPI:

```text
((Current Year CPI / Previous Year CPI) - 1) × 100
```

The output uses:

```text
FREQ = A
INDICATOR = INF
UNIT_MEASURE = PERCENT
OBS_STATUS = E
```

The application currently retains annual inflation for:

```text
COMMODITY = _T
```

---

# Quarterly Input Processing

When:

```text
FREQ = Q
```

the application does not calculate monthly CPI or monthly inflation.

Instead, it processes the quarterly observations directly.

### Quarterly CPI

Quarterly CPI is retained as:

```text
FREQ = Q
INDICATOR = IDX
```

### Quarterly Inflation

Quarterly inflation is calculated from consecutive quarterly CPI observations.

### Annual CPI

Annual CPI is calculated when all four quarters are available:

```text
Annual CPI = Mean(Q1, Q2, Q3, Q4)
```

### Annual Inflation

Annual inflation is calculated from consecutive annual CPI observations.

As with monthly input, annual inflation is retained for:

```text
COMMODITY = _T
```

---

# PICT Statistics Offices

The application contains a reference table linking each `GEO_PICT` code to the corresponding statistics office.

The supported codes are:

| GEO_PICT | Statistics Office                                                        |
| -------- | ------------------------------------------------------------------------ |
| AS       | Data and Statistics American Samoa Department of Commerce                |
| CK       | Cook Islands Statistics Office                                           |
| FJ       | Fiji Bureau of Statistics                                                |
| FM       | FSM Statistics                                                           |
| GU       | The Bureau of Statistics and Plans - Guam                                |
| KI       | Kiribati National Statistics Office                                      |
| MH       | Marshall Islands Economic Policy, Planning and Statistics Office (EPPSO) |
| MP       | CNMI Department of Commerce                                              |
| NC       | Institut de la Statistique et des Etudes Economiques                     |
| NR       | Nauru Bureau of Statistics                                               |
| NU       | Niue Statistics Office                                                   |
| PF       | Institut de la statistique de la Polynésie française                     |
| PG       | PNG National Statistics Office                                           |
| PN       | Pitcairn Statistics Office                                               |
| PW       | Palau Statistics Office                                                  |
| SB       | Solomon Islands National Statistics Office                               |
| TK       | Tokelau Statistics Office                                                |
| TO       | Tonga Statistics Department                                              |
| TV       | Tuvalu Statistics Office                                                 |
| VU       | Vanuatu Bureau of Statistics Office                                      |
| WF       | Wallis and Futuna Statistics Office                                      |
| WS       | Samoa Bureau of Statistics                                               |

The corresponding office name is appended to `OBS_COMMENT` in the final dataset.

---

# Application Interface

The application contains the following sections.

## Upload CPI Data

Users can upload:

```text
.xlsx
.xls
```

files.

The uploaded workbook must contain a worksheet named:

```text
cpi_data
```

The application automatically detects whether the input is monthly or quarterly.

---

## Input Information

After the file is processed, the application displays:

* Input frequency
* Number of countries
* Input period

---

## Process CPI Data

Click:

**Process CPI Data**

to start processing.

The application displays progress information while it:

1. Reads the Excel file
2. Validates the input
3. Converts the data to long format
4. Calculates CPI and inflation indicators
5. Calculates quarterly and annual aggregates
6. Adds statistics office information
7. Produces the final dataset

---

# Application Tabs

## Summary

The Summary tab provides:

* Number of rows
* Number of countries
* Number of commodities
* Number of indicators
* Indicator/frequency summary

---

## Final Data

Displays the complete processed dataset.

The table supports:

* Filtering
* Searching
* Sorting
* Pagination
* Copying
* CSV export
* Excel export

---

## Monthly CPI

Displays monthly CPI observations when monthly data are supplied.

---

## Monthly Inflation

Displays monthly inflation observations when monthly data are supplied.

---

## Quarterly CPI

Displays quarterly CPI observations.

For monthly input, these values are calculated from the monthly observations.

For quarterly input, they are retained from the source data.

---

## Quarterly Inflation

Displays quarterly inflation observations.

---

## Annual CPI

Displays annual CPI observations calculated from complete quarterly data.

---

## Annual Inflation

Displays annual inflation observations.

---

# Final Output

The application produces a single CSV file.

The downloaded file follows the naming convention:

```text
DF_CPI-data_YYYYMMDD_HHMMSS.csv
```

For example:

```text
DF_CPI-data_20260918_113045.csv
```

---

# Final Dataset Structure

The final CSV contains the following columns:

```text
DATAFLOW
FREQ
GEO_PICT
INDICATOR
COMMODITY
TIME_PERIOD
OBS_VALUE
UNIT_MEASURE
UNIT_MULT
OBS_STATUS
BASE_PER
OBS_COMMENT
```

### Column Description

| Column         | Description                            |
| -------------- | -------------------------------------- |
| `DATAFLOW`     | Dataflow identifier                    |
| `FREQ`         | Observation frequency: M, Q or A       |
| `GEO_PICT`     | PICT geographic code                   |
| `INDICATOR`    | CPI index (`IDX`) or inflation (`INF`) |
| `COMMODITY`    | CPI commodity or aggregate             |
| `TIME_PERIOD`  | Observation period                     |
| `OBS_VALUE`    | CPI index or inflation value           |
| `UNIT_MEASURE` | Measurement unit                       |
| `UNIT_MULT`    | Unit multiplier                        |
| `OBS_STATUS`   | Observation status                     |
| `BASE_PER`     | CPI base period                        |
| `OBS_COMMENT`  | Source and processing information      |

---

# Indicator Codes

The application generates two main indicators.

| Indicator | Description          |
| --------- | -------------------- |
| `IDX`     | Consumer Price Index |
| `INF`     | Inflation            |

Inflation observations use:

```text
UNIT_MEASURE = PERCENT
```

---

# Validation

The application performs several validation checks before processing.

## Required Columns

The application checks that all required input columns are present.

If a required column is missing, processing stops and an error message is displayed.

## Frequency

The input file must contain exactly one frequency.

Supported values are:

```text
M
Q
```

Files containing multiple frequencies are rejected.

## Monthly Time Period

Monthly observations must use the format:

```text
YYYY-MM
```

For example:

```text
2025-01
2025-02
2025-03
```

## Quarterly Time Period

Quarterly observations must use the format:

```text
YYYY-Q1
YYYY-Q2
YYYY-Q3
YYYY-Q4
```

Invalid quarter values are rejected.

## Complete Quarters

For monthly-to-quarterly processing, a quarter must contain all three months before a quarterly CPI observation is generated.

## Complete Years

An annual CPI observation is generated only when all four quarters are available.

---

# Requirements

The application requires R and the following R packages:

```r
shiny
dplyr
tidyr
lubridate
readr
readxl
DT
```

Install the required packages with:

```r
install.packages(
  c(
    "shiny",
    "dplyr",
    "tidyr",
    "lubridate",
    "readr",
    "readxl",
    "DT"
  )
)
```

---

# Running the Application

Save the application script as:

```text
app.R
```

Place it inside an application directory, for example:

```text
DF_CPI/
└── app.R
```

The standard Shiny application structure uses an `app.R` file containing the user interface and server code.

From RStudio, open `app.R` and click:

**Run App**

Alternatively, run:

```r
shiny::runApp()
```

or specify the application directory:

```r
shiny::runApp("DF_CPI")
```

---

# Typical Workflow

The recommended workflow is:

```text
1. Prepare CPI Excel workbook
          |
          v
2. Ensure worksheet is named "cpi_data"
          |
          v
3. Upload Excel workbook
          |
          v
4. Application detects M or Q frequency
          |
          v
5. Validate input structure
          |
          v
6. Convert CPI data to long format
          |
          v
7. Calculate CPI and inflation
          |
          v
8. Calculate quarterly/annual values
          |
          v
9. Add statistics office information
          |
          v
10. Review results
          |
          v
11. Download final CSV
```

---

# Important Processing Rules

### Monthly Input

```text
Monthly CPI
      ↓
Monthly Inflation
      ↓
Quarterly CPI
      ↓
Quarterly Inflation
      ↓
Annual CPI
      ↓
Annual Inflation
```

### Quarterly Input

```text
Quarterly CPI
      ↓
Quarterly Inflation
      ↓
Annual CPI
      ↓
Annual Inflation
```

Monthly-to-quarterly aggregation requires three monthly observations, while quarterly-to-annual aggregation requires four quarterly observations.

---

# Error Handling

Processing is wrapped in error handling so that input or processing errors are displayed in the application.

Examples of errors include:

* Missing Excel worksheet
* Missing required columns
* Multiple frequency values
* Unsupported frequency
* Invalid monthly time periods
* Invalid quarterly time periods
* Invalid CPI values
* Other processing errors

The error message is displayed in the **Processing Status** section and through a Shiny notification.

---

# Data Quality Considerations

Before uploading a CPI workbook, users should verify that:

* The worksheet is named `cpi_data`.
* Column names are correct.
* `FREQ` contains only `M` or `Q`.
* `GEO_PICT` contains valid PICT codes.
* Monthly periods use `YYYY-MM`.
* Quarterly periods use `YYYY-Q1` through `YYYY-Q4`.
* CPI values are numeric.
* `BASE_PER` is correctly populated.
* The commodity columns contain the intended CPI series.
* Complete monthly observations are available when quarterly values are required.
* Complete quarterly observations are available when annual values are required.

---

# Technical Architecture

The application is implemented as a single R Shiny application.

The main components are:

```text
app.R
│
├── Required libraries
│
├── Statistics office reference table
│
├── Inflation calculation functions
│
├── User interface
│
├── Server
│   ├── File upload
│   ├── Input validation
│   ├── Frequency detection
│   ├── Data transformation
│   ├── CPI calculations
│   ├── Inflation calculations
│   ├── Aggregation
│   ├── Data tables
│   └── CSV download
│
└── shinyApp()
```

The use of `fileInput()` allows the user to upload an Excel workbook through the Shiny interface, with the uploaded file made available to the server through its temporary `datapath`.

Interactive tables are provided through the `DT` package, allowing filtering, sorting, pagination and export functionality.

---

# Intended Use

This application is intended for CPI data preparation and processing within Pacific regional statistical workflows.

It is particularly suited to preparing CPI data for downstream statistical databases and SDMX-based dissemination systems.

The application standardises the processing of:

* CPI indexes
* Monthly inflation
* Quarterly CPI
* Quarterly inflation
* Annual CPI
* Annual inflation

into a consistent final dataset.

---

# Maintenance

When modifying the application, take care when changing:

* CPI aggregation rules
* Inflation calculations
* Required column names
* `GEO_PICT` codes
* Statistics office names
* Indicator codes
* Frequency codes
* Final column order
* `OBS_COMMENT` construction

Changes to these components can affect downstream data processing and dissemination.

---

# Author

**Pacific Community (SPC)**

The application is designed to support CPI data processing for Pacific Island Countries and Territories within the Pacific Data Hub statistical workflow.

---

# License

Unless otherwise specified by the repository containing this application, users should refer to the repository's license and applicable SPC data and software policies before redistributing or modifying the application.
