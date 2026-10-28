# ADR-002: Import TikTok/Instagram recipes from captions only

**Status:** Accepted (2026-10-23)

## Context
Many recipes people want to save live in short videos. Downloading and analysing the video
would mean scraping against the platforms' terms, storing third-party media, and paying for
video/audio models on every import.

## Decision
Read only the post's caption (via oEmbed). If the caption links to a blog, import that page
with the normal schema.org `Recipe` path. Otherwise Claude Haiku structures the caption text.
If no recipe is found, the user gets a clear message and a paste box.

## Consequences
- No video download, storage or transcoding; imports stay cheap (Haiku only).
- Some reels have no written recipe and can't be imported automatically. The miss rate is an
  open question; revisit video analysis only if it turns out to be high.
- Every recipe keeps its source link and attribution.
