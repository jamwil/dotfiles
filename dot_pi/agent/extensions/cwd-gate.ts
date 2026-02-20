/**
 * CWD Gate Extension
 *
 * Prompts for confirmation before reading, writing, editing, or executing files
 * that are not within:
 * - the current working directory
 * - pi's agent directory (global extensions/skills/prompts/themes/settings)
 */

import * as os from "node:os"
import * as path from "node:path"
import {
    type ExtensionAPI,
    type ExtensionContext,
    getAgentDir,
} from "@mariozechner/pi-coding-agent"

export default function (pi: ExtensionAPI) {
    const AUTO_DENY_TIMEOUT_MS = 90_000
    // Uses pi's configured agent dir (e.g. ~/.pi/agent by default, cross-platform).
    const AGENT_DIR = path.resolve(getAgentDir())

    async function selectYesNoWithAutoDeny(
        ctx: ExtensionContext,
        title: string,
        timeoutMs = AUTO_DENY_TIMEOUT_MS,
    ): Promise<{ allowed: boolean; timedOut: boolean }> {
        const choice = await ctx.ui.select(title, ["Yes", "No"], { timeout: timeoutMs })

        if (choice === undefined) {
            return { allowed: false, timedOut: true }
        }

        return { allowed: choice === "Yes", timedOut: false }
    }

    /**
     * Normalize tool-supplied paths.
     * - Some models include a leading '@' in path arguments.
     * - Support ~, ~/, and ~\\ home expansion.
     * - On Windows, convert common Git Bash/MSYS2-style paths to Win32 paths
     *   (e.g. /c/Users/me -> C:\\Users\\me).
     */
    function normalizeToolPathArg(p: string): string {
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
    function msysToWindowsPath(p: string): string | null {
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

    function normalizeForCompare(p: string): string {
        const normalized = path.normalize(p)
        return process.platform === "win32" ? normalized.toLowerCase() : normalized
    }

    function isEqualOrDescendant(rootPath: string, targetPath: string): boolean {
        const rootResolved = path.resolve(rootPath)
        const targetResolved = path.resolve(targetPath)

        // Prefix match with separator avoids false positives like:
        //   C:\\foo vs C:\\foobar
        const rootPrefix = rootResolved.endsWith(path.sep)
            ? rootResolved
            : `${rootResolved}${path.sep}`

        const rootCmp = normalizeForCompare(rootResolved)
        const rootPrefixCmp = normalizeForCompare(rootPrefix)
        const targetCmp = normalizeForCompare(targetResolved)

        return targetCmp === rootCmp || targetCmp.startsWith(rootPrefixCmp)
    }

    function getTrustedRoots(baseCwd: string): string[] {
        const rootsByCompare = new Map<string, string>()

        for (const root of [path.resolve(baseCwd), AGENT_DIR]) {
            rootsByCompare.set(normalizeForCompare(root), root)
        }

        return Array.from(rootsByCompare.values())
    }

    function isOutsideTrustedRoots(
        baseCwd: string,
        targetPath: string,
        trustedRoots: string[],
    ): boolean {
        const expanded = normalizeToolPathArg(targetPath)

        const baseResolved = path.resolve(baseCwd)
        const targetResolved = path.resolve(baseResolved, expanded)

        return !trustedRoots.some((root) => isEqualOrDescendant(root, targetResolved))
    }

    function looksLikePossiblyDangerousPathToken(token: string): boolean {
        if (!token) return false

        // Unix-ish
        if (token.startsWith("/") || token.startsWith("~") || token.startsWith("..")) return true

        // Windows drive absolute, UNC, root-relative
        if (/^[a-zA-Z]:[\\/]/.test(token)) return true
        if (/^(\\\\|\/\/)[^\\/]+[\\/][^\\/]+/.test(token)) return true
        if (token.startsWith("\\")) return true

        return false
    }

    pi.on("tool_call", async (event, ctx) => {
        const toolName = event.toolName
        const suspiciousPaths: string[] = []
        // On Windows, ctx.cwd may be provided in MSYS/Git-Bash form (/c/...) depending
        // on how pi was launched.
        const cwd = normalizeToolPathArg(ctx.cwd)
        const trustedRoots = getTrustedRoots(cwd)

        if (toolName === "read" || toolName === "write" || toolName === "edit") {
            const p =
                typeof (event.input as any)?.path === "string"
                    ? ((event.input as any).path as string)
                    : ""
            if (p && isOutsideTrustedRoots(cwd, p, trustedRoots)) {
                suspiciousPaths.push(p)
            }
        } else if (toolName === "bash") {
            const command =
                typeof (event.input as any)?.command === "string"
                    ? ((event.input as any).command as string)
                    : ""

            // Naive tokenization to find potential paths.
            // Goal is to catch obvious "outside trusted roots" paths without lots of false positives.
            const tokens = command.split(/\s+/)

            for (const token of tokens) {
                // Strip surrounding quotes and common trailing punctuation.
                const cleanToken = token.replace(/^['"]|['"]$/g, "").replace(/[;,)+\]]+$/g, "")

                if (!looksLikePossiblyDangerousPathToken(cleanToken)) continue

                if (isOutsideTrustedRoots(cwd, cleanToken, trustedRoots)) {
                    suspiciousPaths.push(cleanToken)
                }
            }
        } else {
            return undefined
        }

        if (suspiciousPaths.length > 0) {
            const uniquePaths = Array.from(new Set(suspiciousPaths))

            if (!ctx.hasUI) {
                return {
                    block: true,
                    reason: `Operation targets paths outside trusted roots (${trustedRoots.join(", ")}): ${uniquePaths.join(", ")}`,
                }
            }

            let title = `⚠️  Outside Trusted Roots\n\nAllowed:\n${trustedRoots.join("\n")}\n\n`
            if (toolName === "bash") {
                title += `Command:\n${(event.input as any).command}\n\n`
            }
            title += `Targeting:\n${uniquePaths.join("\n")}\n\nAllow? (auto-deny in 90s)`

            const { allowed, timedOut } = await selectYesNoWithAutoDeny(ctx, title)

            if (!allowed) {
                return {
                    block: true,
                    reason: timedOut ? "Cancelled (no selection)" : "Blocked by user",
                }
            }
        }

        return undefined
    })
}
