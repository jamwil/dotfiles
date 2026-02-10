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

    // Allow-list for specific safe commands. Keep empty for now; populate with RegExp entries
    // (e.g. /\bchmod\b.*--chroot-safe-flag/ ) in future if you want to permit exceptions.
    const allowList: RegExp[] = []

    const dangerousPatterns = [
        /\brm\s+(-rf?|--recursive)/i,
        /\bsudo\b/i,
        /\b(?:chmod|chown)\b/i,
        /\b(?:curl|wget|fetch)\b/i,
        /\bdd\b/i,
        /\b(?:mkfs|fdisk|parted|sfdisk|gdisk)\b/i,
        /\b(?:shred|wipe)\b/i,
        /\b(reboot|shutdown|poweroff|halt|init)\b/i,
        /(?:\bdd\b.*\bof=\/dev\/|>\s*\/dev\/|>>\s*\/dev\/|>\s*\/etc\/|>\s*\/proc\/|>\s*\/sys\/)/i,
        /\b(?:curl|wget|fetch)\b.*\|\s*(?:sh|bash|zsh|sudo)/i,
        /\bgit\b.*\b(reset\s+--hard|clean\s+-fdx|checkout\s+-f)\b/i,
        /\bgit\b.*\bpush\b/i,
        /\bgh\b/i,
        /\bdocker\b.*\b(system\s+prune|rm\s+-f|rmi\s+-f|volume\s+rm|container\s+prune)\b/i,

        // Windows-ish equivalents (often used inside Git Bash / MSYS shells too)
        /\b(?:del|erase)\b/i,
        /\b(?:rmdir|rd)\b/i,
        /\b(?:diskpart|bcdedit)\b/i,
        /(?:^|(?:&&|&|\|\||;)\s*)format(?:\.com|\.exe)?(?=\s|$)/i,
        /\bcmd(?:\.exe)?\s+\/c\s+format(?:\.com|\.exe)?(?=\s|$)/i,
        /\b(?:icacls|takeown)\b/i,
        /\b(?:powershell|pwsh)\b.*\b(?:Remove-Item|Format-Volume|Clear-Disk|Set-Acl)\b/i,
    ]

    pi.on("tool_call", async (event, ctx) => {
        if (event.toolName !== "bash") return undefined

        const command =
            typeof (event.input as any)?.command === "string"
                ? ((event.input as any).command as string)
                : ""

        const isDangerous = dangerousPatterns.some((p) => p.test(command))

        // If command matches allow-list, treat as safe
        const isAllowed = allowList.some((p) => p.test(command))

        if (isDangerous && !isAllowed) {
            if (!ctx.hasUI) {
                // In non-interactive mode, block by default
                return { block: true, reason: "Dangerous command blocked (no UI for confirmation)" }
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
