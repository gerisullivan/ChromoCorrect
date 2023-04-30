
<!-- README.md is generated from README.Rmd. Please edit this file -->

# ChromoCorrect

<!-- badges: start -->
<!-- badges: end -->

ChromoCorrect is an R Package and R Shiny app that detects and corrects
for chromosomal bias in read counts.

## Installation

You can install the development version of ChromoCorrect from
[GitHub](https://github.com/) with:

``` r
# install.packages("devtools")
devtools::install_github("gerisullivan/ChromoCorrect")
```

## Example

To obtain read counts and perform normalisation:

``` r
library(ChromoCorrect)
# If current working directory is folder with all .csv files:
readcounts <- structure_rc()

# If wanting to specify path:
readcounts <- structure_rc(csvpath = "~/path/to/files")

# If not wanting locus information:
readcounts <- structure_rc(csvpath = "~/path/to/files", getLocusInfo = FALSE)

# to normalise the data:
# If column names for control are "MH_1" and "MH_2":
normalise_CB(x, control = "MH", windowSize = "auto", minrc = 10, writePlots = TRUE, locusInfo = TRUE, path = "~/path/to/files")
```