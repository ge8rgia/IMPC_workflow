#
# This is a Shiny web application. You can run the application by clicking
# the 'Run App' button above.
#
# Find out more about building applications with Shiny here:
#
#    https://shiny.posit.co/
#

#Show plots from RShiny to visualise the significant phenotypes associated with each of the 4 genotypes of interest
#Task2-visualise the statistical scores of ALL knock-out mice for the SELECTED phenotype 
#Task3-visualise clusters of genes with similar phenotype scores 

library(shiny)
library(ggplot2)
library(dplyr) #we need gene, phenotype, score
#Gene = the ones that corresponds to the selected phenotype 
#Phenotype = parameter name to be selected 
#Score = JUST the p values? double check

data <- read.csv("/Users/ahmedalshagga/Desktop/DBDM_COURSEWORK_DATA/processed_data/cleaned_merged_output.csv")
phenotype_list <- unique(data$parameter_name)
phenotype_list

# Define UI for application that produces a QQ-plot
ui <- fluidPage(
  
  # Application title
  titlePanel("Statistical scores for all knock-out mouse with selected phenotype"),
  
  # Sidebar with a drop-down list to select phenotype and check-box for significant data where p < 0.05
  sidebarLayout(
    sidebarPanel(
      #Select input drop down list   
      selectInput(
        inputId = "selected_phenotype", 
        label = "Select a phenotype:", 
        choices = unique(phenotype_list), 
        selected = unique(phenotype_list)[1]), #defaulted to the first phenotype 
    
      #Checkbox to also be able to view insignificant data, for more options 
      checkboxInput(inputId = "sig_only", 
                    label = "Show only significant results (p < 0.05)", 
                    value = TRUE) #default is changed to checked so the extra option is to display insignificant p-values 
      ),
    
    #Show plot with all p-values where parameter_name = the selected phenotype
    mainPanel(
      plotOutput("pvalue_plot"))
  )
)

# Define server logic required to draw a histogram
server <- function(input, output, session) {
  #Reactive expression to filter data with two filters 
  #Filter 1 to filter data where the parameter_name = the selected phenotype from the drop-down list
  filtered_data <- reactive({
    req(input$selected_phenotype)
    df <- data %>% filter(parameter_name == input$selected_phenotype)
    
    #Filter 2 to filter data further where if the check-box is checked then data is filtered to only display p-values that are < 0.05
    if (input$sig_only == TRUE) {
        df <- df %>% filter (pvalue < 0.05)
    }
    #Otherwise, return data unfiltered with filter 2 if check-box is unchecked
    return(df)
  })
  
  #Render the plot 
  output$pvalue_plot <- renderPlot({
    
    #Creating new row for p-values and -log10 the p-values for better visualisation
    plot_data <- filtered_data() %>%
      mutate(log_p = -log10(pvalue)) %>%
      filter(log_p != Inf)
    
    #Check for empty data before plotting
    if (nrow(plot_data) == 0) {
      return(ggplot() +
               annotate("text", x = 0.5, y = 0.5,
                        label = "No significant data found for the selected phenotype.") +
               theme_void())
    }
    
    n_p <- nrow(plot_data)
    plot_data$expected_log_p <- -log10(ppoints(n_p))
    
    #Calculate significant threshold line (-log10(0.05))
    sig_threshold <- -log10(0.5)
    
    #Visualising the QQ-plot using ggplot2
    ggplot(plot_data, aes(x = expected_log_p, y = log_p)) + 
      geom_point(colour = "darkblue", size = 1.5) + 
      #Added the dashed line for visualisation
      geom_abline(intercept = 0, slope = 1, colour = "red", linetype = "dashed") + 
      #Creating the dotted threshold line 
      geom_hline(yintercept = sig_threshold, linetype = "dotted", colour = "darkgreen") +
      
      
      labs(
        title = paste("P-values for the selected phenotype:", input$selected_phenotype),
        x = "Expected -log10(p-value)",
        y = "Observed -log10(p-value)"
      ) + 
      theme_minimal() + 
      theme(
        plot.title = element_text(hjust = 0.5)
      )
  })
}

# Run the application 
shinyApp(ui = ui, server = server)
