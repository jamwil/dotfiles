# Pi Agent Tests

Test suites for pi agent extensions and utilities.

Tests import directly from the extension lib modules (`extensions/lib/`),
so they exercise the **real production code** — not duplicated logic.

## Running Tests

Run all tests:

```bash
npm test
```

Or run individual test files:

```bash
npm run test:cwd-patterns
npm run test:cwd-commands
npm run test:permission
```

## Test Files

- **cwd-gate-patterns.test.ts** — Unit tests for path/regex detection (`extensions/lib/cwd-gate-patterns.ts`)
- **cwd-gate-commands.test.ts** — Integration tests with realistic shell commands (`extensions/lib/cwd-gate-patterns.ts`)
- **permission-gate-patterns.test.ts** — Dangerous-command pattern matching (`extensions/lib/permission-gate-patterns.ts`)

## Architecture

```
extensions/
├── cwd-gate.ts              ← extension entry point (thin wrapper)
├── permission-gate.ts       ← extension entry point (thin wrapper)
└── lib/
    ├── cwd-gate-patterns.ts       ← pure testable logic
    └── permission-gate-patterns.ts ← pure testable logic

tests/
├── cwd-gate-patterns.test.ts     ← imports from extensions/lib/
├── cwd-gate-commands.test.ts      ← imports from extensions/lib/
└── permission-gate-patterns.test.ts ← imports from extensions/lib/
```

## Adding Tests

Tests use plain TypeScript with the `tsx` runner. Each test file should:

1. Import the real logic from `../extensions/lib/`
2. Define test cases with expected behavior
3. Exit with status 1 on failure
