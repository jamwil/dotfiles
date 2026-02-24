/**
 * Permission Gate Extension
 *
 * Prompts for confirmation before running potentially dangerous shell commands.
 *
 * Note: Despite the tool name being "bash", on Windows this typically runs via
 * Git Bash / MSYS2 / Cygwin (depending on user setup). This extension aims to
 * be robust across platforms.
 */

import type { ExtensionAPI, ExtensionContext } from "@mariozechner/pi-coding-agent"
import { isDangerousCommand } from "./lib/permission-gate-patterns"

export default function (pi: ExtensionAPI) {
    const AUTO_DENY_TIMEOUT_MS = 90_000

    async function selectYesNoWithAutoDeny(
        ctx: ExtensionContext,
        title: string,
        timeoutMs = AUTO_DENY_TIMEOUT_MS,
    ): Promise<{ allowed: boolean; timedOut: boolean }> {
        const choice = await ctx.ui.select(title, ["Yes", "No"], {
            timeout: timeoutMs,
        })

        if (choice === undefined) {
            return { allowed: false, timedOut: true }
        }

        return { allowed: choice === "Yes", timedOut: false }
    }

    pi.on("tool_call", async (event, ctx) => {
        if (event.toolName !== "bash") return undefined

        const command =
            typeof (event.input as any)?.command === "string"
                ? ((event.input as any).command as string)
                : ""

        if (isDangerousCommand(command)) {
            if (!ctx.hasUI) {
                // In non-interactive mode, block by default
                return {
                    block: true,
                    reason: "Dangerous command blocked (no UI for confirmation)",
                }
            }

            const { allowed, timedOut } = await selectYesNoWithAutoDeny(
                ctx,
                `⚠️ Dangerous command:\n\n  ${command}\n\nAllow? (auto-deny in 90s)`,
            )

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
