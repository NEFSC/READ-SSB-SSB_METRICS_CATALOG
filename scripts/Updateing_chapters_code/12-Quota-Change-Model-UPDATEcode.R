# Automated File Update Script
# -------------------------------------------------------------
# Purpose: Overwrite target file with contents of source file

# Define file paths
source_file <- "C:/Users/samantha.l.werner/Desktop/Github/READ-SSB-SSB_Metrics_Catalog_SOURCEDATA/READ-SSB-Quota_Change_Model/READ-SSB-Quota_Change_Model/Chapter_Template (for SSB metrics catalog).R"
target_file <- "C:/Users/samantha.l.werner/Desktop/Github/READ-SSB-SSB_METRICS_CATALOG/12-Quota-change-model.Rmd"

update_script <- function(src, tgt) {
  # 1. Verify source file exists
  if (!file.exists(src)) {
    stop(paste("Error: Source file does not exist at:", src))
  }

  # 2. Check if target directory exists; create it if missing
  target_dir <- dirname(tgt)
  if (!dir.exists(target_dir)) {
    dir.create(target_dir, recursive = TRUE)
    message(paste("Created missing directory:", target_dir))
  }

  # 3. Perform file overwrite
  success <- file.copy(from = src, to = tgt, overwrite = TRUE)

  if (success) {
    message("File successfully updated!")
    message(paste("Updated target:", tgt))
  } else {
    warning("File update failed. Check file permissions or access paths.")
  }
}

# Run the update
update_script(source_file, target_file)
