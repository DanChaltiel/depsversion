

#' Update cache from GitHub
#'
#' Update the cache used by `depversion` using a file hosted on GitHub.
#'
#' @param cache the local cache file
#' @param backup whether to backup the local cache file
#' @param verbose whether to print stuff
#'
#' @return invisibly the new cache data
#' @export
update_cache_github = function(cache=get_cache_file(), backup=TRUE, verbose=TRUE){
  tmp = tempfile(fileext=".rds")
  download.file("https://github.com/DanChaltiel/depsversion/raw/main/inst/data_ns.rds",
                destfile=tmp)
  cache_gh = read_cache(tmp)
  cache_local = read_cache(cache)

  if(backup && file.exists(cache)){
    st = format(Sys.time(), "%Y-%m-%d_%H-%M-%S")
    cache_bak = cache %>% str_remove("\\.rds$") %>% paste0("_bak_", st, ".rds")
    if(verbose) cli_inform(c("i"="Backing up cache in {.path {cache_bak}}."))
    saveRDS(cache_local, cache_bak)
  }

  #TODO réécrire après https://github.com/tidyverse/dplyr/issues/6844
  miss = dplyr::setdiff(cache_gh$nested, cache_local$nested) %>%
    mutate(across(version, to_package_version))
  more = dplyr::setdiff(cache_local$nested, cache_gh$nested) %>%
    mutate(across(version, to_package_version))


  if(nrow(more)>0){
    if(verbose) cli_inform(c("i"="Local cache is ahead by {nrow(more)} version{?s} of {length(unique(more$package))} package{?s}",
                 " "="Please consider submitting a PR with your cache file."))
  }
  if(nrow(miss)==0){
    if(verbose) cli_inform(c("v"="Local cache is up-to-date"))
    return(cache_local)
  }
  if(verbose) cli_inform(c("!"="Local cache is missing {nrow(miss)} version{?s} of {length(unique(miss$package))} package{?s}"))

  cache_local$nested = bind_rows(cache_local$nested, miss) %>%
    arrange(tolower(package), version)

  miss_summary = dplyr::setdiff(cache_gh$summary, cache_local$summary) %>%
    mutate(across(matches("m.._vrs$"), to_package_version))
  cache_local$summary = bind_rows(cache_local$summary, miss_summary) %>%
    arrange(tolower(package), fun)



  saveRDS(cache_local, cache)
  if(verbose) cli_inform(c("v"="Local cache has been updated"))
  invisible(cache_local)
}

#TODO https://github.com/tidyverse/dplyr/issues/6844
to_package_version = function(x){
  if(is.package_version(x)) return(x)
  package_version(apply(x, 1, \(.x){
    i=max(which(.x>0), 2)
    paste(.x[1:i], collapse=".")
  }))
}
