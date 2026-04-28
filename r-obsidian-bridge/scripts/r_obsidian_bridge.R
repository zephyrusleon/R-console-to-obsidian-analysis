default_obsidian_vault <- "C:/Users/47223/Desktop/要读的文献/researchvault"

`%||%` <- function(x, y) if (is.null(x) || length(x) == 0 || identical(x, "")) y else x

obsidian_sanitize_filename <- function(x) {
  x <- trimws(as.character(x %||% "R output"))
  x <- gsub("[<>:\"/\\\\|?*\r\n\t]+", "-", x)
  x <- gsub("\\s+", " ", x)
  x <- gsub("^[. ]+|[. ]+$", "", x)
  if (!nzchar(x)) x <- "R output"
  x
}

obsidian_note_path <- function(title = NULL,
                               vault = getOption("obsidian.vault", default_obsidian_vault),
                               folder = getOption("obsidian.folder", "R输出"),
                               note = NULL) {
  vault <- normalizePath(vault, winslash = "/", mustWork = FALSE)
  if (!dir.exists(vault)) stop("Obsidian vault does not exist: ", vault, call. = FALSE)

  target_dir <- file.path(vault, folder)
  if (!dir.exists(target_dir)) dir.create(target_dir, recursive = TRUE, showWarnings = FALSE)

  filename <- note %||% paste0(format(Sys.time(), "%Y-%m-%d"), " - ", obsidian_sanitize_filename(title), ".md")
  if (!grepl("\\.md$", filename, ignore.case = TRUE)) filename <- paste0(filename, ".md")
  file.path(target_dir, filename)
}

obsidian_write_entry <- function(title,
                                 code = NULL,
                                 output = NULL,
                                 text = NULL,
                                 vault = getOption("obsidian.vault", default_obsidian_vault),
                                 folder = getOption("obsidian.folder", "R输出"),
                                 note = NULL,
                                 tags = c("r-output"),
                                 append = TRUE) {
  path <- obsidian_note_path(title = title, vault = vault, folder = folder, note = note)
  new_file <- !file.exists(path) || !append
  timestamp <- format(Sys.time(), "%Y-%m-%d %H:%M:%S %z")

  lines <- character()
  if (new_file) {
    tag_text <- paste(tags, collapse = ", ")
    lines <- c(
      "---",
      paste0("created: ", timestamp),
      "source: RStudio/Positron",
      paste0("tags: [", tag_text, "]"),
      "---",
      ""
    )
  } else {
    lines <- c(lines, "")
  }

  lines <- c(lines, paste0("# ", title), "", paste0("Captured: ", timestamp), "")

  if (!is.null(code)) {
    lines <- c(lines, "## Code", "```r", code, "```", "")
  }

  if (!is.null(output)) {
    if (!length(output)) output <- "(no printed output)"
    lines <- c(lines, "## Output", "```", output, "```", "")
  }

  if (!is.null(text)) {
    lines <- c(lines, "## Notes", text, "")
  }

  con <- file(path, open = if (new_file) "w" else "a", encoding = "UTF-8")
  on.exit(close(con), add = TRUE)
  writeLines(lines, con = con, useBytes = TRUE)

  normalizePath(path, winslash = "/", mustWork = TRUE)
}

obsidian_capture <- function(expr,
                             title = NULL,
                             vault = getOption("obsidian.vault", default_obsidian_vault),
                             folder = getOption("obsidian.folder", "R输出"),
                             note = NULL,
                             tags = c("r-output"),
                             append = TRUE) {
  expr_sub <- substitute(expr)
  code <- paste(deparse(expr_sub, width.cutoff = 80), collapse = "\n")
  title <- title %||% code[[1]]
  state <- new.env(parent = emptyenv())
  state$value <- NULL
  state$visible <- FALSE

  output <- capture.output({
    result <- withVisible(eval.parent(expr_sub))
    state$value <- result$value
    state$visible <- result$visible
    if (isTRUE(state$visible) && !is.null(state$value)) print(state$value)
  })

  path <- obsidian_write_entry(
    title = title,
    code = code,
    output = output,
    vault = vault,
    folder = folder,
    note = note,
    tags = tags,
    append = append
  )

  invisible(list(path = path, output = output, value = state$value))
}

obsidian_append_text <- function(title,
                                 text,
                                 code = NULL,
                                 vault = getOption("obsidian.vault", default_obsidian_vault),
                                 folder = getOption("obsidian.folder", "R输出"),
                                 note = NULL,
                                 tags = c("r-output"),
                                 append = TRUE) {
  path <- obsidian_write_entry(
    title = title,
    code = code,
    text = text,
    vault = vault,
    folder = folder,
    note = note,
    tags = tags,
    append = append
  )
  invisible(list(path = path))
}

obsidian_read_recent <- function(vault = getOption("obsidian.vault", default_obsidian_vault),
                                 folder = getOption("obsidian.folder", "R输出"),
                                 n = 5) {
  target_dir <- file.path(normalizePath(vault, winslash = "/", mustWork = FALSE), folder)
  if (!dir.exists(target_dir)) {
    return(data.frame(path = character(), name = character(), modified = as.POSIXct(character()), content = I(list())))
  }

  files <- list.files(target_dir, pattern = "\\.md$", full.names = TRUE)
  if (!length(files)) {
    return(data.frame(path = character(), name = character(), modified = as.POSIXct(character()), content = I(list())))
  }

  info <- file.info(files)
  files <- files[order(info$mtime, decreasing = TRUE)]
  files <- head(files, n)
  info <- file.info(files)
  contents <- lapply(files, function(path) paste(readLines(path, encoding = "UTF-8", warn = FALSE), collapse = "\n"))

  data.frame(
    path = normalizePath(files, winslash = "/", mustWork = TRUE),
    name = basename(files),
    modified = info$mtime,
    content = I(contents),
    row.names = NULL
  )
}

message("R Obsidian bridge loaded. Use obsidian_capture({...}, title = '...') to save output.")
