library(dplyr)
library(stringr)

data <-read.csv("merged_output.csv")


#Checking unique values in each field

for (field in colnames(data)) {
  count <- length(unique(data[ ,field]))
  print(paste("Currently", count, "unique values in", field))
}



#Cross referencing with SOP and Cleaning
print(unique(data[ ,"mouse_life_stage"]))#Contains Typos which have to be cleaned
data <- data %>% mutate(mouse_life_stage=na_if(str_to_sentence(str_squish(mouse_life_stage)),"na"))


print(unique(data[ ,"mouse_strain"])) #Also contains typos, should only have 4:C57BL; B6J; C3H; 129SV
data %>%
  group_by(mouse_strain) %>%
  summarise(count=n(), .groups="drop") #Identifies typos result in decreased C57Bl and 129sv count)

data <-data%>%
  mutate(mouse_strain=case_when(str_detect(mouse_strain,"C5[0-9]BL")~ "C57BL",
                                str_detect(mouse_strain,"12[0-9]SV")~"129sv",)
  ) #Fixes Typos
                                
typo_gene_symbol <-data%>% filter(!str_detect(gene_symbol,"^[A-Z][a-z0-9]+$")) %>%
  distinct(gene_symbol)
print(typo_gene_symbol) #Identified typos in gene symbol column

data <- data %>%
  mutate(gene_symbol = str_to_title(gene_symbol))#Gene symbol convertted to SOP format.

data <- data%>%
  mutate(pvalue= as.numeric(pvalue))
summary(data$pvalue) #max exceeds 1 (1.4998), not possible according to SOP


data <- data %>%
  mutate(pvalue = if_else(pvalue < 0 | pvalue > 1, NA_real_, pvalue))
#Set values which dont fit SOP to NA (266)    
         