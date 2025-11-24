#Main app file to load libraries, and define values
##Set up, if these libraries are not present, run install.packages to which they belong
library(shiny)
library(ggplot2)
library(dplyr)

data_rshiny <- read.csv("/Users/ahmedalshagga/Desktop/DBDM_COURSEWORK_DATA/processed_data/impc_export.csv", 
                        stringsAsFactors = FALSE)


##Further cleaning of p-value data to increase statistical output
data_rshiny <- data_rshiny %>% 
  mutate(
    pvalue = as.numeric (pvalue)) %>%
  filter(!is.na(pvalue)) %>% #Removes NA results within pvalue column   
  
  mutate(
    log_p_value = log10(pvalue), #pvalue is -log10
    Significance_0.05 = (pvalue <= 0.05), #Implementing significant threshold to filter results
    FDR = p.adjust(pvalue, method = "BH"), #Applies BH procedure for False postive discovery rate to our current pvalues
    log_fdr = -log10(FDR) #Applies -log10 scale to DR-adjusted pvalues 
  )

##Creating the user interface within the app
ui <- fluidPage(
  titlePanel("IMPC Phenotype Explorer Dashboard"),
  
  tabsetPanel(
    id = "main_tabs",
    
    #  Task 1
    tabPanel("Explore via Gene Knockout",
             sidebarLayout(
               sidebarPanel (
                 width = 3,
                 h4("Select Gene for Detailed View"),
                 selectInput("Genotype_select",
                             "1. Select Gene Symbol:", 
                             choices = NULL), 
                 numericInput("Significance_Threshold_T1",
                              "2. P-value Threshold (FDR):", 
                              value = 0.01, 
                              min = 0.0,
                              max = 1.0,
                              step = 0.001), 
                 actionButton("plot_genotype", "Generate Plot",
                              class = "btn-primary")
               ),
               mainPanel(
                 h3(textOutput("genotype_title")),
                 plotOutput("genotype_plot") 
               )
             )
    ),
    
    # TAB 2 
    tabPanel("Explore via Phenotype",
             sidebarLayout(
               sidebarPanel(
                 width = 3,
                 h4("Select Phenotype Group for Mouse Comparison"),
                 selectInput("param_group_input",
                             "1. Select Parameter Group:",
                             choices = NULL),
                 sliderInput("fdr_threshold_group", "2. Select FDR Threshold (Significant Genes):",
                             min = 0.001, max = 0.1, value = 0.05, step = 0.005),
                 checkboxInput(inputId = "sig_only_T2", 
                               label = "2. Show only significant results (FDR < 0.05)", 
                               value = FALSE) 
               ),
               mainPanel(
                 h3(textOutput("task2_title")),
                 plotOutput("task2_plot"), 
                 hr(),
                 h4("Significant Genes in Selected Group (FDR < 0.05)"),
                 tableOutput("task2_table")
               )
             )
    ),
    
    # Task 3 
    tabPanel("Visualize Gene Clusters",
             sidebarLayout(
               sidebarPanel(
                 width = 3,
                 h4("Clustering Parameters"),
                 
                 numericInput(
                   inputId = "cluster_k",
                   label = "1. Number of Clusters (K):",
                   value = 4, 
                   min = 2,
                   max = 10, 
                   step = 1
                 ),
                 
                 actionButton("run_clustering", "Run K-means Clustering",
                              class = "btn-success"),
                 
                 hr(),
                 textOutput("cluster_info")
               ),
               mainPanel(
                 h3("Clustering of Significant Genes Based on Phenotype Scores"),
                 
                 plotOutput("cluster_plot"), 
                 
                 h4("Cluster Membership Table"),
                 
                 tableOutput("cluster_table")
               )
             )
    )
  )
)

#########Server Logic
server <- function (input, output, session) {
  #Task 1    
  observe ({
    updateSelectInput(session,
                      "Genotype_select",
                      choices = sort(unique(data_rshiny$Gene_symbol)))
    
    updateSelectInput(session,
                      "param_group_input",
                      choices = sort(unique(data_rshiny$parameter_group)))
    
  })
  
  filtered_genotype_data <- eventReactive(input$plot_genotype, {
    df <- data_rshiny %>%
      filter(Gene_symbol == input$Genotype_select) %>%
      mutate(parameter_group = factor(parameter_group, levels = unique(parameter_group)))
    
    return(df)
  })
  #Task 1 Plot title generation
  output$genotype_title <- renderText({
    paste("Phenotype Scores for Gene Knockout", input$Genotype_select)
  })
  
  #Plot rendeering
  output$genotype_plot <- renderPlot({
    plot_data <- filtered_genotype_data()
    
    log_sig_threshold <- -log10(input$Significance_Threshold_T1)
    
    # Logic for a Manhattan-style plot (Phenotype vs -log10(FDR))
    ggplot(plot_data, aes(x = parameter_group, y = log_fdr, 
                          color = log_fdr > log_sig_threshold)) + 
      geom_point(alpha = 0.8, size = 2) +
      # Add the dynamically calculated significance line
      geom_hline(yintercept = log_sig_threshold, 
                 linetype = "dashed", color = "red", linewidth = 1) + 
      
      labs(title = NULL, # Title handled by renderText
           x = "Phenotype Parameter",
           y = "-log10(FDR-Adjusted p-value)") +
      
      scale_color_manual(name = paste0("FDR < ", input$Significance_Threshold_T1),
                         values = c("gray50", "#0072B2"), # Insignificant, Significant
                         labels = c("Insignificant", "Significant")) +
      
      # Flip coordinates for better readability of many phenotype names
      coord_flip() + 
      theme_minimal() +
      theme(plot.title = element_text(hjust = 0.5),
            # Reduce clutter by removing y-axis labels if there are too many
            axis.text.y = element_blank(), 
            axis.ticks.y = element_blank())
  }, height = 700)
  
  
  #Task 2 
  
observeEvent(input$sig_only_T2, {
    if(input$sig_only_T2) {
      updateSliderInput(session, "fdr_threshold_group", value = 0.05)
    }
  }) #Slider fix
  
  # Reactive expression to filter data based on parameter_group 
  data_task2_reactive <- reactive({
    
    # Ensures the function only runs when a parameter group is selected
    req(input$param_group_input)
    
   #Use the slider input directly as it updates with button
    current_threshold <- input$fdr_threshold_group
    
    # Filter the data for the selected group AND where the FDR is below the threshold
    data_rshiny %>%
      filter(parameter_group == input$param_group_input) %>%
      filter(FDR <= current_threshold) %>%
      # Select only relevant columns for plotting/table
      select(Gene_symbol, parameter_name, pvalue, FDR, log_fdr)
  })
  # Render the plot title for Task 2
  output$task2_title <- renderText({
    paste("Significant Gene Knockouts (FDR <", 
          if(input$sig_only_T2) 0.05 else input$fdr_threshold_group, 
          ") in the", 
          input$param_group_input, "Phenotype Group")
  })
  
  # Render the plot for Task 2
  output$task2_plot <- renderPlot({
    plot_data <- data_task2_reactive()
    
    # Check for empty data
    if (nrow(plot_data) == 0) {
      return(ggplot() + 
               annotate("text", x = 0.5, y = 0.5, 
                        label = "No significant data found for the selected phenotype.") +
               theme_void())
    }
    
    
    # Aggregate data to get the maximum log_fdr for each gene within the group
    agg_data <- plot_data %>%
      group_by(Gene_symbol) %>%
      summarise(max_log_fdr = max(log_fdr, na.rm = TRUE),
                n_phenotypes = n()) %>%
      ungroup() %>%
      arrange(desc(max_log_fdr)) # Order by most significant
    
    # Plotting the most significant result for each gene
    ggplot(agg_data, aes(x = reorder(Gene_symbol, max_log_fdr), y = max_log_fdr)) +
      geom_bar(stat = "identity", fill = "#0072B2") +
      coord_flip() +
      labs(title = NULL,
           x = "Knockout Mouse Genotype",
           y = paste("Maximum -log10(FDR) in", input$param_group_input)) +
      theme_minimal() +
      theme(axis.text.y = element_text(size = 10))
  })
  
  # Render the data table for Task 2
  output$task2_table <- renderTable({
    data <- data_task2_reactive() %>%
      arrange(FDR)
    
    # renderTable automatically handles the table
    return(data)
  }, 
  # Add an option to format the numbers ]
  digits = 5, 
  # Ensure the headers are displayed n]
  striped = TRUE,
  hover = TRUE
  )
}

# Run the application 
shinyApp(ui = ui, server = server)



