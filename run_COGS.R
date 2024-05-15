library(knitr)
library(data.table)
library(tidyverse)
library(filesstrings)

###### SET UP ######

# Setting up the working directory

syncfolder <- './'


###### PROCESSING ###### 

# Listing all the '_input.csv' files in the data_input folder and looping through the file list to run the fixing script

filelist <- list.files(file.path(syncfolder,"analysis_Anvio7"), pattern = '_gene_clusters_summary.txt.gz', full.names=FALSE)

for (file in filelist) {
  Species <- gsub("_gene_clusters_summary.txt.gz", "", file) #grep Species name from the file name
  Species <- gsub("PAN_", "", Species) #grep Species name from the file name
  print(paste("Processing file",Species))
  
  # Saving full paths for all needed input files
  fileDataPath <- paste(syncfolder,"analysis_Anvio7/", file, sep="")

  # Saving input files as objects
  Pangenome <- read.delim(fileDataPath)
  
  # Rendering 'SupplementalMethods_COGS.Rmd':
  rmarkdown::render(input = "SupplementalMethods_COGS.Rmd",
                    output_file = paste0("SupplementalMethods_COGS_", Species, ".html"),
                    params = list(folder = syncfolder))
  
}
