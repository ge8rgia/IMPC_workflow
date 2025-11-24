#
# This is a Shiny web application. You can run the application by clicking
# the 'Run App' button above.
#

# Install packages if required
# Using install.packages("shiny")
# Using install.packages("DT")
# Using install.packages("dplyr")
# Using install.packages("ggplot2")
# Using install.packages("ComplexHeatmap")
# Using install.packages("tidyr")
# Using install.packages("clustree")

# Load libraries 
library(shiny)
library(DT)
library(dplyr)
library(ggplot2)
library(ComplexHeatmap)
library(tidyr)
library(clustree)

# Load merged and cleaned data
rshinydata <- read.csv("/Users/georgiagoddard/Desktop/DCDM_CW/final_data/impc_export.csv", stringsAsFactors = FALSE)
# Fix p-values
rshinydata$pvalue[rshinydata$pvalue == "NULL"] <- NA
rshinydata$pvalue <- as.numeric(rshinydata$pvalue)
# Calculating FDR (BH Procedure) for p-values
rshinydata <- rshinydata %>%
  mutate(fdr=p.adjust(pvalue, method = "BH"))

# Make lists
parameter_groups <- sort(unique(rshinydata$parameter_group))
parameter_names <- sort(unique(rshinydata$parameter_name))
gene_list <- sort(unique(rshinydata$Gene_symbol))

# UI --------------------------------------------------------------------------
ui <- fluidPage(
  titlePanel("IMPC Phenotype Explorer Dashboard"),
  
  tabsetPanel(
    # Tab 1 => Task 1 => Explore via Gene Knockout
    tabPanel("Explore via Gene Knockout",
             sidebarLayout(
               sidebarPanel(
                 selectInput("selected_gene", "Select a knockout gene:", choices = gene_list),
                 #checkboxInput("sig_only_gene", "Show only significant results (p < 0.05)", FALSE)
                 numericInput("pval_thresh_gene", "Filter by p-value threshold:", value = 0.05, min = 0, max = 15, step = 0.001),
                 checkboxInput("sig_only_gene", "Apply p-value threshold", FALSE),
                 checkboxInput("fdr_only_gene", "Apply FDR-adjusted p-value threshold", FALSE),
                 helpText("Manhattan Plot: The dashed red line is constant and calculated using p-value = 0.05. It does not change based on the above selected p-value threshold input.")
                 ),
               mainPanel(
                 tabsetPanel(
                   tabPanel("Table", br(), DTOutput("gene_table")),
                   tabPanel("Manhattan Plot", br(), plotOutput("gene_manhattan", height = "600px"))
                 )
               )
             )
    ),
    
    # Tab 2 => Task 2 => Explore via Phenotype
    tabPanel("Explore via Phenotype",
             sidebarLayout(
               sidebarPanel(
                 selectInput("param_group_input", "Select a parameter group:", choices = c("no filter", parameter_groups), selected = "no filter"),
                 #checkboxInput("apply_gene_filter", "Apply gene filter", FALSE),
                 selectInput("param_name_input", "Select a phenotype:", choices = c("no filter", parameter_names), selected = "no filter"),
                 #checkboxInput("sig_only_T2", "Show only significant results (p < 0.05)", FALSE)
                 numericInput("pval_thresh_T2", "Filter by p-value threshold:", value = 0.05, min = 0, max = 15, step = 0.001),
                 checkboxInput("sig_only_T2", "Apply p-value threshold", FALSE),
                 checkboxInput("fdr_only_T2", "Apply FDR-adjusted p-value threshold", FALSE)
               ),
               mainPanel(
                 tabsetPanel(
                   tabPanel("Table", h4("Significant Genes"), DTOutput("task2_table_DT")),
                   tabPanel("Bar Plot", h4(textOutput("task2_title")), plotOutput("task2_plot")),
                   tabPanel("QQ Plot", h4("QQ Plot for Selected Phenotype Group"), plotOutput("task2_qq"))
                 )
               )
             )
    ),
    
    # Tab 3 => Task 3 => Visualize Gene Clusters
    tabPanel("Gene Clusters - Heatmap",
             sidebarLayout(
               sidebarPanel(
                 selectInput("selected_genes_cluster", "Filter genes:", choices = gene_list, selected = "no filter", multiple = TRUE),
                 checkboxInput("apply_gene_filter", "Apply gene filter", FALSE),
                 selectInput("selected_parameters_cluster", "Filter phenotypes:", choices = parameter_names, selected = "no filter", multiple = TRUE),
                 checkboxInput("apply_param_filter", "Apply phenotype filter", FALSE),
                 selectInput("param_group_cluster", "Filter by parameter group:", choices = c("no filter", parameter_groups), selected = "no filter"),
                 checkboxInput("apply_group_filter", "Apply parameter group filter", FALSE),
                 numericInput("top_n_genes", "Number of top variable genes:", value = 100, min = 5, max = 100),
                 checkboxInput("scale_rows", "Scale the data", TRUE),
                 hr(),
                 checkboxInput("use_fdr_cluster", "Cluster using FDR-adjusted values (instead of raw p-values)", FALSE)
               ),
               mainPanel(
                 plotOutput("cluster_heatmap", height = "800px")
               )
             )
    ),
    
    # Tab 4 => Task 4 => Visualize Gene Clusters
    tabPanel("Gene Clusters - K groups",
             sidebarLayout(
               sidebarPanel(
                 numericInput("k_clusters", "Number of clusters:", value = 5, min = 3, max = 20, step = 1),
                 numericInput("pval_thresh_cluster", "Filter by p-value threshold:", value = 0.05, min = 0, max = 15, step = 0.001),
                 checkboxInput("apply_pval_filter_cluster", "Apply p-value threshold", TRUE),
                 checkboxInput("use_fdr_cluster2", "Apply FDR-adjusted p-value threshold", FALSE),
                 helpText("Filtering the table for a cluster of choice can be done by typing in the cluster in the 'Search:' space above the table.")
               ),
               mainPanel(
                 tabsetPanel(
                   tabPanel("Gene cluster groups", br(), DTOutput("gene_cluster_table")),
                   tabPanel("Clustree", br(), plotOutput("k_cluster_tree", height = "800px"))
                 )
               )
             )
    )
    
  )
)

# SERVER --------------------------------------------------------------------------
server <- function(input, output, session) {

  ## Toggling between FDR and P-value

  ## Tab 1
  observeEvent(input$sig_only_gene, {
    if(input$sig_only_gene){
      updateCheckboxInput(session, "fdr_only_gene", value = FALSE)
    }
  })
  observeEvent(input$fdr_only_gene, {
    if(input$fdr_only_gene){
      updateCheckboxInput(session, "sig_only_gene", value = FALSE)
    }
  })
  
  ## Tab 2
  observeEvent(input$sig_only_T2, {
    if(input$sig_only_T2){
      updateCheckboxInput(session, "fdr_only_T2", value = FALSE)
    }
  })
  observeEvent(input$fdr_only_T2, {
    if(input$fdr_only_T2){
      updateCheckboxInput(session, "sig_only_T2", value = FALSE)
    }
  }) 
#Dropdown logic
  observeEvent(input$param_group_input, {
    
    if (input$param_group_input == "no filter") {
      updateSelectInput(session, "param_name_input",
                        choices = c("no filter", parameter_names),
                        selected = "no filter")  # If no group selected, show ALL parameter names
    } else {
      
      filtered_phenotypes <- rshinydata %>%
        filter(parameter_group == input$param_group_input) %>%
        pull(parameter_name) %>%
        unique() %>%
        sort() # If a group selected, filter the list of phenotypes so it will only show corresponding parameters
    
      updateSelectInput(session, "param_name_input",
                        choices = c("no filter", filtered_phenotypes),
                        selected = "no filter") # Update the phenotype dropdown 
    }
  })
  
  ## Tab 3
  observeEvent(input$apply_param_filter, {
    if(input$apply_param_filter) updateCheckboxInput(session, "apply_group_filter", value = FALSE)
  })
  observeEvent(input$apply_group_filter, {
    if(input$apply_group_filter) updateCheckboxInput(session, "apply_param_filter", value = FALSE)
  })
  
  ## Tab 4
  observeEvent(input$apply_pval_filter_cluster, {
    if(input$apply_pval_filter_cluster){
      updateCheckboxInput(session, "use_fdr_cluster2", value = FALSE)
    }
  })
  observeEvent(input$use_fdr_cluster2, {
    if(input$use_fdr_cluster2){
      updateCheckboxInput(session, "apply_pval_filter_cluster", value = FALSE)
    }
  })
  
  ## Tab 1 ------------------------------------------------------------------------
  gene_filtered <- reactive({
    req(input$selected_gene)
    
    df <- rshinydata %>%
      filter(Gene_symbol == input$selected_gene) %>%
      select(parameter_name, parameter_group, pvalue, fdr) %>% 
      arrange(parameter_name)
    
    if (input$sig_only_gene) {
      df <- df %>% filter(pvalue < input$pval_thresh_gene) #Pvalue filter
    }
    if (input$fdr_only_gene) {
      df <- df %>% filter(fdr < input$pval_thresh_gene) #FDR filter 
    }
    
    df
  })
  
  # Gene table visualization
  output$gene_table <- renderDT({
    datatable(
      gene_filtered(),
      options = list(pageLength = 10, autoWidth = TRUE),
      rownames = FALSE
    )
  })
  
  # Manhattan plot visualization
  output$gene_manhattan <- renderPlot({
    manhattan_plot_data <- gene_filtered()
    
    req(nrow(manhattan_plot_data) > 0)
    
    
    manhattan_plot_data$log_p <- -log10(manhattan_plot_data$pvalue)
    
    main_title <- paste("Phenotype Overview for", input$selected_gene) #Main title is blank till filter option selected 
    sub_text <-"" #Plot generated empty with no title 
    if(input$sig_only_gene){
      main_title <- paste("P-values (Significant) for", input$selected_gene)
      sub_text <- paste("Filtered by P-value <", input$pval_thresh_gene)
    } #Updates title if P-value selected 
    else if(input$fdr_only_gene){
      main_title <- paste("FDR-adjusted P-values (Significant) for", input$selected_gene)
      sub_text <- paste("Filtered by FDR <", input$pval_thresh_gene)
    } #Updates title if FDR option selected 
    
    ggplot(manhattan_plot_data, aes(x = reorder(parameter_name, log_p), y = log_p)) +
      geom_point(color = "darkblue") +
      geom_hline(yintercept = -log10(0.05),
                 color = "red", linetype = "dashed") +
      coord_flip() +
      labs(
        title = main_title,
        subtitle = sub_text,
        x = "Phenotype",
        y = "-log10(p-value)"
      ) +
      theme_minimal()
  })
  
  
  ## Tab 2 ------------------------------------------------------------------------
  
  task2_filtered <- reactive({
    
      df2 <- rshinydata %>%
        select(Gene_symbol, parameter_name, parameter_group, pvalue, fdr) %>%
        mutate(log_p = -log10(pvalue))
    
    # Filter parameter_group or parameter_name
    if (input$param_group_input != "no filter") {
      df2 <- df2 %>% filter(parameter_group == input$param_group_input)}
    if (input$param_name_input != "no filter") {
      df2 <- df2 %>% filter(parameter_name == input$param_name_input)}
    if (input$param_group_input == "no filter" &&
        input$param_name_input == "no filter") {
      df2 <- df2 %>% slice(0)
    }
    
    if (input$sig_only_T2) {
      df2 <- df2 %>% filter(pvalue < input$pval_thresh_T2) #P-value filter 
    }
      if (input$fdr_only_T2) {
        df2 <- df2 %>% filter(fdr < input$pval_thresh_T2) #FDR-value filter 
      }
    
    df2
  })
  
  output$task2_title <- renderText({
    filter_text <- "All Gene Knockouts"
    if (input$sig_only_T2) {
      filter_text <- paste0("Significant Knockouts (p < ", input$pval_thresh_T2, ")")   # Numeric threshold dynamic change for pvalue
    } else if (input$fdr_only_T2) {
      filter_text <- paste0("Significant Knockouts (FDR < ", input$pval_thresh_T2, ")") # Numeric threshold dynamic change for FDR
    }
      
    selected_text <- if (!is.null(input$param_group_input) && input$param_group_input != "no filter") {
      paste("in the", input$param_group_input, "Parameter Group")
    } else if (!is.null(input$param_name_input) && input$param_name_input != "no filter") {
      paste("for the parameter", input$param_name_input)
    } else {
      ""
    }
    
    paste(filter_text, selected_text)
  })
  
  # Gene table visualization
  output$task2_table_DT <- renderDT({
    df3 <- task2_filtered() %>% arrange(pvalue)
    datatable(df3,
              options = list(pageLength = 10, autoWidth = TRUE),
              rownames = FALSE)
  })
  
  # Bar plot visualization
  output$task2_plot <- renderPlot({
    df4 <- task2_filtered()
    
    if (nrow(df4) == 0) {
      return(
        ggplot() +
          annotate("text", x = 0.5, y = 0.5,
                   label = "No significant data found for the selected phenotype group.") +
          theme_void()
      )
    }
    
    grouped_genes <- df4 %>%
      group_by(Gene_symbol) %>%
      summarise(max_log_p = max(log_p, na.rm = TRUE)) %>%
      arrange(desc(max_log_p))
    
    ggplot(grouped_genes, aes(x = reorder(Gene_symbol, max_log_p), y = max_log_p)) +
      geom_bar(stat = "identity", fill = "#0072B2") +
      coord_flip() +
      labs(x = "Knockout Mouse Genotype",
           y = paste("Maximum -log10(p-value) in", input$param_group_input)
      ) +
      theme_minimal()
  })
  
  # QQ Plot visualization
  output$task2_qq <- renderPlot({
    df5 <- task2_filtered()
    
    if (nrow(df5) == 0) {
      return(
        ggplot() +
          annotate("text", x = 0.5, y = 0.5,
                   label = "No data available for QQ plot.") +
          theme_void()
      )
    }
    
    df5 <- df5 %>% filter(!is.na(pvalue), pvalue > 0)
    
    df5 <- df5 %>%
      mutate(observed = -log10(pvalue),
             expected = -log10(ppoints(n()))
      )
    
    ggplot(df5, aes(x = expected, y = observed)) +
      geom_point(color = "darkblue", size = 1.8) +
      geom_abline(intercept = 0, slope = 1,
                  color = "red", linetype = "dashed") +
      labs(title = paste("QQ Plot for", input$param_group_input),
           x = "Expected -log10(p)",
           y = "Observed -log10(p)"
      ) +
      theme_minimal()
  })
  
  ## Tab 3 ------------------------------------------------------------------------
  
  task3_filtered <- reactive({
  
    filter_choice <- if(input$use_fdr_cluster) "fdr" else "pvalue" #Selecting P or FDR values for clustering 
    
    df6 <- rshinydata %>%
      filter(!is.na(.data[[filter_choice]]), .data[[filter_choice]] > 0, is.finite(.data[[filter_choice]])) %>%
      mutate(plot_val = -log10(as.numeric(.data[[filter_choice]]))) %>%
      select(Gene_symbol, parameter_name, plot_val) %>%
      tidyr::pivot_wider(
      names_from = parameter_name,
      values_from = plot_val,
      values_fn = max,
      values_fill = 0
      )
    # Gene filter if used
    if (input$apply_gene_filter) {
      if (!("no filter" %in% input$selected_genes_cluster)) {
        df6 <- df6 %>% filter(Gene_symbol %in% input$selected_genes_cluster)
      }
    }
    
    # Generate wide matrix
    wide_data_matrix <- as.matrix(df6[, -1])
    rownames(wide_data_matrix) <- df6$Gene_symbol
    
    # Parameter group filter if used
    if (input$apply_group_filter && input$param_group_cluster != "no filter") {
      group_params <- rshinydata %>%
        filter(parameter_group == input$param_group_cluster) %>%
        pull(parameter_name) %>%
        unique()
      keep_cols <- intersect(colnames(wide_data_matrix), group_params)
      wide_data_matrix <- wide_data_matrix[, keep_cols, drop = FALSE]
    }
    
    #Specific parameter filter if used
    if (input$apply_param_filter) {
      if (!("no filter" %in% input$selected_parameters_cluster)) {
        cols_to_keep <- intersect(colnames(wide_data_matrix), input$selected_parameters_cluster)
        wide_data_matrix <- wide_data_matrix[ , cols_to_keep, drop = FALSE]
      }
    }
    
    # Select top N most variable genes
    if (!input$apply_gene_filter) {
      vars <- apply(wide_data_matrix, 1, var)
      n_genes <- min(input$top_n_genes, nrow(wide_data_matrix)) 
      if(n_genes > 0){
        top_idx <- order(vars, decreasing = TRUE)[1:n_genes]
        wide_data_matrix <- wide_data_matrix[top_idx, , drop = FALSE]
      }
    }
    
    if (input$scale_rows && nrow(wide_data_matrix) > 1) {
      wide_data_matrix <- t(scale(t(wide_data_matrix)))
    }
    
    wide_data_matrix
  })
  # Render the heatmap
  output$cluster_heatmap <- renderPlot({
    output_matrix <- task3_filtered()
    legend_name <- if(input$use_fdr_cluster) "-log10(FDR)" else "-log10(p)"
    
    if(nrow(output_matrix) < 2 || ncol(output_matrix) < 2) {
      plot(1, type="n", axes=FALSE, xlab="", ylab="")
      text(1, 1, "Not enough data to cluster.")
    } else {
    
    ComplexHeatmap::Heatmap(
      output_matrix,
      name = legend_name,
      clustering_method_rows = "ward.D2",
      clustering_method_columns = "ward.D2",
      show_row_names = TRUE,
      show_column_names = TRUE,
      row_names_gp = grid::gpar(fontsize = 6),
      column_names_gp = grid::gpar(fontsize = 8)
    )
    }
  })
  
  ## Tab 4 ------------------------------------------------------------------------
  
  # Reactive matrix for clustering
  task4_matrix <- reactive({
    
    metric_col2 <- if(input$use_fdr_cluster2) "fdr" else "pvalue" #Selecting P or FDR values for clustering 
    
    df7 <- rshinydata %>%
      filter(!is.na(.data[[metric_col2]]), .data[[metric_col2]] > 0, is.finite(.data[[metric_col2]])) %>%
      mutate(plot_val = -log10(as.numeric(.data[[metric_col2]]))) %>%
      select(Gene_symbol, parameter_name, plot_val) %>%
      tidyr::pivot_wider(
        names_from = parameter_name,
        values_from = plot_val,
        values_fn = max,
        values_fill = 0
      )
    
    if (input$apply_pval_filter_cluster) {
      keep_genes <- rshinydata %>% 
        filter(pvalue < input$pval_thresh_cluster) %>% pull(Gene_symbol)
      df7 <- df7 %>% filter(Gene_symbol %in% keep_genes)
    }
    if (input$use_fdr_cluster2) {
      keep_genes <- rshinydata %>% 
        filter(fdr < input$pval_thresh_cluster) %>% pull(Gene_symbol)
      df7 <- df7 %>% filter(Gene_symbol %in% keep_genes)
    }
    
    if (nrow(df7) == 0) {
      return(matrix(numeric(0), nrow = 0, ncol = 0))
    }
    
    # Generate wide matrix
    wide_data_matrix <- as.matrix(df7[, -1])
    rownames(wide_data_matrix) <- df7$Gene_symbol
    
    nzv <- apply(wide_data_matrix, 1, var) > 0
    wide_data_matrix <- wide_data_matrix[nzv, , drop = FALSE]
    
    if (nrow(wide_data_matrix) < 2) {
      return(matrix(numeric(0), nrow = 0, ncol = 0))
    }
    
    # Select top N most variable genes
    vars <- apply(wide_data_matrix, 1, var)
    n_genes <- min(input$top_n_genes, nrow(wide_data_matrix))
    
    if (n_genes > 1) {
      top_idx <- order(vars, decreasing = TRUE)[1:n_genes]
      wide_data_matrix <- wide_data_matrix[top_idx, , drop = FALSE]
    }
    
    if (input$scale_rows && nrow(wide_data_matrix) > 1) {
      wide_data_matrix <- t(scale(t(wide_data_matrix)))
    }
    
    wide_data_matrix
  })
  
  # Reactive table of clusters for Gene cluster groups
  task4_clusters <- reactive({
    mat <- task4_matrix()
    req(nrow(mat) > 1)
    
    # Hierarchical clustering
    dist_mat <- as.dist(1 - cor(t(mat)))
    hc <- hclust(dist_mat, method = "ward.D2")
    
    # Cut tree for selected number of clusters
    k <- input$k_clusters
    clusters <- cutree(hc, k = k)
    
    # Cluster assignment table
    cluster_table <- data.frame(
      Gene = rownames(mat),
      cluster = clusters,
      stringsAsFactors = FALSE
     ) %>%
      mutate(cluster = paste("Cluster", cluster))
    
    # Join with original data
    long_data <- rshinydata %>%
      filter(Gene_symbol %in% rownames(mat)) %>%
      select(Gene_symbol, parameter_name, parameter_group, pvalue, fdr)
    
    # Apply p-value filter if requested
    if (input$apply_pval_filter_cluster) {
      long_data <- long_data %>% filter(pvalue < input$pval_thresh_cluster) #P-value filter 
    }
    if (input$use_fdr_cluster2) {
      long_data <- long_data %>% filter(fdr < input$pval_thresh_cluster) #FDR-value filter 
    }
    
    # Merge clusters
    long_data <- long_data %>%
      left_join(cluster_table, by = c("Gene_symbol" = "Gene")) %>%
      rename(Gene = Gene_symbol) %>%
      arrange(cluster, Gene)
    
    long_data
  })
  
  # Render the Gene cluster groups table
  output$gene_cluster_table <- renderDT({
    datatable(task4_clusters(),
              options = list(pageLength = 10, autoWidth = TRUE, search = list(smart = FALSE)),
              rownames = FALSE)
  })
  
  # Render the Clustree
  output$k_cluster_tree <- renderPlot({
    mat <- task4_matrix()
    req(nrow(mat) > 1)
    
    # Hierarchical clustering
    dist_mat <- as.dist(1 - cor(t(mat)))
    hc <- hclust(dist_mat, method = "ward.D2")
    
    # Generate cluster assignments across a range of k
    max_k <- input$k_clusters
    ks <- 2:max_k
    
    cluster_df <- data.frame(Gene = rownames(mat))
    
    for (k in ks) {
      cluster_df[[paste0("k", k)]] <- cutree(hc, k = k)
    }
    
    clustree::clustree(
      cluster_df,
      prefix = "k"
    )
  })
  
}

# RUN APP ------------------------------------------------------------------------
shinyApp(ui = ui, server = server)
