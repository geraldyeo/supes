# Supes — Claude Code Plugin

Bridge plugin routing ECC domain capabilities into Superpowers pipeline stages.

---

## What this repo is

A Claude Code plugin (`geraldyeo/supes`). It has no build step, no package manager, no compiled output. Everything is plain bash and markdown.

---

## Key constraint

**Never fork or copy files from Superpowers (`obra/superpowers`) or ECC (`affaan-m/everything-claude-code`).**
Bridge skills reference ECC skills and agents by name only. Routing defaults live in `docs/routing-defaults.md` and the hook — nowhere else.

---

## Directory roles

| Path | Role |
|---|---|
| `.claude-plugin/metadata.json` | Plugin identity — id must stay `geraldyeo/supes` (lowercase) |
| `hooks/session-start` | Core hook: stack detection, CLAUDE.md parsing, context injection |
| `hooks/hooks.json` | Wires session-start to SessionStart lifecycle event |
| `skills/bridge-*/skill.md` | Thin ECC routing selectors — no domain knowledge, just routing |
| `docs/routing-defaults.md` | Single source of truth for stack → ECC skill mappings per stage |
| `docs/CLAUDE.md.template` | Annotated reference for per-project overrides |
| `tests/session_start.bats` | bats-core tests for the session-start hook |
| `tests/test_helper.bash` | bats setup/teardown — uses `TEST_TMPDIR` (not `TMPDIR`, system collision) |

---

## Sync requirement

`docs/routing-defaults.md` and `get_defaults()` in `hooks/session-start` must stay in sync. When adding a new stack or changing skill names, update both in the same commit. The execute stage for all stacks is `multi-execute autonomous-loops`.

---

## Testing

Uses [bats-core](https://github.com/bats/bats-core). Run all tests:

```bash
bats tests/session_start.bats
```

The hook has two test-only entry points:
- `--detect-only`: returns space-separated stack tokens from file-based detection (skips `stack:` override — tests file detection in isolation)
- `--parse-only <stage>`: applies `stack:` override + returns merged skill list for a stage

All 22 tests must pass before committing changes to the hook or routing defaults.

---

## Hook output format

The session-start hook must output valid JSON matching Claude Code's hook schema:

```json
{"additionalContext": "...", "hookSpecificOutput": {"additionalContext": "..."}}
```

The `additionalContext` value starts with `EXTREMELY_IMPORTANT: Supes routing active.`

---

## Bridge skill rules

Each bridge skill (`skills/bridge-*/skill.md`) follows a strict 4-step pattern:
1. Read stack + routing from session context
2. Load mapped ECC skills (domain knowledge lives in ECC, not here)
3. Note ECC agent availability
4. Yield to the corresponding Superpowers stage skill

**No domain guidance in bridge skills.** Their role is routing only.

---

## Valid stack tokens

Auto-detected: `node` `typescript` `react` `next` `python` `django` `go` `rust` `java` `spring`

The `stack:` override in a project's CLAUDE.md must use only these tokens. `postgresql`, `react-typescript`, and other compound names are not valid.

---

## Merge modes (supes block)

| Syntax | Behaviour |
|---|---|
| `tdd: skill-x` | Additive — appends to defaults |
| `tdd: -skill-y skill-x` | Removal — strips skill-y, adds skill-x |
| `tdd!: skill-x` | Replace — ignores defaults entirely |

First occurrence of a stage key wins; duplicates are ignored.

---

## What NOT to change

- The `EXTREMELY_IMPORTANT` prefix in the injected context (Superpowers depends on this pattern)
- The `hooks.json` event name `SessionStart` (Claude Code lifecycle API)
- The plugin id `geraldyeo/supes` — lowercase, no capital S
