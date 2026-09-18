# Pacific Data Hub Data Preparation Packages

A collection of R packages for downloading, processing, transforming, and preparing statistical data for integration into the Pacific Data Hub and related SDMX/.Stat data workflows.

This repository contains independent data-processing packages organised by data source or statistical domain. Each package can be installed directly from its subdirectory and used independently.

## Packages

| Package                                      | Description                                                        |
| -------------------------------------------- | ------------------------------------------------------------------ |
| [`DF_ADBKI`](DF_ADBKI)                       | Asian Development Bank Key Indicators data preparation             |
| [`DF_COMMODITY_PRICES`](DF_COMMODITY_PRICES) | Commodity prices data preparation                                  |
| [`DF_CPI`](DF_CPI)                           | Consumer Price Index (CPI) data preparation                        |
| [`DF_IMTS`](DF_IMTS)                         | International Merchandise Trade Statistics (IMTS) data preparation |
| [`DF_UIS`](DF_UIS)                           | UNESCO Institute for Statistics (UIS) data preparation             |
| [`DF_WASH`](DF_WASH)                         | Water, Sanitation and Hygiene (WASH) data preparation              |

Each package contains its own `DESCRIPTION`, source code, documentation, and package-specific instructions where applicable.

---

## Installation

### Prerequisites

You need R installed on your computer.

It is recommended to use a recent version of R and RStudio or another R development environment.

Install the `remotes` package if it is not already installed:

```r
install.packages("remotes")
```

### Install a package from this repository

Each package can be installed directly from its subdirectory using `remotes::install_github()`.

The root URL which points to the repository is as follows:

```text
https://github.com/trara538/dot-stat-processing
```

---

## Package Installation

### ADB Key Indicators

Install the `DF_ADBKI` package:

```r
remotes::install_github("https://github.com/trara538/dot-stat-processing", subdir = "DF_ADBKI")
```

Load the package:

```r
library(DFADBKI)
```

Package directory:

[`DF_ADBKI`](DF_ADBKI)

---

### Commodity Prices

Install the `DF_COMMODITY_PRICES` package:

```r
remotes::install_github("https://github.com/trara538/dot-stat-processing", subdir = "DF_COMMODITY_PRICES")
```

Load the package:

```r
library(DFCOMMODITYPRICES)
```

Package directory:

[`DF_COMMODITY_PRICES`](DF_COMMODITY_PRICES)

---

### Consumer Price Index

Install the `DF_CPI` package:

```r
remotes::install_github("https://github.com/trara538/dot-stat-processing", subdir = "DF_CPI")
```

Load the package:

```r
library(DFCPI)
```

Package directory:

[`DF_CPI`](DF_CPI)

---

### International Merchandise Trade Statistics

Install the `DF_IMTS` package:

```r
remotes::install_github("https://github.com/trara538/dot-stat-processing",  subdir = "DF_IMTS")
```
Load the package:

```r
library(DFIMTS)
```

Package directory:

[`DF_IMTS`](DF_IMTS)

---

### UNESCO Institute for Statistics

Install the `DF_UIS` package:

```r
remotes::install_github("https://github.com/trara538/dot-stat-processing",  subdir = "DF_UIS")
```

Load the package:

```r
library(DFUIS)
```

Package directory:

[`DF_UIS`](DF_UIS)

---

### Water, Sanitation and Hygiene

Install the `DF_WASH` package:

```r
remotes::install_github("https://github.com/trara538/dot-stat-processing",  subdir = "DF_WASH")
```

Load the package:

```r
library(DFWASH)
```

Package directory:

[`DF_WASH`](DF_WASH)

---

## Install All Packages

If you need all packages, they can be installed together:

```r
install.packages("remotes")

packages <- c(
  "DF_ADBKI",
  "DF_COMMODITY_PRICES",
  "DF_CPI",
  "DF_IMTS",
  "DF_UIS",
  "DF_WASH"
)

for (pkg in packages) {
  remotes::install_github("https://github.com/trara538/dot-stat-processing", subdir = pkg)
}
```

After installation:

```r
library(DFADBKI)
library(DFCOMMODITYPRICES)
library(DFCPI)
library(DFIMTS)
library(DFUIS)
library(DFWASH)
```

---

## Install a Specific Package

If you only need one data source, install only the corresponding package.

For example, to install the UIS package:

```r
remotes::install_github("https://github.com/trara538/dot-stat-processing",  subdir = "DF_UIS")
```

This allows users to install only the functionality they require without installing the other data-processing packages.

---

## Update Packages

To update a package to the latest version in the repository, run the same installation command again.

For example:

```r
remotes::install_github("https://github.com/trara538/dot-stat-processing",  subdir = "DF_CPI")
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
  
  remotes::install_github(
    "https://github.com/trara538/dot-stat-processing",
    subdir = pkg,
    upgrade = "always"
  )
}
```

---

## Repository Structure

The repository is organised as follows:

```text
.
├── README.md
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

## Package Documentation

Each package has its own directory containing package-specific documentation, dependencies, functions, and usage instructions.

See:

* [`DF_ADBKI`](DF_ADBKI)
* [`DF_COMMODITY_PRICES`](DF_COMMODITY_PRICES)
* [`DF_CPI`](DF_CPI)
* [`DF_IMTS`](DF_IMTS)
* [`DF_UIS`](DF_UIS)
* [`DF_WASH`](DF_WASH)

For detailed instructions, refer to the README or documentation contained within each package.

---

## Data Processing Workflow

The packages are designed to support a common data preparation workflow:

```text
External Data Source
        │
        ▼
   Data Download
        │
        ▼
 Data Transformation
        │
        ▼
 Data Validation
        │
        ▼
 SDMX / .Stat Preparation
        │
        ▼
 Pacific Data Hub
```

The individual packages handle source-specific extraction and transformation requirements while producing data suitable for downstream statistical data workflows.

---

## Dependencies

Each package manages its own R dependencies through its `DESCRIPTION` file.

When installing a package from GitHub, `remotes` will install the package and its declared dependencies.

If you encounter a missing-package error, install the required package using:

```r
install.packages("package_name")
```

Package-specific dependencies should be documented in the corresponding package directory.

---

## Development Installation

If you are developing or modifying one of the packages locally, clone the repository:

```bash
git clone https://github.com/trara538/dot-stat-processing.git
```

Then open the relevant package directory in RStudio.

For example:

```text
YOUR_REPOSITORY/
└── DF_CPI/
```

The package can then be installed locally using:

```r
remotes::install_local("DF_CPI")
```

or, from the repository root:

```r
remotes::install_local("./DF_CPI")
```

---

## Contributing

Contributions are welcome.

When modifying a package:

1. Make changes within the relevant package directory.
2. Update the package documentation where necessary.
3. Test the package before committing changes.
4. Ensure that changes do not break the other packages.
5. Commit and push the changes to the repository.

For package-specific development instructions, refer to the documentation inside the relevant package directory.

---

## Support

For questions, issues, or requests related to a specific package, please open an issue in the repository and identify the package concerned.

When reporting an issue, include:

* Package name
* Package version or Git commit
* R version
* Operating system
* Error message
* Minimal example that reproduces the problem, where possible

---

## License

See the [`LICENSE`](LICENSE) file for licensing information.

---

## Maintainer

This repository is maintained as part of the Pacific Data Hub statistical data preparation workflow.

```

A small but important point: **`remotes::install_github(..., subdir = "...")` assumes each of those six directories is a valid standalone R package**, including its own `DESCRIPTION` and package structure. If that is how you've structured them, the installation approach above is appropriate.

If you give me the **actual GitHub repository URL**, I can replace `YOUR_ORGANISATION/YOUR_REPOSITORY` throughout and tailor the README to the exact package names/functions in your repository.
```
