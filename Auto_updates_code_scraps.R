# sync_sections.R

# 1. Configuration
source_url <- "https://raw.githubusercontent.com/NEFSC/READ-SSB-Lee-RFAdataset/main/documentation/output_documentation/output_data_description.md"
target_file <- "08-RFA-Chapter.Rmd"

# 2. Fetch fresh data from the other Repo
source_lines <- readLines(source_url)

# 3. Read your local Catalog file
target_lines <- readLines(target_file)

# 4. Find the "Anchor" positions in your Catalog
start_idx <- grep("", target_lines)
end_idx <- grep("", target_lines)

if (length(start_idx) > 0 && length(end_idx) > 0) {

  # Logic: Only update if the content has actually changed
  # (Optional: you could add a check here to compare source vs current)

  # Reconstruct the file:
  # Everything BEFORE the start tag + The START tag + NEW CONTENT + The END tag + Everything AFTER
  updated_content <- c(
    target_lines[1:start_idx],
    source_lines,
    target_lines[end_idx:length(target_lines)]
  )

  writeLines(updated_content, target_file)
  message("Section updated successfully!")
} else {
  stop("Markers not found in the target file!")
}
