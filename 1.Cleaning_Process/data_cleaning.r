
#  title: "data_cleaning"
#editor: 
#format: html
 # wrap: 72
#  markdown: 
#---
  
  ## Libraries and Packages
  
  
library(dplyr)
library(stringr)


## Setting paths via relative directory structure, loading data and loading SOP 
project_root <- "../../Group3"
input_data_path <- file.path(project_root, "processed_data", "merged_output.csv")
sop_path        <- file.path(project_root, "metadata", "IMPC_SOP.csv")
output_path     <- file.path(project_root, "processed_data", "clean_merged_data.csv")


# Check if files exist before reading
if (!file.exists(input_data_path)) stop("Error: merged_output.csv not found. Run Format_and_Merge.r first.")
if (!file.exists(sop_path)) stop("Error: IMPC_SOP.csv not found.")

data <- read.csv(input_data_path)
SOP  <- read.csv(sop_path)
head(SOP)

## Checking unique values in each field


for (field in colnames(data)) {
  count <- length(unique(data[ ,field]))
  print(paste("Currently", count, "unique values in", field))
}
# 25358 unique values in analysis_id (total data rows), 186 unique values in gene_accession_id, 182 unique values in gene_symbol, 14 unique values in mouse_life_stage, 17 unique values in mouse_strain, 319 unique values in parameter_id, 157 unique values in parameter_name, 25302 unique values in pvalue


# Checking each column for errors, inconsistencies, referencing SOP

## 1. Gene Accession ID


# Checking that gene_accession_id strings are between 9:11 length
all(str_length(data$gene_accession_id) %in% 9:11) #TRUE

# True/False vector for capitalisation
typo_geneaccession_id <- all(toupper(data$gene_accession_id) == data$gene_accession_id)
print(typo_geneaccession_id)
# FALSE, therefore some gene_accession_id are not capitalised
data[ data$gene_accession_id != toupper(data$gene_accession_id), "gene_accession_id" ] %>% unique()
# Prints non-capitalised entries


## 2. Gene Symbol


## Checking that mouse gene_symbol strings are between 1:13 in length
all(str_length(data$gene_symbol) %in% 1:13) #TRUE

print(unique(data[ ,"gene_symbol"]))
# All in different formats


## 3. Mouse Life Stage


# Checking that mouse_life_stage strings are between 4:17 in length
all(str_length(data$mouse_life_stage) %in% 4:17) #FALSE

#Exploring why this is the case
data$mouse_life_stage[!(str_length(data$mouse_life_stage) %in% 4:17)] #prints the entries outside of the 4:17 length
# Due to NA - however, some of the NAs are not in standard capitalised format.

print(unique(data[ ,"mouse_life_stage"])) 
# Contains wrong formats - shows 14 possible mouse life stages, there are only 7 possible stages: E12.5, E15.5, E18.5, E9.5, Early adult, Later adult, Middle aged adult


## 4. Mouse Strain


# Checking that mouse_strain strings are between 3:5 in length
all(str_length(data$mouse_strain) %in% 3:5) #TRUE 

print(unique(data[ ,"mouse_strain"]))
# Contains typos, erroneous entries - shows 17 possible mouse strains, there are only 4 possible strains: C57BL, B6J, C3H, 129SV

# Shows frequency of typos
data%>%
  group_by(mouse_strain) %>%
  summarise(count=n(), .groups="drop")


## 5. Parameter ID


# Checking that parameter_id strings are between 15:20 in length
all(str_length(data$parameter_id) %in% 15:20) #TRUE

# True/false vector for capitalisation
typo_parameter_id <- all(toupper(data$parameter_id) == data$parameter_id)
print(typo_parameter_id)
#FALSE, therefore some parameter_ids are not all capitalised
data[ data$parameter_id != toupper(data$parameter_id), "parameter_id" ] %>% unique()
# Prints non-capitalised entries

# _ standard 
sum(grepl("-", data$parameter_id)) #1128 contain a - instead of _


## 6. Parameter Name


# Checking that parameter_name strings are between 2:74 in length
all(str_length(data$parameter_name) %in% 2:74) #TRUE 

# Check if they all begin with a capital letter
all(grepl("^[A-Z]", data$parameter_name)) #FALSE
data$parameter_name[!grepl("^[A-Z]", data$parameter_name)] #those which do not

# Exploring why this is the case
sum(!grepl("^[A-Z]", data$parameter_name)) #1267 do not start with capital
sum(grepl("^[0-9%]", data$parameter_name)) #1267 start with number or % sign

#Therefore, the remainder of entries start with a capital letter and are in standard format


## 7. p-value


summary(data$pvalue)
# Minimum = -0.4870 and maximum = 1.4998 - this is an error, minimum = 0, maximum = 1


# Cleaning Pipeline


valid_strains <- c("C57BL", "B6J", "C3H", "129SV") #Specifiying valid mouse strains from SOP

cleaned_data <- data %>% 
  mutate(
    gene_accession_id = toupper(gene_accession_id), #All gene_accession_id to capitals, standard format
    
    gene_symbol = str_to_title(gene_symbol), #Capitalizing firs letter of every gene_symbol, standard format
    
    mouse_life_stage = str_to_sentence(na_if(str_to_lower(
      str_squish(mouse_life_stage)
    ),"na")), #Capitalising only first letter of every mouse_life_stage string, standard format
    
    mouse_strain = case_when
    (str_detect(mouse_strain,"C5[0-9]BL")~ "C57BL",
      str_detect(mouse_strain,"12[0-9]SV")~"129SV",
      mouse_strain %in% valid_strains ~ mouse_strain, #Keeps valid strains, capitalising only first letter of string, sets missing values to NA 
      TRUE ~ NA_character_
    ),
    
    parameter_id = toupper(parameter_id), #All parameter_id to capitals, standard format
    parameter_id = str_replace_all(parameter_id, "-", "_"), #Replacing - to _
    
    pvalue=as.numeric(pvalue),
    pvalue=if_else(pvalue <0 | pvalue >1, NA_real_, pvalue) #Setting pvalues which do not fit SOP min/max to NA
  )  


# Verifying Cleaning

## 1. Verify Gene Accession ID


cleaned_data %>%
  filter(gene_accession_id!= toupper(gene_accession_id)) %>%
  distinct(gene_accession_id)
# 0 probelmatic - all same format
# Confirm with True/False vector
all(cleaned_data$gene_accession_id == toupper(cleaned_data$gene_accession_id))
# TRUE - all strings are capitalised


## 2. Verifying Gene Symbol


cleaned_data %>% filter(!str_detect(gene_symbol,"^[A-Z][a-z0-9]+$")) %>%
  distinct(gene_symbol)
# 0 - all strings begin with a capital


## 3. Verifying Mouse Life Stage


print(unique(cleaned_data$mouse_life_stage)) 
# Now the correct format - all begin with captital letter
# 6/7 possible mouse_life_stages, in our data there are no E15.5 stage mice
# NAs in capitals 


## 4. Verifying Mouse Strain


cleaned_data%>%
  group_by(mouse_strain) %>%
  summarise(count=n(), .groups="drop") #Total frequency of different mouse strains

# Correctly renamed
sum(cleaned_data$mouse_strain == "C57BL", na.rm = TRUE) #24638
sum(cleaned_data$mouse_strain == "129SV", na.rm = TRUE) #720

#sum(data$mouse_strain == "B6J", na.rm = TRUE) #0 of B6J strain
#sum(data$mouse_strain == "C3H", na.rm = TRUE) #0 of C3H strain


## 5. Verifying Parameter ID


cleaned_data %>%
  filter(parameter_id != toupper(parameter_id)) %>%
  distinct(parameter_id)
# 0 problematic, all the same format
# Confirm with true/false vector
all(cleaned_data$parameter_id == toupper(cleaned_data$parameter_id))
# TRUE - all parameter_id strings are capitalised

sum(grepl("-", cleaned_data$parameter_id))
#0 contain - now


## 6. Verifying p-value


summary(cleaned_data$pvalue)
# Minimum = 0.0000, Maximum = 1.0000

# Counting NAs in pvalue
sum(is.na(cleaned_data$pvalue)) ##266 NAs


# Fixing Parameter Name inconsistencies


# Mismatches:
# ‘Mean cell haemoglobin concentration’ and ‘Mean cell hemoglobin concentration’
# ‘Mean cell volume’ + ‘Mean-cell-volume’
# ‘Mean corpuscular haemoglobin’ + ‘Mean corpuscular hemoglobin’ + ‘Mean-corpuscular-haemoglobin’
# ‘Platelet count’ + ‘Platelets-count’

# IMPC names:
# ‘Mean cell hemoglobin concentration’
# 'Mean cell volume'
# 'Mean corpuscular hemoglobin'
# 'Platelet count'

# ESLIM_016_001_003 parameter_name is 'Haemoglobin'
# For name consistency (useful in parameter grouping stage) we will also change this to 'Hemoglobin'

# Replace mismatched names
cleaned_data$parameter_name <-
  gsub("Mean cell haemoglobin concentration", "Mean cell hemoglobin concentration",
       gsub("Mean-cell-volume", "Mean cell volume",
            gsub("Mean corpuscular haemoglobin", "Mean corpuscular hemoglobin",
                 gsub("Mean-corpuscular-haemoglobin", "Mean corpuscular hemoglobin",
                      gsub("Platelets-count", "Platelet count",
                           gsub("Haemoglobin", "Hemoglobin",
                                cleaned_data$parameter_name))))))

# Check that this has not affected string length
all(str_length(cleaned_data$parameter_name) %in% 2:74) #TRUE


## Saving cleaned data
write.csv(cleaned_data, file = output_path, row.names = FALSE)
message(paste("Cleaned data saved to:", output_path))