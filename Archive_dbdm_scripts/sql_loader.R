library(dplyr)
library(stringr)
library(tidyr) 
######Checking the metadata files which will be loaded into SQL
INPUT_DIR <-("../DBDM_COURSEWORK_DATA/metadata/")
#Loading all files
parameters <- read_csv(file.path(INPUT_DIR, "IMPC_parameter_description.txt"), col_types = cols(.default = "c"))
procedures <- read_csv(file.path(INPUT_DIR, "IMPC_procedure.txt"), col_types = cols(.default = "c"))
diseases <- read_tsv(file.path(INPUT_DIR, "Disease_information.txt"), col_types = cols(.default = "c"))

#Audit function
audit_file <- function(df, name) {
  cat("---", name, "---\n")
  cat("Rows:", nrow(df), "| Columns:", ncol(df), "\n")
  cat("Duplicates:", sum(duplicated(df)), "\n")
  
  # Missing values
  missing <- colSums(is.na(df))
  total_missing <- sum(missing)
  
  if (total_missing > 0) {
    cat("Missing values:\n")
    print(missing[missing > 0])
  } else {
    cat("No missing values.\n")
  }
  cat("\n")
}

#Check Disease Info file, specifically ID's
check_diseases <- function(df) {
  cat("--- Disease Format Check ---\n")
  cat("Invalid DOID:", sum(!str_detect(df$`DO Disease ID`, "^DOID:\\d+$"), na.rm = TRUE), "\n")
  cat("Invalid MGI:", sum(!str_detect(df$`Mouse MGI ID`, "^MGI:\\d+$"), na.rm = TRUE), "\n")
  cat("Multi-OMIM IDs:", sum(str_detect(df$`OMIM IDs`, "\\|"), na.rm = TRUE), "\n\n")
}

#Check Paramter and Procedure relationships
check_integrity <- function(params, procs) {
  cat("--- Parameter-Procedure Integrity ---\n")
  
  # Check for duplicate parameter IDs
  dups <- sum(duplicated(params$impcParameterOrigId))
  cat("Duplicate parameter IDs:", dups, "\n")
  
  # Check for missing references
  missing <- anti_join(procs, params, by = "impcParameterOrigId")
  missing_ids <- unique(missing$impcParameterOrigId)
  
  cat("Procedure IDs missing from parameters:", length(missing_ids), "\n")
  if (length(missing_ids) > 0) {
    cat("Examples:", paste(head(missing_ids, 3), collapse = ", "), "\n")
  }
  cat("\n")
}

#Check each file
audit_file(diseases, "Diseases")
check_diseases(diseases)

audit_file(parameters, "Parameters")
cat("Empty descriptions:", sum(is.na(parameters$description)), "\n\n")

audit_file(procedures, "Procedures")
check_integrity(parameters, procedures) #Returned 14 duplicate ID's, must be removed

#Cleaning metadata files
parameters_clean <- parameters %>% distinct()
diseases_expanded <- diseases %>%
  separate_rows(`OMIM IDs`, sep = "\\|")

procedures_clean <-procedures %>%
  distinct()

OUTPUT_DIR <-"../DBDM_COURSEWORK_DATA/processed_data/"
write.csv(procedures_clean, file.path(OUTPUT_DIR, "procedures_clean_for_sql.csv"))

write.csv (parameters_clean, file.path(OUTPUT_DIR, "parameters_clean_for_sql.csv"))

write.csv(diseases_expanded,
          file.path(OUTPUT_DIR, "diseased_clean"))


