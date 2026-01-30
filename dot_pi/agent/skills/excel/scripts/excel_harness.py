# /// script
# requires-python = ">=3.10"
# dependencies = ["pywin32>=306"]
# ///

"""excel_harness.py

A small harness for driving *an already-open* Microsoft Excel workbook via
pywin32 (COM).

Target use case: interactive pair work.

What it does:
- Attaches to an existing (running) Excel instance
- Selects an already-open workbook by name (or full path)
- Executes agent-provided Python code with useful variables pre-bound

Pre-bound variables available to the executed code:
- excel: Excel Application COM object
- wb:    Target Workbook COM object
- win32c: win32com.client.constants

Result convention:
- If executed code sets __result__ (any JSON-serializable object), the harness
  prints it as a single line prefixed with "__RESULT__=".

Examples (recommended to run with uv):
  uv run excel_harness.py --list-workbooks
  uv run excel_harness.py --workbook "Book1.xlsx" --code "wb.Worksheets(1).Range('A1').Value='Hi'"
  uv run excel_harness.py --workbook "Book1.xlsx" --script snippet.py
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


def _connect_excel() -> Any:
    """Return the running Excel Application COM object.

    This harness intentionally does NOT start Excel. The workbook must already
    be open in an existing Excel session.
    """

    import pythoncom
    import win32com.client

    pythoncom.CoInitialize()

    try:
        return win32com.client.GetActiveObject("Excel.Application")
    except Exception as e:
        # Ensure COM is uninitialized if we failed before handing off.
        pythoncom.CoUninitialize()
        raise RuntimeError(
            "Could not attach to a running Excel instance. "
            "Open Excel and the target workbook, then try again."
        ) from e


def _iter_workbooks(excel: Any):
    # excel.Workbooks is a 1-indexed COM collection
    for i in range(1, excel.Workbooks.Count + 1):
        yield excel.Workbooks(i)


def _normalize(s: str) -> str:
    return s.strip().lower()


def _find_workbook(excel: Any, workbook_name: str) -> Any:
    """Find an open workbook by .Name or .FullName."""

    target = _normalize(workbook_name)
    target_base = _normalize(os.path.basename(workbook_name))

    matches = []
    for wb in _iter_workbooks(excel):
        try:
            name = _normalize(str(wb.Name))
            fullname = _normalize(str(wb.FullName))
        except Exception:
            continue

        if target == name or target == fullname or target_base == name or fullname.endswith("\\" + target_base):
            matches.append(wb)

    if len(matches) == 1:
        return matches[0]

    if len(matches) > 1:
        raise RuntimeError(
            f"Multiple open workbooks matched {workbook_name!r}. Be more specific (try a full path)."
        )

    open_names = []
    for wb in _iter_workbooks(excel):
        try:
            open_names.append(str(wb.Name))
        except Exception:
            pass

    raise FileNotFoundError(
        f"Workbook {workbook_name!r} not found among open workbooks: {', '.join(open_names) or '<none>'}"
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


def _run_user_code(*, excel: Any, wb: Any, code: str) -> Dict[str, Any]:
    import win32com.client

    ns: Dict[str, Any] = {
        "excel": excel,
        "wb": wb,
        "win32c": win32com.client.constants,
        "__file__": "<excel_harness_exec>",
        "__name__": "__excel_harness_exec__",
    }

    exec(compile(code, "<excel-agent-code>", "exec"), ns, ns)
    return ns


def main(argv: Optional[list[str]] = None) -> int:
    p = argparse.ArgumentParser(description="Drive an already-open Excel workbook via pywin32.")
    p.add_argument("--workbook", help="Name or full path of an already-open workbook (e.g., Budget.xlsx)")
    p.add_argument("--list-workbooks", action="store_true", help="List currently open workbooks and exit")
    p.add_argument("--script", help="Path to a Python snippet to execute with wb bound")
    p.add_argument("--code", help="Inline Python code to execute")
    args = p.parse_args(argv)

    import pythoncom

    try:
        excel = _connect_excel()

        if args.list_workbooks:
            names = []
            for wb in _iter_workbooks(excel):
                try:
                    names.append({"Name": str(wb.Name), "FullName": str(wb.FullName)})
                except Exception:
                    pass
            print(json.dumps({"open_workbooks": names}, indent=2))
            return 0

        if not args.workbook:
            p.error("--workbook is required unless --list-workbooks is used")

        wb = _find_workbook(excel, args.workbook)

        code = _load_code(args.script, args.code)
        if not code.strip():
            raise ValueError("No code provided. Use --script, --code, or pipe code on stdin.")

        ns = _run_user_code(excel=excel, wb=wb, code=code)

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
        # Release COM apartment
        try:
            pythoncom.CoUninitialize()
        except Exception:
            pass


if __name__ == "__main__":
    raise SystemExit(main())
