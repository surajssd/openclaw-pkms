# Metadata Schema

Field definitions and taxonomy for recall notes.

## Required Fields

| Field        | Type   | Description                          |
| ------------ | ------ | ------------------------------------ |
| `title`      | string | Descriptive title for the content    |
| `type`       | enum   | Content category (see values below)  |
| `summary`    | string | 1-3 sentence summary of the content |
| `date_saved` | date   | Date the note was saved (YYYY-MM-DD) |

## Optional Fields

| Field    | Type         | Description                         |
| -------- | ------------ | ----------------------------------- |
| `author` | string       | Original author of the content      |
| `source` | string       | Where the content came from         |
| `genre`  | string       | Subject area or literary genre      |
| `tags`   | list[string] | Descriptive tags for categorization |

## Type Values

- `article` — Blog post, news article, essay
- `book` — Full book reference
- `book-notes` — Notes or takeaways from a book
- `idea` — Original thought or concept
- `quote` — Notable quote or passage
- `recipe` — Cooking or process recipe
- `reference` — Reference material (docs, specs, cheat sheets)
- `tutorial` — How-to or instructional content
- `video` — Video notes or transcript
- `podcast` — Podcast notes or transcript
- `paper` — Academic or research paper
- `snippet` — Code snippet or small reusable piece

## Genre Examples

non-fiction, fiction, sci-fi, fantasy, business, psychology, technology,
philosophy, self-help, history, science, economics, biography, memoir,
health, design, engineering, mathematics, cooking, travel

## Source Examples

Goodreads, Medium, Substack, Twitter/X, YouTube, Hacker News, Reddit,
Wikipedia, arXiv, GitHub, personal, manual, conversation, email
