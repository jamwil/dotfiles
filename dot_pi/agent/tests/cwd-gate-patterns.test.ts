/**
 * Unit tests for cwd-gate pattern/path detection logic.
 *
 * Exercises the real functions exported from the extension lib module.
 */

import {
    looksLikePossiblyDangerousPathToken,
    looksLikeRegexNotPath,
} from "../extensions/lib/cwd-gate-patterns"

const testCases = [
    // Real paths - should be DANGEROUS
    { input: "/etc/passwd", expectDangerous: true, category: "Real root path" },
    {
        input: "/home/user/file.txt",
        expectDangerous: true,
        category: "Real absolute path",
    },
    { input: "~/config", expectDangerous: true, category: "Home expansion" },
    {
        input: "../other",
        expectDangerous: true,
        category: "Relative parent path",
    },
    { input: "/tmp/test", expectDangerous: true, category: "Temp path" },

    // Regex patterns - should NOT be dangerous
    {
        input: "/foo|bar/",
        expectDangerous: false,
        category: "Regex alternation",
    },
    {
        input: "/pattern+/",
        expectDangerous: false,
        category: "Regex quantifier +",
    },
    {
        input: "/test{2,3}/",
        expectDangerous: false,
        category: "Regex repetition",
    },
    { input: "/(group)/", expectDangerous: false, category: "Regex grouping" },
    { input: "/^start/", expectDangerous: false, category: "Regex anchor ^" },
    { input: "/end$/", expectDangerous: false, category: "Regex anchor $" },
    {
        input: "/(foo|bar)+$/",
        expectDangerous: false,
        category: "Complex regex",
    },
    {
        input: "s/foo/bar/",
        expectDangerous: false,
        category: "Sed substitution",
    },
    {
        input: "y/abc/xyz/",
        expectDangerous: false,
        category: "Sed transliteration",
    },

    // Path globs - should be DANGEROUS (glob doesn't mean regex)
    {
        input: "/usr/lib*",
        expectDangerous: true,
        category: "Path with glob *",
    },
    {
        input: "/tmp/file?.txt",
        expectDangerous: true,
        category: "Path with glob ?",
    },
    {
        input: "/etc/[a-z]*",
        expectDangerous: true,
        category: "Path with glob []",
    },

    // Edge cases
    {
        input: "*.rs",
        expectDangerous: false,
        category: "Relative glob (no leading /)",
    },
    {
        input: "./local",
        expectDangerous: false,
        category: "Current dir relative",
    },
    {
        input: "relative/path",
        expectDangerous: false,
        category: "Simple relative path",
    },
    { input: "", expectDangerous: false, category: "Empty string" },
]

console.log("Testing cwd-gate pattern detection\n")
console.log("=".repeat(80))

let passed = 0
let failed = 0

for (const test of testCases) {
    const actual = looksLikePossiblyDangerousPathToken(test.input)
    const isRegex = looksLikeRegexNotPath(test.input)
    const result = actual === test.expectDangerous ? "✓ PASS" : "✗ FAIL"

    if (actual === test.expectDangerous) {
        passed++
    } else {
        failed++
    }

    console.log(`\n${result} | ${test.category}`)
    console.log(`  Input: "${test.input}"`)
    console.log(`  Expected dangerous: ${test.expectDangerous}, Actual: ${actual}`)
    console.log(`  Detected as regex: ${isRegex}`)
}

console.log("\n" + "=".repeat(80))
console.log(`\nResults: ${passed} passed, ${failed} failed out of ${testCases.length} tests`)

if (failed > 0) {
    process.exit(1)
}
