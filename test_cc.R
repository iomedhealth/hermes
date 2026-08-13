library(CDMConnector)
library(CohortConstructor)
library(dplyr)
library(omopgenerics)

Sys.setenv(EUNOMIA_DATA_FOLDER = file.path(tempdir(), "eunomia"))
con <- DBI::dbConnect(duckdb::duckdb(), CDMConnector::eunomiaDir("GiBleed"))
cdm <- CDMConnector::cdmFromCon(con, cdmSchema = "main", writeSchema = "main")

res <- conceptCohort(cdm, conceptSet = list(target_cohort = 4285898L), name = "target_cohort")
print(class(res))

DBI::dbDisconnect(con, shutdown = TRUE)
