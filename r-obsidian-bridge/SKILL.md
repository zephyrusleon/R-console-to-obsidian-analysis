---
name: r-obsidian-bridge
description: Use when RStudio, Positron, R console output, Rscript results, model summaries, tables, statistical results, or analysis notes need to be saved into an Obsidian vault or read back from Obsidian markdown files.
---

# R Obsidian Bridge

## Overview

Use this skill to connect R work with an Obsidian vault through plain markdown notes. The local bridge script captures R code and printed output, writes it into the vault, and keeps the notes readable by both Obsidian and Codex.

## Quick Start

For this workspace, the vault is:

`C:/Users/47223/Desktop/要读的文献/researchvault`

In RStudio or Positron, run:

```r
source("C:/Users/47223/Desktop/要读的文献/researchvault/tools/r_obsidian_bridge.R", encoding = "UTF-8")

obsidian_capture(
  summary(lm(mpg ~ wt, data = mtcars)),
  title = "mtcars regression",
  note = "R session.md"
)
```

The note is written under `R输出/` in the vault. Obsidian sees it automatically because it is a normal markdown file.

## Workflow

1. Locate the vault. Prefer the current workspace vault if present: `researchvault/.obsidian`.
2. Source `tools/r_obsidian_bridge.R` in RStudio, Positron, or Rscript.
3. Use `obsidian_capture(expr, title = "...")` for live R expressions.
4. Use `obsidian_append_text(title, text, code = optional_code)` for already-copied console text or manual observations.
5. Verify the markdown file was created under `R输出/`.
6. To understand the user's R results later, read the relevant `.md` files from `R输出/` first, then inspect linked notes if needed.

## Available R Helpers

| Helper | Use |
|---|---|
| `obsidian_capture(expr, title, note = NULL)` | Run an R expression and save its code plus printed output. |
| `obsidian_append_text(title, text, code = NULL, note = NULL)` | Save manually supplied text, copied output, or comments. |
| `obsidian_read_recent(n = 5)` | Read recent captured notes from R for a quick check. |
| `options(obsidian.vault = "...")` | Override the target vault path. |
| `options(obsidian.folder = "...")` | Override the target folder, default `R输出`. |

## Reading Back Notes

When asked to read or understand captured R results:

- Search `researchvault/R输出/*.md` first.
- Read complete note files, not only headings, because the output is inside fenced blocks.
- Treat each note as a timestamped analysis record: title, captured time, code, output, and optional notes.
- If a note references papers or project notes elsewhere in the vault, follow those links only after reading the captured R note.

## Bundled Script

The skill includes `scripts/r_obsidian_bridge.R` as the portable bridge. If the vault copy is missing, copy this bundled script into the target vault's `tools/` folder and source it from R.

## Common Mistakes

- PowerShell aliases `r` to command history on this machine. Use RStudio/Positron, or call the full `Rscript.exe` path when testing from PowerShell.
- Do not paste console output into Obsidian manually when a reproducible R expression is available; capture the expression so the note includes both code and output.
- Do not write into `.obsidian/`; captured results belong in normal markdown folders.
- Do not assume Obsidian needs an import step. Creating or appending a `.md` file inside the vault is enough.
