#!/usr/bin/env Rscript

#' Find repository root containing DESCRIPTION and packages/
findRepoRoot <- function(startDir = getwd()) {
  curr <- normalizePath(startDir, winslash = "/", mustWork = FALSE)
  while (curr != "/" && curr != "") {
    if (file.exists(file.path(curr, "DESCRIPTION")) && dir.exists(file.path(curr, "packages"))) {
      return(curr)
    }
    parent <- dirname(curr)
    if (parent == curr) break
    curr <- parent
  }
  stop("Could not find monorepo root (must contain root DESCRIPTION and packages/).")
}

#' Resolve target argument into list of package paths relative to repo root
resolveTargets <- function(target) {
  target <- tolower(trimws(target))
  
  if (target %in% c("wave1", "foundation")) {
    c("packages/CohortUtilisation", "packages/CohortCosts")
  } else if (target %in% c("wave2", "analytics", "cohorteconomics")) {
    c("packages/CohortEconomics")
  } else if (target %in% c("wave3", "metapackage", "root", "omopheor", ".")) {
    c(".")
  } else if (target == "cohortutilisation") {
    c("packages/CohortUtilisation")
  } else if (target == "cohortcosts") {
    c("packages/CohortCosts")
  } else if (target == "all") {
    c("packages/CohortUtilisation", "packages/CohortCosts", "packages/CohortEconomics", ".")
  } else {
    stop("Unknown submission target: '", target, "'.\n",
         "Supported targets: 'wave1' (foundation), 'wave2' (analytics), 'wave3' (metapackage), 'all', or a package name.")
  }
}

#' Extract maintainer name and email from package description
getMaintainerInfo <- function(pkg) {
  pkg <- devtools::as.package(pkg)
  authors <- pkg$`authors@r`
  if (!is.null(authors)) {
    people <- eval(parse(text = authors))
    cre <- if (is.character(people)) {
      utils::as.person(people)
    } else {
      Find(function(x) "cre" %in% x$role, people)
    }
    list(name = paste(cre$given, cre$family), email = cre$email)
  } else if (!is.null(pkg$maintainer)) {
    cre <- utils::as.person(pkg$maintainer)
    list(name = paste(cre$given, cre$family), email = cre$email)
  } else {
    list(name = "Unknown", email = "unknown@example.com")
  }
}

#' Submit a single package directory to CRAN
submitPackageToCran <- function(pkgRelPath, repoRoot, checkWin = FALSE, dryRun = FALSE, document = TRUE) {
  pkgFullPath <- normalizePath(file.path(repoRoot, pkgRelPath), winslash = "/", mustWork = TRUE)
  pkg <- devtools::as.package(pkgFullPath)
  pkgName <- pkg$package
  pkgVer <- pkg$version
  maint <- getMaintainerInfo(pkg)
  maintainerEmail <- maint$email

  cat(sprintf("\n=======================================================\n"))
  cat(sprintf(" Processing CRAN Submission: %s (v%s)\n", pkgName, pkgVer))
  cat(sprintf(" Path: %s\n", pkgFullPath))
  cat(sprintf(" Maintainer: %s\n", maintainerEmail))
  cat(sprintf("=======================================================\n"))

  # 1. Document package if requested
  if (isTRUE(document)) {
    cat(" -> Refreshing documentation via devtools::document()...\n")
    devtools::document(pkgFullPath, quiet = TRUE)
  }

  # 2. Check cran-comments.md
  cranCommentsPath <- file.path(pkgFullPath, "cran-comments.md")
  if (!file.exists(cranCommentsPath)) {
    warning("cran-comments.md not found in ", pkgFullPath)
  } else {
    cat(" [OK] cran-comments.md found.\n")
  }

  # 3. Optional Win-Builder Pre-check
  if (isTRUE(checkWin)) {
    cat(" -> Uploading to win-builder (devel & release)...\n")
    devtools::check_win_devel(pkgFullPath, manual = FALSE, quiet = TRUE)
    devtools::check_win_release(pkgFullPath, manual = FALSE, quiet = TRUE)
    cat(" [OK] Win-builder checks dispatched. Results will arrive at ", maintainerEmail, " in 15-30m.\n")
  }

  # 4. Build Package Tarball
  cat(" -> Building source package (.tar.gz)...\n")
  builtPath <- pkgbuild::build(pkgFullPath, tempdir(), vignettes = !dryRun, manual = !dryRun, quiet = TRUE)
  tarSizeKb <- round(file.info(builtPath)$size / 1024, 1)
  cat(sprintf(" [OK] Package built: %s (Size: %.1f KB)\n", basename(builtPath), tarSizeKb))

  if (tarSizeKb > 5 * 1024) {
    stop("Built package exceeds CRAN limit of 5 MB (", tarSizeKb, " KB). Aborting submission.")
  }

  # 5. Submit or Dry Run
  if (isTRUE(dryRun)) {
    cat(sprintf("\n [DRY RUN] %s (v%s) ready for submission. Skipping upload.\n", pkgName, pkgVer))
    return(invisible(builtPath))
  }

  cat("\n -> Uploading to CRAN via devtools:::upload_cran()...\n")
  devtools:::upload_cran(pkg, builtPath)

  cat(sprintf("\n [SUCCESS] %s (v%s) submitted to CRAN!\n", pkgName, pkgVer))
  cat(sprintf(" IMPORTANT: Check '%s' and click the CRAN confirmation link within 30 minutes.\n\n", maintainerEmail))
  
  invisible(builtPath)
}

#' Submit specified target to CRAN
#'
#' @param target Character: "wave1", "wave2", "wave3", "all", or package name.
#' @param checkWin Logical: upload to win-builder before submission. Default FALSE.
#' @param dryRun Logical: build and check without uploading. Default FALSE.
#' @param document Logical: whether to run devtools::document(). Default TRUE.
#' @param rootDir Root directory of the repository. Defaults to auto-detection.
#'
#' @return Invisibly returns list of built tarball paths.
#' @export
submitCran <- function(target = "wave1", checkWin = FALSE, dryRun = FALSE, document = TRUE, rootDir = NULL) {
  repoRoot <- if (is.null(rootDir)) findRepoRoot() else normalizePath(rootDir, winslash = "/")
  pkgPaths <- resolveTargets(target)

  results <- list()
  for (p in pkgPaths) {
    res <- submitPackageToCran(
      pkgRelPath = p,
      repoRoot = repoRoot,
      checkWin = checkWin,
      dryRun = dryRun,
      document = document
    )
    results[[p]] <- res
  }

  invisible(results)
}

# Run when invoked directly via Rscript
if (sys.nframe() == 0L) {
  args <- commandArgs(trailingOnly = TRUE)
  target <- "wave1"
  checkWin <- FALSE
  dryRun <- FALSE
  document <- TRUE

  for (arg in args) {
    if (arg %in% c("--check-win", "-w")) {
      checkWin <- TRUE
    } else if (arg %in% c("--dry-run", "-d")) {
      dryRun <- TRUE
    } else if (arg %in% c("--no-document")) {
      document <- FALSE
    } else if (!startsWith(arg, "-")) {
      target <- arg
    }
  }

  submitCran(target = target, checkWin = checkWin, dryRun = dryRun, document = document)
}
