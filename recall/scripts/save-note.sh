#!/usr/bin/env bash
#
# save-note.sh — Write a structured markdown note with YAML frontmatter.
#
# Required flags: --title, --type, --summary
# Optional flags: --author, --source, --genre, --tags (comma-separated),
#                 --date (YYYY-MM-DD-HH-MM-SS), --body-file <path>, --dir <path>
#
# Output: Prints saved filepath to stdout. Exit 0 on success, 1 on error.

set -euo pipefail

# ── Defaults ─────────────────────────────────────────────────────────────────
TITLE=""
TYPE=""
SUMMARY=""
AUTHOR=""
SOURCE=""
GENRE=""
TAGS=""
DATE=""
BODY_FILE=""
DIR=""

# ── Parse flags ──────────────────────────────────────────────────────────────
while [[ $# -gt 0 ]]; do
    case "$1" in
    --title)
        TITLE="$2"
        shift 2
        ;;
    --type)
        TYPE="$2"
        shift 2
        ;;
    --summary)
        SUMMARY="$2"
        shift 2
        ;;
    --author)
        AUTHOR="$2"
        shift 2
        ;;
    --source)
        SOURCE="$2"
        shift 2
        ;;
    --genre)
        GENRE="$2"
        shift 2
        ;;
    --tags)
        TAGS="$2"
        shift 2
        ;;
    --date)
        DATE="$2"
        shift 2
        ;;
    --body-file)
        BODY_FILE="$2"
        shift 2
        ;;
    --dir)
        DIR="$2"
        shift 2
        ;;
    *)
        echo "Error: unknown flag '$1'" >&2
        exit 1
        ;;
    esac
done

# ── Validate required fields ────────────────────────────────────────────────
missing=()
[[ -z "$TITLE" ]] && missing+=("--title")
[[ -z "$TYPE" ]] && missing+=("--type")
[[ -z "$SUMMARY" ]] && missing+=("--summary")

if [[ ${#missing[@]} -gt 0 ]]; then
    echo "Error: missing required flags: ${missing[*]}" >&2
    exit 1
fi

# ── Determine output directory ──────────────────────────────────────────────
if [[ -n "$DIR" ]]; then
    OUTPUT_DIR="$DIR"
elif [[ -n "${RECALL_DIR:-}" ]]; then
    OUTPUT_DIR="$RECALL_DIR"
else
    OUTPUT_DIR="$HOME/recall"
fi

mkdir -p "$OUTPUT_DIR"

# ── Set date ─────────────────────────────────────────────────────────────────
if [[ -z "$DATE" ]]; then
    DATE="$(date "+%Y-%m-%d-%H-%M-%S")"
fi

# ── Slugify title ────────────────────────────────────────────────────────────
slug=$(echo "$TITLE" |
    tr '[:upper:]' '[:lower:]' |
    sed 's/[^a-z0-9]/-/g' |
    sed 's/--*/-/g' |
    sed 's/^-//' |
    sed 's/-$//' |
    cut -c1-60)

# ── Handle filename collisions ──────────────────────────────────────────────
base="${DATE}-${slug}"
filepath="${OUTPUT_DIR}/${base}.md"
counter=2

while [[ -e "$filepath" ]]; do
    filepath="${OUTPUT_DIR}/${base}-${counter}.md"
    counter=$((counter + 1))
done

# ── Assemble YAML frontmatter ───────────────────────────────────────────────
{
    echo "---"
    echo "title: \"${TITLE}\""
    echo "type: ${TYPE}"

    [[ -n "$AUTHOR" ]] && echo "author: \"${AUTHOR}\""
    [[ -n "$SOURCE" ]] && echo "source: ${SOURCE}"
    [[ -n "$GENRE" ]] && echo "genre: ${GENRE}"

    if [[ -n "$TAGS" ]]; then
        echo "tags:"
        IFS=',' read -ra tag_array <<<"$TAGS"
        for tag in "${tag_array[@]}"; do
            tag="$(echo "$tag" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')"
            echo "  - ${tag}"
        done
    fi

    echo "date_saved: ${DATE}"
    echo "summary: >"
    echo "  ${SUMMARY}"
    echo "---"
} >"$filepath"

# ── Append body content ─────────────────────────────────────────────────────
if [[ -n "$BODY_FILE" ]]; then
    if [[ ! -f "$BODY_FILE" ]]; then
        echo "Error: body file not found: ${BODY_FILE}" >&2
        exit 1
    fi
    echo "" >>"$filepath"
    cat "$BODY_FILE" >>"$filepath"
fi

# ── Output ───────────────────────────────────────────────────────────────────
echo "$filepath"
