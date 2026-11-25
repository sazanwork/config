# Decisions

## Index

| Decision | Summary |
|---|---|
| [base-and-presets](#base-and-presets) | A neutral common base supports environment-specific presets. |
| [published-package](#published-package) | Consumers install a versioned npm configuration package. |

## Active decisions

### base-and-presets

Biome and TypeScript use a strict shared base and small presets for React,
Astro, Node, and bundlers. Consumers opt into their own environment. This keeps
JSX rules out of server-only projects and makes each consumer's setup explicit.

### published-package

Consumers install the shared configurations as `@mikitasazan/config`. The
package removes the need to read a config file from outside the repository.
Local installs, CI, and fresh clones resolve the same package exports with
any home directory layout.
