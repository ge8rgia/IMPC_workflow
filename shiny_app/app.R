#Main app file to load libraries, and define values
##Set up, if these libraries are not present, run install.packages to which they belong
library(shiny)
libary(ggplot2)
library(dplyr)

data_rshiny <- read.csv("~/Desktop/DBDM COURSEWORK DATA/processed_data/cleaned_merged_output.csv", stringsAsFactors = FALSE)


##Further cleaning of p-value data to increase statistical output
data_rshiny <- data_rshiny %>% 
  filter(!is.na(pvalue)) %>% #Removes NA results within pvalue column
  mutate(
    log_p_value = log10(pvalue), #pvalue is -log10
    Significance_0.05 = (pvalue <= 0.05), #Implementing significant threshold to filter results
    FDR =p.adjust(pvalue, method = "BH"), #Applies BH procedure for False postive discovery rate to our current pvalues
    log_p_value =-log10(FDR) #Applies -log10 scale to DR-adjusted pvalues 
  )

##Creating the user interface within the app
ui <- fluidPage(
  titlepanel ("IMPC Phenotype Explorer"),
) tabsetPanel(
  id = "main tabs",
  tabPanel("Explore via Gene Knockout",
           sidebarLayout(
             sidebarPanel (width = 3,
                           selectInput("Genotype_select",
                                       "Select Genotype:",
                                       choices =NULL),
                           numericInput("Significance Threshold (pvalue):",
                                        value = 0.05,
                                        min = 0.0,
                                        max=1.0
                                        step =0.01),
                           )
           ),
           column(9,
                  box(width=12,))
             
           ))
)
