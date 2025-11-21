#
# This is a Shiny web application. You can run the application by clicking
# the 'Run App' button above.
#
# Find out more about building applications with Shiny here:
#
#    https://shiny.posit.co/
#

library(shiny)
library(DT)
library(dplyr)

rshinydata <- read.csv("~/Desktop/Group3/processed_data/cleaned_merged_data.csv", stringsAsFactors = FALSE)
gene_list <- unique(rshinydata$gene_symbol)
gene_list

##need to just get the pvalues that are significant --> toggle
#Manhattan plot below 

# Define UI for application that user can select a particular knockout mouse and visualize the statistical scores of all phenotypes tested
ui <- fluidPage(

  #Application title
    titlePanel("Phenotype Scores for Selected Knockout Mouse"),
    sidebarLayout(
        sidebarPanel(
            selectInput("selected_gene", "Select a knockout gene:", choices = gene_list), #dropdown list of genes 
            checkboxInput("sig_only", 
                          "Show only significant results (p < 0.05)",
                          FALSE)
        ),
      
        #show table with p values
        mainPanel(
          dataTableOutput("pvalue_table")
        )
      )
    )

# Define server logic required to draw a histogram
server <- function(input, output, session){
  filtered_data <- reactive({
    req(input$selected_gene)
    
    df <- rshinydata %>%
      filter(gene_symbol == input$selected_gene) %>% #starting with input gene
      select(parameter_name, pvalue) %>% #selecting parameter name and pvalue to be in table
      arrange(parameter_name) #alphabetically sorts parameters
    
    #significance filter if toggle selected
    if (input$sig_only) {
     df <- df %>% filter(pvalue < 0.05)
    }
    df
  })
  
  output$pvalue_table <- renderDataTable({ #matched sever function
    filtered_data()
   
  })
  
}

# Run the application 
shinyApp(ui = ui, server = server)
