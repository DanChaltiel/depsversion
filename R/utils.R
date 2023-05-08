

#' unnest `ns` and calculate min/max version for each function
#' @importFrom dplyr arrange filter group_by left_join mutate summarise ungroup
#' @importFrom tidyr unnest
#' @noRd
#' @keywords internal
expand_data_ns = function(data_ns){

  data_ns_s = data_ns %>%
    group_by(package) %>%
    summarise(
      pkg_n_vrs=length(version),
      pkg_min_vrs=min(version),
      pkg_max_vrs=max(version)
    )
  data_ns %>% #10s
    unnest(ns) %>%
    filter(type=="export") %>%
    group_by(package, type, fun) %>%
    summarise(fun_min_vrs=min(version),
              fun_max_vrs=max(version)) %>%
    ungroup() %>%
    left_join(data_ns_s, by="package") %>%
    mutate(
      since_start = fun_min_vrs==pkg_min_vrs,
      until_now = fun_max_vrs==pkg_max_vrs,
      always = since_start & until_now
    ) %>%
    arrange(type, tolower(package), package, tolower(fun))
}

#' unnest `ns` and calculate min/max version for each function
#' @importFrom dplyr arrange left_join mutate
#' @importFrom tibble as_tibble
#' @importFrom data.table as.data.table
#' @importFrom tidyr unnest
#' @noRd
#' @keywords internal
expand_data_ns_dt = function(data_ns){
  dt = as.data.table(data_ns)
  data_ns_s = dt[,.(pkg_n_vrs=length(version),
                    pkg_min_vrs=min(version),
                    pkg_max_vrs=max(version)),
                 by=.(package)] %>%
    as_tibble()


  #TODO accélérer ça c'est bien trop long !!
  #s pour dplyr, s pour datatable
  dt2 = data_ns %>% unnest(ns) %>% as.data.table()
  rtn = dt2[type=="export",
            .(fun_min_vrs=base::min(version),
              fun_max_vrs=base::max(version)),
            by=.(package, type, fun)] %>%
    left_join(data_ns_s, by="package") %>%
    mutate(
      since_start = fun_min_vrs==pkg_min_vrs,
      until_now = fun_max_vrs==pkg_max_vrs,
      always = since_start & until_now
    ) %>%
    # arrange(type, tolower(package), tolower(fun)) %>%
    arrange(type, tolower(package), package, tolower(fun), fun) %>% #TODO remove this line
    as_tibble()
  attr(rtn, '.internal.selfref') = NULL #TODO remove this line
  rtn
}



#' @importFrom cli cli_abort cli_warn
#' @importFrom stringr str_ends
#' @importFrom tidyr unnest
#' @noRd
#' @keywords internal
read_cache = function(cache){
  if(!str_ends(tolower(cache), "\\.rds")){
    cli_abort("File {.path {cache}} should be a {.val .rds} file.")
  }
  if(!file.exists(cache)){
    return(empty_cache())
  }
  data_ns = readRDS(cache)

  dup_nested = data_ns$nested %>%
    filter(n()>1, .by=c(package, version))
  if(nrow(dup_nested)>0){
    cli_warn(c("Duplicate rows in the cache.", "i"="run {.run dplyr::filter(data_ns$nested, n()>1, .by=c(package, version))} to vizualize them and remove them accordingly."))
  }

  dup_summary = data_ns$summary %>%
    filter(n()>1, .by=c(package, fun))
  if(nrow(dup_nested)>0){
    cli_warn(c("Duplicate rows in the cache.", "i"="run {.run dplyr::filter(data_ns$summary, n()>1, .by=c(package, fun))} to vizualize them and remove them accordingly."))
  }

  a = data_ns$nested %>% unnest(ns)
  b = data_ns$summary
  stopifnot(b$type=="export")
  stopifnot(setequal(a$package, b$package))
  stopifnot(setequal(b$package, a$package))

  data_ns
  #
  #
  # data_ns$nested$ns_file = str_remove(data_ns$nested$ns_file, "^./")
  # data_ns$nested = data_ns$nested[!duplicated(data_ns$nested),]
  # data_ns$nested = data_ns$nested %>% filter(!is.na(mtime))
  # dplyr::filter(data_ns$nested, n()>1, .by=c(package, version))

  # saveRDS(data_ns, "inst/data_ns.rds")

}



# empty_cache = function() map(read_cache("inst/data_ns.rds"), ~filter(.x, F))
empty_cache = function() {
  list(
    nested = structure(
      list(
        package = character(0),
        version = structure(list(), class = c("package_version", "numeric_version")),
        ns_file = character(0),
        mtime = structure(numeric(0), tzone = "", class = c("POSIXct", "POSIXt")),
        ns = list()
      ),
      row.names = integer(0),
      class = c("tbl_df", "tbl", "data.frame")
    ),
    summary = structure(
      list(
        package = character(0),
        type = character(0),
        fun = character(0),
        fun_min_vrs = structure(list(), class = c("package_version", "numeric_version")),
        fun_max_vrs = structure(list(), class = c("package_version", "numeric_version")),
        pkg_n_vrs = integer(0),
        pkg_min_vrs = structure(list(), class = c("package_version", "numeric_version")),
        pkg_max_vrs = structure(list(), class = c("package_version", "numeric_version")),
        since_start = logical(0),
        until_now = logical(0),
        always = logical(0)
      ),
      class = c("tbl_df", "tbl", "data.frame"),
      row.names = integer(0)
    )
  )
}




# ns_file = "miniCRAN/src/extract_ns/askpass/askpass_1.0_NAMESPACE"
# ns_file = "miniCRAN/src/extract_ns/dplyr/dplyr_1.0.9_NAMESPACE"
#
# #TODO a very weird multiline export(...)
# ns_file = "miniCRAN/src/extract_ns/bit/bit_1.1-10_NAMESPACE"
#
# # ns_file = data_ns$ns_file[1]
# read_ns(ns_file)
#' parseNamespaceFile is not good enough
#' @importFrom dplyr bind_rows
#' @importFrom readr read_lines
#' @importFrom stringr str_match str_remove_all str_split str_subset
#' @importFrom tibble tibble
#' @noRd
#' @keywords internal
parse_ns = function(ns_file){
  if(!file.exists(ns_file)){
    # cli_warn("{.file {ns_file}} does not exist.")
    return(NULL)
  }
  l = read_lines(ns_file)

  export = l %>% str_subset("export\\((.*)\\)") %>%
    str_match("export\\((.*)\\)") %>% .[,2] %>%
    # str_remove_all('"') %>%
    str_split(", ?") %>% unlist() %>% unique()

  import =  l %>% str_subset("import\\(.*\\)") %>%
    str_match("import\\((.*)\\)") %>% .[,2] %>%
    str_split(", ?") %>% unlist() %>%
    str_remove_all('"') %>%
    str_subset("except *=", negate=TRUE) %>% unique()

  importFrom = l %>% str_subset("importFrom\\((.*)\\)") %>%
    str_match("importFrom\\((.*)\\)") %>% .[,2] %>% unique()

  rtn = bind_rows(
    tibble(type="export", fun=export),
    tibble(type="import", fun=import),
    tibble(type="importFrom", fun=importFrom),
  )
  attr(rtn, "mtime") = file.info(ns_file)$mtime
  rtn
}


get_cache_file = function(){
  getOption("depsversion_cache", "data_ns.rds")
}

