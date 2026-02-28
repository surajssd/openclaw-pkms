#!/usr/bin/env bash
#
# search-notes.sh — Search structured markdown notes by tag, type, query, or date.
#
# Optional flags: --tag <tag>, --type <type>, --query <text>,
#                 --since <date>, --until <date>, --dir <path>
#
# All filters combine with AND logic. No filters = return all notes.
# Exit 0 on success (including no matches), exit 1 on errors.

set -euo pipefail

# ── Defaults ─────────────────────────────────────────────────────────────────
TAG=""
TYPE=""
QUERY=""
SINCE=""
UNTIL=""
DIR=""

# ── Parse flags ──────────────────────────────────────────────────────────────
while [[ $# -gt 0 ]]; do
    case "$1" in
    --tag)
        TAG="$2"
        shift 2
        ;;
    --type)
        TYPE="$2"
        shift 2
        ;;
    --query)
        QUERY="$2"
        shift 2
        ;;
    --since)
        SINCE="$2"
        shift 2
        ;;
    --until)
        UNTIL="$2"
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

# ── Resolve note directory ───────────────────────────────────────────────────
if [[ -n "$DIR" ]]; then
    NOTE_DIR="$DIR"
elif [[ -n "${RECALL_DIR:-}" ]]; then
    NOTE_DIR="$RECALL_DIR"
else
    NOTE_DIR="$HOME/recall"
fi

if [[ ! -d "$NOTE_DIR" ]]; then
    echo "Error: directory not found: ${NOTE_DIR}" >&2
    exit 1
fi

# ── Search notes ─────────────────────────────────────────────────────────────
shopt -s nullglob
files=("${NOTE_DIR}"/*.md)
shopt -u nullglob

for file in "${files[@]}"; do
    # ── Extract frontmatter ──────────────────────────────────────────────
    in_frontmatter=false
    frontmatter=""
    fm_title=""
    fm_type=""
    fm_date=""
    fm_tags=""
    fm_summary=""

    while IFS= read -r line; do
        if [[ "$line" == "---" ]]; then
            if $in_frontmatter; then
                break
            else
                in_frontmatter=true
                continue
            fi
        fi
        if $in_frontmatter; then
            frontmatter+="${line}"$'\n'
        fi
    done <"$file"

    # ── Parse fields from frontmatter ────────────────────────────────────
    while IFS= read -r line; do
        case "$line" in
        title:*)
            fm_title="${line#title:}"
            fm_title="${fm_title#"${fm_title%%[![:space:]]*}"}"
            fm_title="${fm_title#\"}"
            fm_title="${fm_title%\"}"
            ;;
        type:*)
            fm_type="${line#type:}"
            fm_type="${fm_type#"${fm_type%%[![:space:]]*}"}"
            ;;
        date_saved:*)
            fm_date="${line#date_saved:}"
            fm_date="${fm_date#"${fm_date%%[![:space:]]*}"}"
            ;;
        summary:*)
            fm_summary="${line#summary:}"
            fm_summary="${fm_summary#"${fm_summary%%[![:space:]]*}"}"
            # Handle multi-line summary (YAML block scalar with >)
            if [[ "$fm_summary" == ">" || "$fm_summary" == ">-" ]]; then
                fm_summary=""
            fi
            ;;
        esac
    done <<<"$frontmatter"

    # Collect summary continuation lines (indented lines after "summary: >")
    if [[ -z "$fm_summary" ]]; then
        in_summary=false
        while IFS= read -r line; do
            if [[ "$line" =~ ^summary: ]]; then
                in_summary=true
                continue
            fi
            if $in_summary; then
                if [[ "$line" =~ ^[[:space:]] ]]; then
                    trimmed="${line#"${line%%[![:space:]]*}"}"
                    if [[ -n "$fm_summary" ]]; then
                        fm_summary+=" ${trimmed}"
                    else
                        fm_summary="${trimmed}"
                    fi
                else
                    break
                fi
            fi
        done <<<"$frontmatter"
    fi

    # Collect tags (lines matching "  - tagname")
    while IFS= read -r line; do
        if [[ "$line" =~ ^[[:space:]]+-[[:space:]]+(.*) ]]; then
            tag_val="${BASH_REMATCH[1]}"
            if [[ -n "$fm_tags" ]]; then
                fm_tags+=", ${tag_val}"
            else
                fm_tags="${tag_val}"
            fi
        fi
    done < <(
        in_tags=false
        while IFS= read -r l; do
            if [[ "$l" == "tags:" ]]; then
                in_tags=true
                continue
            fi
            if $in_tags; then
                if [[ "$l" =~ ^[[:space:]]+-[[:space:]] ]]; then
                    echo "$l"
                else
                    break
                fi
            fi
        done <<<"$frontmatter"
    )

    # ── Apply filters ────────────────────────────────────────────────────
    skip=false

    # --tag filter: check if tag appears in tags list
    if [[ -n "$TAG" ]] && ! $skip; then
        if ! echo "$fm_tags" | grep -qi "\b${TAG}\b" 2>/dev/null; then
            skip=true
        fi
    fi

    # --type filter: exact match
    if [[ -n "$TYPE" ]] && ! $skip; then
        if [[ "$fm_type" != "$TYPE" ]]; then
            skip=true
        fi
    fi

    # --since filter: lexicographic >= (prefix-aware)
    if [[ -n "$SINCE" ]] && ! $skip; then
        # Pad the date to compare: truncate fm_date to length of SINCE for prefix match
        cmp_date="${fm_date:0:${#SINCE}}"
        if [[ "$cmp_date" < "$SINCE" ]]; then
            skip=true
        fi
    fi

    # --until filter: prefix-aware <=
    if [[ -n "$UNTIL" ]] && ! $skip; then
        cmp_date="${fm_date:0:${#UNTIL}}"
        if [[ "$cmp_date" > "$UNTIL" ]]; then
            skip=true
        fi
    fi

    # --query filter: case-insensitive full-text search
    if [[ -n "$QUERY" ]] && ! $skip; then
        if ! grep -qi "$QUERY" "$file" 2>/dev/null; then
            skip=true
        fi
    fi

    # ── Print match ──────────────────────────────────────────────────────
    if ! $skip; then
        echo "---"
        echo "filepath: ${file}"
        echo "title: ${fm_title}"
        echo "type: ${fm_type}"
        echo "date_saved: ${fm_date}"
        echo "tags: ${fm_tags}"
        echo "summary: ${fm_summary}"
        echo "---"
    fi
done
