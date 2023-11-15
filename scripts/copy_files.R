library(readr)

# Function to copy matching files
copy_files <- function(csv_file, source_dir, destination_dir, file_type) {
  # Create the destination directory if it doesn't exist
  if (!file.exists(destination_dir)) {
    dir.create(destination_dir, recursive = TRUE)
  }
  
  # Read the CSV file
  csv_data <- read_csv(csv_file)
  
  # Iterate through the names and copy matching files
  for (name in csv_data$name) {
    filename <- paste0(name, ".", file_type)
    source_file_path <- file.path(source_dir, filename)
    
    if (file.exists(source_file_path)) {
      destination_file_path <- file.path(destination_dir, filename)
      file.copy(source_file_path, destination_file_path)
      cat("Copied:", source_file_path, "to", destination_file_path, "\n")
    } else {
      cat("File not found:", source_file_path, "\n")
    }
  }
}

# Function to copy matching files into subfolders
copy_files_in_subfolders <- function(csv_file, source_dir, destination_dir, file_type) {
  # Create the destination directory if it doesn't exist
  if (!file.exists(destination_dir)) {
    dir.create(destination_dir, recursive = TRUE)
  }
  
  # Read the CSV file
  csv_data <- read_csv(csv_file)
  
  # Iterate through the rows of the CSV data
  for (i in 1:nrow(csv_data)) {
    genus <- csv_data[i, "genus"]
    species <- csv_data[i, "species"]
    name <- csv_data[i, "name"]
    
    # Create a subfolder based on genus and species
    subfolder_name <- paste(genus, species, sep = "_")
    subfolder_path <- file.path(destination_dir, as.character(subfolder_name))
    
    if (!file.exists(subfolder_path)) {
      dir.create(subfolder_path, recursive = TRUE)
    }
    
    # Use the specified file_type argument
    filename <- paste0(name, ".", file_type)
    source_file_path <- file.path(source_dir, as.character(filename))
    
    if (file.exists(source_file_path)) {
      destination_file_path <- file.path(subfolder_path, as.character(filename))
      file.copy(source_file_path, destination_file_path)
      cat("Copied:", source_file_path, "to", destination_file_path, "\n")
    } else {
      cat("File not found:", source_file_path, "\n")
    }
  }
}
