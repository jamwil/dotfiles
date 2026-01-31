/**
 * CWD Gate Extension
 *
 * Prompts for confirmation before reading, writing, editing, or executing files
 * that are not within or a descendant of the current working directory.
 */

import type { ExtensionAPI } from "@mariozechner/pi-coding-agent"
import * as os from "os"
import * as path from "path"

export default function (pi: ExtensionAPI) {
    const cwd = process.cwd()
    const AUTO_DENY_TIMEOUT_MS = 90_000

    async function selectWithAutoDeny(
        ctx: { ui: { select: (message: string, options: string[]) => Promise<string> } },
        message: string,
        options: string[],
        timeoutMs = AUTO_DENY_TIMEOUT_MS,
        timeoutDefault = "No",
    ): Promise<{ choice: string; timedOut: boolean }> {
        const timeoutSentinel = "__timeout__"
        let timeoutId: NodeJS.Timeout | undefined

        try {
            const result = await Promise.race([
                ctx.ui.select(message, options),
                new Promise<string>((resolve) => {
                    timeoutId = setTimeout(() => resolve(timeoutSentinel), timeoutMs)
                }),
            ])

            if (result === timeoutSentinel) {
                return { choice: timeoutDefault, timedOut: true }
            }

            return { choice: result, timedOut: false }
        } finally {
            if (timeoutId) clearTimeout(timeoutId)
        }
    }

    function expandHome(p: string): string {
        if (p === "~" || p.startsWith("~/")) {
            return path.join(os.homedir(), p.slice(1))
        }
        return p
    }

    function isOutsideCwd(targetPath: string): boolean {
        const expanded = expandHome(targetPath)
        const resolved = path.resolve(cwd, expanded)
        const rel = path.relative(cwd, resolved)
        return rel.startsWith("..") || path.isAbsolute(rel)
    }

    pi.on("tool_call", async (event, ctx) => {
        const toolName = event.toolName
        const suspiciousPaths: string[] = []

        if (toolName === "read" || toolName === "write" || toolName === "edit") {
            const p = event.input.path as string
            if (p && isOutsideCwd(p)) {
                suspiciousPaths.push(p)
            }
        } else if (toolName === "bash") {
            const command = event.input.command as string
            // Naive tokenization to find potential paths
            const tokens = command.split(/\s+/)

            for (const token of tokens) {
                // Strip quotes
                const cleanToken = token.replace(/^['"]|['"]$/g, "")

                // Check if token looks like a path (absolute, parent dir, or home alias)
                if (
                    cleanToken.startsWith("/") ||
                    cleanToken.startsWith("..") ||
                    cleanToken.startsWith("~")
                ) {
                    if (isOutsideCwd(cleanToken)) {
                        suspiciousPaths.push(cleanToken)
                    }
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

            let message = `⚠️  Outside CWD Detected (${cwd})\n\n`
            if (toolName === "bash") {
                message += `Command:\n${event.input.command}\n\n`
            }
            message += `Targeting:\n${uniquePaths.join("\n")}\n\nAllow? (auto-deny in 90s)`

            const { choice, timedOut } = await selectWithAutoDeny(
                ctx,
                message,
                ["Yes", "No"],
                AUTO_DENY_TIMEOUT_MS,
                "No",
            )

            if (choice !== "Yes") {
                return {
                    block: true,
                    reason: timedOut
                        ? "Auto-denied (no selection within 90 seconds)"
                        : "Blocked by user",
                }
            }
        }

        return undefined
    })
}
