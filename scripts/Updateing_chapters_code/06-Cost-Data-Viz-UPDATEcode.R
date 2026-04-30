library(rvest)
library(stringr)
library(dplyr)
library(knitr)
library(tidyr)

# --- 1. SET LOCAL PATHS ---
base_path <- "C:/Users/samantha.l.werner/Desktop/Github/READ-SSB-SSB_Metrics_Catalog_SOURCEDATA/READ-SSB-COST-DATA/READ-SSB-COST-DATA/"
source_readme <- paste0(base_path, "README.md")
source_php    <- paste0(base_path, "app/Views/about.blade.php")
target_rmd    <- "06-Cost-Data-Visualization-Tool.Rmd"

# --- 2. EXTRACTION: README (Product Overview & Time Series) ---
readme_lines <- readLines(source_readme)
start_idx <- which(str_detect(readme_lines, "^## Cost Data"))
next_headers_rm <- which(str_detect(readme_lines, "^#+ "))
end_idx <- next_headers_rm[next_headers_rm > start_idx][1] - 1
if(is.na(end_idx)) end_idx <- length(readme_lines)

# Sync the Overview paragraph
new_overview_text <- readme_lines[(start_idx + 1):end_idx] %>%
  str_trim() %>% .[. != ""] %>% paste(collapse = "\n\n")

# Auto-calculate Time Series from text
extracted_years <- str_extract_all(new_overview_text, "\\b\\d{4}\\b") %>%
  unlist() %>% unique() %>% sort() %>% paste(collapse = ", ")
new_time_series_line <- paste0("* Time Series: (", extracted_years, ")")

# --- 3. DYNAMIC CALCULATION: R-Version of the PHP Date Logic ---
# Logic: If month is before July, rebase to CurrentYear - 2, otherwise - 1.
current_month <- as.numeric(format(Sys.Date(), "%m"))
current_year  <- as.numeric(format(Sys.Date(), "%Y"))
rebase_year   <- if(current_month < 7) current_year - 2 else current_year - 1

# --- 4. EXTRACTION: PHP (Metrics Table & Methodology Scraper) ---
php_html <- read_html(source_php)

# A. Table Extraction (Exploded but cleaned)
rows <- php_html %>% html_nodes("table tr") %>% .[-1]
exploded_data <- lapply(rows, function(row) {
  cells <- row %>% html_nodes("td")
  if(length(cells) < 3) return(NULL)
  data.frame(
    Category = cells[1] %>% html_text(trim = TRUE),
    Metric = cells[2] %>% html_nodes("li") %>% html_text(trim = TRUE) %>% {if(length(.)==0) cells[2] %>% html_text(trim = TRUE) else .},
    Description = cells[3] %>% html_text(trim = TRUE),
    stringsAsFactors = FALSE
  )
})
cost_table_final <- bind_rows(exploded_data) %>% mutate(across(everything(), ~ str_squish(.)))

# B. Build Hierarchical List (For ## List of Metrics)
nested_metric_list <- cost_table_final %>%
  group_by(Category) %>%
  summarize(m = paste0("  * ", Metric, collapse = "\n"), .groups = 'drop') %>%
  mutate(combined = paste0("* **", Category, "**\n", m)) %>%
  pull(combined) %>% paste(collapse = "\n")

# C. Build Grouped Table (For ## Metric Descriptions)
table_for_description <- cost_table_final %>%
  group_by(Category, Description) %>%
  summarize(Metric = paste(Metric, collapse = "<br>"), .groups = 'drop') %>%
  select(Category, Metric, Description) %>%
  kable(format = "markdown", col.names = c("Cost Category", "Sub-Components", "Description/Notes"))

# D. DYNAMIC SCRAPER: Anchored to "Gear Grouping" with PHP-to-Number conversion
h2_nodes <- php_html %>% html_nodes("h2")
h2_texts <- h2_nodes %>% html_text(trim = TRUE)
start_h2_idx <- which(str_detect(h2_texts, "Gear Grouping"))
if(length(start_h2_idx) == 0) start_h2_idx <- 1

php_sections_md <- ""
found_headers <- c()

for(i in start_h2_idx:length(h2_nodes)) {
  current_title <- h2_texts[i]

  paragraphs <- h2_nodes[i] %>%
    html_nodes(xpath = "following-sibling::p[preceding-sibling::h2[1]]") %>%
    .[sapply(., function(x) {
      prev_h2 <- x %>% html_nodes(xpath = "preceding-sibling::h2[1]") %>% html_text(trim = TRUE)
      return(prev_h2 == current_title)
    })] %>%
    html_text(trim = TRUE) %>% str_squish() %>% .[. != ""]

  # CONVERT PHP CODE TO R-CALCULATED NUMBER:
  # Finds the @php...{{ $rebaseYear }} string and replaces it with the year (e.g., 2024)
  paragraphs <- gsub("@php.*?@endphp\\s*\\{\\{\\s*\\$rebaseYear\\s*\\}\\}", rebase_year, paragraphs)

  # Remove repeating "annual cost" sentence to clean up prose
  paragraphs <- paragraphs[!str_detect(paragraphs, "annual cost for the year in which the data were collected")]

  if(length(paragraphs) > 0) {
    php_sections_md <- paste0(php_sections_md, "### ", current_title, "\n\n", paste(paragraphs, collapse = "\n\n"), "\n\n")
    found_headers <- c(found_headers, current_title)
  }
}

# --- 5. RECONSTRUCTION: THE ORDERED BUILD ---
target_lines <- readLines(target_rmd)

# Find the fixed top (Overview) and bottom (Data Sources) anchors
top_end_idx <- which(str_detect(target_lines, "## List of Metrics"))[1] - 1
bottom_start_idx <- which(str_detect(target_lines, "## Data Sources"))[1]

# Fallbacks if target file is structurally different
if(is.na(top_end_idx)) top_end_idx <- which(str_detect(target_lines, "## Metric Descriptions"))[1] - 1
if(is.na(bottom_start_idx)) bottom_start_idx <- length(target_lines)

top_content <- target_lines[1:top_end_idx]
bottom_content <- target_lines[bottom_start_idx:length(target_lines)]

# Update Product Overview and Time Series line in the Top Content
ov_idx <- which(str_detect(top_content, "## Product Overview"))
ts_idx <- which(str_detect(top_content, "^\\* Time Series:"))
if(length(ts_idx) > 0) top_content[ts_idx] <- new_time_series_line

# Replace existing overview paragraph text
bullets_start <- which(str_detect(top_content, "^\\*"))[which(str_detect(top_content, "^\\*")) > ov_idx][1]
top_content[ov_idx:(bullets_start-1)] <- c("## Product Overview", "\n", new_overview_text, "\n")

# Assemble the dynamic middle in strict requested order
middle_content <- c(
  "## List of Metrics", "\n", nested_metric_list, "\n",
  "## Metric Descriptions", "\n", table_for_description, "\n",
  "## Additional Methods/Decision Rules", "\n",
  "### Summary Group Decision Rules", "\n",
  "The primary gear for each vessel is determined by the gear type which yielded the highest revenues from catch sold to a federal dealer in the year in which costs were being investigated. Though each vessel is grouped into a primary gear type, vessel costs are not apportioned to the gear usage, such that the summaries reflect a vessel's total costs for each year.", "\n",
  php_sections_md,
  "All data are presented as an annual cost for the year in which the data were collected.", "\n"
)

# Merge all parts
final_output <- c(top_content, middle_content, bottom_content)

# --- 6. SAVE & REPORT ---
writeLines(final_output, target_rmd)

cat("\n--- MASTER SYNC COMPLETE ---\n")
cat("Target File: ", target_rmd, "\n")
cat("Calculated Rebase Year: ", rebase_year, "\n")
cat("Found Methodology Sections:\n")
cat(paste("-", found_headers, collapse = "\n"), "\n")
cat("----------------------------\n")
