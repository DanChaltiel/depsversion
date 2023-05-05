


#' Build the cache for `depsversion`
#'
#' @param pkg the packages to
#' @param cache path to a `.rds` file used as a cache.
#' @param target path to a directory used as a local repository. Can take several Gb of space.
#' @param verbose whether to print progress
#' @param update_cache whether to update the `cache` file. Used for debugging.
#' @param dependencies whether to import dependencies of `pkg`
#'
#' @return invisibly, the tibble saved to `cache`
#' @export
#'
#' @importFrom cli cli_alert_success cli_h1 cli_inform cli_warn
#' @importFrom dplyr arrange bind_rows
#' @importFrom rlang check_dots_empty
#' @importFrom glue glue
build_cache = function(pkg, ...,
                       cache=getOption("depsversion_cache", "data_ns.rds"),
                       target=getOption("depsversion_target", "./miniCRAN"),
                       verbose=TRUE, update_cache=TRUE, dependencies=TRUE){
  start_time = Sys.time()
  check_dots_empty()
  dir.create(target, recursive=TRUE, showWarnings=FALSE)
  data_ns = read_cache(cache)

  # 1 - Initialization: finding missing packages
  if(verbose){
    cli_h1("Init")
    cli_inform("Found {nrow(data_ns$nested)} versions of {length(unique(data_ns$nested$package))} packages in {.path {cache}}.")
    if(nrow(data_ns$nested)==0){
      cli_inform(c("i"="Creating new cache file {.path {cache}}."))
    }
  }
  deps_todo = get_missing_packages(pkg, data_ns, dependencies, target, verbose)
  if(length(deps_todo)==0) return(invisible(data_ns))

  # 2 - Download package archives
  download_packages(deps_todo, target, verbose)
  # dl = download_packages(deps_todo, target, verbose)
  # if(!all(file.exists(unlist(dl)))) cli_warn("This is weird...") #TODO actual warning

  # 3 - Extract NAMESPACE from archives
  archive_source = glue("{target}/src/contrib")
  target_extract = glue("{target}/src/extract_ns")
  extract_files(deps_todo, archive_source, target_extract, verbose=verbose)
  #TODO utiliser dl ici plutôt que deps_todo pour n'extraire que ce qu'il faut ?
  #TODO extract DESCRIPTION?
  # extract_files(deps_todo, archive_source, glue("{target}/src/extract_desc"), keyword="DESCRIPTION")

  # 4 - Read NAMESPACE files and reprocess the cache
  if(verbose) cli_h1("Reprocessing")
  nested_new = read_namespace_files(deps_todo, target_extract, verbose)
  if(any(nested_new$ns_file %in% data_ns$nested$ns_file)){
    cli_warn("This is weird too...") #TODO actual warning
  }
  nested_new = bind_rows(nested_new, data_ns$nested) %>% arrange(tolower(package), version)
  summary_new = expand_data_ns_dt(nested_new)

  # 5 - Out
  data_ns_new = list(nested=nested_new,summary=summary_new)
  if(update_cache) saveRDS(data_ns_new, cache)

  elapsed = round(Sys.time() - start_time)
  if(verbose) cli_alert_success("Rebuilding cache successful! It took {as.numeric(elapsed)} {attr(elapsed, 'units')}.")

  invisible(data_ns_new)
}

# Utils ---------------------------------------------------------------------------------------


#' @importFrom cli cli_alert_success cli_inform
#' @importFrom dplyr case_when filter full_join mutate pull select slice_head
#' @importFrom miniCRAN pkgDep
#' @importFrom pkgsearch cran_packages
get_missing_packages = function(pkg, data_ns, dependencies, target, verbose){

  deps = pkg
  if(isTRUE(dependencies)) {
    deps = sort(miniCRAN::pkgDep(pkg, suggests=FALSE))
  }

  cran_data = pkgsearch::cran_packages(deps) %>%
    mutate(cran_pkg_max_vrs=package_version(Version)) %>%
    select(package=Package, cran_pkg_max_vrs)

  cur_data = data_ns$summary %>%
    slice_head(n=1, by=package) %>%
    select(package, cur_pkg_max_vrs=pkg_max_vrs)

  deps_todo = full_join(cran_data, cur_data, by="package") %>%
    mutate(todo = case_when(
      is.na(cur_pkg_max_vrs) ~ "new",
      cur_pkg_max_vrs!=cran_pkg_max_vrs ~ "update",
      .default = "ok",
    )) %>%
    filter(todo!="ok") %>% #TODO récupérer plus d'infos ici ?
    pull(package)

  if(verbose) {
    if(length(deps_todo)==0){
      cli_alert_success("Cache is up-to-date for {.pkg {pkg}}!")
    } else {
      cli_inform("Updating cache for {length(deps_todo)}/{length(deps)} dependencie{?s} for {.pkg {pkg}}.")
    }
  }

  deps_todo
}


#' download packages (.tar.gz) last version and archived in {target}/src/contrib
#' @importFrom cli cli_h1 cli_inform cli_bullets
#' @importFrom dplyr filter left_join mutate select
#' @importFrom miniCRAN addOldPackage makeRepo
#' @importFrom pkgsearch cran_package_history
#' @importFrom purrr imap keep map
#' @importFrom rlang set_names
#' @importFrom stringr str_remove str_split_fixed
#' @importFrom tibble as_tibble
#' @importFrom tidyr replace_na
#' @noRd
#' @keywords internal
download_packages = function(deps_todo, target, verbose=TRUE){
  if(verbose) {
    cli_h1("Downloading")
    cli_inform("Searching CRAN for {length(deps_todo)} packages history.")
  }

  local_data = dir(file.path(target, "src/contrib")) %>%
    str_split_fixed("_", 2) %>%
    as.data.frame() %>%
    select(package=V1, version=V2) %>%
    mutate(version = str_remove(version, "\\.tar\\.gz"), downloaded=TRUE) %>%
    as_tibble()

  dl_todo = deps_todo %>%
    set_names() %>%
    map(~{
      pkgsearch::cran_package_history(.x) %>%
        select(package=Package, version=Version) %>%
        left_join(local_data, by=c("package", "version")) %>%
        mutate(downloaded = replace_na(downloaded, FALSE),
               version2 = package_version(version),
               last_version = version2==max(version2)) %>%
        filter(!downloaded)
    }) %>%
    keep(~nrow(.x)>0)

  # x = dl_todo %>% keep(~!all(.x$downloaded))
  dl_todo %>% keep(~!all(!.x$downloaded)) %>% length()
  #
  # dl_todo$lattice$downloaded %>% table

  if(verbose) {
    n_versions = dl_todo %>% map_dbl(nrow) %>% sum()
    cli_inform(c(">"="{length(dl_todo)} package{?s} ({n_versions} version{?s}) need{?s/} downloading archives."))
  }

  # .x=dl_todo$miniCRAN
  # .y="miniCRAN"
  # browser()

  #TODO waiting for variables inside pb https://github.com/tidyverse/purrr/issues/1078
  # pb = list(format="Downloading {pb_total} ({names(dl_todo)[pb_current]}/{pb_total}) {pb_bar} {pb_percent}  [{round(cli::pb_elapsed_raw)}s]  | ETA: {pb_eta}", clear=F)
  # pb = list(format="pb_current={pb_current} {browser()}", clear=F)
  dl_todo %>%
    imap(~{
      if(verbose) cli_bullets(c("*"="Downloading {nrow(.x)} version{?s} of  {.pkg { .y}}
                              (from {min(.x$version)} to {max(.x$version)})"))
      # Sys.sleep(5)
      a = character(0)
      if(any(.x$last_version)){
        a = miniCRAN::makeRepo(.y, path=target, writePACKAGES=FALSE, quiet=TRUE)
      }
      .x = .x %>% filter(!last_version) #max version is not archived
      b = miniCRAN::addOldPackage(.y, path=target, vers=.x$version, writePACKAGES=FALSE, quiet=TRUE)
      # c(file.path(dirname(a), basename(names(b))), a)
      character(0)
    }, .progress=FALSE)
  # https://cran.rstudio.com//src/contrib/Archive/miniCRAN/miniCRAN_0.0.16.tar.gz
  # https://cran.rstudio.com/src/contrib/Archive/miniCRAN/miniCRAN_0.0-16.tar.gz
  # https://cran.rstudio.com/src/contrib/Archive/miniCRAN/miniCRAN_0.0.16.tar.gz
}



#' @importFrom dplyr filter mutate
#' @importFrom glue glue
#' @importFrom purrr map
#' @importFrom stringr str_count
#' @importFrom tibble tibble
#' @importFrom tidyr separate
#' @noRd
#' @keywords internal
read_namespace_files = function(deps_todo, folder, verbose){
  #TODO waiting for variables inside pb https://github.com/tidyverse/purrr/issues/1078
  pb = list(format="Reading NS file ({pb_current}/{pb_total}) {pb_bar} {pb_percent}  [{round(cli::pb_elapsed_raw)}s]  | ETA: {pb_eta}", clear=FALSE)
  if(!verbose) pb=FALSE
  rex = paste(deps_todo, collapse="|")
  rtn = tibble(package=dir(folder, pattern=rex, recursive=TRUE)) %>%
    filter(str_count(package, "/")==1) %>% #recursive only once
    separate(package, c("package", "version", NA), sep="_") %>%
    mutate(
      package = basename(package),
      ns_file = glue("{folder}/{package}/{package}_{version}_NAMESPACE"),
      mtime = file.info(ns_file)$mtime,
      version = package_version(version),
      ns = map(ns_file, ~parse_ns(.x), .progress=pb)
    )
  rtn
}



#' @importFrom cli cli_h1
#' @importFrom glue glue
#' @importFrom purrr walk
#' @importFrom stringr str_remove
#' @noRd
#' @keywords internal
extract_files = function(deps_todo, archive_source, target_extract, keyword="NAMESPACE", verbose=TRUE){
  dir.create(target_extract, recursive=TRUE, showWarnings=FALSE)
  rex = paste(deps_todo, collapse="|")
  archives = dir(archive_source, pattern=rex, full.names=TRUE)
  archives_todo_ns = {
    pkg_name = basename(archives) %>% str_remove("_.*")
    f_name = basename(archives) %>% str_remove("\\.tar\\.gz")
    path = glue("{target_extract}/{pkg_name}/{f_name}")
    !file.exists(glue("{path}_{keyword}"))
  }

  if(verbose){
    cli_h1("Extracting {sum(archives_todo_ns)}/{length(archives_todo_ns)} archives")
  }

  #TODO waiting for variables inside pb https://github.com/tidyverse/purrr/issues/1078
  pb = list(format="Extracting archive #{pb_current} on {pb_total} {pb_bar} {pb_percent}  [{round(cli::pb_elapsed_raw)}s]  | ETA: {pb_eta}", clear=FALSE)
  # browser()
  archives[archives_todo_ns] %>%
    walk(~{
      pkg_name = basename(.x) %>% str_remove("_.*")
      f_name = basename(.x) %>% str_remove("\\.tar\\.gz")
      if(!file.exists(glue("{target_extract}/{pkg_name}/{f_name}_{keyword}"))){
        # if(verbose) cli::cli_inform("Extracting {keyword} from {.x}")
        untar_keyword(.x, target_extract, "NAMESPACE")
      } else {
        # if(verbose) cli::cli_inform("Skipping {keyword} from {.x}")
      }
    }, .progress=pb)
}


#TODO faire un truc pour les packages sans NAMESPACE ?
# archive = "miniCRAN/src/contrib/RSQLite_0.2-1.tar.gz"
# untar_keyword(archive, target_extract, "NAMESPACE")
#' @importFrom cli cli_warn
#' @importFrom glue glue
#' @importFrom stringr str_remove
#' @importFrom utils untar
#' @noRd
#' @keywords internal
untar_keyword = function(archive, target_dir, keyword, warn_missing=FALSE){
  dir.create(target_dir, recursive=TRUE, showWarnings=FALSE)
  archive_path = normalizePath(archive)
  target_path = normalizePath(target_dir)
  pkg_name = basename(archive) %>% str_remove("_.*")
  new_name = basename(archive) %>% str_remove("\\.tar\\.gz")

  # browser()
  # x=capture.output(suppressMessages(suppressWarnings(untar(archive_path, files=glue("{pkg_name}/{keyword}"),
  #                exdir=target_dir)))
  msg = untar(archive_path, files=glue("{pkg_name}/{keyword}"),
              exdir=target_dir, tar="internal")
  #TODO ça marche pas avec internal :-(
  # suppressWarnings(untar(archive_path, files=glue("{pkg_name}/{keyword}"),
  #                        exdir=target_dir))
  x = glue("{target_path}/{pkg_name}/{keyword}")
  if(file.exists(x)){
    file.rename(x, glue("{target_path}/{pkg_name}/{new_name}_{keyword}"))
  } else if(warn_missing){
    cli_warn("No {keyword} file in {.path {archive}}")
  }
  invisible()
}
