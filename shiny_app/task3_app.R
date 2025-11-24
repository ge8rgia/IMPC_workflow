library(shiny)
library(ggplot2)
library(dplyr)
library(DT) # For interactive tables
library(pheatmap) # For aesthetic heatmaps (Task 3)
library(factoextra) # For clustering evaluation (Optional but good practice)
library(RColorBrewer) # For color schemes
library(tidyr) # For data pivoting (Task 3)

theme_set(theme_minimal())

data <- read.csv("/Users/yzk/Desktop/DCDM/impc_export.csv", header = TRUE, stringsAsFactors = FALSE)
#First, deal with NULL values 
data$pvalue[data$pvalue == "NULL"] <- NA

data_rshiny <- data_rshiny %>% 
  mutate(
    pvalue = as.numeric (pvalue)) %>%
  filter(!is.na(pvalue)) %>% #Removes NA results within pvalue column   
  
  mutate(
    log_p_value = log10(pvalue), #pvalue is -log10
    significance_0.05 = (pvalue <= 0.05), #Implementing significant threshold to filter results
    FDR = p.adjust(pvalue, method = "BH"), #Applies BH procedure for False postive discovery rate to our current pvalues
    log_fdr = -log10(FDR) #Applies -log10 scale to DR-adjusted pvalues 
  )

# Define UI for application that draws a histogram
ui <- fluidPage(
  
  # Application title
  titlePanel("Visualize Gene Clusters"),
  
  sidebarLayout(
    sidebarPanel(
      width = 4, 
      h4("Clustering Parameters"),
      
      numericInput(
        inputId = "cluster_k",
        label = "1. Number of Clusters(k)",
        value = 4, 
        min = 2,
        max = 10, 
        step = 1
      ),
      actionButton("run_clustering", "Run K-means Clustering", class = "btn-success"), 
      hr(),
      textOutput("cluster_info")
      
    ),
    
    # Show a plot of the generated distribution
    mainPanel(
      h3("Clustering of Significant Genes Based on Phenotype Scores"),
      plotOutput("cluster_plot"),
      h4("Cluster Membership Table"),
      tableOutput("cluster_table")
    )
  )
)

# Define server logic required to draw a histogram
server <- function(input, output) {
  
  # 4.1 Data Preparation (Filtering and Pivoting to Wide Format)
  clustered_data_prep <- reactive({
    
    # 1. Filter: Keep only genes that are significant (FDR <= 0.05) across *at least one* phenotype
    sig_genes <- data_rshiny %>%
      filter(FDR <= 0.05) %>%
      pull(Gene_symbol) %>%
      unique()
    
    df_filtered <- data_rshiny %>%
      filter(Gene_symbol %in% sig_genes)
    
    # Check if there are any significant genes
    if (nrow(df_filtered) == 0) {
      return(list(matrix = matrix(0, 0, 0), n_genes = 0))
    }
    
    # 2. Pivot: Reshape to wide format (Gene_symbol as rows, parameter_name as columns)
    wide_data <- df_filtered %>%
      select(Gene_ID = Gene_symbol, parameter_name, log_fdr) %>%
      pivot_wider(
        names_from = parameter_name,
        values_from = log_fdr,
        values_fill = 0, 
        values_fn = max 
      ) %>%
      # Set Gene_ID as row names for clustering matrix
      column_to_rownames(var = "Gene_ID")
    
    # 3. Convert to matrix and scale (z-score scaling is essential for clustering)
    matrix_scaled <- wide_data %>%
      select(where(is.numeric)) %>% # FIX: Ensure ONLY numeric columns are selected before conversion
      as.matrix() %>%
      scale()
    
    # Return both the scaled matrix and the number of genes used
    list(
      matrix = matrix_scaled,
      n_genes = nrow(wide_data)
    )
  })
  
  #K-means Clustering (Event Reactive, triggered by button)
  kmeans_result <- eventReactive(input$run_clustering, {
    
    # Get the prepared matrix
    prep_data <- clustered_data_prep()
    req(prep_data$n_genes > 1) # Require at least 2 genes to cluster
    
    # Ensure K is within the valid range
    k <- min(input$cluster_k, prep_data$n_genes - 1)
    
    # Show a progress message
    showNotification(paste("Running K-means clustering with K =", k), duration = 3)
    
    # Perform K-means clustering (set.seed ensures reproducibility)
    set.seed(123) 
    kmeans(prep_data$matrix, centers = k, nstart = 25)
  })
  
  output$cluster_info <- renderText({
    n_genes <- clustered_data_prep()$n_genes
    if (n_genes == 0) {
      return("No genes met the significance threshold (FDR < 0.05) for clustering.")
    }
    paste("Data ready:", n_genes, "significant genes prepared for clustering.")
  })
  
  output$cluster_plot <- renderPlot({
    
    # Ensure clustering has run
    km_res <- kmeans_result()
    matrix_scaled <- clustered_data_prep()$matrix
    
    # Check for minimal data
    if (nrow(matrix_scaled) < 2) {
      return(NULL) # Don't plot if data is insufficient
    }
    
    # Prepare row annotations (the cluster assignment)
    annotation_row <- data.frame(Cluster = factor(km_res$cluster))
    rownames(annotation_row) <- rownames(matrix_scaled)
    
    # Get colors for consistency
    k_val <- length(unique(km_res$cluster))
    cluster_colors <- RColorBrewer::brewer.pal(n = max(3, k_val), name = "Set1")[1:k_val]
    names(cluster_colors) <- unique(sort(km_res$cluster))
    annotation_colors <- list(Cluster = cluster_colors)
    
    #Heatmap 
    pheatmap::pheatmap(matrix_scaled,
                       color = colorRampPalette(rev(RColorBrewer::brewer.pal(n = 7, name = "RdYlBu")))(100),
                       scale = "none", # Data is already scaled
                       cluster_rows = TRUE, 
                       clustering_method = "ward.D2",
                       cluster_cols = FALSE,
                       show_rownames = FALSE,
                       annotation_row = annotation_row,
                       annotation_colors = annotation_colors,
                       main = paste("Heatmap of -log10(FDR) Scores (K =", k_val, ")"),
                       fontsize = 8,
                       legend_breaks = c(min(matrix_scaled), 0, max(matrix_scaled)),
                       legend_labels = c("Low Z-Score", "Mean Z-Score", "High Z-Score")
    )
  })
  
  output$cluster_table <- renderTable({
    
    # Ensure clustering has run
    km_res <- kmeans_result()
    
    # Create a table showing Gene ID, Cluster, and the mean scores for the cluster
    clustered_data <- data.frame(
      Gene_symbol = rownames(clustered_data_prep()$matrix),
      Cluster = factor(km_res$cluster),
      clustered_data_prep()$matrix 
    )
    
    # Summarize mean scores per cluster
    cluster_summary <- clustered_data %>%
      group_by(Cluster) %>%
      summarise(across(where(is.numeric), ~ round(mean(.x, na.rm = TRUE), 3)),
                Count = n())
    
    return(cluster_summary)
  })
  
}

shinyApp(ui = ui, server = server)