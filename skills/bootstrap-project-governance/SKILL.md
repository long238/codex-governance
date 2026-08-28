---
name: bootstrap-project-governance
description: Inspect a current or explicitly named local project and propose a project-level Codex governance pack without importing unrelated project logic. Use only when explicitly invoked to bootstrap or merge AGENTS.md and governance docs; never write on the first pass.
---

# Bootstrap Project Governance

Create or merge project-level Codex governance only after a read-only proposal and a separate approval.

## Resolve the target

1. If the user supplied an absolute target directory, resolve and use that exact directory.
2. Otherwise, ask Git for the root containing the current working directory. If no Git root exists, use the current working directory itself.
3. If the user supplied only a relative or ambiguous path, pause and request an absolute path. Do not guess among similarly named folders.
4. State the resolved absolute target before inspecting it.
5. Never initialize Git as part of this workflow.

## Enforce boundaries

- Operate only on the resolved target directory.
- Do not modify global Codex files, user configuration, this Skill's installation, or any sibling project.
- Do not inspect or modify nested `AGENTS.md` files unless the user explicitly adds that nested scope.
- Do not copy framework choices, domain terms, concrete types, product paths, storage structures, test names, or delivery rules from another project.
- Treat unknown project facts as `待确认`; do not turn examples or recommendations into current facts.
- Follow any governing instructions already active for the target project.

## Load the governance model

Read [references/governance-model.md](references/governance-model.md) completely before preparing a proposal. Read only the candidate files under [assets/project-governance](assets/project-governance) that are needed for the proposed target files.

The assets are source material, not files to copy blindly. Adapt them to evidence found in the target and preserve the distinction between current facts and future recommendations.

## Inspect the target read-only

Use the smallest useful inspection:

1. Check whether the target is a Git repository and, when it is, record its root and current status without changing either.
2. Inspect the root `AGENTS.md` or equivalent project instructions if present.
3. Inspect the main README, root build manifests, continuous-integration configuration, obvious test entry points, and the existing `docs/` structure.
4. Use existing documentation routing when one exists. Do not recursively load all documentation.
5. Identify evidence for actual build, test, architecture, dependency, release, and contribution practices. Leave anything unproven as `待确认`.

## Present the first-pass proposal

Do not write files during the first pass, even if the initial invocation also asks to apply the template. Return four clearly separated sections:

- `保留`：existing rules and files that should remain unchanged or be incorporated.
- `建议新增`：candidate files and generic rules that fill demonstrated gaps.
- `冲突`：existing rules that conflict with the candidate governance model or with each other; do not resolve them silently.
- `待确认`：project facts or choices that cannot be proved from the target.

Also provide:

- the exact target path;
- the exact candidate file list;
- whether each file would be created, merged, or left unchanged;
- a concise validation plan;
- an explicit statement that no files have been changed.

When no governance files exist, show the candidate file set and the adaptations needed. When governance files already exist, propose a merge that preserves unknown and project-specific rules. Never propose wholesale replacement merely because the candidate template is newer.

## Require a separate approval

After presenting the proposal, stop and wait for a new, explicit approval to write the listed files. Acknowledgement of the analysis is not approval. If the approved scope or target changes, update the proposal before writing.

## Apply an approved proposal

When a separate approval is received:

1. Recheck the target status and the files to be edited. If they changed since the proposal or contain overlapping work, stop and report the conflict.
2. Create or merge only the approved files, preferably with patch-based edits.
3. Preserve existing unknown or project-specific constraints unless the user explicitly approved their removal.
4. Do not create `.codex/worklogs/` during initialization. The target `AGENTS.md` defines when a real task may create it and how it remains local.
5. Do not create nested instruction files, initialize Git, stage, commit, push, or alter remotes.

## Validate and report

- Check relative links among generated governance files.
- Search for unresolved template markers and unrelated project terminology.
- In a Git target, run `git diff --check` and review only the resulting governance diff.
- State which checks passed, failed, or were not run.
- List every changed file and remind the user that the target project was not committed automatically.
