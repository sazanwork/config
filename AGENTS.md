# config

Shared lint, format and TypeScript configs for the owner's projects. Read `README.md` first.
`npm test` runs the smoke and integration tests (`test/smoke.sh`, `test/integration.sh`).

## Parallel lanes
- Lane env: none; there is no database or port. Acceptance setup: `npm ci --ignore-scripts`.
- Gates: `npm test`.
- Merge setup: `npm ci --ignore-scripts`.
- Merge gates: `npm test`.
- A lane never publishes to npm, never pushes tags, never touches another repository.
