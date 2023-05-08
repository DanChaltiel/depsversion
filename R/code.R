
#' Title
#'
#' @param ns_path path to NAMESPACE
#' @param data the result of [build_cache] or its cache file
#' @param verbose whether to print the result
#'
#' @return the code to include in DESCRIPTION (invisibly if `verbose==TRUE`)
#' @export
#'
#' @importFrom cli cli_abort cli_inform cli_warn
#' @importFrom dplyr arrange filter left_join mutate pull select summarise
#' @importFrom glue glue
#' @importFrom tidyr separate
#' @importFrom utils installed.packages
get_import_code = function(ns_path, cache=getOption("depsversion_cache", "data_ns.rds"),
                    verbose=TRUE){
  ns_file = parse_ns(ns_path)
  if(is.null(ns_file)){
    cli_abort("{.path {ns_path}} does not exist.")
  }
  if(any(ns_file$type=="import")){
    cli_inform(c("!"="NAMESPACE contains {.fun import} calls.",
                 "i"="{.pkg depsversion} should be used with {.fun importFrom} calls only. Use the {.pkg autoimport} package if needed.",
                 " "="Results shown below are likely to be erroneous."))
  }

  data = read_cache(cache)
  base_packages = rownames(installed.packages(priority = "base"))

  b = data$summary %>%
    filter(type=="export") %>%
    select(-type)

  a = ns_file %>%
    filter(type=="importFrom") %>%
    select(-type) %>%
    separate(fun, into=c("importFrom", "importWhat"), sep=", ?") %>%
    mutate(base_package = importFrom %in% base_packages,
           is_parsed = base_package | importFrom %in% b$package)
  i = ns_file %>%
    filter(type=="import") %>%
    select(importFrom=fun)

  if(any(!a$is_parsed)){
    miss = a %>% filter(!is_parsed) %>% pull(importFrom) %>% unique()
    miss2 = miss %>% paste(collapse='", "')
    cli_abort(c("{.arg cache} is missing information about packages {.pkg {miss}}.",
                " "='Please run the following code to build it:',
                " "='{.run depsversion::build_cache(c("{miss2}"))}'))
  }

  #TODO use `reason` somewhere?

  rtn = a %>%
    left_join(b, by=c("importFrom"="package", "importWhat"="fun")) %>%
    summarise(reason=paste(importWhat, collapse=", "),
              .by=c(importFrom, pkg_max_vrs, fun_min_vrs)) %>%
    {if(nrow(i)>0) bind_rows(., i) else .} %>% #FIXME waiting for https://github.com/r-lib/vctrs/issues/1748
    arrange(importFrom, fun_min_vrs) %>%
    filter(is.na(fun_min_vrs) | fun_min_vrs==max(fun_min_vrs),
           .by=importFrom) %>%
    mutate(
      code = ifelse(is.na(fun_min_vrs),
                    glue("    {importFrom},", .trim=F),
                    glue("    {importFrom} (>= {fun_min_vrs}),", .trim=F))
    )

  code = paste(c("Imports:", rtn$code), collapse="\n")
  f = identity
  if(verbose){
    cli_inform("Replace the `Imports` section in DESCRIPTION with:")
    message(code)
    f = invisible
  }
  f(code)
}

