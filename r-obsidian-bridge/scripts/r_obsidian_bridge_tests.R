`%||%` <- function(x, y) if (is.null(x)) y else x

file_arg <- grep("^--file=", commandArgs(FALSE), value = TRUE)
script_file <- if (length(file_arg)) sub("^--file=", "", file_arg[[1]]) else file.path(getwd(), "researchvault", "tools", "r_obsidian_bridge_tests.R")
script_path <- file.path(dirname(normalizePath(script_file, winslash = "/", mustWork = FALSE)), "r_obsidian_bridge.R")
source(script_path, encoding = "UTF-8")

assert_true <- function(condition, message) {
  if (!isTRUE(condition)) stop(message, call. = FALSE)
}

assert_contains <- function(text, pattern, message) {
  if (!grepl(pattern, text, fixed = TRUE)) stop(message, call. = FALSE)
}

temp_vault <- tempfile("obsidian-vault-")
dir.create(temp_vault)

result <- obsidian_capture(
  1 + 1,
  title = "Smoke Test",
  vault = temp_vault,
  folder = "R-output",
  note = "session.md"
)

assert_true(file.exists(result$path), "capture should create a markdown note")
note_text <- paste(readLines(result$path, encoding = "UTF-8", warn = FALSE), collapse = "\n")
assert_contains(note_text, "# Smoke Test", "note should include the title")
assert_contains(note_text, "```r\n1 + 1\n```", "note should include the R code block")
assert_contains(note_text, "[1] 2", "note should include printed output")
assert_contains(note_text, "tags:", "note should include metadata")

obsidian_capture(
  {
    x <- 3
    x * 4
  },
  title = "Append Test",
  vault = temp_vault,
  folder = "R-output",
  note = "session.md"
)

note_text <- paste(readLines(result$path, encoding = "UTF-8", warn = FALSE), collapse = "\n")
assert_contains(note_text, "# Smoke Test", "second capture should keep existing content")
assert_contains(note_text, "# Append Test", "second capture should append new content")
assert_contains(note_text, "[1] 12", "second capture should include new output")

recent <- obsidian_read_recent(vault = temp_vault, folder = "R-output", n = 1)
assert_true(nrow(recent) == 1, "read_recent should return one note")
assert_contains(recent$content[[1]], "Append Test", "read_recent should expose note content")

cat("All r_obsidian_bridge tests passed\n")
