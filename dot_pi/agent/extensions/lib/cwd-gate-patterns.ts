/**
 * Pure pattern-detection and path-analysis logic for the CWD Gate extension.
 *
 * This module is intentionally free of side-effects and framework imports so
 * it can be exercised directly from unit tests.
 */

import * as os from "node:os"
import * as path from "node:path"

/* ------------------------------------------------------------------ */
/*  Path normalisation                                                */
/* ------------------------------------------------------------------ */

/**
 * Normalize tool-supplied paths.
 * - Some models include a leading '@' in path arguments.
 * - Support ~, ~/, and ~\\ home expansion.
 * - On Windows, convert common Git Bash/MSYS2-style paths to Win32 paths
 *   (e.g. /c/Users/me -> C:\\Users\\me).
 */
export function normalizeToolPathArg(p: string): string {
    const stripped = p.startsWith("@") ? p.slice(1) : p

    if (stripped === "~") return os.homedir()

    if (stripped.startsWith("~/") || stripped.startsWith("~\\")) {
        return path.join(os.homedir(), stripped.slice(2))
    }

    if (process.platform === "win32") {
        const msys = msysToWindowsPath(stripped)
        if (msys) return msys
    }

    return stripped
}

/**
 * Convert MSYS2/Git-Bash paths to native Win32 paths.
 *
 * Examples:
 *   /c/Users/a -> C:\\Users\\a
 *   /cygdrive/c/Users/a -> C:\\Users\\a
 */
export function msysToWindowsPath(p: string): string | null {
    // /c/...
    let m = p.match(/^\/([a-zA-Z])(?:\/(.*))?$/)
    if (m) {
        const drive = m[1].toUpperCase()
        const rest = (m[2] ?? "").replace(/\//g, "\\")
        return rest ? `${drive}:\\${rest}` : `${drive}:\\`
    }

    // /cygdrive/c/...
    m = p.match(/^\/cygdrive\/([a-zA-Z])(?:\/(.*))?$/)
    if (m) {
        const drive = m[1].toUpperCase()
        const rest = (m[2] ?? "").replace(/\//g, "\\")
        return rest ? `${drive}:\\${rest}` : `${drive}:\\`
    }

    return null
}

export function normalizeForCompare(p: string): string {
    const normalized = path.normalize(p)
    return process.platform === "win32" ? normalized.toLowerCase() : normalized
}

/* ------------------------------------------------------------------ */
/*  Trusted-root helpers                                              */
/* ------------------------------------------------------------------ */

export function isEqualOrDescendant(rootPath: string, targetPath: string): boolean {
    const rootResolved = path.resolve(rootPath)
    const targetResolved = path.resolve(targetPath)

    // Prefix match with separator avoids false positives like:
    //   C:\\foo vs C:\\foobar
    const rootPrefix = rootResolved.endsWith(path.sep) ? rootResolved : `${rootResolved}${path.sep}`

    const rootCmp = normalizeForCompare(rootResolved)
    const rootPrefixCmp = normalizeForCompare(rootPrefix)
    const targetCmp = normalizeForCompare(targetResolved)

    return targetCmp === rootCmp || targetCmp.startsWith(rootPrefixCmp)
}

export function getTrustedRoots(baseCwd: string, agentDir: string): string[] {
    const rootsByCompare = new Map<string, string>()

    const extraTrustedRoots = process.platform === "win32" ? [] : ["/tmp"]

    for (const root of [path.resolve(baseCwd), agentDir, ...extraTrustedRoots]) {
        rootsByCompare.set(normalizeForCompare(root), root)
    }

    return Array.from(rootsByCompare.values())
}

export function isOutsideTrustedRoots(
    baseCwd: string,
    targetPath: string,
    trustedRoots: string[],
): { outside: boolean; resolved: string } {
    const expanded = normalizeToolPathArg(targetPath)

    const baseResolved = path.resolve(baseCwd)
    const targetResolved = path.resolve(baseResolved, expanded)

    const outside = !trustedRoots.some((root) => isEqualOrDescendant(root, targetResolved))
    return { outside, resolved: targetResolved }
}

/* ------------------------------------------------------------------ */
/*  Regex-vs-path heuristics                                          */
/* ------------------------------------------------------------------ */

/**
 * Heuristic: does the token look like a regex pattern rather than a path?
 * Catches common ripgrep/grep/sed patterns to avoid false positives.
 */
export function looksLikeRegexNotPath(token: string): boolean {
    // Sed/awk substitution expressions: s/foo/bar/, y/abc/xyz/
    if (/^[sy]\//.test(token)) return true

    if (token.startsWith("/")) {
        // Contains regex metacharacters that are uncommon/invalid in real paths:
        // |  alternation
        // +  one-or-more quantifier
        // {  repetition quantifier (paths don't contain literal braces)
        // (  grouping
        // ^  anchor
        // $  anchor
        //
        // Intentionally excludes *, ?, and [] which appear in valid path globs.
        if (/[|+{}()^$]/.test(token)) return true
    }

    return false
}

export function looksLikePossiblyDangerousPathToken(token: string): boolean {
    if (!token) return false

    // Filter out regex patterns before path checks
    if (looksLikeRegexNotPath(token)) return false

    // Unix-ish
    if (token.startsWith("/") || token.startsWith("~") || token.startsWith("..")) return true

    // Windows drive absolute, UNC, root-relative
    if (/^[a-zA-Z]:[\\/]/.test(token)) return true
    if (/^(\\\\|\/\/)[^\\/]+[\\/][^\\/]+/.test(token)) return true
    if (token.startsWith("\\")) return true

    return false
}

/* ------------------------------------------------------------------ */
/*  Bash-command token extraction                                     */
/* ------------------------------------------------------------------ */

export type SuspiciousPath = { original: string; resolved: string }

/**
 * Extract tokens from a bash command that look like paths outside of trusted
 * roots.  Returns an array of suspicious path entries.
 */
export function extractSuspiciousPathsFromCommand(
    command: string,
    cwd: string,
    trustedRoots: string[],
): SuspiciousPath[] {
    const tokens = command.split(/\s+/)
    const suspicious: SuspiciousPath[] = []

    for (const token of tokens) {
        // Strip surrounding quotes and common trailing punctuation.
        const cleanToken = token.replace(/^['"]|['"]$/g, "").replace(/[;,)+\]]+$/g, "")

        if (!looksLikePossiblyDangerousPathToken(cleanToken)) continue

        const { outside, resolved } = isOutsideTrustedRoots(cwd, cleanToken, trustedRoots)
        if (outside) {
            suspicious.push({ original: cleanToken, resolved })
        }
    }

    return suspicious
}
