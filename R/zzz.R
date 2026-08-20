# Tidyverse-style metapackage attach hook

.onAttach <- function(libname, pkgname) {
  needed_pkgs <- c("CohortUtilisation", "CohortCosts", "CohortEconomics")

  # Load namespaces and attach
  attached_status <- character()
  for (pkg in needed_pkgs) {
    if (requireNamespace(pkg, quietly = TRUE)) {
      if (!paste0("package:", pkg) %in% search()) {
        try(attachNamespace(pkg), silent = TRUE)
      }
      ver <- as.character(utils::packageVersion(pkg))
      attached_status <- c(attached_status, paste0(pkg, " ", ver))
    }
  }

  if (length(attached_status) > 0 && interactive()) {
    header <- cli::rule(
      left = cli::style_bold("Attaching packages"),
      right = paste0("hermes ", utils::packageVersion("hermes")),
      line = 1
    )
    packageStartupMessage(header)
    for (s in attached_status) {
      packageStartupMessage(cli::col_green(cli::symbol$tick), " ", s)
    }
  }
}
