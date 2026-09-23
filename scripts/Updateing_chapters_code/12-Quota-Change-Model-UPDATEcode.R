library(stringr)

# --- Define Paths ---
target_path <- "C:/Users/samantha.l.werner/Desktop/Github/READ-SSB-SSB_METRICS_CATALOG/08-RFA-Chapter.Rmd"
source_path <- "C:/Users/samantha.l.werner/Desktop/Github/READ-SSB-SSB_Metrics_Catalog_SOURCEDATA/READ-SSB-Lee-RFAdataset/READ-SSB-Lee-RFAdataset/documentation/output_documentation/output_data_description.md"

# --- Helper Functions ---
read_file_lines <- function(filepath) {
  if (!file.exists(filepath)) stop(paste("File not found:", filepath))
  readLines(filepath, warn = FALSE)
}

extract_section <- function(lines, header_pattern, next_header_pattern = "^#") {
  start_idx <- grep(header_pattern, lines, ignore.case = TRUE)
  if (length(start_idx) == 0) return(character(0))

  start <- start_idx[1] + 1
  remaining_lines <- lines[start:length(lines)]

  end_relative <- grep(next_header_pattern, remaining_lines)
  if (length(end_relative) > 0) {
    end <- start + end_relative[1] - 2
  } else {
    end <- length(lines)
  }

  return(trimws(lines[start:end]))
}

extract_tables <- function(lines) {
  table_lines <- grep("^\\s*\\|", lines)
  if (length(table_lines) == 0) return(list())

  splits <- cumsum(c(1, diff(table_lines) != 1))
  grouped_tables <- split(lines[table_lines], splits)
  return(grouped_tables)
}

# --- Main Synchronization Logic ---
sync_rfa_chapter <- function(target_file, source_file) {
  src_lines <- read_file_lines(source_file)
  tgt_lines <- read_file_lines(target_file)

  # 1. Source Data Extraction
  # --------------------------------------------------------------------------
  purpose_content <- extract_section(src_lines, "^#+\\s*Purpose", "^#")
  purpose_text <- paste(purpose_content[purpose_content != ""], collapse = " ")

  overview_lines <- extract_section(src_lines, "^#+\\s*Overview", "^#")
  overview_tables <- extract_tables(overview_lines)

  table2 <- if (length(overview_tables) >= 2) overview_tables[[2]] else character(0)

  indicators_list <- character(0)
  if (length(table2) > 2) {
    data_rows <- table2[3:length(table2)]
    col1_items <- sapply(strsplit(data_rows, "\\|"), function(x) {
      if (length(x) >= 2) trimws(x[2]) else ""
    })
    col1_items <- col1_items[col1_items != ""]
    indicators_list <- paste0("- ", col1_items)
  }

  storage_content <- extract_section(src_lines, "^#+\\s*Data Storage", "^#")

  overview_no_table2 <- overview_lines
  if (length(table2) > 0) {
    table2_indices <- match(table2, overview_lines)
    overview_no_table2 <- overview_lines[-table2_indices[!is.na(table2_indices)]]
  }

  warnings_content <- extract_section(src_lines, "^#+\\s*Warnings", "^#")

  # 2. Target File Replacement
  # --------------------------------------------------------------------------
  new_tgt <- tgt_lines

  replace_target_section <- function(lines, header_pattern, new_content) {
    h_idx <- grep(header_pattern, lines, ignore.case = TRUE)
    if (length(h_idx) == 0) return(lines)

    idx <- h_idx[1]
    header_level <- nchar(str_extract(lines[idx], "^#+"))
    next_h_pattern <- paste0("^#{1,", header_level, "}\\s")

    rem <- lines[(idx + 1):length(lines)]
    next_match <- grep(next_h_pattern, rem)

    end_idx <- if (length(next_match) > 0) idx + next_match[1] - 1 else length(lines)

    c(lines[1:idx], "", new_content, "", if (end_idx < length(lines)) lines[(end_idx + 1):length(lines)] else character(0))
  }

  # FIXED: Intro replacement without duplicating text
  rfa_head_idx <- grep("^#\\s*Regulatory Flexibility Act", new_tgt, ignore.case = TRUE)
  if (length(rfa_head_idx) > 0 && purpose_text != "") {
    line_after <- rfa_head_idx[1] + 1
    while (line_after <= length(new_tgt) && trimws(new_tgt[line_after]) == "") {
      line_after <- line_after + 1
    }
    if (line_after <= length(new_tgt)) {
      sentences <- unlist(strsplit(new_tgt[line_after], "(?<=\\.)\\s+", perl = TRUE))
      if (length(sentences) >= 1) {
        # Keep sentence 1, set sentence 2 to purpose_text, drop any leftover duplicated text
        first_sentence <- sentences[1]
        new_tgt[line_after] <- paste(first_sentence, purpose_text)
      }
    }
  }

  # Update sections
  if (length(indicators_list) > 0) {
    new_tgt <- replace_target_section(new_tgt, "^##\\s*list of metrics", indicators_list)
  }

  if (length(storage_content) > 0) {
    new_tgt <- replace_target_section(new_tgt, "^###\\s*Data Outputs/Outlets", storage_content)
  }

  if (length(table2) > 0) {
    new_tgt <- replace_target_section(new_tgt, "^#+\\s*(8\\.3\\s*)?Metric Descriptions", table2)
  }

  if (length(overview_no_table2) > 0) {
    new_tgt <- replace_target_section(new_tgt, "^###\\s*Data Overview", overview_no_table2)
  }

  if (length(warnings_content) > 0) {
    new_tgt <- replace_target_section(new_tgt, "^###\\s*Warnings", warnings_content)
  }

  # Save changes
  writeLines(new_tgt, target_file)
  message("Successfully updated '08-RFA-Chapter.Rmd' without text duplication!")
}

# Run script
sync_rfa_chapter(target_path, source_path)
