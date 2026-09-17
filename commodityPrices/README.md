# World Bank Commodity Prices Shiny Data Processing Application

## 1. Overview

The **World Bank Commodity Prices Shiny Data Processing Application** is an R Shiny application designed to download, process, standardise, and combine annual and monthly commodity price data published by the World Bank.

The application retrieves the latest available World Bank commodity price workbooks directly from the World Bank, transforms the data into a standard long-format structure, maps the World Bank commodity names to the SPC commodity reference list, and produces an SDMX-ready commodity price dataset.

The final dataset is generated as:

```text
DF_COMMODITY_PRICES.CSV
```

The application also provides interactive tables for reviewing the processed annual, monthly, and combined datasets.

---

# 2. Purpose

The application is intended to simplify the recurring processing of World Bank commodity price data for integration into the SPC DotStat environment.

The application performs the following tasks:

1. Loads the local commodity reference list.
2. Downloads the latest World Bank annual commodity price workbook.
3. Downloads the latest World Bank monthly commodity price workbook.
4. Extracts the relevant worksheets.
5. Transforms the World Bank data from wide to long format.
6. Matches commodities against the SPC commodity reference list.
7. Adds standard SDMX fields.
8. Combines annual and monthly observations.
9. Saves the final dataset to the SPC DotStat REFDB directory.
10. Provides interactive previews and summary statistics.
11. Allows the processed dataset to be downloaded from the application.

---

# 3. Application Structure

The application is a single R Shiny script containing:

```text
World Bank Commodity Prices Shiny Application
│
├── Required libraries
├── Application settings
├── Commodity reference list
├── World Bank URLs
├── Annual data download function
├── Monthly data download function
├── Annual data processing function
├── Monthly data processing function
├── Shiny user interface
├── Shiny server
└── Application launch
```

---

# 4. Required R Packages

The application requires the following R packages:

```r
library(shiny)
library(dplyr)
library(readxl)
library(readr)
library(DT)
library(tidyr)
```

The application also uses `purrr::map_dfr()` for reshaping the commodity data.

If `purrr` is not already available through the installed tidyverse environment, install it separately:

```r
install.packages("purrr")
```

The main packages are used as follows:

| Package  | Purpose                                         |
| -------- | ----------------------------------------------- |
| `shiny`  | Application user interface and server           |
| `dplyr`  | Data manipulation and transformation            |
| `readxl` | Reading World Bank Excel workbooks              |
| `readr`  | Data import/export functionality                |
| `DT`     | Interactive data tables                         |
| `tidyr`  | Data reshaping                                  |
| `purrr`  | Iterating through commodity time-period columns |

---

# 5. Input Files

## 5.1 Commodity Reference File

The application requires a local reference file:

```text
CPriceList.csv
```

The file must be located in the same directory from which the application is run.

The expected location is:

```text
<application directory>/CPriceList.csv
```

The application checks whether this file exists before starting:

```r
if (!file.exists(commodity_list_file)) {
  
  stop(
    paste0(
      "CPriceList.csv was not found.\n\n",
      "Expected location:\n",
      commodity_list_file
    )
  )
}
```

If the file cannot be found, the application stops and displays the expected file location.

---

# 6. Commodity Reference List

The commodity reference file is loaded using:

```r
comPriceList <- read.csv(
  commodity_list_file,
  stringsAsFactors = FALSE,
  check.names = FALSE
)
```

The reference list is used to map World Bank commodity names to the corresponding SPC commodity identifiers.

The processing uses:

```text
Name
Id
UNIT_MEASURE
```

The `Name` field is used as the merge key.

The resulting `Id` becomes the SDMX:

```text
COMMODITY
```

dimension.

The `UNIT_MEASURE` field provides the measurement unit for the commodity price observation.

---

# 7. World Bank Data Sources

The application downloads two World Bank Commodity Markets workbooks.

## 7.1 Annual Data

The annual workbook is downloaded from the World Bank and the following worksheet is used:

```text
Annual Prices (Nominal)
```

The annual data is processed using the:

```r
aPrices()
```

function.

---

## 7.2 Monthly Data

The monthly workbook is downloaded from the World Bank and the following worksheet is used:

```text
Monthly Prices
```

The monthly data is processed using the:

```r
mPrices()
```

function.

---

# 8. Annual Data Processing

The annual World Bank workbook is downloaded to the R temporary directory.

The application reads:

```text
Annual Prices (Nominal)
```

The first five rows are removed:

```r
data <- data[-c(1:5), ]
```

The first remaining row is then used as the column names.

The resulting dataset is transposed so that commodities become observations and years become columns.

The first three columns are renamed:

```text
Name
unit
code
```

The resulting structure is then matched against the commodity reference list.

---

# 9. Monthly Data Processing

The monthly World Bank workbook is downloaded to the R temporary directory.

The application reads:

```text
Monthly Prices
```

The first three rows are removed:

```r
mdata <- mdata[-c(1:3), ]
```

The first remaining row becomes the column names.

The data is then transposed in the same manner as the annual data.

The first three columns are renamed:

```text
Name
unit
code
```

Monthly period labels are converted from the World Bank format:

```text
2025M01
2025M02
2025M03
```

to:

```text
2025-01
2025-02
2025-03
```

This transformation is performed using:

```r
gsub(
  "^([0-9]{4})M([0-9]{2})$",
  "\\1-\\2",
  ...
)
```

The resulting periods are suitable for the monthly SDMX `TIME_PERIOD` field.

---

# 10. Commodity Matching

Both annual and monthly datasets are merged with the local commodity reference list using:

```r
merge(
  comPrice,
  comPriceList,
  by = "Name"
)
```

This means the World Bank commodity `Name` must match a corresponding `Name` in `CPriceList.csv`.

After the merge, the reference `Id` is moved to the first column.

The `Id` becomes:

```text
COMMODITY
```

in the final SDMX dataset.

---

# 11. Wide-to-Long Transformation

The World Bank source data is originally structured in wide format.

For example:

```text
Name       2020    2021    2022    2023
Crude Oil  41.8    70.9    100.9   82.6
Gold       1770    1799    1800    1940
```

The application converts this to long format:

```text
COMMODITY    TIME_PERIOD    OBS_VALUE
OIL          2020            41.80
OIL          2021            70.90
OIL          2022            100.90
GOLD         2020            1770.00
GOLD         2021            1799.00
GOLD         2022            1800.00
```

This transformation is performed using `purrr::map_dfr()`.

---

# 12. Annual SDMX Structure

Annual observations are assigned the following SDMX fields:

| Field          | Value / Source                 |
| -------------- | ------------------------------ |
| `DATAFLOW`     | `SPC:DF_COMMODITY_PRICES(1.0)` |
| `FREQ`         | `A`                            |
| `TIME_PERIOD`  | World Bank annual period       |
| `COMMODITY`    | Commodity reference `Id`       |
| `INDICATOR`    | `COMPRICE`                     |
| `OBS_VALUE`    | World Bank commodity price     |
| `UNIT_MEASURE` | Commodity reference list       |
| `UNIT_MULT`    | Empty                          |
| `OBS_STATUS`   | Empty                          |
| `DATA_SOURCE`  | Empty                          |
| `OBS_COMMENT`  | Empty                          |

---

# 13. Monthly SDMX Structure

Monthly observations are assigned the following SDMX fields:

| Field          | Value / Source                      |
| -------------- | ----------------------------------- |
| `DATAFLOW`     | `SPC:DF_COMMODITY_PRICES(1.0)`      |
| `FREQ`         | `M`                                 |
| `TIME_PERIOD`  | Converted World Bank monthly period |
| `COMMODITY`    | Commodity reference `Id`            |
| `INDICATOR`    | `COMPRICE`                          |
| `OBS_VALUE`    | World Bank commodity price          |
| `UNIT_MEASURE` | Commodity reference list            |
| `UNIT_MULT`    | Empty                               |
| `OBS_STATUS`   | Empty                               |
| `DATA_SOURCE`  | Empty                               |
| `OBS_COMMENT`  | Empty                               |

---

# 14. Observation Cleaning

World Bank observations are converted to numeric values.

For annual data:

```r
CPrice_long$OBS_VALUE <- as.numeric(
  CPrice_long$OBS_VALUE
)
```

Missing observations are removed:

```r
filter(
  !is.na(OBS_VALUE),
  UNIT_MEASURE != ""
)
```

For monthly data, missing observations are removed using:

```r
filter(
  !is.na(OBS_VALUE)
)
```

The final observation values are rounded to two decimal places:

```r
OBS_VALUE = round(
  as.numeric(OBS_VALUE),
  2
)
```

---

# 15. Final Dataset

Annual and monthly datasets are combined using:

```r
DF_COMMODITIES <- bind_rows(
  annual_processed,
  monthly_processed
)
```

The final dataset contains the following columns:

```text
DATAFLOW
FREQ
TIME_PERIOD
COMMODITY
INDICATOR
OBS_VALUE
UNIT_MEASURE
UNIT_MULT
OBS_STATUS
DATA_SOURCE
OBS_COMMENT
```

---

# 16. Dataflow

The application assigns all observations to:

```text
SPC:DF_COMMODITY_PRICES(1.0)
```

The indicator is:

```text
COMPRICE
```

Frequency is assigned as:

```text
A = Annual
M = Monthly
```

---

# 17. Application User Interface

The application uses a standard Shiny interface based on:

```r
fluidPage()
```

It does not require `shinydashboard`.

The interface consists of a sidebar and main panel.

---

# 18. Sidebar

The sidebar contains four main sections.

## 18.1 Commodity Price Reference

Displays the name and location of:

```text
CPriceList.csv
```

The application shows the full path being used.

---

## 18.2 Download World Bank Data

The main processing button is:

```text
Download & Process Data
```

Selecting this button starts the complete processing workflow.

The application downloads and processes:

1. Annual commodity prices
2. Monthly commodity prices
3. Combined annual and monthly data

---

## 18.3 Download Final CSV

After successful processing, the user can download the final combined dataset using:

```text
Download Final CSV
```

The downloaded file is named:

```text
DF_COMMODITY_PRICES_YYYYMMDD_HHMMSS.csv
```

---

## 18.4 Processing Status

The status section displays:

* Annual observation count
* Monthly observation count
