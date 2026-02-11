


# Create the 'chapters' folder if it doesn't exist
if (!dir.exists("chapters")) {
  dir.create("chapters")
}


#This bypasses the googledrive package and authentication entirely
doc_id <- "1qDZh8YXgLPjA6kaZxCOk8FwSFrzFJmzp6y2t_UCJQHc"
download_url <- paste0("https://docs.google.com/document/d/", doc_id, "/export?format=docx")

download.file(download_url, destfile = "chapters/performancemeasures_chapter.docx", mode = "wb")







# 1. Load necessary libraries
library(googledrive)
library(rmarkdown)

# 2. Authenticate (This will open a browser window the first time)
drive_auth()

# 1. Clear the old session
drive_deauth()

# 2. Authenticate with a very specific, limited scope
# This scope only allows R to see the files you tell it to
drive_auth(scopes = "https://www.googleapis.com/auth/drive.file")


# Try this specific way to find the file first
target_file <- drive_get(as_id(gdoc_link))

# Then download using the object we just found
drive_download(
  file = target_file,
  path = "chapters/performancemeasures_chapter.docx",
  overwrite = TRUE
)


# 3. Identify your Google Doc by URL or ID
# Example ID: '1u8yV6_...etc'
gdoc_link <- "https://docs.google.com/document/d/1qDZh8YXgLPjA6kaZxCOk8FwSFrzFJmzp6y2t_UCJQHc/edit?tab=t.0"

# 4. Download the Google Doc as a .docx file
# We use .docx because Pandoc handles the conversion to Markdown very cleanly
drive_download(
  file = as_id(gdoc_link),
  path = "chapters/performancemeasures_chapter.docx",
  overwrite = TRUE,
  type = "docx"
)

# 5. Convert the .docx to .Rmd (or .md) for Bookdown
pandoc_convert(
  input = "chapters/performancemeasures_chapter.docx",
  to = "markdown",
  output = "chapters/02-Performance-Measures.Rmd"
)
