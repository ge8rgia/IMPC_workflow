#Main app file to load libraries, and define values
##Set up, if these libraries are not present, run install.packages to which they belong
library(shiny)
library(ggplot2)
library(dplyr)

data_rshiny <- read.csv("/Users/ahmedalshagga/Desktop/DBDM_COURSEWORK_DATA/processed_data/cleaned_merged_output.csv", 
                        stringsAsFactors = FALSE)


##Further cleaning of p-value data to increase statistical output
data_rshiny <- data_rshiny %>% 
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
    
    # --- TAB 1: EXPLORE VIA GENE KNOCKOUT (Task 1) ---
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
    
    # --- TAB 2: EXPLORE VIA PHENOTYPE (Task 2 - REVERTED) ---
    tabPanel("Explore via Phenotype",
             sidebarLayout(
               sidebarPanel(
                 width = 3,
                 h4("Select Phenotype for Mouse Comparison"),
                 selectInput(
                   inputId = "selected_phenotype", 
                   label = "1. Select a Phenotype (Parameter Name):", 
                   choices = NULL, 
                   selected = NULL 
                 ),
                 checkboxInput(inputId = "sig_only_T2", 
                               label = "2. Show only significant results (FDR < 0.05)", 
                               value = FALSE) 
               ),
               mainPanel(
                 h3(textOutput("phenotype_title")),
                 plotOutput("phenotype_scatter_plot") 
               )
             )
    ),
    
    # --- TAB 3: VISUALIZE GENE CLUSTERS (UI Skeleton) ---
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
                 
                 actionButton("run_clustering", "Run Clustering Analysis",
                              class = "btn-success"),
                 
                 hr(),
                 textOutput("cluster_info")
               ),
               mainPanel(
                 h3("Gene Clusters and Group Membership"),
                 
                 plotOutput("cluster_plot"), 
                 
                 h4("Cluster Membership Table"),
                 dataTableOutput("cluster_table") 
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
                      choices = sort(unique(data_rshiny$gene_symbol)))
    
    updateSelectInput(session,
                      "selected_phenotype",
                      choices = sort(unique(data_rshiny$parameter_name)))
    
  })
  
  filtered_genotype_data <- eventReactive(input$plot_genotype, {
    df <- data_rshiny %>%
      filter(gene_symbol == input$Genotype_select) %>%
      mutate(parameter_name = factor(parameter_name, levels = unique(parameter_name)))
    
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
    ggplot(plot_data, aes(x = parameter_name, y = log_fdr, 
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
  
  # Reactive expression to filter data based on Phenotype selection and significance checkbox
  filtered_phenotype_data <- reactive({
    req(input$selected_phenotype)
    
    # 1. Filter by selected Phenotype
    df <- data_rshiny %>% 
      filter(parameter_name == input$selected_phenotype) %>%
      # Ensure factor ordering for plotting
      mutate(gene_symbol = factor(gene_symbol, levels = unique(gene_symbol)))
    
    # 2. Filter by significance if the checkbox is checked (FDR < 0.05)
    if (input$sig_only_T2 == TRUE) {
      df <- df %>% filter(FDR < 0.05)
    }
    
    return(df)
  })
  
  # Render the plot title for Task 2
  output$phenotype_title <- renderText({
    paste("Statistical Scores for All Mice with Phenotype:", input$selected_phenotype)
  })
  
  # Render the plot for Task 2
  output$phenotype_scatter_plot <- renderPlot({
    plot_data <- filtered_phenotype_data()
    
    # Calculate the log threshold (FIXED BUG: using 0.05)
    log_sig_threshold <- -log10(0.05)
    
    # Check for empty data
    if (nrow(plot_data) == 0) {
      return(ggplot() + 
               annotate("text", x = 0.5, y = 0.5, 
                        label = "No significant data found for the selected phenotype.") +
               theme_void())
    }
    
    # Logic to create the **IMPROVED SCATTER PLOT** (Genotype vs -log10(FDR))
    # This plot clearly shows the "Mice" (Genotypes) that are significant.
    ggplot(plot_data, aes(x = gene_symbol, y = log_fdr, 
                          color = log_fdr > log_sig_threshold)) + 
      geom_point(alpha = 0.8, size = 3) +
      geom_hline(yintercept = log_sig_threshold, 
                 linetype = "dashed", color = "red", linewidth = 1) + 
      
      labs(title = NULL, # Title handled by renderText
           x = "Knockout Mouse Genotype",
           y = "-log10(FDR-Adjusted p-value)") +
      
      scale_color_manual(name = "FDR < 0.05",
                         values = c("gray50", "#D55E00"), # Insignificant, Significant
                         labels = c("Insignificant", "Significant")) +
      
      # Flip coordinates for better readability of many genotypes
      coord_flip() + 
      theme_minimal() +
      theme(plot.title = element_text(hjust = 0.5),
            axis.text.y = element_blank(), # Hide Genotype names on axis for clutter
            axis.ticks.y = element_blank())
  }, height = 700)
  
}



# Run the application 
shinyApp(ui = ui, server = server)



