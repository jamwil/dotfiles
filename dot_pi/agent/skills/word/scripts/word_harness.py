# /// script
# requires-python = ">=3.10"
# dependencies = ["pywin32>=306"]
# ///

"""word_harness.py

A small harness for driving *an already-open* Microsoft Word document via
pywin32 (COM).

Target use case: interactive pair work.

What it does:
- Attaches to an existing (running) Word instance
- Selects an already-open document by name (or full path)
- Executes agent-provided Python code with useful variables pre-bound

Pre-bound variables available to the executed code:
- word:  Word Application COM object
- doc:   Target Document COM object
- win32c: win32com.client.constants

Result convention:
- If executed code sets __result__ (any JSON-serializable object), the harness
  prints it as a single line prefixed with "__RESULT__=".

Examples (recommended to run with uv):
  uv run word_harness.py --list-documents
  uv run word_harness.py --document "Document1" --code "__result__={'preview': doc.Content.Text[:100]}"
  uv run word_harness.py --document "Report.docx" --script snippet.py
"""

from __future__ import annotations

import argparse
import json
import os
import sys
import traceback
from typing import Any, Dict, Optional


def _eprint(*args: Any, **kwargs: Any) -> None:
    print(*args, file=sys.stderr, **kwargs)


def _connect_word() -> Any:
    """Return the running Word Application COM object.

    This harness intentionally does NOT start Word. The document must already
    be open in an existing Word session.
    """

    import pythoncom
    import win32com.client

    pythoncom.CoInitialize()

    try:
        return win32com.client.GetActiveObject("Word.Application")
    except Exception as e:
        pythoncom.CoUninitialize()
        raise RuntimeError(
            "Could not attach to a running Word instance. "
            "Open Word and the target document, then try again."
        ) from e


def _iter_documents(word: Any):
    # word.Documents is a 1-indexed COM collection
    for i in range(1, word.Documents.Count + 1):
        yield word.Documents(i)


def _normalize(s: str) -> str:
    return s.strip().lower()


def _doc_fullname(doc: Any) -> Optional[str]:
    """Best-effort FullName.

    Unsaved documents may not have a FullName/Path; accessing it may raise.
    """

    try:
        v = getattr(doc, "FullName", None)
        if v is None:
            return None
        return str(v)
    except Exception:
        return None


def _find_document(word: Any, document_name: str) -> Any:
    """Find an open document by .Name or .FullName."""

    target = _normalize(document_name)
    target_base = _normalize(os.path.basename(document_name))

    matches = []
    for doc in _iter_documents(word):
        try:
            name = _normalize(str(doc.Name))
        except Exception:
            continue

        fullname = _doc_fullname(doc)
        fullname_n = _normalize(fullname) if fullname else ""

        if (
            target == name
            or (fullname and (target == fullname_n))
            or target_base == name
            or (fullname and fullname_n.endswith("\\" + target_base))
        ):
            matches.append(doc)

    if len(matches) == 1:
        return matches[0]

    if len(matches) > 1:
        raise RuntimeError(
            f"Multiple open documents matched {document_name!r}. Be more specific (try a full path)."
        )

    open_names = []
    for doc in _iter_documents(word):
        try:
            open_names.append(str(doc.Name))
        except Exception:
            pass

    raise FileNotFoundError(
        f"Document {document_name!r} not found among open documents: {', '.join(open_names) or '<none>'}"
    )


def _load_code(script_path: Optional[str], code_arg: Optional[str]) -> str:
    if script_path and code_arg:
        raise ValueError("Use only one of --script or --code")

    if script_path:
        with open(script_path, "r", encoding="utf-8") as f:
            return f.read()

    if code_arg is not None:
        return code_arg

    # Default: read from stdin (useful for piping generated code)
    return sys.stdin.read()


def _run_user_code(*, word: Any, doc: Any, code: str) -> Dict[str, Any]:
    import win32com.client

    ns: Dict[str, Any] = {
        "word": word,
        "doc": doc,
        "win32c": win32com.client.constants,
        "__file__": "<word_harness_exec>",
        "__name__": "__word_harness_exec__",
    }

    exec(compile(code, "<word-agent-code>", "exec"), ns, ns)
    return ns


def main(argv: Optional[list[str]] = None) -> int:
    p = argparse.ArgumentParser(description="Drive an already-open Word document via pywin32.")
    p.add_argument("--document", help="Name or full path of an already-open document (e.g., Report.docx)")
    p.add_argument("--list-documents", action="store_true", help="List currently open documents and exit")
    p.add_argument("--script", help="Path to a Python snippet to execute with doc bound")
    p.add_argument("--code", help="Inline Python code to execute")
    args = p.parse_args(argv)

    import pythoncom

    try:
        word = _connect_word()

        if args.list_documents:
            docs = []
            for doc in _iter_documents(word):
                try:
                    docs.append(
                        {
                            "Name": str(doc.Name),
                            "FullName": _doc_fullname(doc),
                            "Saved": bool(getattr(doc, "Saved", True)),
                        }
                    )
                except Exception:
                    pass
            print(json.dumps({"open_documents": docs}, indent=2))
            return 0

        if not args.document:
            p.error("--document is required unless --list-documents is used")

        doc = _find_document(word, args.document)

        code = _load_code(args.script, args.code)
        if not code.strip():
            raise ValueError("No code provided. Use --script, --code, or pipe code on stdin.")

        ns = _run_user_code(word=word, doc=doc, code=code)

        if "__result__" in ns:
            try:
                print("__RESULT__=" + json.dumps(ns["__result__"], default=str))
            except Exception:
                print("__RESULT__=" + json.dumps(str(ns["__result__"])))

        return 0

    except SystemExit:
        raise
    except Exception as e:
        _eprint("ERROR:", e)
        _eprint(traceback.format_exc())
        return 1
    finally:
        try:
            pythoncom.CoUninitialize()
        except Exception:
            pass


if __name__ == "__main__":
    raise SystemExit(main())
