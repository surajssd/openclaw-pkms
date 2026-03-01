#!/usr/bin/env bash
#
# scrape-url.sh — Scrape a URL and output clean content to stdout.
#
# Uses trafilatura to extract article content from web pages.
#
# Required flags: --url <url>
# Optional flags: --format markdown|text (default: markdown)
#
# Output: Extracted content to stdout. Exit 0 on success, 1 on error.

set -euo pipefail

# ── Defaults ─────────────────────────────────────────────────────────────────
URL=""
FORMAT="markdown"

# ── Parse flags ──────────────────────────────────────────────────────────────
while [[ $# -gt 0 ]]; do
    case "$1" in
    --url)
        URL="$2"
        shift 2
        ;;
    --format)
        FORMAT="$2"
        shift 2
        ;;
    *)
        echo "Error: unknown flag '$1'" >&2
        exit 1
        ;;
    esac
done

# ── Validate required fields ────────────────────────────────────────────────
if [[ -z "$URL" ]]; then
    echo "Error: missing required flag: --url" >&2
    echo "Usage: scrape-url.sh --url <url> [--format markdown|text]" >&2
    exit 1
fi

# ── Validate format ─────────────────────────────────────────────────────────
if [[ "$FORMAT" != "markdown" && "$FORMAT" != "text" ]]; then
    echo "Error: --format must be 'markdown' or 'text', got '$FORMAT'" >&2
    exit 1
fi

# ── Check trafilatura is installed ──────────────────────────────────────────
if ! command -v trafilatura &>/dev/null; then
    echo "Error: trafilatura is not installed or not in PATH." >&2
    echo "Install it with: pip install trafilatura" >&2
    exit 1
fi

# ── Build trafilatura command ───────────────────────────────────────────────
TRAF_ARGS=(-u "$URL")
if [[ "$FORMAT" == "markdown" ]]; then
    TRAF_ARGS+=(--markdown)
fi

# ── Run trafilatura ─────────────────────────────────────────────────────────
CONTENT=$(trafilatura "${TRAF_ARGS[@]}" 2>/dev/null) || true

if [[ -z "$CONTENT" ]]; then
    echo "Error: failed to extract content from URL: $URL" >&2
    echo "The page may be empty, paywalled, or require authentication." >&2
    exit 1
fi

# ── Output ───────────────────────────────────────────────────────────────────
echo "$CONTENT"
