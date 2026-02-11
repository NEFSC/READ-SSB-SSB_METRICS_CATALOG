# 1. Load necessary libraries
library(googledrive)
library(rmarkdown)

# 2. Authenticate (This will open a browser window the first time)
drive_auth()

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



##is this safe to use?
## used in alaska https://www.youtube.com/watch?v=4Lo3peWvHbE&t=1s

#additional context: 1. The "Scope" of the Authorization
#When you run drive_auth(), the browser window will ask you to grant the tidyverse/googledrive app permission to "See, edit, create, and delete all of your Google Drive files."

#The App Level: The R package is granted broad permission so that it can perform any command you type (like drive_find or drive_mkdir).

#2. Broad Access vs. Targeted Action
#Think of the R package like a Master Key.

#The Authorization (drive_auth): You are handing the R session the master key to your NOAA Google Drive.

#The Action (drive_download): The script only uses that key to open the one specific door (the URL/ID) you pointed to.

#[!IMPORTANT] Privacy Note: The R session "sees" what you see. It will not give your collaborators access to your whole drive; it only gives the code running on your machine the ability to interact with your files. If you share your code with a colleague, they would have to run drive_auth() themselves and would only be able to download the file if they also have permission to view that Google Doc.
