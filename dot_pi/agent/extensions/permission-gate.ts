/**
 * Permission Gate Extension
 *
 * Prompts for confirmation before running potentially dangerous bash commands.
 * Patterns checked: rm -rf, sudo, chmod/chown 777
 */

import type { ExtensionAPI } from "@mariozechner/pi-coding-agent"

export default function (pi: ExtensionAPI) {
    // Allow-list for specific safe commands. Keep empty for now; populate with RegExp entries
    // (e.g. /\bchmod\b.*--chroot-safe-flag/ ) in future if you want to permit exceptions.
    const allowList: RegExp[] = []

    const dangerousPatterns = [
        /\brm\s+(-rf?|--recursive)/i,
        /\bsudo\b/i,
        /\b(?:chmod|chown)\b/i,
        /\b(?:curl|wget)\b/i,
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
    ]

    pi.on("tool_call", async (event, ctx) => {
        if (event.toolName !== "bash") return undefined

        const command = event.input.command as string
        const isDangerous = dangerousPatterns.some((p) => p.test(command))

        // If command matches allow-list, treat as safe
        const isAllowed = allowList.some((p) => p.test(command))

        if (isDangerous && !isAllowed) {
            if (!ctx.hasUI) {
                // In non-interactive mode, block by default
                return { block: true, reason: "Dangerous command blocked (no UI for confirmation)" }
            }

            const choice = await ctx.ui.select(`⚠️ Dangerous command:\n\n  ${command}\n\nAllow?`, [
                "Yes",
                "No",
            ])

            if (choice !== "Yes") {
                return { block: true, reason: "Blocked by user" }
            }
        }

        return undefined
    })
}
