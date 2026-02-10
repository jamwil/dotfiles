/**
 * CWD Gate Extension
 *
 * Prompts for confirmation before reading, writing, editing, or executing files
 * that are not within or a descendant of the current working directory.
 */

import * as os from "node:os"
import * as path from "node:path"
import type { ExtensionAPI, ExtensionContext } from "@mariozechner/pi-coding-agent"

export default function (pi: ExtensionAPI) {
    const AUTO_DENY_TIMEOUT_MS = 90_000

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
     */
    function normalizeToolPathArg(p: string): string {
        const stripped = p.startsWith("@") ? p.slice(1) : p

        if (stripped === "~") return os.homedir()

        if (stripped.startsWith("~/") || stripped.startsWith("~\\")) {
            return path.join(os.homedir(), stripped.slice(2))
        }

        return stripped
    }

    function normalizeForCompare(p: string): string {
        const normalized = path.normalize(p)
        return process.platform === "win32" ? normalized.toLowerCase() : normalized
    }

    function isOutsideCwd(baseCwd: string, targetPath: string): boolean {
        const expanded = normalizeToolPathArg(targetPath)

        const baseResolved = path.resolve(baseCwd)
        const targetResolved = path.resolve(baseResolved, expanded)

        // Prefix match with separator avoids false positives like:
        //   C:\\foo vs C:\\foobar
        const basePrefix = baseResolved.endsWith(path.sep)
            ? baseResolved
            : `${baseResolved}${path.sep}`

        const baseCmp = normalizeForCompare(basePrefix)
        const targetCmp = normalizeForCompare(targetResolved)
        const baseCmpNoSep = normalizeForCompare(baseResolved)

        return !(targetCmp === baseCmpNoSep || targetCmp.startsWith(baseCmp))
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
        const cwd = ctx.cwd

        if (toolName === "read" || toolName === "write" || toolName === "edit") {
            const p =
                typeof (event.input as any)?.path === "string"
                    ? ((event.input as any).path as string)
                    : ""
            if (p && isOutsideCwd(cwd, p)) {
                suspiciousPaths.push(p)
            }
        } else if (toolName === "bash") {
            const command =
                typeof (event.input as any)?.command === "string"
                    ? ((event.input as any).command as string)
                    : ""

            // Naive tokenization to find potential paths.
            // Goal is to catch obvious "outside cwd" paths without lots of false positives.
            const tokens = command.split(/\s+/)

            for (const token of tokens) {
                // Strip surrounding quotes and common trailing punctuation.
                const cleanToken = token.replace(/^['"]|['"]$/g, "").replace(/[;,)+\]]+$/g, "")

                if (!looksLikePossiblyDangerousPathToken(cleanToken)) continue

                if (isOutsideCwd(cwd, cleanToken)) {
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
                    reason: `Operation targets files outside CWD (${cwd}): ${uniquePaths.join(", ")}`,
                }
            }

            let title = `⚠️  Outside CWD Detected (${cwd})\n\n`
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
