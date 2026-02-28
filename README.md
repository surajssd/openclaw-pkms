# openclaw-pkms

# OpenClaw Skill: Recall-Personal Knowledge Management System (PKMS)

Skill name: Recall — Personal Knowledge Management Skill

- Knowledge Collectors
Here we define how the knowledge is collected into the KMS.
Types of Collectors

- Chat Collector (Main chat window / Telegram / WhatsApp, etc)
Users can provide a link to an article to store in the KMS.
Along with that article they can provide notes in the form of text, voice or image. So the system should give more importance to the notes along with the article.
LLM should summarize the content from Link
Users can simply provide a photo of some text and ask it to be saved in the KMS
Users can provide a link to a video, get the video’s captions, and other properties of the video and add it to the KMS.

- Goodreads Highlights Collector
We can login to the user account and save the public highlights from their “Read” book shelf and save highlights from those books.
Books Highlight Collector 

## Recall — Personal Knowledge Management Skill

Short description
-- Recall is an OpenClaw skill for a personal knowledge management system (PKMS). It ingests content (links, text, images, video captions, highlights), extracts summaries and metadata with an LLM, embeds content for semantic search, and resurfaces items via chat/email according to a learnable ranking.

## Table of contents

- Overview
- Collectors (how knowledge is collected)
- On-save flow (what happens when content is saved)
- Resurface flow (how and when content is shown again)
- Ranking signals
- Query / Quiz / Serendipity modes
- Technical details
- User personas
- TODO / Next steps

## Overview

Recall helps users capture and later resurface knowledge. It supports multiple collectors, labels saved items with structured metadata, stores semantic embeddings, and provides search, digest, and active recall (quiz) experiences.

## Collectors

Supported and planned collectors:

- Chat collector (Telegram, WhatsApp, web chat)
	- Users can send links, text, voice, or images.
	- When images contain text the system should OCR and save the extracted text.
	- Video links: extract captions and key metadata and save.
- Goodreads highlights collector
	- Authenticate and pull public highlights from the user's "Read" shelf.
- Book highlights collector (import from Kindle/other exports)
- Instapaper collector (TODO)
- Personal GitHub repository collector (TODO)

Collector design notes:

- When both source content and user notes are provided, prefer user notes for summaries and tagging.
- Normalise source metadata (author, title, source, date) where available.

## On-save flow

When a user saves content the system should:

1. Ingest the raw content
	 - From a URL (scrape HTML), from raw text, from image (OCR), or from video (captions).
2. Extract a canonical text body
	 - Use BeautifulSoup or trafilatura for HTML scraping.
3. Send text to an LLM to get back:
	 - Summary
	 - Tags / attributes (type, topic, genre, author, title, source, date)
	 - One-line takeaway
4. Create metadata labels (examples):
	 - type=book
	 - genre=non-fiction,habits
	 - author=James Clear
	 - title=Atomic Habits
	 - source=Goodreads
	 - date_saved=2026-02-28
5. Embed the summary using a cost-effective embedding model
	 - e.g., OpenAI text-embedding-3-small or a local sentence-transformers model
6. Store vector + metadata in a vector DB (ChromaDB or compatible store)

## Resurface / Reminders flow

Recall resurfaces knowledge via chat (Telegram) or email driven by a ranking algorithm that learns user preferences.

Typical steps:

1. User triggers (explicit query) or scheduled/resurface job runs.
2. Parse intent (filter by metadata) or perform semantic vector search.
3. Rank results and return the top N (3–5) with summary + source link.

For quiz mode:

- Retrieve highlights/notes for the requested item (book/topic).
- Use an LLM to generate 2–3 recall questions from those highlights.

## Ranking signals

Signals used to surface and rank items:

- Explicit user preferences ("show me more business content")
- Frequency of saves in a topic
- Time since last resurfaced (favor older, unseen items)
- Engagement with resurfaced items (responses, likes, dismissals)
- User edits or adds extra notes (increases importance)

## Modes

- Query mode
	- Example: "Show me everything I saved about machine learning in the last month"
	- Filter by tags and date, return a digest with summaries and source links.

- Quiz / Test mode
	- Example: "Test my knowledge on Atomic Habits"
	- Retrieve highlights and use an LLM to generate recall questions.

- Serendipity mode
	- Occasionally surface older high-ranked items the user hasn't reviewed in a while.

## User personas

- Alex — The Voracious Reader
	- Reads widely (Substack, Medium, blogs). Needs retention and digest features.
	- Wants monthly digests and occasional quizzes.

- Veronica — The Non-fiction Book Nerd
	- Takes careful notes but forgets insights over time.
	- Uses Goodreads highlights and wants cross-book pattern detection.

## Technical details (implementation notes)

- Scraping / ingestion
	- Use BeautifulSoup or trafilatura for HTML scraping.
	- Use OCR for images (Tesseract or cloud OCR APIs).
	- Extract video captions via a captions API or YouTube transcripts.

- LLM responsibilities
	- Produce: summary, tags, one-liner takeaway, and (for quiz mode) questions.

- Embeddings & vector store
	- Use a cheap embedding model (OpenAI text-embedding-3-small or local embedding model).
	- Store vectors + JSON metadata in ChromaDB or another vector database.

- Metadata schema (suggested)

```json
{
	"id": "uuid",
	"title": "Atomic Habits",
	"author": "James Clear",
	"type": "book",
	"genre": ["non-fiction","habits"],
	"source": "Goodreads",
	"date_saved": "2026-02-28",
	"takeaway": "Small habits compound over time.",
	"summary": "...",
	"embedding_model": "text-embedding-3-small"
}
```

