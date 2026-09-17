# IMTS Data Processing Shiny Application

## Overview

The **IMTS Data Processing Shiny Application** is an R/Shiny application designed to process International Merchandise Trade Statistics (IMTS) data supplied in an Excel workbook.

The application reads the individual IMTS worksheets, reshapes the data from wide to long format, standardises the resulting dataset, removes missing observations, and produces a single consolidated CSV file suitable for downstream data processing and SDMX/DotStat workflows.

The application provides:

* IMTS Excel workbook upload
* Workbook worksheet validation
* Worksheet-specific data processing
* Conversion from wide to long format
* Standardisation of observation values
* Consolidation of all IMTS worksheets
* Processing progress information
* Processing logs
* Summary statistics
* Interactive final-data preview
* CSV download
* Automatic creation of a timestamped output directory

---

## Application Name

**IMTS Data Processing Application**

---

## Purpose

The application converts an IMTS Excel workbook containing multiple trade-statistics worksheets into one standardised dataset.

The processing is designed to accommodate different types of IMTS data, including:

* Balance of Trade
* Imports
* Exports
* Re-exports
* Total exports
* Balance of Trade by country
* Trade by region
* Mode of transport
* SITC-based exports
* SITC-based imports

The resulting dataset contains a common set of fields that can be used for subsequent processing and integration into the SPC/DotStat environment.

---

## Input

The application accepts:

```text
.xlsx
```

The uploaded workbook must contain IMTS worksheets recognised by the application.

### Supported worksheets

The application currently supports the following worksheets:

| Worksheet    | Description                 |
| ------------ | --------------------------- |
| `bot`        | Balance of Trade            |
| `imports`    | Imports                     |
| `exports`    | Exports                     |
| `reexports`  | Re-exports                  |
| `totexports` | Total exports               |
| `bot_cty`    | Balance of Trade by country |
| `trade_reg`  | Trade by region             |
| `mode_trspt` | Trade by mode of transport  |
| `x_sitc`     | Exports by SITC             |
| `m_sitc`     | Imports by SITC             |

The application checks the workbook before processing.

If the workbook contains a worksheet that is not included in the approved worksheet list, processing is stopped and an error notification is displayed.

---

# Processing Workflow

The application follows the workflow below:

```text
Upload IMTS Excel workbook
          |
          v
Read workbook worksheets
          |
          v
Validate worksheet names
          |
          v
Process each worksheet
          |
          v
Convert wide data to long format
          |
          v
Combine all worksheets
          |
          v
Remove missing observations
          |
          v
Convert OBS_VALUE to numeric
          |
          v
Standardise column order
          |
          v
Create output directory
          |
          v
Save DF_IMTS_data.CSV
```

---

# Worksheet Processing

Different worksheets require different reshaping logic because the columns containing observations represent different dimensions.

## 1. Balance of Trade

The `bot` worksheet is converted using:

```r
pivot_longer(
  cols = -c(DATAFLOW:OBS_COMMENT),
  names_to = "TRADE_FLOW",
  values_to = "OBS_VALUE"
)
```

The original observation columns are therefore converted into the:

```text
TRADE_FLOW
```

dimension.

---

## 2. Commodity-based worksheets

The following worksheets are treated as commodity-based datasets:

```text
imports
exports
reexports
totexports
x_sitc
m_sitc
```

These worksheets are reshaped using:

```r
pivot_longer(
  cols = -c(DATAFLOW:OBS_COMMENT),
  names_to = "COMMODITY",
  values_to = "OBS_VALUE"
)
```

The original observation columns become the:

```text
COMMODITY
```

dimension.

---

## 3. Balance of Trade by Country

The `bot_cty` worksheet is processed by converting the observation columns into:

```text
TIME_PERIOD
```

The application determines the frequency based on the length of the time-period value.

Values longer than four characters are treated as monthly:

```text
FREQ = "M"
```

Values of four characters or fewer are treated as annual:

```text
FREQ = "A"
```

For example:

```text
2024     -> A
2024-01  -> M
```

---

## 4. Mode of Transport

The `mode_trspt` worksheet is reshaped using:

```r
pivot_longer(
  cols = -c(DATAFLOW:OBS_COMMENT),
  names_to = "TRANSPORT",
  values_to = "OBS_VALUE"
)
```

The original observation columns therefore become the:

```text
TRANSPORT
```

dimension.

---

## 5. Other worksheets

The remaining worksheets, including:

```text
trade_reg
```

are reshaped using `TIME_PERIOD` as the long-format dimension.

Frequency is determined automatically:

```r
FREQ = ifelse(
  nchar(TIME_PERIOD) > 4,
  "M",
  "A"
)
```

---

# Data Cleaning

After all worksheets have been processed and combined, the application performs several cleaning operations.

## Remove missing observations

Observations where `OBS_VALUE` is missing are removed:

```r
filter(!is.na(OBS_VALUE))
```

---

## Replace remaining missing values

Remaining `NA` values are converted to empty strings:

```r
final_df[is.na(final_df)] <- ""
```

---

## Convert observation values

`OBS_VALUE` is converted to numeric and rounded to zero decimal places:

```r
OBS_VALUE = round(
  as.numeric(OBS_VALUE),
  0
)
```

Therefore, the final observation values are stored as numeric values rounded to the nearest whole number.

---

# Final Dataset Structure

The final dataset is standardised into the following column order:

```text
DATAFLOW
FREQ
TIME_PERIOD
GEO_PICT
INDICATOR
TRADE_FLOW
COMMODITY
COUNTERPART
TRANSPORT
CURRENCY
OBS_VALUE
UNIT_MEASURE
UNIT_MULT
OBS_STATUS
DATA_SOURCE
OBS_COMMENT
```

### Column descriptions

| Column         | Description                                                  |
| -------------- | ------------------------------------------------------------ |
| `DATAFLOW`     | Dataflow identifier                                          |
| `FREQ`         | Observation frequency, such as annual (`A`) or monthly (`M`) |
| `TIME_PERIOD`  | Reference period                                             |
| `GEO_PICT`     | PICT geographic identifier                                   |
| `INDICATOR`    | IMTS indicator identifier                                    |
| `TRADE_FLOW`   | Trade-flow dimension                                         |
| `COMMODITY`    | Commodity or SITC dimension                                  |
| `COUNTERPART`  | Trading partner/counterpart                                  |
| `TRANSPORT`    | Mode of transport                                            |
| `CURRENCY`     | Currency identifier                                          |
| `OBS_VALUE`    | Observation value                                            |
| `UNIT_MEASURE` | Unit of measure                                              |
| `UNIT_MULT`    | Unit multiplier                                              |
| `OBS_STATUS`   | Observation status                                           |
| `DATA_SOURCE`  | Data source                                                  |
| `OBS_COMMENT`  | Observation comment                                          |

Not every worksheet necessarily populates every dimension. Dimensions that are not applicable to a particular worksheet remain empty in the consolidated dataset.

---

# Application Interface

The application contains three main tabs.

## 1. Summary

The Summary tab provides a high-level overview of the processed dataset.

It displays:

### Observations

The total number of observations in the final dataset.

### Indicators

The number of unique values in:

```text
INDICATOR
```

### Frequencies

The number of unique values in:

```text
FREQ
```

### Trade Flows

The number of unique values in:

```text
TRADE_FLOW
```

The tab also contains an interactive indicator summary showing the number of observations by:

```text
FREQ
INDICATOR
```

---

## 2. IMTS Data

The IMTS Data tab displays the complete processed dataset.

The table supports:

* Column filtering
* Pagination
* Horizontal scrolling
* Copying data
* CSV export
* Excel export

The default page length is:

```text
25 rows
```

---

## 3. Processing Log

The Processing Log tab records the processing activities performed by the application.

Each log entry includes a timestamp.

Example:

```text
[2026-09-17 15:30:00] Starting IMTS data processing...
[2026-09-17 15:30:01] Reading IMTS Excel workbook...
[2026-09-17 15:30:02] Worksheets detected: bot, imports, exports
[2026-09-17 15:30:03] Processing worksheet: bot
[2026-09-17 15:30:04] Processing worksheet: imports
[2026-09-17 15:30:05] Final dataset contains 25,000 observations.
[2026-09-17 15:30:06] Final CSV saved: ...
[2026-09-17 15:30:06] IMTS data processing completed successfully.
```

The log is useful for identifying where an error occurred during processing.

---

# Processing Status

The sidebar displays the current processing status.

Before processing:

```text
Waiting for IMTS Excel file...
```

After successful processing:

```text
Processing completed successfully.
The final dataset is ready for download.
```

Errors encountered during processing are displayed through Shiny notifications and recorded in the Processing Log.

---

# Output

The application automatically creates the following base directory:

```text
C:/Users/<USERNAME>/OneDrive - SPC/DotStat/REFDB/DF_IMTS/
```

The Windows username is obtained dynamically using:

```r
username <- Sys.getenv("USERNAME")
```

This means the application does not require the username to be hard-coded.

---

# Output Folder

For each successful processing run, a new timestamped folder is created.

The naming convention is:

```text
YYYYMMDD_HHMMSS_IMTS_data_Update
```

For example:

```text
20260917_153000_IMTS_data_Update
```

The complete output structure is therefore:

```text
DF_IMTS/
└── 20260917_153000_IMTS_data_Update/
    └── DF_IMTS_data.CSV
```

Each processing run creates a separate output folder, preventing previous processing results from being overwritten.

---

# Output File

The automatically generated file is:

```text
DF_IMTS_data.CSV
```

The file contains the complete consolidated IMTS dataset.

The CSV is written using:

```r
write.csv(
  final_df,
  output_file,
  row.names = FALSE,
  na = ""
)
```

Missing values are therefore written as empty fields rather than `NA`.

---

# Download

The application also provides a **Download Final CSV** button.

The downloaded file uses the following naming convention:

```text
DF_IMTS_data_YYYYMMDD_HHMMSS.CSV
```

For example:

```text
DF_IMTS_data_20260917_153045.CSV
```

The downloaded file contains the same processed dataset displayed in the IMTS Data tab.

---

# Required R Packages

The application requires the following R packages:

```r
library(shiny)
library(readxl)
library(dplyr)
library(tidyr)
library(DT)
```

If the packages are not already installed, install them using:

```r
install.packages(c(
  "shiny",
  "readxl",
  "dplyr",
  "tidyr",
  "DT"
))
```

---

# Running the Application

## Option 1: Run from RStudio

Open the application `.R` file in RStudio and click:

```text
Run App
```

Alternatively, run:

```r
shiny::runApp()
```

from the application directory.

---

## Option 2: Run directly from R

The application can also be started using:

```r
shinyApp(ui, server)
```

The script already contains:

```r
shinyApp(
  ui = ui,
  server = server
)
```

so no additional command is required when running the complete script.

---

# Application Directory

The application determines its working directory dynamically:

```r
repository <- normalizePath(
  ".",
  winslash = "/",
  mustWork = TRUE
)

setwd(repository)
```

This allows the application to be moved between compatible project directories without changing a hard-coded working directory.

---

# Error Handling

The application uses `tryCatch()` around the main processing operation.

If an error occurs, the application:

1. Captures the error message.
2. Adds the error to the processing log.
3. Displays a Shiny error notification.
4. Prevents the application from terminating unexpectedly.

For example:

```text
Processing failed: <error message>
```

The Processing Log should be checked when troubleshooting an unsuccessful run.

---

# Worksheet Validation

Before any worksheet processing takes place, the application retrieves the workbook worksheet names using:

```r
excel_sheets(file_path)
```

It then compares them against the approved worksheet list.

If an unsupported worksheet is found, processing is stopped.

Example:

```text
Unsupported worksheet(s): population, notes
```

This validation prevents unexpected worksheets from being incorporated into the final dataset.

---

# Important Input Requirements

The Excel workbook should follow the expected IMTS structure.

The worksheets must use the required field structure, including the common fields represented by:

```text
DATAFLOW
...
OBS_COMMENT
```

The application uses:

```r
-c(DATAFLOW:OBS_COMMENT)
```

when identifying the observation columns to reshape.

Therefore, the ordering and presence of the expected metadata columns in the source workbook are important.

The workbook should be checked if errors occur during `pivot_longer()`.

---

# Troubleshooting

## Error: Unsupported worksheet(s)

### Cause

The workbook contains a worksheet that is not included in the approved IMTS worksheet list.

### Solution

Remove the unsupported worksheet or add its name to:

```r
allowed_sheets
```

Only add a worksheet after confirming that its structure and processing requirements are compatible with the application.

---

## Error involving `pivot_longer()`

### Cause

A worksheet may not contain the expected columns or the common metadata columns may not be in the expected structure.

### Solution

Check that the worksheet contains the required fields beginning with:

```text
DATAFLOW
```

and ending with:

```text
OBS_COMMENT
```

Also check that the observation columns are structured consistently with the worksheet type.

---

## Error converting `OBS_VALUE`

### Cause

An observation contains a value that cannot be converted to numeric.

### Solution

Inspect the source worksheet for text or non-numeric values in the observation fields.

The application currently uses:

```r
as.numeric(OBS_VALUE)
```

before rounding the result.

---

## No data displayed after processing

Check the Processing Log first.

Possible causes include:

* The uploaded workbook is empty.
* All observations are missing.
* Worksheet structures do not match the expected format.
* Required columns are missing.
* An error occurred during worksheet processing.

---

## Output folder is not created

The output directory is created only after the data has been successfully processed.

Check that the user account has permission to write to:

```text
C:/Users/<USERNAME>/OneDrive - SPC/DotStat/REFDB/
```

Also verify that OneDrive is available and synchronised.

---

# Data Processing Logic Summary

The main transformation rules are:

| Worksheet(s) | Long-format dimension | Frequency       |
| ------------ | --------------------- | --------------- |
| `bot`        | `TRADE_FLOW`          | Existing `FREQ` |
| `imports`    | `COMMODITY`           | Existing `FREQ` |
| `exports`    | `COMMODITY`           | Existing `FREQ` |
| `reexports`  | `COMMODITY`           | Existing `FREQ` |
| `totexports` | `COMMODITY`           | Existing `FREQ` |
| `x_sitc`     | `COMMODITY`           | Existing `FREQ` |
| `m_sitc`     | `COMMODITY`           | Existing `FREQ` |
| `bot_cty`    | `TIME_PERIOD`         | Derived         |
| `mode_trspt` | `TRANSPORT`           | Existing `FREQ` |
| `trade_reg`  | `TIME_PERIOD`         | Derived         |

For derived frequency:

```text
TIME_PERIOD length > 4  -> M
TIME_PERIOD length <= 4 -> A
```

---

# Standardisation

The final dataset is consolidated using:

```r
bind_rows()
```

After consolidation, the application:

1. Removes missing observations.
2. Replaces remaining missing values with empty strings.
3. Converts `OBS_VALUE` to numeric.
4. Rounds `OBS_VALUE` to zero decimal places.
5. Applies the standard column order.
6. Stores the final dataset in a reactive object.
7. Creates the output directory.
8. Writes the final CSV.

---

# Technology

The application is developed in:

* **R**
* **Shiny**
* **readxl**
* **dplyr**
* **tidyr**
* **DT**

The application does **not** require `shinydashboard`.

---

# Maintenance

When modifying the application, pay particular attention to the following sections:

### Adding a new worksheet

Update:

```r
allowed_sheets
```

Then add the appropriate worksheet-specific transformation in the processing loop.

### Changing the final data structure

Update the `select()` statement:

```r
select(
  DATAFLOW,
  FREQ,
  TIME_PERIOD,
  GEO_PICT,
  INDICATOR,
  TRADE_FLOW,
  COMMODITY,
  COUNTERPART,
  TRANSPORT,
  CURRENCY,
  OBS_VALUE,
  UNIT_MEASURE,
  UNIT_MULT,
  OBS_STATUS,
  DATA_SOURCE,
  OBS_COMMENT
)
```

### Changing the output location

Modify:

```r
output_base
```

### Changing the output filename

Modify:

```r
"DF_IMTS_data.CSV"
```

and/or the `downloadHandler()` filename function.

---

# Recommended Processing Checklist

Before processing an IMTS workbook:

* [ ] Confirm the workbook is an `.xlsx` file.
* [ ] Confirm the required IMTS worksheets are present.
* [ ] Confirm there are no unsupported worksheets.
* [ ] Confirm the common metadata columns are correctly structured.
* [ ] Confirm observation values are numeric or convertible to numeric.
* [ ] Upload the workbook.
* [ ] Click **Process IMTS Data**.
* [ ] Check the Processing Log.
* [ ] Review the Summary tab.
* [ ] Review the IMTS Data tab.
* [ ] Confirm the output CSV was created.
* [ ] Download the final CSV if required.

---

# Output Summary

The application produces one consolidated IMTS dataset:

```text
DF_IMTS_data.CSV
```

with the standardised structure:

```text
DATAFLOW
FREQ
TIME_PERIOD
GEO_PICT
INDICATOR
TRADE_FLOW
COMMODITY
COUNTERPART
TRANSPORT
CURRENCY
OBS_VALUE
UNIT_MEASURE
UNIT_MULT
OBS_STATUS
DATA_SOURCE
OBS_COMMENT
```

The application is intended to provide a consistent and repeatable process for converting IMTS Excel workbooks into a format suitable for downstream SPC data processing and DotStat/SDMX workflows.
