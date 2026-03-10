# Supes — Design Document
_2026-03-10_

## Problem

[Superpowers](https://github.com/obra/superpowers) enforces a disciplined development pipeline (brainstorm → worktree → plan → execute → TDD → review → finish) but provides only generic guidance at each stage.

[Everything Claude Code (ECC)](https://github.com/affaan-m/everything-claude-code) provides rich domain capabilities — 65+ skills, 16 specialised agents, ambient quality hooks — but no enforced workflow.

The goal: a thin bridge plugin (`geraldyeo/supes`) that routes ECC domain capabilities into Superpowers pipeline stages, without forking either repo.

---

## Constraints

- Must not fork or copy files from Superpowers or ECC
- Must stay updatable independently when either source updates
- Team use via per-project `CLAUDE.md` — teammates install three plugins, no other setup
- Personal `~/.claude/` setup first; team promotion is the upgrade path

---

## Architecture

Supes sits as an orchestration layer between Superpowers and ECC:

```
Superpowers Plugin     ECC Plugin             Supes Plugin
┌──────────────┐      ┌──────────────┐       ┌────────────────────┐
│ Stage skills │      │ Domain skills│       │ session-start hook │
│ (brainstorm, │      │ (django-tdd, │◄──────│ (reads CLAUDE.md,  │
│  tdd, review,│      │  go-review,  │       │  injects routing)  │
│  plan, etc.) │      │  security,   │       │                    │
│              │      │  architect)  │       │ bridge skills      │
│ Pipeline     │      │ Agents       │◄──────│ (ECC selectors,    │
│ enforcement  │      │ Ambient hooks│       │  not domain guides)│
└──────────────┘      └──────────────┘       │                    │
        │                    ▲               │ hooks.json         │
        └────────────────────┘               │ (ambient ECC hooks)│
              Routes via                     └────────────────────┘
              session context
```

Supes owns three things:
1. **Session-start hook** — reads project `CLAUDE.md`, injects routing manifest as `EXTREMELY_IMPORTANT` context
2. **Bridge skills** — thin ECC capability selectors that yield to Superpowers stage skills
3. **Hook configuration** — activates a curated subset of ECC ambient hooks

---

## Directory Structure

```
Supes/
├── .claude-plugin/
│   └── metadata.json
├── skills/
│   ├── bridge-brainstorm/skill.md
│   ├── bridge-plan/skill.md
│   ├── bridge-tdd/skill.md
│   ├── bridge-review/skill.md
│   └── bridge-execute/skill.md
├── hooks/
│   ├── hooks.json
│   └── session-start
├── docs/
│   ├── plans/
│   │   └── (this file)
│   ├── routing-defaults.md    # full default mapping table, versioned
│   └── CLAUDE.md.template     # annotated reference for per-project overrides
└── README.md
```

No agents directory — Supes delegates to ECC's existing agents by name.

---

## Session-Start Hook

### Behaviour

1. Auto-detects project stack from files present in working directory:

| File | Detected stack tokens |
|---|---|
| `package.json` | `typescript`, `node` |
| `package.json` + React dep | `react-typescript` |
| `requirements.txt` / `pyproject.toml` | `python` |
| `manage.py` | `django` |
| `go.mod` | `go` |
| `Cargo.toml` | `rust` |
| `build.gradle` | `java`, `spring` |

2. Applies default ECC skill routing for detected stack (see `docs/routing-defaults.md`)
3. Reads `supes` fenced block from `CLAUDE.md` if present, merges overrides
4. Injects combined routing manifest as `EXTREMELY_IMPORTANT` session context

If no `CLAUDE.md` or no `supes` block: auto-detection only, silent on missing block. Zero breakage for non-Supes projects.

### Injected Context Format

```
EXTREMELY_IMPORTANT: Supes routing active.
Stack: [detected tokens]

At each Superpowers stage, invoke the corresponding bridge skill FIRST:
  brainstorming           → bridge-brainstorm  (ECC: <skills>, agent: architect)
  writing-plans           → bridge-plan        (ECC: <skills>, agent: planner)
  test-driven-development → bridge-tdd         (ECC: <skills>, agent: tdd-guide)
  requesting-code-review  → bridge-review      (ECC: <skills>, agent: code-reviewer)
  executing-plans         → bridge-execute     (ECC: <skills>, agent: chief-of-staff)

ECC ambient hooks active: quality-gate, auto-format, session-memory, cost-tracking.
```

### supes Block Format

````markdown
```supes
stack: python django postgresql     # optional: override auto-detection

# Additive (default): appends skill-x to detected defaults
tdd: skill-x

# Removal: strip skill-y from defaults, add skill-x
tdd: -skill-y skill-x

# Replace: ignore defaults entirely for this stage
tdd!: skill-x
```
````

All skill names are resolved by Claude at runtime — any plugin, personal `~/.claude/skills/`, or ECC skill is valid. The hook does not validate names.

---

## Bridge Skills

Each bridge skill is a thin selector — no domain knowledge, just routing logic:

```
1. Read stack + routing from session context
2. Invoke mapped ECC skills (domain knowledge lives in ECC)
3. Invoke ECC agent if applicable
4. Yield to the corresponding Superpowers stage skill
```

| Bridge Skill | ECC Skills | ECC Agent | Yields To |
|---|---|---|---|
| `bridge-brainstorm` | `ai-first-engineering`, stack's design skill | `architect` | Superpowers `brainstorming` |
| `bridge-plan` | `backend-patterns`, `deployment-patterns`, stack's data skill | `planner` | Superpowers `writing-plans` |
| `bridge-tdd` | stack-specific testing skill + `security-scan` | `tdd-guide` | Superpowers `test-driven-development` |
| `bridge-review` | `security-review` + stack-specific reviewer | `code-reviewer` + lang reviewer | Superpowers `requesting-code-review` |
| `bridge-execute` | `multi-execute`, `autonomous-loops` | `chief-of-staff` | Superpowers `executing-plans` |

Bridge skills never contain domain knowledge. ECC skill updates flow through automatically.

---

## Hook Configuration

`hooks.json` activates a curated subset of ECC ambient hooks:

| Hook | Trigger | Rationale |
|---|---|---|
| Auto-format (JS/TS) | PostToolUse / Edit | Code quality baseline |
| TypeScript check | PostToolUse / `.ts/.tsx` | Catch type errors immediately |
| Quality gate | PostToolUse / Edit+Write | Fast feedback loop |
| Session memory | Stop | Continuity across sessions |
| Pattern extraction | Stop | Feeds continuous learning |
| Cost tracker | Stop | Token spend visibility |
| Strategic compact | PreToolUse ~50 calls | Prevents context bloat |

**Not included:** dev server blocker (tmux-specific), git push reminder (Superpowers governs branch workflow), PR logger (Superpowers `finishing-a-development-branch` handles this).

`ECC_HOOK_PROFILE` and `ECC_DISABLED_HOOKS` env vars still work — Supes does not override them.

---

## Update Strategy

| Source | Update command | Impact on Supes |
|---|---|---|
| Superpowers | `/plugin update obra/superpowers` | None — Supes never touches SP files |
| ECC | `/plugin update affaan-m/everything-claude-code` | None — bridge skills reference by name only |
| Supes | `/plugin update geraldyeo/supes` | Updates routing defaults, bridge skills, hooks |
| Project `CLAUDE.md` | Edit + commit in project repo | Affects only that project |

**Maintenance risk:** `docs/routing-defaults.md` can go stale if ECC renames skills. Mitigation:
- `routing-defaults.md` is the single source of truth for all default mappings
- README notes to verify it after ECC updates
- Future: `/supes-check` slash command validates all skill names in the active routing manifest

---

## Documentation Plan

| File | Contents |
|---|---|
| `README.md` | Installation, three-tier config model, all auto-detected stacks, quick-start |
| `docs/routing-defaults.md` | Full stack → ECC skill mapping table per stage, versioned with the hook |
| `docs/CLAUDE.md.template` | Annotated reference showing all override options with examples |
| `hooks/session-start` | Inline comments on each detection step |

---

## Team Promotion Path

1. Teammates install three plugins: Superpowers, ECC, Supes
2. Copy `docs/CLAUDE.md.template` snippet into project `CLAUDE.md`, fill in stack
3. Done — zero other setup

Future: if a team wants stronger defaults, publish a team fork of Supes with custom `routing-defaults.md`.
