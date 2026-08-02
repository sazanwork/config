---
name: github-product-delivery
description: Operate a lightweight product-delivery system in GitHub Projects across product, engineering, design, growth, legal, and operations. Use when Codex needs to set up or audit a GitHub Project, capture or triage work, create initiatives and sub-issues, plan iterations, assign a DRI, manage dependencies, prepare reviews and releases, or produce weekly delivery reports for a small cross-functional team.
---

# GitHub Product Delivery

Run the team's product-delivery workflow through GitHub Issues, Projects, pull requests, milestones, iterations, and dependencies.

## Start every task

1. Locate `.github/product-delivery.toml` from the repository root. If it is absent, search parent or dedicated configuration repositories before proposing a new file.
2. Read `references/workflow.md` before changing project structure, statuses, priorities, iterations, milestones, or ownership.
3. Verify GitHub CLI access with `gh auth status`. Project operations require the `project` scope; request it with `gh auth refresh -s project` when missing.
4. Inspect the current state before writing. Never assume field IDs, option IDs, project numbers, repository ownership, issue types, milestones, or iteration IDs.
5. Prefer bundled scripts for deterministic setup and field updates. Use direct `gh` commands only when the scripts do not cover the operation.

## Select the operation

- **setup / repair**: run `scripts/bootstrap_project.py --config .github/product-delivery.toml`; then run `scripts/projectctl.py audit`.
- **intake**: create a structured issue, add it to the configured Project, and set `Status=Triage`.
- **triage**: inspect new items, detect duplicates, fill missing metadata, and recommend `Backlog`, `Ready`, `Duplicate`, `Not planned`, or `Need information`.
- **create initiative**: create a measurable outcome with scope, non-goals, success criteria, risks, dependencies, and child work.
- **decompose**: split `L` work into independently verifiable `S` or `M` sub-issues; preserve one clear outcome in the parent.
- **plan iteration**: select only `Ready` and unblocked work, respect one primary `In Progress` item per person, and show capacity or dependency risks before mutating.
- **start work**: assign one DRI, move the item to `In Progress`, create or identify the implementation branch, and keep the issue linked to the pull request.
- **prepare review**: verify acceptance criteria, tests or evidence, linked PR/design/document, and move to `In Review` only when reviewable.
- **release audit**: inspect a milestone for incomplete, blocked, unreviewed, or unlinked work and produce a go/no-go summary.
- **weekly report**: report completed, active, review-waiting, blocked, release risks, required decisions, and proposed next actions.

## Canonical model

Use exactly one canonical location for each fact:

- state → Project `Status`
- urgency → `Priority`
- rough effort → `Size`
- functional ownership → `Area`
- active planning window → `Iteration`
- release commitment → repository `Milestone`
- large outcome → `Initiative`
- composition of work → sub-issues
- primary accountability → one assignee / DRI
- blockage → GitHub dependency relationship; use a `blocked` label only as a compatibility fallback
- implementation → linked pull request

Do not duplicate Project fields with labels. Labels are allowed only for issue-type compatibility in user-owned repositories and for exceptional operational markers defined in the config.

## Mutation rules

Before a batch mutation, print a compact plan listing targets and intended changes. Proceed autonomously for reversible, in-scope changes. Stop before destructive or governance-changing actions.

Never:

- create or delete an organization;
- delete a Project, issue, milestone, branch, or field;
- rewrite priorities or target dates without explicit product authority;
- invent deadlines, assignees, acceptance criteria, or legal conclusions;
- move an item to `Ready` without acceptance criteria and resolved product decisions;
- plan an `L` item without decomposition;
- close an issue merely because a PR was opened;
- merge a PR unless the user explicitly asks for the merge;
- silently carry unfinished work into the next iteration.

Archive instead of delete. Preserve existing field option IDs when updating a populated Project.

## Readiness gates

An item may enter `Ready` only when it has:

- a specific expected outcome;
- testable acceptance criteria;
- `Priority`, `Area`, and `Size`;
- `Size` equal to `S` or `M`;
- identified dependencies;
- a design link for UI work;
- no unresolved product decision.

## Completion gates

Apply the domain-specific Definition of Done in `references/workflow.md`. Close an issue only after the result is accepted and all follow-up work has its own issue.

## Output requirements

After every operation, state:

1. what was inspected;
2. what changed, with issue/PR/Project links;
3. what was not changed and why;
4. risks or decisions requiring a human owner;
5. the next recommended action.
