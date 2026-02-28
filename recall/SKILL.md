---
name: recall
description: >
  Save and organize content as structured markdown notes with auto-extracted
  metadata. Use when the user wants to save an article, book notes, quote,
  idea, or any content for later reference. Handles text extraction, tagging,
  and filing automatically.
metadata:
  author: github.com/surajssd
  version: "0.1"
allowed-tools: Bash Read Write Edit
---

# Recall — Save Content as Structured Notes

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

```bash
SKILL_DIR="$(dirname "$(readlink -f "$0")")"
```

Use the skill's own directory to locate the script. Build the command with all
applicable flags:

```bash
"${SKILL_DIR}/scripts/save-note.sh" \
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
- **URLs as content:** If the user provides a URL, use WebFetch to retrieve the
  content, then save the extracted text.

## Script Location

The save script path is:

```
/Users/suraj/code/git/openclaw-pkms/recall/scripts/save-note.sh
```

Or if accessed via the symlink:

```
~/.claude/skills/recall/scripts/save-note.sh
```
