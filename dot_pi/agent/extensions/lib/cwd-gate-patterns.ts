/**
 * Pure pattern-detection and path-analysis logic for the CWD Gate extension.
 *
 * This module is intentionally free of side-effects and framework imports so
 * it can be exercised directly from unit tests.
 */

import * as os from "node:os"
import * as path from "node:path"

export type PathSyntax = "native" | "bash"

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
 * Normalize bash-command paths.
 *
 * Pi's bash tool runs under bash semantics, so command paths should be treated
 * as forward-slash paths. On Windows we convert native drive-letter paths to
 * bash-style /c/... paths for comparison, but we do not treat bare backslashes
 * as path separators when scanning command tokens.
 */
export function normalizeBashPathArg(p: string): string {
    const stripped = p.startsWith("@") ? p.slice(1) : p

    if (stripped === "~") return getBashHomeDir()

    if (stripped.startsWith("~/") || stripped.startsWith("~\\")) {
        const remainder = stripped.slice(2).replace(/\\/g, "/")
        return path.posix.join(getBashHomeDir(), remainder)
    }

    if (process.platform === "win32") {
        const bashPath = windowsToBashPath(stripped)
        if (bashPath) return bashPath
    }

    return stripped
}

function getBashHomeDir(): string {
    if (process.platform !== "win32") {
        return os.homedir()
    }

    return windowsToBashPath(os.homedir()) ?? os.homedir().replace(/\\/g, "/")
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

/**
 * Convert native Win32 drive-letter paths to bash-style /c/... paths.
 */
export function windowsToBashPath(p: string): string | null {
    let m = p.match(/^([a-zA-Z]):[\\/](.*)$/)
    if (m) {
        const drive = m[1].toLowerCase()
        const rest = m[2].replace(/\\/g, "/").replace(/^\/+/, "")
        return rest ? `/${drive}/${rest}` : `/${drive}`
    }

    m = p.match(/^([a-zA-Z]):$/)
    if (m) {
        return `/${m[1].toLowerCase()}`
    }

    return null
}

export function normalizeForCompare(p: string): string {
    const normalized = path.normalize(p)
    return process.platform === "win32" ? normalized.toLowerCase() : normalized
}

export function normalizeForBashCompare(p: string): string {
    const normalized = path.posix.normalize(p)
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

export function isEqualOrDescendantBash(rootPath: string, targetPath: string): boolean {
    const rootResolved = path.posix.resolve(normalizeBashPathArg(rootPath))
    const targetResolved = path.posix.resolve(normalizeBashPathArg(targetPath))

    const rootPrefix = rootResolved.endsWith(path.posix.sep)
        ? rootResolved
        : `${rootResolved}${path.posix.sep}`

    const rootCmp = normalizeForBashCompare(rootResolved)
    const rootPrefixCmp = normalizeForBashCompare(rootPrefix)
    const targetCmp = normalizeForBashCompare(targetResolved)

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

export function getBashTrustedRoots(baseCwd: string, agentDir: string): string[] {
    const rootsByCompare = new Map<string, string>()

    for (const root of [
        path.posix.resolve(normalizeBashPathArg(baseCwd)),
        path.posix.resolve(normalizeBashPathArg(agentDir)),
        "/tmp",
    ]) {
        rootsByCompare.set(normalizeForBashCompare(root), root)
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

export function isOutsideTrustedRootsForBash(
    baseCwd: string,
    targetPath: string,
    trustedRoots: string[],
): { outside: boolean; resolved: string } {
    const expanded = normalizeBashPathArg(targetPath)

    const baseResolved = path.posix.resolve(normalizeBashPathArg(baseCwd))
    const targetResolved = path.posix.resolve(baseResolved, expanded)

    const outside = !trustedRoots.some((root) => isEqualOrDescendantBash(root, targetResolved))
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

export function looksLikePossiblyDangerousBashPathToken(token: string): boolean {
    if (!token) return false

    // Filter out regex patterns before path checks
    if (looksLikeRegexNotPath(token)) return false

    // Bash paths should use forward slashes. Do not treat backslashes as path
    // separators here; they are commonly used for escaping quotes/spaces.
    if (token.startsWith("/") || token.startsWith("~") || token.startsWith("..")) return true
    if (/^[a-zA-Z]:\//.test(token)) return true

    return false
}

/* ------------------------------------------------------------------ */
/*  Bash-command token extraction                                     */
/* ------------------------------------------------------------------ */

export type SuspiciousPath = { original: string; resolved: string; syntax: PathSyntax }

/**
 * Extract tokens from a bash command that look like paths outside of trusted
 * roots. Returns an array of suspicious path entries.
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

        if (!looksLikePossiblyDangerousBashPathToken(cleanToken)) continue

        const { outside, resolved } = isOutsideTrustedRootsForBash(cwd, cleanToken, trustedRoots)
        if (outside) {
            suspicious.push({ original: cleanToken, resolved, syntax: "bash" })
        }
    }

    return suspicious
}
