/**
 * Integration tests for cwd-gate with realistic shell commands.
 *
 * Exercises the real functions exported from the extension lib module.
 */

import {
    extractSuspiciousPathsFromCommand,
    getTrustedRoots,
    normalizeToolPathArg,
} from "../extensions/lib/cwd-gate-patterns"

/**
 * Helper: extract suspicious tokens from a command as if running in a
 * project directory.  Uses a synthetic cwd and agent dir so results are
 * deterministic regardless of the machine running the tests.
 */
function extractSuspiciousTokens(command: string): string[] {
    const cwd = "/home/user/project"
    const agentDir = "/home/user/.pi/agent"
    const trustedRoots = getTrustedRoots(cwd, agentDir)

    return extractSuspiciousPathsFromCommand(command, cwd, trustedRoots).map((p) => p.original)
}

const commands = [
    {
        cmd: "rg '/foo|bar/' src/",
        expectSuspicious: [],
        description: "Ripgrep with alternation pattern",
    },
    {
        cmd: "rg -e '/(start|end)+$/' --glob '*.rs'",
        expectSuspicious: [],
        description: "Ripgrep with complex regex and glob",
    },
    {
        cmd: "rg 'pattern' /etc/passwd",
        expectSuspicious: ["/etc/passwd"],
        description: "Ripgrep searching in system file (should warn)",
    },
    {
        cmd: "rg --pcre2 '/^test{2,}/' .",
        expectSuspicious: [],
        description: "Ripgrep with repetition quantifier",
    },
    {
        cmd: "sed 's/foo/bar/g' /tmp/file.txt",
        expectSuspicious: [],
        description: "Sed with substitution (pattern OK, /tmp is trusted)",
    },
    {
        cmd: "find /usr/local -name '*.so'",
        expectSuspicious: ["/usr/local"],
        description: "Find in system directory (should warn)",
    },
    {
        cmd: "rg 'test' ../parent/file",
        expectSuspicious: ["../parent/file"],
        description: "Ripgrep with parent directory (should warn)",
    },
    {
        cmd: "rg '/[a-z]+/' --glob '*.txt' src/",
        expectSuspicious: [],
        description: "Regex with character class and quantifier",
    },
    {
        cmd: "cat ~/secrets.txt",
        expectSuspicious: ["~/secrets.txt"],
        description: "Cat with home expansion (should warn)",
    },
    {
        cmd: "rg 'import' --glob '*.rs' src/ test/",
        expectSuspicious: [],
        description: "Ripgrep with multiple relative dirs (OK)",
    },
]

console.log("Testing ripgrep command pattern detection\n")
console.log("=".repeat(80))

let passed = 0
let failed = 0

for (const test of commands) {
    const actual = extractSuspiciousTokens(test.cmd)
    const expectedSet = new Set(test.expectSuspicious)

    const match =
        actual.length === test.expectSuspicious.length && actual.every((t) => expectedSet.has(t))

    const result = match ? "✓ PASS" : "✗ FAIL"

    if (match) {
        passed++
    } else {
        failed++
    }

    console.log(`\n${result} | ${test.description}`)
    console.log(`  Command: ${test.cmd}`)
    console.log(`  Expected suspicious: [${test.expectSuspicious.join(", ")}]`)
    console.log(`  Actual suspicious:   [${actual.join(", ")}]`)
}

console.log("\n" + "=".repeat(80))
console.log(`\nResults: ${passed} passed, ${failed} failed out of ${commands.length} tests`)

if (failed > 0) {
    process.exit(1)
}
