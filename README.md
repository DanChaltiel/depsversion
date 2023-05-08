
# depsversion

<!-- badges: start -->
[![Lifecycle: experimental](https://img.shields.io/badge/lifecycle-experimental-orange.svg)](https://lifecycle.r-lib.org/articles/stages.html#experimental)
<!-- badges: end -->

The goal of `depsversion` is to figure out which minimum version to indicate in DESCRIPTION's Import section.

There are 2 main functions here: `get_import_code()` to get the code for the section, and `build_cache()` to build the information needed for `get_import_code()`.

## Installation

You can install the development version of `depsversion` like so:

``` r
remotes::install_github("DanChaltiel/depsversion")
```



## WIP

This package if heavily experimental, any feedback or collaboration is welcome!

Of note, I'd like to:

 - deal with packages without NAMESPACE
 - add a minimal date so you don't have to download very old archives
 - fix some old bugs (like in "anytime_0.0.1_NAMESPACE")
 - use a DESCRIPTION file in `build_cache()`?


## Get started

Just provide a path to a NAMESPACE file to `get_import_code()`, and there you go.

```r
get_import_code("F:/GITHUB/crosstable/NAMESPACE")
#> Replace the `Imports` section in DESCRIPTION with:
#> Imports:
#>     checkmate (>= 1.9.0),
#>     cli (>= 3.0.0),
#>     dplyr (>= 1.1.0),
#>     flextable (>= 0.5.1),
#>     forcats (>= 1.0.0),
#>     glue (>= 1.3.0),
#>     lifecycle (>= 0.2.0),
#>     methods,
#>     officer (>= 0.4.0),
#>     purrr (>= 0.2.3),
#>     rlang (>= 1.0.0),
#>     stats,
#>     stringr (>= 1.4.0),
#>     tibble (>= 1.1),
#>     tidyr (>= 1.0.0),
#>     utils,
```

OK, let's be honest, that was a bit too easy. 

This function actually relies on a cache file that needs to be built beforehand.

You can download a starting cache using `update_cache_github()`. It is up-to-date for tidyverse packages as of May 2023. 

If you come from the future or if you import non-tidyverse packages, you might need to rebuild the cache using `build_cache("my_package_on_CRAN")`.


First, you need to download the cache file:

```r
update_cache_github()
#> trying URL 'https://github.com/DanChaltiel/depsversion/raw/main/inst/data_ns.rds'
#> Content type 'application/octet-stream' length 363495 bytes (354 KB)
#> downloaded 354 KB
#> 
#> ! Local cache is missing 3955 versions of 211 packages
#> v Local cache has been updated


build_cache("crosstable")
#> -- Init ----------------------------------------------------------------------------------
#> Found 3955 versions of 211 packages in inst/data_ns.rds.
#> v Cache is up-to-date for crosstable!
```



Don't worry, `get_import_code()` will tell you what code you should run if needed (See section "from scratch" in the end).




## Limitations

This package has several, potentially fatal limitations:

> `depsversion` only takes exporting into account

If a function gains a feature without changing name, this will be unnoticed.

You can consider the output of `depsversion` as a minimum though.

> `depsversion` cannot work with `ìmport()` calls in NAMESPACE (only `importFrom`)

It cannot work with direct package reference with `::`.
   
This can be helped using my other package [`autoimport`](https://github.com/DanChaltiel/autoimport) which automatically finds imports by reading your code. Give it a shot!


## Start from scratch

The "Get started" example is working using pre-built information that were up-to-date on may 2023. Here is how it look like to start from scratch.

First, set some options and ask for the code. 

Of note, many packages might be downloaded in `depsversion_target`, so the folder can take several Gb of spaces in some cases.

``` r
library(depsversion)
options(depsversion_cache="path/to/my/cache.rds",
        depsversion_target="path/to/a/dir")
get_import_code("F:/GITHUB/crosstable/NAMESPACE")
#>Error in `get_import_code()`:
#>! `cache` is missing information about packages checkmate, cli, dplyr, flextable,
#>  forcats, glue, lifecycle, officer, purrr, rlang, stringr, tibble, and tidyr.
#>  Please run the following code to build it:
#>  depsversion::build_cache(c("checkmate", "cli", "dplyr", "flextable", "forcats", "glue",
#>  "lifecycle", "officer", "purrr", "rlang", "stringr", "tibble", "tidyr"))
```

Of course, your cache is empty at this point, but the error told you to run another function:

``` r
depsversion::build_cache(c("checkmate", "cli", "dplyr", "flextable", "forcats", "glue", "lifecycle", "officer", "purrr", "rlang", "stringr", "tibble", "tidyr"))
#> i Creating new cache file tests/testthat/inst/data_ns.rds.
#> 
#> -- Init ----------------------------------------------------------------------------------
#> Found 0 versions of 0 packages in tests/testthat/inst/data_ns.rds.
#> Warning in miniCRAN::pkgDep(pkg, suggest = FALSE) :
#>   partial argument match of 'suggest' to 'suggests'
#> Updating cache for 77/77 dependencies for checkmate, cli, dplyr, flextable, forcats,
#> glue, lifecycle, officer, purrr, rlang, stringr, tibble, and tidyr.
#> 
#> -- Downloading ---------------------------------------------------------------------------
#> Searching CRAN for 77 packages history.
#> > 77 packages (1611 versions) need downloading archives.
#> * Downloading 2 versions of askpass (from 1.0 to 1.1)
#> * Downloading 22 versions of backports (from 1.0.0 to 1.4.1)
#> * Downloading 4 versions of base64enc (from 0.1-0 to 0.1-3)
#> * Downloading 8 versions of bslib (from 0.2.4 to 0.4.2)
#> * Downloading 9 versions of cachem (from 1.0.0 to 1.0.8)
#> * Downloading 31 versions of checkmate (from 1.0 to 2.2.0)
#> * Downloading 23 versions of cli (from 1.0.0 to 3.6.1)
#> * Downloading 17 versions of commonmark (from 0.2 to 1.9.0)
#> * Downloading 14 versions of cpp11 (from 0.1.0 to 0.4.3)
#> * Downloading 14 versions of crayon (from 1.0.0 to 1.5.2)
#> * Downloading 20 versions of crul (from 0.1.0 to 1.3)
#> * Downloading 39 versions of curl (from 0.2 to 5.0.0)
#> * Downloading 60 versions of data.table (from 1.0 to 1.9.8)
#> * Downloading 47 versions of digest (from 0.1.0 to 0.6.9)
#> * Downloading 43 versions of dplyr (from 0.1 to 1.1.2)
#> * Downloading 8 versions of ellipsis (from 0.0.1 to 0.3.2)
#> * Downloading 31 versions of evaluate (from 0.1 to 0.9)
#> * Downloading 12 versions of fansi (from 0.2.1 to 1.0.4)
#> * Downloading 4 versions of fastmap (from 1.0.0 to 1.1.1)
#> * Downloading 44 versions of flextable (from 0.1.0 to 0.9.1)
#> * Downloading 8 versions of fontawesome (from 0.1.0 to 0.5.1)
#> * Downloading 2 versions of fontBitstreamVera (from 0.1.0 to 0.1.1)
#> * Downloading 1 version of fontLiberation (from 0.1.0 to 0.1.0)
#> * Downloading 3 versions of fontquiver (from 0.1.0 to 0.2.1)
#> * Downloading 9 versions of forcats (from 0.1.0 to 1.0.0)
#> * Downloading 22 versions of fs (from 1.0.0 to 1.6.2)
#> * Downloading 23 versions of gdtools (from 0.0.3 to 0.3.3)
#> * Downloading 6 versions of generics (from 0.0.1 to 0.1.3)
#> * Downloading 4 versions of gfonts (from 0.1.1 to 0.2.0)
#> * Downloading 15 versions of glue (from 1.0.0 to 1.6.2)
#> * Downloading 13 versions of highr (from 0.1 to 0.9)
#> * Downloading 13 versions of htmltools (from 0.2.4 to 0.5.5)
#> * Downloading 3 versions of httpcode (from 0.1.0 to 0.3.0)
#> * Downloading 38 versions of httpuv (from 1.0.5 to 1.6.9)
#> * Downloading 4 versions of jquerylib (from 0.1 to 0.1.4)
#> * Downloading 39 versions of jsonlite (from 0.9.0 to 1.8.4)
#> * Downloading 58 versions of knitr (from 0.1 to 1.9)
#> * Downloading 15 versions of later (from 0.3 to 1.3.1)
#> * Downloading 6 versions of lifecycle (from 0.1.0 to 1.0.3)
#> * Downloading 6 versions of magrittr (from 1.0.0 to 2.0.3)
#> * Downloading 6 versions of memoise (from 0.1 to 2.0.1)
#> * Downloading 14 versions of mime (from 0.1 to 0.9)
#> * Downloading 43 versions of officer (from 0.1.0 to 0.6.2)
#> * Downloading 39 versions of openssl (from 0.1 to 2.0.6)
#> * Downloading 29 versions of pillar (from 1.0.0 to 1.9.0)
#> * Downloading 5 versions of pkgconfig (from 1.0.0 to 2.0.3)
#> * Downloading 4 versions of promises (from 1.0.1 to 1.2.0.1)
#> * Downloading 16 versions of purrr (from 0.1.0 to 1.0.1)
#> * Downloading 15 versions of R6 (from 1.0.1 to 2.5.1)
#> * Downloading 21 versions of ragg (from 0.1.0 to 1.2.5)
#> * Downloading 4 versions of rappdirs (from 0.3 to 0.3.3)
#> * Downloading 96 versions of Rcpp (from 0.10.0 to 1.0.9)
#> * Downloading 36 versions of rlang (from 0.1 to 1.1.1)
#> * Downloading 53 versions of rmarkdown (from 0.3.3 to 2.9)
#> * Downloading 12 versions of sass (from 0.1.1 to 0.4.6)
#> * Downloading 47 versions of shiny (from 0.10.0 to 1.7.4)
#> * Downloading 9 versions of sourcetools (from 0.1.0 to 0.1.7-1)
#> * Downloading 34 versions of stringi (from 0.1-25 to 1.7.8)
#> * Downloading 16 versions of stringr (from 0.1.10 to 1.5.0)
#> * Downloading 15 versions of sys (from 1.0 to 3.4.1)
#> * Downloading 14 versions of systemfonts (from 0.1.0 to 1.0.4)
#> * Downloading 12 versions of textshaping (from 0.1.0 to 0.3.6)
#> * Downloading 32 versions of tibble (from 1.0 to 3.2.1)
#> * Downloading 30 versions of tidyr (from 0.1 to 1.3.0)
#> * Downloading 12 versions of tidyselect (from 0.1.1 to 1.2.0)
#> * Downloading 45 versions of tinytex (from 0.1 to 0.9)
#> * Downloading 3 versions of triebeard (from 0.2.0 to 0.4.1)
#> * Downloading 15 versions of urltools (from 0.5 to 1.7.3)
#> * Downloading 9 versions of utf8 (from 1.0.0 to 1.2.3)
#> * Downloading 7 versions of uuid (from 0.1-1 to 1.1-0)
#> * Downloading 24 versions of vctrs (from 0.1.0 to 0.6.2)
#> * Downloading 14 versions of withr (from 1.0.0 to 2.5.0)
#> * Downloading 39 versions of xfun (from 0.1 to 0.9)
#> * Downloading 16 versions of xml2 (from 0.1.0 to 1.3.4)
#> * Downloading 40 versions of xtable (from 1.0-1 to 1.8-4)
#> * Downloading 33 versions of yaml (from 1.0 to 2.3.7)
#> * Downloading 12 versions of zip (from 1.0.0 to 2.3.0)
#> 
#> -- Extracting 1611/1611 archives ---------------------------------------------------------
#> Extracting archive #1611 on 1611 ==============================>  100%  [209s]  | ETA:  0s
#> 
#> -- Reprocessing --------------------------------------------------------------------------
#> Reading NS file (1577/1577) ==============================>  100%  [28s]  | ETA:  0s
#> v Rebuilding cache successful! It took 10 mins.
```

There you are, you can get the code now!

```r
get_import_code("F:/GITHUB/crosstable/NAMESPACE")
#> Replace the `Imports` section in DESCRIPTION with:
#> Imports:
#>     checkmate (>= 1.9.0),
#>     cli (>= 3.0.0),
#>     dplyr (>= 1.1.0),
#>     flextable (>= 0.5.1),
#>     forcats (>= 1.0.0),
#>     glue (>= 1.3.0),
#>     lifecycle (>= 0.2.0),
#>     methods,
#>     officer (>= 0.4.0),
#>     purrr (>= 0.2.3),
#>     rlang (>= 1.0.0),
#>     stats,
#>     stringr (>= 1.4.0),
#>     tibble (>= 1.1),
#>     tidyr (>= 1.0.0),
#>     utils,
```
