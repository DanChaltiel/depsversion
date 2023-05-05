


library(tidyverse)
library(rlang)

Sys.setenv(LANGUAGE="en")
Sys.setlocale("LC_TIME", "English")
options(
  encoding="UTF-8",
  rlang_backtrace_on_error = "full",
  warn=1,
  warnPartialMatchArgs=TRUE,
  stringsAsFactors=FALSE,
  dplyr.summarise.inform=FALSE,
  # conflicts.policy="depends.ok",
  tidyverse.quiet=TRUE
)


# data_ns_l_export = readRDS("data_ns_l.rds") %>%
#   ungroup() %>%
#   filter(type=="export")


# data_ns = readRDS("data_ns.rds")
# cur_data_ptet = expand_data_ns_dt(data_ns)

# pkg="haven"
# cur_data=data_ns_l_export
# cur_data

# cache="data_ns.rds"
# verbose=TRUE
# target="./miniCRAN"
# update_cache=FALSE
# dependencies=TRUE
#TODO what about package removed from CRAN and thus archived ?
#TODO date minimale pour éviter de chercher trop loin dans les archives inutilement
#cf history$haven$date avec pkgsearch::cran_package_history()


# repos = gsub("/$", "", getOption("repos"))
# options(repos="https://cran.rstudio.com/")

#TODO creating cache
#TODO know which package don't have NAMESPACE

options(depsversion_cache=test_path("inst/data_ns.rds"),
        depsversion_target=test_path("miniCRAN"))
# options(depsversion_cache="inst/data_ns.rds",
#         depsversion_dir=test_path("miniCRAN"))

cli::cli_bullets(c(" "="Init: cache={.path {getOption('depsversion_cache')}},
                   target={.path {getOption('depsversion_target')}}"))


if(FALSE){
  unlink(test_path("miniCRAN"), recursive=TRUE)
  unlink(test_path("inst/data_ns.rds"))
}



if(FALSE){
  x=get_code("F:/GITHUB/crosstable/NAMESPACE")
  build_cache("crosstable", update_cache=TRUE)
  x=get_code("F:/GITHUB/crosstable/NAMESPACE")


  build_cache("haven", update_cache=FALSE)
  build_cache("readr", update_cache=FALSE)


  build_cache("vctrs", update_cache=TRUE)

  get_code("")

  x=get_code("F:/GITHUB/crosstable/NAMESPACE")
  x=get_code("tests/testthat/miniCRAN/src/extract_ns/vctrs/vctrs_0.6.2_NAMESPACE")
  x

  pkgDep("rlang", suggests=FALSE)
  pkgDep("glue", suggests=FALSE)

  x=pkgDep("dplyr", suggests=FALSE) %>% set_names()
  map(x,~pkgDep(.x, suggests=FALSE))

}
