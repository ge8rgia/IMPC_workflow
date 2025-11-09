library(dplyr)
library(stringr)


#Function to cross referencing with SOP for cleaning Function
run_cross_reference <-function(dataset_to_check) {
  print("Mouse_life_stage_typo' ")
  print(unique(dataset_to_check[ ,"mouse_life_stage"])) 
  
  print("Pvalue_summary' ")
  print(summary(dataset_to_check$pvalue))
  
  print("'mouse_strain' typos")
  dataset_to_check %>%
    group_by(mouse_strain) %>%
    summarise(count = n(), .groups = "drop") %>%
    print() # 
  
  print("Checking 'gene_symbol' typos")
  dataset_to_check %>% 
    filter(!str_detect(gene_symbol, "^[A-Z][a-z0-9]+$")) %>%
    distinct(gene_symbol) %>%
    print()
  
  print("gene_accession_id' typos")
  dataset_to_check %>%
    filter(!str_detect(gene_accession_id, "^MGI:")) %>%
    distinct(gene_accession_id) %>%
    print()
  
  print("parameter_id' typos")
  dataset_to_check %>%
    filter(!str_detect(parameter_id, "^[A-Z0-9_]+$")) %>%
    distinct(parameter_id) %>%
    print()
}
data <- read.csv("../processed_data/merged_output.csv")


#Quick Summary
for (field in colnames(data)) {
  count <- length(unique(data[ ,field]))
  print(paste("Currently", count, "unique values in", field))
}

run_cross_reference(data) #Check on unclean data

#Mouse_life_stage:Contains typos which have to be cleaned
#P_value, has a max which exceed 1(1.4998), requires cleaning
#Mouse_strain: Contains typos, should only have the following 4:C57BL; B6J; C3H; 129SV, the typo effect C7BL and 129SV count
#Gene_Symbol: Contains typos
#Ascension ID: 86 in the wrong format (mgi)
#Parameter_ID: 147 wrongly formatted
#Analysis_ID: Doesn't require further cleaning
#Parameter_Name: Doesnt require further cleaning 

####DATA_CLEANING#######

valid_strains <-c("C57BL", "B6J", "C3H", "129SV") #Defines SOP values for this
data_cleaned<- data %>% 
  mutate(
    mouse_life_stage=str_to_sentence(na_if(str_to_lower(
                                           str_squish(mouse_life_stage)
                                           ),"na")),
    
    mouse_strain=case_when
    (str_detect(mouse_strain,"C5[0-9]BL")~ "C57BL",
    str_detect(mouse_strain,"12[0-9]SV")~"129SV",
    mouse_strain %in% valid_strains ~ mouse_strain, #Keeps valid strains, set others to NA
      TRUE ~ NA_character_
  ),
  
gene_symbol = str_to_title(gene_symbol),#Gene symbol converted to SOP format.
                       
pvalue=as.numeric(pvalue),
pvalue=if_else(pvalue <0 | pvalue >1, NA_real_, pvalue), #Set values which dont fit SOP to NA (266)

gene_accession_id = str_replace(gene_accession_id, "^mgi:", "MGI:"),#Corrects mgi to correct format (MGI)

parameter_id = str_to_upper(parameter_id),
parameter_id = str_replace_all(parameter_id,"-","_")
)

#Verifying
run_cross_reference(data_cleaned) #Clean and can now save
#Save clean data 
write.csv(data_cleaned,
          "../processed_data/cleaned_merged_output.csv",
          row.names = FALSE)

