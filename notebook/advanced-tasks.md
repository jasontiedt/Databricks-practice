# Advanced workflows — Databricks MCP toolkit

A second pass of short, focused exercises that extend the foundation in
[tasks.md](tasks.md). Three tracks, eight tasks, **~60 minutes total** if you
do them back-to-back. Pick one track or all three.

> **Prereqs.** You've worked through at least Stage 1–2 of [tasks.md](tasks.md),
> customized the instruction files (Task 2.4), and the prompt files at
> `.github/prompts/` are wired up.

---

## Track A — Compose Copilot artifacts into pipelines (~20 min)

### Task A.1 — Delegate parallel discovery to a subagent (10 min)
**Goal.** Have a read-only subagent crawl many tables in parallel without bloating your main chat.

**Steps.**
1. In a fresh chat, ask: *"Use the `Explore` subagent (thoroughness: quick) to summarize every table in `<your schema>` in parallel. Return one markdown table with columns: name, column count, row count, 1-line purpose guess."*
2. Time it. Compare to running `/describe-table` sequentially on the same tables.
3. Save the result as `notebook/reports/<schema>-inventory.md`.

**Done when.** You have a full-schema inventory that took less elapsed time than the sequential approach, and the main chat history isn't cluttered with per-table noise.

---

### Task A.2 — Evaluate a prompt (10 min)
**Goal.** Score one of your prompt files against the Chat Customizations Evaluations extension.

**Steps.**
1. Install the **Chat Customizations Evaluations** extension if not present (search the Marketplace from VS Code).
2. Open `.github/prompts/profile-table.prompt.md` (or any prompt you've authored).
3. Run **Analyze prompt** from the Command Palette.
4. Read the Problems panel. Apply the fixes it suggests.

**Done when.** Zero diagnostics remain on at least one of your prompt files, and you've kept a note of the most useful diagnostic for next time.

---

## Track B — Multi-environment & multi-system (~25 min)

### Task B.1 — Env-swap pattern (10 min)
**Goal.** Add a `dev`/`prod` switch that maps to different catalog/schema pairs without editing prompts each time.

**Steps.**
1. Create `.vscode/env-map.json`:
   ```json
   {
     "dev":  { "catalog": "main_dev",  "schema": "silver" },
     "prod": { "catalog": "main",      "schema": "silver" }
   }
   ```
   Adjust to your actual environments.
2. Edit one prompt (e.g. `/explore-schema`) to take `${input:env|dev,prod:dev}` instead of `${input:catalog}` / `${input:schema}`.
3. In the prompt body, instruct Copilot: *"Read `.vscode/env-map.json`, look up `catalog` and `schema` for the chosen `env`, and use those for every query."*
4. Run it twice — once per env. Verify each run hits the right catalog.

**Done when.** Switching `env` produces different queries against different catalogs **inside the same prompt run** — no manual override needed.

---

### Task B.2 — Differential query (10 min)
**Goal.** Compare schema + sample distribution of the same table across two environments.

**Steps.**
1. Pick a table that exists in both your dev and prod (or two time snapshots of the same data).
2. Ask Copilot: *"Compare `<env_a>.<schema>.<table>` to `<env_b>.<schema>.<table>`. Report (a) column-list diff using `EXCEPT`, (b) row-count diff, and (c) top-10 values of `<column>` side-by-side. Render as one markdown table per section."*
3. Read the generated SQL — note where it used `EXCEPT` / `INTERSECT` vs separate queries with a join.

**Done when.** You have a one-page diff that surfaces both schema drift and data drift between the two environments.

---

### Task B.3 — Multi-MCP composition (5 min)
**Goal.** Combine the Databricks MCP with another MCP server in a single chat turn.

**Steps.**
1. If you don't already have the GitHub MCP server enabled in `.vscode/mcp.json`, add it (or use any second MCP server you have).
2. Ask: *"Find the last PR that modified any file under `queries/`. Then run the SQL in that file through the Databricks MCP and summarize the result."*
3. Confirm Copilot called both MCP servers in sequence — once for git history, once for SQL execution.

**Done when.** A single chat answer cites a PR number **and** query results from two different MCP tools.

---

## Track C — Quality of life (~15 min)

### Task C.1 — Auto-generated `queries/README.md` (5 min)
**Goal.** Keep an index of your saved queries up to date with one command.

**Steps.**
1. Ask Copilot: *"Read every `*.sql` file in `queries/`, extract the leading header comment, and produce `queries/README.md` with a table: filename | description | last modified."*
2. Commit the README.
3. Add or rename a query, re-run the prompt, and confirm the README stays in sync.

**Done when.** `queries/README.md` lists every file with a description, and regenerating it is one chat command away.

---

### Task C.2 — Personal favorites file (5 min)
**Goal.** Build a "starred queries" file the agent can append to.

**Steps.**
1. Create `notebook/favorites.md` with topic sections (e.g. *Schema*, *Profiling*, *Time series*).
2. Author `.github/prompts/favorite.prompt.md` that takes inputs: `${input:queryPath}`, `${input:section}`, `${input:note}`. The body appends one bullet `- [<filename>](<path>) — <note>` to the matching section.
3. Run it on two real queries you want to remember.

**Done when.** `notebook/favorites.md` has two new entries that you didn't type manually, and you can re-invoke the prompt without re-editing it.

---

### Task C.3 — Pre-flight grounding check (5 min)
**Goal.** Catch SQL that references nonexistent tables before you commit it.

**Steps.**
1. Create `scripts/check_sql_tables.py`:
   - For each `*.sql` argument on the command line, regex out `catalog.schema.table` references.
   - For each, query `information_schema.tables` via `databricks-sql-connector` (reuse `.env` from Task 3.1).
   - Print a diff and exit non-zero if any are missing.
2. Run `python scripts/check_sql_tables.py queries/*.sql` and confirm it succeeds on your known-good files.
3. (Optional) Wire it into a pre-commit hook by adding `.pre-commit-config.yaml` with a local hook pointing at the script.

**Done when.** Running the script on a query that references a fake table name exits non-zero with a clear message; running it on real queries exits zero.

---

## Checklist

```markdown
- [ ] A.1 Subagent parallel discovery   (10 min)
- [ ] A.2 Prompt evaluation             (10 min)
- [ ] B.1 Env-swap pattern              (10 min)
- [ ] B.2 Differential query            (10 min)
- [ ] B.3 Multi-MCP composition         ( 5 min)
- [ ] C.1 Auto-generated README          ( 5 min)
- [ ] C.2 Personal favorites prompt     ( 5 min)
- [ ] C.3 Pre-flight grounding check    ( 5 min)
```

**Total focused time: ~60 minutes.** Each task is small enough to skip the
ones that don't fit your workflow without losing the thread of the others.
