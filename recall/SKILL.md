---
name: recall
description: >
  Save and search/recall content as structured markdown notes with auto-extracted
  metadata. Use when the user wants to save an article, book notes, quote,
  idea, or any content for later reference. Also use when the user wants to
  search, find, or recall previously saved notes. Handles text extraction,
  tagging, filing, and searching automatically.
metadata:
  author: github.com/surajssd
  version: "0.1"
allowed-tools: Bash Read Write Edit
---

# Recall — Save & Search Structured Notes

When the user wants to save content, follow these three steps. Do NOT ask for
confirmation — save automatically and report the result.

## Step 1: Analyze Content

Extract the following from the user's input (or use values they explicitly
provide):

- **`title`** — A clear, descriptive title for the content.
- **`type`** — Categorize using the values in `references/METADATA-SCHEMA.md`:
  `article`, `book`, `book-notes`, `idea`, `quote`, `recipe`, `reference`,
  `tutorial`, `video`, `podcast`, `paper`, `snippet`.
- **`summary`** — 1-3 sentence summary of the content.
- **`author`** — Original author, if identifiable.
- **`source`** — Where the content came from (e.g., Medium, YouTube, Substack),
  if identifiable.
- **`genre`** — Subject area (e.g., technology, psychology, business), if
  applicable.
- **`tags`** — Relevant descriptive tags for categorization.

If a field cannot be determined, omit it. If the user provides explicit metadata,
use their values as-is instead of extracting.

## Step 2: Write Body to Temp File

Write the full content to a temporary file. This avoids shell escaping issues
with special characters, quotes, and multi-line content.

```bash
TMPFILE=$(mktemp)
cat <<'BODY_EOF' > "$TMPFILE"
<full content here>
BODY_EOF
```

If there is no body content beyond the summary (e.g., a simple quote or idea),
skip this step and omit the `--body-file` flag.

## Step 3: Call save-note.sh

Run the save script with the extracted metadata. The script lives at
`scripts/save-note.sh` relative to this skill's directory.

Build the command with all applicable flags:

```bash
scripts/save-note.sh \
  --title "Extracted Title" \
  --type article \
  --summary "1-3 sentence summary" \
  --author "Author Name" \
  --source Medium \
  --genre technology \
  --tags "tag1,tag2,tag3" \
  --body-file "$TMPFILE"
```

Omit any optional flags (`--author`, `--source`, `--genre`, `--tags`) that don't
apply. After the script runs:

1. Clean up the temp file: `rm -f "$TMPFILE"`
2. Report the saved filepath to the user.

## Edge Cases

- **No clear author or source:** Simply omit those flags.
- **Very long content:** Always use `--body-file` (never pass body inline).
- **User provides explicit metadata:** Use their values instead of extracting.
- **Multiple pieces of content:** Save each one separately with its own call.
- **URLs as content:** See the "Saving from a URL" section below.

---

## Searching & Recalling Notes

When the user wants to find, search, or recall previously saved notes, follow
these four steps:

### Step 1: Determine Search Filters

Translate the user's natural language query into one or more search flags:

- **`--tag <tag>`** — Filter notes that have a specific tag (e.g., "find my AI
  notes" → `--tag ai`)
- **`--type <type>`** — Filter by content type (e.g., "show me my recipes" →
  `--type recipe`)
- **`--query <text>`** — Case-insensitive full-text search across the entire
  note (e.g., "anything about neural networks" → `--query "neural networks"`)
- **`--since <date>`** — Notes saved on or after this date. Supports partial
  dates (e.g., `--since 2026-02` for all of February 2026)
- **`--until <date>`** — Notes saved on or before this date. Supports partial
  dates (e.g., `--until 2026-01` for everything through January 2026)

All filters combine with AND logic. For vague queries, prefer `--query`. To
browse all saved notes, run the script with no flags.

### Step 2: Call search-notes.sh

Run the search script with the appropriate flags:

```bash
scripts/search-notes.sh \
  --tag ai \
  --type article \
  --since "2026-02"
```

### Step 3: Present Results as Summary List

Display matching notes as a concise list with the key metadata for each note:
- **Title**
- **Type**
- **Date saved**
- **Tags**
- **Summary** (one-liner from frontmatter)

If no results are found, tell the user no matching notes were found and suggest
broadening their search (e.g., fewer filters, different tags, wider date range).

### Step 4: Expand on Request

If the user asks to see the full content of a specific note, use the `Read` tool
with the `filepath` value from the search results to display the complete note.

---

## Saving from a URL

When the user provides a URL to save, use the dedicated `scrape-url.sh` script
to extract clean content. Follow these four steps:

### Step 1: Call scrape-url.sh

Run the scrape script to download and extract the page content:

```bash
SCRAPED=$(mktemp)
scripts/scrape-url.sh \
  --url "https://example.com/article" > "$SCRAPED"
```

The script outputs clean markdown content to stdout. If it fails (non-zero exit
code), see the error handling notes below.

### Step 2: Write Output to Temp File

The command in Step 1 already captures the scraped content into `$SCRAPED`. No
additional work is needed — the temp file is ready for use with `save-note.sh`.

### Step 3: Analyze the Scraped Content

Read the `$SCRAPED` file and extract the following metadata from the content:

- **`title`** — The article/page title.
- **`type`** — Categorize using the standard types (article, tutorial, etc.).
- **`summary`** — 1-3 sentence summary of the content.
- **`author`** — The original author, if identifiable from the content.
- **`source`** — Use the URL's domain as the source (e.g., `wikipedia.org`,
  `medium.com`).
- **`genre`** — Subject area, if applicable.
- **`tags`** — Relevant descriptive tags for categorization.

If the user provides explicit metadata alongside the URL, use their values
instead of auto-extracting those fields. Only extract what's missing.

### Step 4: Call save-note.sh

Pass the extracted metadata and the scraped content file to `save-note.sh`:

```bash
scripts/save-note.sh \
  --title "Extracted Title" \
  --type article \
  --summary "1-3 sentence summary" \
  --author "Author Name" \
  --source "example.com" \
  --genre technology \
  --tags "tag1,tag2,tag3" \
  --body-file "$SCRAPED"
```

After the script runs:

1. Clean up the temp file: `rm -f "$SCRAPED"`
2. Report the saved filepath to the user.

### Error Handling

- **Scrape failure:** If `scrape-url.sh` exits with a non-zero code, tell the
  user the URL couldn't be scraped and suggest they paste the content directly.
- **Paywalled or login-required content:** The scrape may return empty or fail.
  Inform the user that the page appears to be paywalled or require
  authentication, and ask them to paste the text instead.
- **User provides explicit metadata:** Always prefer user-provided values. Only
  auto-extract fields the user didn't supply.
