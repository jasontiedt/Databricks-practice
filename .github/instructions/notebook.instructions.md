---
applyTo: 'notebook/**'
description: 'Conventions for the notebook/ folder (learning notes, runnable exercises).'
---

# Notebook folder conventions

These rules apply to everything under `notebook/`.

## Purpose

This folder is a personal Databricks learning journal. Content here should be
**explorative, narrative, and reproducible** — not production analysis.

## File types

<!-- CUSTOMIZE based on what you actually keep here -->

- `*.md` — long-form notes, learning paths, summaries.
- `*.sql` — runnable query snippets keyed to the notes.
- `*.ipynb` / `*.py` — only if you're prototyping locally; prefer Databricks
  notebooks in the workspace for actual execution.

## Markdown style

- One H1 per file matching the filename.
- Use H2 for major topics, H3 for subtopics — do not skip levels.
- Code fences must declare a language: ` ```sql `, ` ```python `, ` ```bash `.
- Inline code uses single backticks for identifiers and keywords.
- Tables are preferred over bulleted key/value lists when comparing options.

## Linking SQL to notes

When a note explains a query, embed the SQL in the markdown **and** keep a
runnable copy in `queries/` if it's reusable. Cross-link them:

```markdown
See [queries/schema_and_visualize.sql](../queries/schema_and_visualize.sql)
section 5 for the histogram template.
```

## Learning content rules

- Cite the Databricks docs URL when you state a fact about behavior.
- When a concept has multiple correct approaches, list trade-offs in a small
  table rather than picking one silently.
- Mark unverified claims with `> TODO: verify against warehouse`.

<!-- CUSTOMIZE: add personal preferences below, e.g.:
- "Always include a `## Recap` section at the end of each note."
- "Tag advanced topics with `[advanced]` in the heading."
- "Date-stamp each file with `Last reviewed: YYYY-MM-DD` at the top."
-->

## What this folder is NOT

- Not a place for credentials, tokens, or warehouse IDs.
- Not a place for proprietary or PII data samples — use synthetic values.
- Not a substitute for production runbooks.
