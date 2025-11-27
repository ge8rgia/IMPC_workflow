#install.packages("tidyverse")
library(tidyverse)
#Organising unzipped files into their respective directories
project_root <- "../../Group3"
dirs_to_create <- c("data", "metadata", "processed_data")
for (d in dirs_to_create) {
  dir.create(file.path(project_root, d), showWarnings = FALSE, recursive = TRUE)
} #Creates the directories

#Classifies the metadata files when unzipped
metadata_files <- c("IMPC_SOP.csv", 
                    "Disease_information.txt", 
                    "IMPC_parameter_description.txt", 
                    "IMPC_procedure.txt",
                    "query_genes.csv")

for (f in metadata_files) {
  source_path <- file.path(project_root, f)
  dest_path   <- file.path(project_root, "metadata", f)
  
  if (file.exists(source_path)) {
    file.rename(from = source_path, to = dest_path)
    message(paste("Moved to metadata:", f))
  }
} #Moving metadata files to their directory

uncategorised_csvs <- list.files(path = project_root, pattern = "\\.csv$", full.names = FALSE)
#Assumes remaining .csvs are data files and not in data/

if (length(uncategorised_csvs) > 0) {
  for (f in uncategorised_csvs) {
    source_path <- file.path(project_root, f)
    dest_path   <- file.path(project_root, "data", f)
    
    file.rename(from = source_path, to = dest_path)
    message(paste("Moved to data:", f))
  }
}

#Format and collate the data using relative paths, and is running inside IMPC directory which is a subdirectory of Group3/
input_dir     <- file.path(project_root, "data")
output_dir    <- file.path(project_root, "processed_data")
sop_file_path <- file.path(project_root, "metadata", "IMPC_SOP.csv")

sop_data<-read_csv(sop_file_path, show_col_types = FALSE)
cat("Retrieving headers from SOP to cross reference")
correct_headers <-tolower(sop_data$dataField) #Column of correct headers to check against
if(length(correct_headers)== 0 ) {
  stop(paste("Error:Cant read datafield column in", sop_file_path))
} 
cat(sprintf("loaded %d correct headers from SOP.\n", length(correct_headers)))

csv_files <-list.files(input_dir, pattern ="\\.csv$", full.names = TRUE) #Gets list of all csv files in data directory
if(length(csv_files) ==0) {
  stop(paste("Error:no csv files located in", input_dir))
}
cat(sprintf("found %d data files to process in %s\n",length(csv_files), input_dir))

processing_files <-function(file_path) {
  lines <- read_lines(file_path, skip_empty_rows = TRUE)
  data <- tibble(line = lines) %>%
    separate(line, into = c("key", "value"), sep = ",", extra = "merge", fill = "right") %>%
    filter(!is.na(key) & key != "") %>%
    mutate(key = tolower(key)) %>%
    filter(key %in% correct_headers) %>%
    mutate(value = as.character(value))
  
  wide_data <- data %>%
    pivot_wider(names_from = key, values_from = value)
  
  return(wide_data)
}

#Merging files
cat("Merging all files ...\n")
all_raw_data <-map_dfr(csv_files, processing_files, .id ="source_file_id") %>%
  mutate(source_file = basename(csv_files[as.integer(source_file_id)])) %>%
  select(-source_file_id) #removes this temporary column 


missing_columns <-setdiff(correct_headers, names(all_raw_data))

if (length(missing_columns) > 0) {
  all_raw_data[missing_columns] <- NA_character_
}

matched_data <- all_raw_data %>%
  select(all_of(correct_headers))

write_csv(matched_data, file.path(output_dir, "merged_output.csv"), na = "")
cat(sprintf("Merged files saved to %s\n", output_dir))
                          
                          
                          
                          
                          
                          
                          
                          