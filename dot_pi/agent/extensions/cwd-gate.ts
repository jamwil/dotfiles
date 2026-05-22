/**
 * CWD Gate Extension
 *
 * Prompts for confirmation before reading, writing, editing, or executing files
 * that are not within:
 * - the current working directory
 * - /tmp (POSIX/bash)
 * - pi's agent directory (global extensions/skills/prompts/themes/settings)
 */

import * as path from "node:path"
import {
    type ExtensionAPI,
    type ExtensionContext,
    getAgentDir,
} from "@jamwil/pi"
import {
    type PathSyntax,
    type SuspiciousPath,
    extractSuspiciousPathsFromCommand,
    getBashTrustedRoots,
    getTrustedRoots,
    isEqualOrDescendant,
    isEqualOrDescendantBash,
    isOutsideTrustedRoots,
    normalizeForBashCompare,
    normalizeForCompare,
    normalizeToolPathArg,
} from "./lib/cwd-gate-patterns"

export default function (pi: ExtensionAPI) {
    const AUTO_DENY_TIMEOUT_MS = 90_000
    // Uses pi's configured agent dir (e.g. ~/.pi/agent by default, cross-platform).
    const AGENT_DIR = path.resolve(getAgentDir())

    type StoredDecision = { root: string; allowed: boolean; syntax: PathSyntax }
    const rememberedDecisions = new Map<string, StoredDecision>()

    function normalizeDecisionKey(p: string, syntax: PathSyntax): string {
        if (syntax === "bash") {
            return normalizeForBashCompare(path.posix.resolve(p))
        }

        return normalizeForCompare(path.resolve(p))
    }

    function rememberDecision(rootPath: string, allowed: boolean, syntax: PathSyntax): void {
        const resolvedRoot = syntax === "bash" ? path.posix.resolve(rootPath) : path.resolve(rootPath)
        rememberedDecisions.set(normalizeDecisionKey(resolvedRoot, syntax), {
            root: resolvedRoot,
            allowed,
            syntax,
        })
    }

    function findRememberedDecision(
        targetResolved: string,
        syntax: PathSyntax,
    ): StoredDecision | undefined {
        for (const decision of rememberedDecisions.values()) {
            if (decision.syntax !== syntax) continue

            const covered =
                syntax === "bash"
                    ? isEqualOrDescendantBash(decision.root, targetResolved)
                    : isEqualOrDescendant(decision.root, targetResolved)

            if (covered) {
                return decision
            }
        }

        return undefined
    }

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
        const toolName = event.toolName
        const suspiciousPaths: SuspiciousPath[] = []
        const nativeCwd = normalizeToolPathArg(ctx.cwd)
        let trustedRoots: string[] = []

        if (toolName === "read" || toolName === "write" || toolName === "edit") {
            trustedRoots = getTrustedRoots(nativeCwd, AGENT_DIR)

            const p =
                typeof (event.input as any)?.path === "string"
                    ? ((event.input as any).path as string)
                    : ""
            if (p) {
                const { outside, resolved } = isOutsideTrustedRoots(nativeCwd, p, trustedRoots)
                if (outside) {
                    suspiciousPaths.push({ original: p, resolved, syntax: "native" })
                }
            }
        } else if (toolName === "bash") {
            const command =
                typeof (event.input as any)?.command === "string"
                    ? ((event.input as any).command as string)
                    : ""

            trustedRoots = getBashTrustedRoots(ctx.cwd, AGENT_DIR)
            suspiciousPaths.push(...extractSuspiciousPathsFromCommand(command, ctx.cwd, trustedRoots))
        } else {
            return undefined
        }

        if (suspiciousPaths.length > 0) {
            const pendingPaths: SuspiciousPath[] = []

            for (const suspicious of suspiciousPaths) {
                const remembered = findRememberedDecision(suspicious.resolved, suspicious.syntax)
                if (remembered) {
                    if (!remembered.allowed) {
                        return {
                            block: true,
                            reason: `Blocked by prior denial for ${remembered.root}`,
                        }
                    }

                    continue
                }

                pendingPaths.push(suspicious)
            }

            if (pendingPaths.length === 0) {
                return undefined
            }

            const uniquePaths = Array.from(new Set(pendingPaths.map((p) => p.original)))

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
                if (!timedOut) {
                    for (const pathEntry of pendingPaths) {
                        rememberDecision(pathEntry.resolved, false, pathEntry.syntax)
                    }
                }

                return {
                    block: true,
                    reason: timedOut ? "Cancelled (no selection)" : "Blocked by user",
                }
            }

            for (const pathEntry of pendingPaths) {
                rememberDecision(pathEntry.resolved, true, pathEntry.syntax)
            }
        }

        return undefined
    })
}
