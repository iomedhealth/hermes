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

#' Parse and compute new semantic version
calculateNewVersion <- function(currentVer, type) {
  if (!grepl("^[0-9]+\\.[0-9]+\\.[0-9]+", currentVer)) {
    stop("Invalid current version format: ", currentVer)
  }
  parts <- as.integer(strsplit(currentVer, "[.-]")[[1]])
  if (length(parts) < 3 || any(is.na(parts[1:3]))) {
    stop("Invalid current version format: ", currentVer)
  }
  major <- parts[1]
  minor <- parts[2]
  patch <- parts[3]

  type <- tolower(trimws(type))
  if (type == "patch") {
    sprintf("%d.%d.%d", major, minor, patch + 1L)
  } else if (type == "minor") {
    sprintf("%d.%d.0", major, minor + 1L)
  } else if (type == "major") {
    sprintf("%d.0.0", major + 1L)
  } else if (grepl("^[0-9]+\\.[0-9]+\\.[0-9]+([.-].*)?$", type)) {
    type
  } else {
    stop("Unknown bump type or invalid version: '", type, "'.\n",
         "Expected 'patch', 'minor', 'major', or explicit SemVer string (e.g. '0.7.0').")
  }
}

#' Update version and internal dependency constraints in a DESCRIPTION file
updateDescriptionFile <- function(filePath, newVer, internalPkgs = NULL) {
  if (!file.exists(filePath)) {
    stop("File not found: ", filePath)
  }
  lines <- readLines(filePath, warn = FALSE)

  # Update Version: line
  lines <- sub("^Version:\\s*.*$", paste0("Version: ", newVer), lines)

  # Update internal packages (>= X.Y.Z) in Imports
  if (!is.null(internalPkgs) && length(internalPkgs) > 0) {
    for (pkg in internalPkgs) {
      pattern <- paste0("(", pkg, "\\s*\\(>=\\s*)[^)]+(\\))")
      replacement <- paste0("\\1", newVer, "\\2")
      lines <- sub(pattern, replacement, lines)
    }
  }

  writeLines(lines, filePath)
}

#' Bump Monorepo Version
#'
#' @param type Character: "patch", "minor", "major", or explicit version string.
#' @param rootDir Root directory of the repository. Defaults to auto-detection.
#' @param document Logical: whether to run devtools::document(). Default TRUE.
#'
#' @return Invisibly returns the new version string.
#' @export
bumpVersion <- function(type = "patch", rootDir = NULL, document = TRUE) {
  repoRoot <- if (is.null(rootDir)) findRepoRoot() else normalizePath(rootDir, winslash = "/")

  rootDescPath <- file.path(repoRoot, "DESCRIPTION")
  rootDescLines <- readLines(rootDescPath, warn = FALSE)
  verLine <- grep("^Version:\\s*", rootDescLines, value = TRUE)
  if (length(verLine) == 0) {
    stop("Could not find Version field in root DESCRIPTION: ", rootDescPath)
  }
  currentVer <- trimws(sub("^Version:\\s*", "", verLine[1]))
  newVer <- calculateNewVersion(currentVer, type)

  cat(sprintf("\n=== omopHeor Monorepo Version Bumper ===\n"))
  cat(sprintf("Current Version: %s\n", currentVer))
  cat(sprintf("New Version:     %s (%s)\n\n", newVer, type))

  # 1. Update root DESCRIPTION
  internalAll <- c("CohortUtilisation", "CohortCosts", "CohortEconomics")
  updateDescriptionFile(rootDescPath, newVer, internalPkgs = internalAll)
  cat(sprintf(" [OK] Updated root DESCRIPTION -> Version %s & internal dependencies\n", newVer))

  # 2. Update subpackages
  subpkgs <- list(
    CohortUtilisation = character(0),
    CohortCosts = character(0),
    CohortEconomics = c("CohortUtilisation", "CohortCosts")
  )

  for (pkg in names(subpkgs)) {
    pkgDescPath <- file.path(repoRoot, "packages", pkg, "DESCRIPTION")
    updateDescriptionFile(pkgDescPath, newVer, internalPkgs = subpkgs[[pkg]])
    cat(sprintf(" [OK] Updated packages/%s/DESCRIPTION -> Version %s\n", pkg, newVer))
  }

  # 3. Run devtools::document()
  if (isTRUE(document)) {
    cat("\nRunning devtools::document() across monorepo...\n")
    for (pkg in names(subpkgs)) {
      pkgPath <- file.path(repoRoot, "packages", pkg)
      cat(sprintf(" -> Documenting packages/%s...\n", pkg))
      devtools::document(pkgPath, quiet = TRUE)
    }
    cat(" -> Documenting root omopHeor...\n")
    devtools::document(repoRoot, quiet = TRUE)
    cat(" [OK] Documentation synchronized.\n")
  }

  cat(sprintf("\nMonorepo successfully bumped to version %s!\n\n", newVer))
  invisible(newVer)
}

# Run when invoked directly via Rscript
if (sys.nframe() == 0L) {
  args <- commandArgs(trailingOnly = TRUE)
  bumpType <- if (length(args) > 0) args[1] else "patch"
  bumpVersion(type = bumpType)
}
