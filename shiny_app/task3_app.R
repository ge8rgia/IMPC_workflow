library(shiny)
library(ggplot2)
library(dplyr)
library(DT)
library(plotly) #install if missing 
#install.packages("plotly")
library(readr)

data_rshiny <- read.csv("/Users/yzk/Desktop/DCDM/impc_export.csv", header = TRUE,
                                stringsAsFactors = FALSE) #to prevent character vectors (text data) from being automatically converted into factors

num_genes <- nrow(data_rshiny)


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

#Task3-visualise clusters of genes with similar phenotype scores 
# Define UI for application that draws a histogram
ui <- fluidPage(

    # Application title
    titlePanel("Old Faithful Geyser Data"),

    # Sidebar with a slider input for number of bins 
    sidebarLayout(
        sidebarPanel(
            sliderInput("bins",
                        "Number of bins:",
                        min = 1,
                        max = 50,
                        value = 30)
        ),

        # Show a plot of the generated distribution
        mainPanel(
           plotOutput("distPlot")
        )
    )
)

# Define server logic required to draw a histogram
server <- function(input, output) {

    output$distPlot <- renderPlot({
        # generate bins based on input$bins from ui.R
        x    <- faithful[, 2]
        bins <- seq(min(x), max(x), length.out = input$bins + 1)

        # draw the histogram with the specified number of bins
        hist(x, breaks = bins, col = 'darkgray', border = 'white',
             xlab = 'Waiting time to next eruption (in mins)',
             main = 'Histogram of waiting times')
    })
}

# Run the application 
shinyApp(ui = ui, server = server)
