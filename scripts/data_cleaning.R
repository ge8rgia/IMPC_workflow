library(dplyr)
library(stringr)
getwd()
setwd("~/Desktop/DBDM COURSEWORK DATA/processed_data/")

data <-read.csv("merged_output.csv")
for (field in colnames(data)) {
  count <- length(unique(data[ ,field]))
  print(paste("Currently", count, "unique values in", field))
}
