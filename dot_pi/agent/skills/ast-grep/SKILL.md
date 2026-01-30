---
name: ast-grep
description:
  Enables the agent to perform structural code search and rewrite tasks using
  ast-grep (sg), a syntax-aware tool for accurate pattern matching and
  refactoring across multiple programming languages.
license: MIT
---

# ast-grep (sg) Utility Skill

## Overview

The agent has access to `ast-grep` (command: `sg`), a structural code search and
rewrite tool based on syntactic pattern matching. It enables precise,
language-aware codebase queries and transformations.

## When to Use

- Searching for code patterns across files/languages accurately
- Refactoring code safely using structural matches instead of regex
- Finding complex syntactic constructs (e.g. function calls with specific
  parameters)
- Replacing code patterns with templates
- Analyzing code structure without false positives from text-based search

## Usage

**Important**: patterns should be wrapped in single quotes not double quotes to
avoid variable expansion (patterns use the `$` symbol).

### Search

```sh
sg run -p <pattern> -l <language>
```

Example: Find all console.log calls in JavaScript

```sh
sg run -p 'console.log($ARGS)' -l js
```

### Rewrite

```sh
sg run -p <pattern> --rewrite <template> -l <language>
```

Example: Replace console.log with logger.info

```sh
sg run -p 'console.log($ARGS)' --rewrite 'logger.info($ARGS)' -l js
```

### Pattern Syntax

- **Syntax Requirements**: Pattern code must be valid and parseable by
  tree-sitter. Provide sufficient context if parsing fails.
- **Metavariables**: Start with `$` (e.g., `$VAR`, `$_`) to match a single AST
  node.
- **Multi Metavariables**: Use `$$$` (or `$$$NAME`) to match zero or more AST
  nodes (e.g., arguments, statements).
- **Capturing Rules**:
  - Reusing a metavariable (e.g., `$A == $A`) ensures identical nodes match.
  - Prefix with `_` (e.g., `$_FUNC`) for non-capturing matches (optimizes
    performance).
  - Use `$$VAR` to capture unnamed AST nodes.

---

Use `sg --help` for more info.
