# Pacific Data Hub Data Preparation Packages

R packages for downloading, processing, transforming, validating, and preparing statistical data for the **Pacific Data Hub** and related **SDMX/.Stat** data workflows.

The repository contains six independent data-preparation packages. Each package focuses on a specific statistical data source or domain and can be installed independently from GitHub.

## Repository

[dot-stat-processing on GitHub](https://github.com/trara538/dot-stat-processing?utm_source=chatgpt.com)

---

## Packages

| Directory                                    | R Package           | Description                                |
| -------------------------------------------- | ------------------- | ------------------------------------------ |
| [`DF_ADBKI`](DF_ADBKI)                       | `DFADBKI`           | Asian Development Bank Key Indicators      |
| [`DF_COMMODITY_PRICES`](DF_COMMODITY_PRICES) | `DFCOMMODITYPRICES` | Commodity Prices                           |
| [`DF_CPI`](DF_CPI)                           | `DFCPI`             | Consumer Price Index                       |
| [`DF_IMTS`](DF_IMTS)                         | `DFIMTS`            | International Merchandise Trade Statistics |
| [`DF_UIS`](DF_UIS)                           | `DFUIS`             | UNESCO Institute for Statistics            |
| [`DF_WASH`](DF_WASH)                         | `DFWASH`            | Water, Sanitation and Hygiene              |

Each directory is a standalone R package with its own `DESCRIPTION`, `NAMESPACE`, R source code, and package documentation.

---

# Installation

## Prerequisites

You need:

* R
* RStudio or another R development environment
* Internet access to GitHub

Install the `remotes` package if it is not already installed:

```r
install.packages("remotes")
```

---

# Install Individual Packages

Packages can be installed directly from the GitHub repository using `remotes::install_github()`.

## ADB Key Indicators

### Install

```r
remotes::install_github(
  "trara538/dot-stat-processing",
  subdir = "DF_ADBKI"
)
```

### Load

```r
library(DFADBKI)
```

### Package

[`DF_ADBKI`](DF_ADBKI)

---

## Commodity Prices

### Install

```r
remotes::install_github(
  "trara538/dot-stat-processing",
  subdir = "DF_COMMODITY_PRICES"
)
```

### Load

```r
library(DFCOMMODITYPRICES)
```

### Package

[`DF_COMMODITY_PRICES`](DF_COMMODITY_PRICES)

---

## Consumer Price Index

### Install

```r
remotes::install_github(
  "trara538/dot-stat-processing",
  subdir = "DF_CPI"
)
```

### Load

```r
library(DFCPI)
```

### Package

[`DF_CPI`](DF_CPI)

---

## International Merchandise Trade Statistics

### Install

```r
remotes::install_github(
  "trara538/dot-stat-processing",
  subdir = "DF_IMTS"
)
```

### Load

```r
library(DFIMTS)
```

### Package

[`DF_IMTS`](DF_IMTS)

---

## UNESCO Institute for Statistics

### Install

```r
remotes::install_github(
  "trara538/dot-stat-processing",
  subdir = "DF_UIS"
)
```

### Load

```r
library(DFUIS)
```

### Package

[`DF_UIS`](DF_UIS)

---

## Water, Sanitation and Hygiene

### Install

```r
remotes::install_github(
  "trara538/dot-stat-processing",
  subdir = "DF_WASH"
)
```

### Load

```r
library(DFWASH)
```

### Package

[`DF_WASH`](DF_WASH)

---

# Install All Packages

If you need all six packages, they can be installed with a single R script:

```r
# Install remotes if required
if (!requireNamespace("remotes", quietly = TRUE)) {
  install.packages("remotes")
}

# Package directories
packages <- c(
  "DF_ADBKI",
  "DF_COMMODITY_PRICES",
  "DF_CPI",
  "DF_IMTS",
  "DF_UIS",
  "DF_WASH"
)

# Install all packages
for (pkg in packages) {

  message("Installing ", pkg, "...")

  remotes::install_github(
    "trara538/dot-stat-processing",
    subdir = pkg
  )
}
```

After installation, load the packages:

```r
library(DFADBKI)
library(DFCOMMODITYPRICES)
library(DFCPI)
library(DFIMTS)
library(DFUIS)
library(DFWASH)
```

---

# Update Packages

To update an individual package, run its installation command again.

For example:

```r
remotes::install_github(
  "trara538/dot-stat-processing",
  subdir = "DF_CPI"
)
```

To update all packages:

```r
packages <- c(
  "DF_ADBKI",
  "DF_COMMODITY_PRICES",
  "DF_CPI",
  "DF_IMTS",
  "DF_UIS",
  "DF_WASH"
)

for (pkg in packages) {

  message("Updating ", pkg, "...")

  remotes::install_github(
    "trara538/dot-stat-processing",
    subdir = pkg,
    upgrade = "always"
  )
}
```

---

# Repository Structure

```text
dot-stat-processing/
│
├── README.md
├── dot-stat-processing.Rproj
├── .gitignore
│
├── DF_ADBKI/
│   ├── DESCRIPTION
│   ├── NAMESPACE
│   ├── R/
│   ├── man/
│   └── ...
│
├── DF_COMMODITY_PRICES/
│   ├── DESCRIPTION
│   ├── NAMESPACE
│   ├── R/
│   ├── man/
│   └── ...
│
├── DF_CPI/
│   ├── DESCRIPTION
│   ├── NAMESPACE
│   ├── R/
│   ├── man/
│   └── ...
│
├── DF_IMTS/
│   ├── DESCRIPTION
│   ├── NAMESPACE
│   ├── R/
│   ├── man/
│   └── ...
│
├── DF_UIS/
│   ├── DESCRIPTION
│   ├── NAMESPACE
│   ├── R/
│   ├── man/
│   └── ...
│
└── DF_WASH/
    ├── DESCRIPTION
    ├── NAMESPACE
    ├── R/
    ├── man/
    └── ...
```

---

# Development Installation

To work on the packages locally, clone the repository:

```bash
git clone https://github.com/trara538/dot-stat-processing.git
```

Move into the repository:

```bash
cd dot-stat-processing
```

A package can then be installed locally.

For example:

```r
remotes::install_local("DF_CPI")
```

Or:

```r
remotes::install_local("./DF_CPI")
```

---

# Data Processing Workflow

The packages support a common data preparation workflow:

```text
┌─────────────────────────────┐
│     External Data Source    │
└──────────────┬──────────────┘
               │
               ▼
┌─────────────────────────────┐
│       Data Download         │
└──────────────┬──────────────┘
               │
               ▼
┌─────────────────────────────┐
│     Data Transformation     │
└──────────────┬──────────────┘
               │
               ▼
┌─────────────────────────────┐
│       Data Validation       │
└──────────────┬──────────────┘
               │
               ▼
┌─────────────────────────────┐
│     SDMX / .Stat Output     │
└──────────────┬──────────────┘
               │
               ▼
┌─────────────────────────────┐
│       Pacific Data Hub      │
└─────────────────────────────┘
```

Each package contains source-specific processing logic while following the requirements of the downstream statistical data workflow.

---

# Package Documentation

Detailed documentation is available within each package directory.

### Packages

* [`DF_ADBKI`](DF_ADBKI)
* [`DF_COMMODITY_PRICES`](DF_COMMODITY_PRICES)
* [`DF_CPI`](DF_CPI)
* [`DF_IMTS`](DF_IMTS)
* [`DF_UIS`](DF_UIS)
* [`DF_WASH`](DF_WASH)

Refer to the individual package documentation for package-specific functions, data sources, processing steps, and usage instructions.

---

# Dependencies

Each package manages its R dependencies through its own `DESCRIPTION` file.

When a package is installed using:

```r
remotes::install_github()
```

its declared dependencies are installed automatically.

If a dependency is missing, it can be installed manually:

```r
install.packages("package_name")
```

Package-specific dependencies should be documented within the relevant package.

---

# Contributing

When making changes to a package:

1. Make changes within the relevant package directory.
2. Update the package documentation where required.
3. Test the package before committing changes.
4. Check that changes do not adversely affect other packages.
5. Commit the changes.
6. Push the changes to GitHub.

For example, changes to the CPI package should be made within:

```text
DF_CPI/
```

while changes to the UIS package should be made within:

```text
DF_UIS/
```

---

# Reporting Issues

If you encounter a problem, please open an issue in the GitHub repository:

[Open an issue on dot-stat-processing](https://github.com/trara538/dot-stat-processing/issues?utm_source=chatgpt.com)

When reporting an issue, include:

* Package name
* Package version or Git commit
* R version
* Operating system
* Error message
* Relevant code
* A minimal reproducible example, where possible

---

# License

See the [`LICENSE`](LICENSE) file for licensing information.

---

# Maintainer

This repository is maintained as part of the **Pacific Data Hub statistical data preparation workflow**.

---

## Repository

[https://github.com/trara538/dot-stat-processing](https://github.com/trara538/dot-stat-processing)
