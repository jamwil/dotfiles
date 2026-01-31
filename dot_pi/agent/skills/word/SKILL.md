---
name: word
description:
  Automates Microsoft Word via pywin32 (COM) for interactive pair work. Attaches
  to a running Word instance, selects an already-open document by name, and runs
  agent-generated Python to manipulate content and save/export.
compatibility: Windows + Microsoft Word. Requires uv.
---

# Word (pywin32) Skill

This skill is for **interactive pair work** where the user already has:

- Microsoft Word running
- The target document already open

The harness attaches to the running Word session and executes agent-provided
Python code with these variables pre-bound:

- `word`: Word Application COM object
- `doc`: target Document COM object
- `win32c`: `win32com.client.constants`

## Where is the Python harness script?

In this skills repo, each skill lives in its own folder. For this skill, the
entrypoint Python script is:

- `word/scripts/word_harness.py`

All example commands below assume you run them from the **skills directory
root** (so that relative path resolves). The skills directory is typically at
`~/.pi/agent/skills/`.

**Path note (Windows + bash):** Use **forward slashes** (`/`) in paths when
writing commands (e.g. `word/scripts/word_harness.py`). Windows may show paths
with backslashes (`C:\\...`), but the agent runs commands in a bash-like shell
where `/` is the expected separator.

## Run (uv one-liners)

List open documents:

```bash
uv run word/scripts/word_harness.py --list-documents
```

Run inline code against an open document:

```bash
uv run word/scripts/word_harness.py --document 'Report.docx' --code '__result__ = {"first_paragraph": doc.Paragraphs(1).Range.Text}'
```

**Quoting note (bash):** Prefer **single quotes** around CLI argument values
(e.g. `--code '...'`, `--script '...'`). This avoids bash interpreting
characters like `$` as variable expansions.

Run a snippet file:

```bash
uv run word/scripts/word_harness.py --document 'Report.docx' --script /path/to/snippet.py
```

### Snippet pattern

Write snippets assuming `word` and `doc` exist:

```python
# Append a paragraph at the end (non-destructive; doesn’t save unless you do)
rng = doc.Content
rng.Collapse(0)  # 0 = wdCollapseEnd
rng.InsertAfter("\nHello from pi\n")

__result__ = {
  "name": doc.Name,
  "saved": bool(doc.Saved),
  "length": doc.Content.End,
}
```

The harness will print `__RESULT__=<json>` if `__result__` is set.

## Agent workflow

1. Ask the user which document is open (usually the `.docx` file name).
2. If uncertain, run `--list-documents` and pick from the output.
3. Generate a small, incremental snippet to perform the requested action.
4. Execute via `uv run ... --code` (tiny changes) or `--script` (multi-step).

## Safety notes

- The harness **will not start Word** or open files; it only manipulates what’s
  already open.
- **Do not save automatically.** Avoid calling `doc.Save()` / `doc.SaveAs(...)`
  unless the user explicitly asks to persist changes.
- Avoid destructive operations unless explicitly requested.
- Prefer incremental edits and frequent saves/exports when asked.
