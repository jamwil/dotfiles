/**
 * Unit tests for cwd-gate pattern/path detection logic.
 *
 * Exercises the real functions exported from the extension lib module.
 */

import {
    looksLikePossiblyDangerousBashPathToken,
    looksLikePossiblyDangerousPathToken,
    looksLikeRegexNotPath,
} from "../extensions/lib/cwd-gate-patterns"

const nativeTestCases = [
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
    {
        input: "C:\\Users\\me\\file.txt",
        expectDangerous: true,
        category: "Native Windows absolute path",
    },
    {
        input: "\\\\server\\share\\file.txt",
        expectDangerous: true,
        category: "UNC path",
    },

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

const bashTestCases = [
    { input: "/etc/passwd", expectDangerous: true, category: "POSIX absolute path" },
    { input: "~/config", expectDangerous: true, category: "Bash home expansion" },
    { input: "../other", expectDangerous: true, category: "Bash parent relative" },
    {
        input: '"quoted"',
        expectDangerous: false,
        category: "Quoted string is not a path",
    },
    {
        input: '\\"quoted\\"',
        expectDangerous: false,
        category: "Escaped quotes are not a bash path",
    },
    {
        input: "C:\\Users\\me\\file.txt",
        expectDangerous: false,
        category: "Backslash Windows path is not treated as bash path",
    },
    {
        input: "\\\\server\\share\\file.txt",
        expectDangerous: false,
        category: "UNC-style backslash path is not treated as bash path",
    },
    {
        input: "C:/Users/me/file.txt",
        expectDangerous: true,
        category: "Forward-slash drive path still counts as bash path",
    },
    { input: "src/file.ts", expectDangerous: false, category: "Relative file within cwd" },
    { input: "", expectDangerous: false, category: "Empty string" },
]

function runSuite(
    title: string,
    cases: { input: string; expectDangerous: boolean; category: string }[],
    detector: (token: string) => boolean,
) {
    console.log(`Testing ${title}\n`)
    console.log("=".repeat(80))

    let passed = 0
    let failed = 0

    for (const test of cases) {
        const actual = detector(test.input)
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
    console.log(`\nResults: ${passed} passed, ${failed} failed out of ${cases.length} tests`)

    if (failed > 0) {
        process.exit(1)
    }

    console.log("\n")
}

runSuite("cwd-gate native pattern detection", nativeTestCases, looksLikePossiblyDangerousPathToken)
runSuite("cwd-gate bash pattern detection", bashTestCases, looksLikePossiblyDangerousBashPathToken)
