#install.packages("tidyverse")
library(tidyverse)

#Format and collate the data
input_dir <-"/Users/ahmedalshagga/Desktop/DBDM_COURSEWORK_DATA/data/"
output_dir <-"/Users/ahmedalshagga/Desktop/DBDM_COURSEWORK_DATA/processed_data/"
sop_file_path<- "/Users/ahmedalshagga/Desktop/DBDM_COURSEWORK_DATA/metadata/IMPC_SOP.csv"

#Creating output dir if it doesnt exist 
dir.create(output_dir, showWarnings = FALSE, recursive = TRUE)

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
                          
                          
                          
                          
                          
                          
                          
                          