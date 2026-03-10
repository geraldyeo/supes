# Supes

A bridge plugin for [Claude Code](https://claude.ai/code) that routes
[ECC](https://github.com/affaan-m/everything-claude-code) domain capabilities
into [Superpowers](https://github.com/obra/superpowers) pipeline stages.

Zero config. Auto-detects your stack. Override per-project via a single
`CLAUDE.md` block.

---

## Requirements

Install all three plugins:

```
/plugin marketplace add obra/superpowers
/plugin marketplace add affaan-m/everything-claude-code
/plugin marketplace add geraldyeo/supes
```

---

## How it works

Supes injects routing context at session start. Claude enters every session
knowing which ECC skills and agents apply to the current project at each
Superpowers stage:

```
brainstorming           → bridge-brainstorm  (ECC domain context + architect agent)
writing-plans           → bridge-plan        (ECC patterns + planner agent)
test-driven-development → bridge-tdd         (stack-specific testing skills + tdd-guide)
requesting-code-review  → bridge-review      (security + language reviewers)
executing-plans         → bridge-execute     (multi-execute + chief-of-staff)
```

Superpowers still enforces the pipeline. ECC still owns domain knowledge.
Supes just wires them together.

---

## Configuration tiers

| Situation | What you do | What Supes does |
|---|---|---|
| No CLAUDE.md supes block | Nothing | Auto-detect stack, apply defaults |
| Add `stack:` line | Declare stack explicitly | Use your declaration, apply defaults |
| Add stage lines | List extra or replacement skills | Merge with defaults |

### Three merge modes

````
```supes
# Additive (default): appended to defaults
tdd: my-custom-skill

# Removal: strip a default with - prefix
tdd: -django-security my-custom-skill

# Replace: ignore defaults entirely for this stage
tdd!: my-custom-skill
```
````

Skill names can be from ECC, Superpowers, another plugin, or `~/.claude/skills/`.

---

## Default routing

See [docs/routing-defaults.md](docs/routing-defaults.md) for the full default
mapping table — which stacks map to which ECC skills at each stage.

Detected stacks: `node` `react` `next` `python` `django` `go` `rust` `java` `spring`

---

## Team setup

1. Teammates install all three plugins (Superpowers, ECC, Supes)
2. Copy the supes block from [docs/CLAUDE.md.template](docs/CLAUDE.md.template) into the project `CLAUDE.md`
3. Done — no other setup

---

## Updates

```bash
/plugin update obra/superpowers
/plugin update affaan-m/everything-claude-code
/plugin update geraldyeo/supes
```

Each updates independently. Supes never touches Superpowers or ECC files.
After updating ECC, verify `docs/routing-defaults.md` still matches ECC skill names.

---

## /supes-check (planned)

A future `/supes-check` command will validate all skill names in the active
routing manifest, catching stale ECC references before they cause confusion.
