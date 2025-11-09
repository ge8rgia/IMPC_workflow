library(dplyr)
library(stringr)
library(here)
data <- read.csv(here("processed_data", "merged_output.csv"))


#Checking unique values in each field

for (field in colnames(data)) {
  count <- length(unique(data[ ,field]))
  print(paste("Currently", count, "unique values in", field))
}



#Cross referencing with SOP and Cleaning
print(unique(data[ ,"mouse_life_stage"])) #Contains Typos which have to be cleaned

summary(data$pvalue) #max exceeds 1 (1.4998), not possible according to SOP

print(unique(data[ ,"mouse_strain"]))#Also contains typos, should only have 4:C57BL; B6J; C3H; 129SV

data%>%
  group_by(mouse_strain) %>%
  summarise(count=n(), .groups="drop") #Identifies typos result in decreased C57Bl and 129sv count)

typo_gene_symbol <-data%>% filter(!str_detect(gene_symbol,"^[A-Z][a-z0-9]+$")) %>%
  distinct(gene_symbol)
print(typo_gene_symbol) #Identified typos in gene symbol column


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
pvalue=if_else(pvalue <0 | pvalue >1, NA_real_, pvalue)
)#Set values which dont fit SOP to NA (266)    

#Verifying
summary(data_cleaned$pvalue)

print(unique(data_cleaned$mouse_life_stage))

data_cleaned%>%
  group_by(mouse_strain) %>%
  summarise(count=n(), .groups="drop")

data_cleaned %>% filter(!str_detect(gene_symbol,"^[A-Z][a-z0-9]+$")) %>%
  distinct(gene_symbol)
