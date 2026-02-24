/**
 * Pure pattern-matching logic for the Permission Gate extension.
 *
 * This module is intentionally free of side-effects and framework imports so
 * it can be exercised directly from unit tests.
 */

/**
 * Allow-list for specific safe commands. Keep empty for now; populate with
 * RegExp entries in future if you want to permit exceptions.
 */
export const allowPatterns: RegExp[] = []

export const dangerousPatterns: RegExp[] = [
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

/** Returns the subset of `dangerousPatterns` that match the command. */
export function matchesDangerousPatterns(command: string): RegExp[] {
    return dangerousPatterns.filter((p) => p.test(command))
}

/** Returns `true` when the command is dangerous and not on the allow-list. */
export function isDangerousCommand(command: string): boolean {
    const isDangerous = dangerousPatterns.some((p) => p.test(command))
    const isAllowed = allowPatterns.some((p) => p.test(command))
    return isDangerous && !isAllowed
}
