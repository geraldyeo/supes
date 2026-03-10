# Supes Bridge Plugin Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Build the Supes Claude Code plugin — a thin bridge that routes ECC domain capabilities into Superpowers pipeline stages via zero-config stack detection and a merge-based `supes` CLAUDE.md block.

**Architecture:** A session-start bash hook reads the project's files to auto-detect stack, merges any `supes` block overrides from `CLAUDE.md`, then injects routing context as `EXTREMELY_IMPORTANT` before Superpowers' own injection. Five bridge skills act as thin ECC capability selectors. A curated `hooks.json` activates ECC ambient hooks.

**Tech Stack:** Bash (session-start hook), JSON (metadata + hooks config), Markdown (skills, docs), bats-core (hook unit tests)

---

### Task 1: Plugin scaffold

**Files:**
- Create: `.claude-plugin/metadata.json`
- Create: `tests/` (empty dir with `.gitkeep`)

**Step 1: Create plugin metadata**

```json
{
  "name": "Supes",
  "id": "geraldyeo/supes",
  "version": "0.1.0",
  "description": "Bridge plugin routing ECC domain capabilities into Superpowers pipeline stages. Zero-config stack detection with per-project CLAUDE.md overrides.",
  "author": "geraldyeo",
  "platforms": ["claude-code"]
}
```

Write to `.claude-plugin/metadata.json`.

**Step 2: Create tests directory**

```bash
mkdir -p tests && touch tests/.gitkeep
```

**Step 3: Commit**

```bash
git add .claude-plugin/metadata.json tests/.gitkeep
git commit -m "feat: add plugin scaffold"
```

---

### Task 2: Routing defaults document

**Files:**
- Create: `docs/routing-defaults.md`

This is the single source of truth for default ECC skill mappings. The session-start hook must match this exactly. Update both together whenever defaults change.

**Step 1: Write routing-defaults.md**

```markdown
# Supes Routing Defaults

This table defines the default ECC skills invoked at each Superpowers stage for each detected stack.
Update this file and the session-start hook together — they must stay in sync.

## Detection Triggers

| File Present | Stack Tokens Added |
|---|---|
| `package.json` | `node` |
| `package.json` + `"react"` in deps | `react` |
| `package.json` + `"next"` in deps | `next` |
| `requirements.txt` or `pyproject.toml` | `python` |
| `manage.py` | `django` |
| `go.mod` | `go` |
| `Cargo.toml` | `rust` |
| `build.gradle` or `pom.xml` | `java` |
| `build.gradle` + `spring` in contents | `spring` |

## Default Stage Mappings

### python

| Stage | ECC Skills | ECC Agent |
|---|---|---|
| brainstorm | `ai-first-engineering` | `architect` |
| plan | `backend-patterns` | `planner` |
| tdd | `python-testing` | `tdd-guide` |
| review | `security-review`, `python-reviewer` | `code-reviewer` |
| execute | `multi-execute` | `chief-of-staff` |

### django (extends python)

| Stage | ECC Skills | ECC Agent |
|---|---|---|
| tdd | `django-tdd`, `python-testing`, `django-security` | `tdd-guide` |
| plan | `backend-patterns`, `database-migrations` | `planner` |

### go

| Stage | ECC Skills | ECC Agent |
|---|---|---|
| brainstorm | `ai-first-engineering` | `architect` |
| plan | `backend-patterns` | `planner` |
| tdd | `golang-testing` | `tdd-guide` |
| review | `security-review`, `go-reviewer` | `go-reviewer` |
| execute | `multi-execute` | `chief-of-staff` |

### node / typescript

| Stage | ECC Skills | ECC Agent |
|---|---|---|
| brainstorm | `ai-first-engineering` | `architect` |
| plan | `backend-patterns`, `api-design` | `planner` |
| tdd | `tdd-workflow` | `tdd-guide` |
| review | `security-review` | `code-reviewer` |
| execute | `multi-execute` | `chief-of-staff` |

### react (extends node/typescript)

| Stage | ECC Skills | ECC Agent |
|---|---|---|
| plan | `frontend-patterns`, `api-design` | `planner` |
| tdd | `tdd-workflow`, `e2e-testing` | `tdd-guide` |
| review | `security-review` | `code-reviewer` |

### rust

| Stage | ECC Skills | ECC Agent |
|---|---|---|
| brainstorm | `ai-first-engineering` | `architect` |
| plan | `backend-patterns` | `planner` |
| tdd | `tdd-workflow` | `tdd-guide` |
| review | `security-review` | `code-reviewer` |
| execute | `multi-execute` | `chief-of-staff` |

### java / spring

| Stage | ECC Skills | ECC Agent |
|---|---|---|
| brainstorm | `ai-first-engineering` | `architect` |
| plan | `backend-patterns`, `api-design` | `planner` |
| tdd | `springboot-tdd` | `tdd-guide` |
| review | `security-review`, `springboot-security` | `code-reviewer` |
| execute | `multi-execute` | `chief-of-staff` |

### fallback (no stack detected)

| Stage | ECC Skills | ECC Agent |
|---|---|---|
| brainstorm | `ai-first-engineering` | `architect` |
| plan | `backend-patterns` | `planner` |
| tdd | `tdd-workflow` | `tdd-guide` |
| review | `security-review` | `code-reviewer` |
| execute | `multi-execute` | `chief-of-staff` |
```

**Step 2: Commit**

```bash
git add docs/routing-defaults.md
git commit -m "docs: add routing defaults table"
```

---

### Task 3: Install bats-core for hook testing

**Files:**
- Create: `tests/test_helper.bash`

**Step 1: Install bats-core**

```bash
brew install bats-core
```

Expected: `bats --version` prints `Bats 1.x.x`

**Step 2: Create test helper**

```bash
# tests/test_helper.bash
# Sets up a temp project directory for each test.
# Usage: load 'test_helper' in each .bats file.

setup() {
  TMPDIR=$(mktemp -d)
  cd "$TMPDIR" || exit 1
}

teardown() {
  rm -rf "$TMPDIR"
}
```

**Step 3: Commit**

```bash
git add tests/test_helper.bash
git commit -m "test: add bats test helper"
```

---

### Task 4: Session-start hook — stack detection

**Files:**
- Create: `hooks/session-start`
- Create: `tests/session_start.bats`

**Step 1: Write failing tests for stack detection**

```bash
# tests/session_start.bats
#!/usr/bin/env bats

load 'test_helper'

HOOK="$BATS_TEST_DIRNAME/../hooks/session-start"

@test "detects node from package.json" {
  echo '{}' > package.json
  run bash "$HOOK" --detect-only
  [[ "$output" == *"node"* ]]
}

@test "detects react from package.json react dep" {
  echo '{"dependencies":{"react":"^18.0.0"}}' > package.json
  run bash "$HOOK" --detect-only
  [[ "$output" == *"react"* ]]
}

@test "detects python from requirements.txt" {
  touch requirements.txt
  run bash "$HOOK" --detect-only
  [[ "$output" == *"python"* ]]
}

@test "detects django from manage.py" {
  touch requirements.txt manage.py
  run bash "$HOOK" --detect-only
  [[ "$output" == *"django"* ]]
}

@test "detects go from go.mod" {
  touch go.mod
  run bash "$HOOK" --detect-only
  [[ "$output" == *"go"* ]]
}

@test "detects rust from Cargo.toml" {
  touch Cargo.toml
  run bash "$HOOK" --detect-only
  [[ "$output" == *"rust"* ]]
}

@test "returns fallback when no known files" {
  run bash "$HOOK" --detect-only
  [[ "$output" == *"fallback"* ]]
}
```

**Step 2: Run tests, verify they all fail**

```bash
bats tests/session_start.bats
```

Expected: all 7 tests FAIL (hook does not exist yet)

**Step 3: Create the hook with stack detection**

```bash
#!/usr/bin/env bash
# hooks/session-start
# Supes bridge plugin — session initialisation
# Detects project stack, merges supes block from CLAUDE.md, injects routing context.

set -euo pipefail

PLUGIN_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

# ── Stack detection ────────────────────────────────────────────────────────────

detect_stack() {
  local tokens=""

  if [[ -f "package.json" ]]; then
    tokens="$tokens node"
    grep -q '"react"' package.json 2>/dev/null && tokens="$tokens react"
    grep -q '"next"'  package.json 2>/dev/null && tokens="$tokens next"
  fi

  if [[ -f "requirements.txt" || -f "pyproject.toml" ]]; then
    tokens="$tokens python"
  fi

  [[ -f "manage.py" ]]            && tokens="$tokens django"
  [[ -f "go.mod" ]]               && tokens="$tokens go"
  [[ -f "Cargo.toml" ]]           && tokens="$tokens rust"
  [[ -f "build.gradle" || -f "pom.xml" ]] && tokens="$tokens java"

  if [[ -f "build.gradle" ]]; then
    grep -qi "spring" build.gradle 2>/dev/null && tokens="$tokens spring"
  fi

  # Trim and deduplicate
  echo "$tokens" | tr ' ' '\n' | grep -v '^$' | sort -u | tr '\n' ' ' | sed 's/ $//'
}

# ── Entry point for --detect-only flag (used by tests) ────────────────────────

if [[ "${1:-}" == "--detect-only" ]]; then
  result=$(detect_stack)
  [[ -z "$result" ]] && echo "fallback" || echo "$result"
  exit 0
fi
```

Make it executable:

```bash
chmod +x hooks/session-start
```

**Step 4: Run tests, verify they pass**

```bash
bats tests/session_start.bats
```

Expected: all 7 tests PASS

**Step 5: Commit**

```bash
git add hooks/session-start tests/session_start.bats
git commit -m "feat: add stack detection to session-start hook"
```

---

### Task 5: Session-start hook — supes block parsing

**Files:**
- Modify: `hooks/session-start`
- Modify: `tests/session_start.bats`

**Step 1: Write failing tests for supes block parsing**

Append to `tests/session_start.bats`:

```bash
@test "parses additive tdd from supes block" {
  touch go.mod
  cat > CLAUDE.md <<'EOF'
# My Project

```supes
tdd: my-custom-skill
```
EOF
  run bash "$HOOK" --parse-only tdd
  [[ "$output" == *"golang-testing"* ]]
  [[ "$output" == *"my-custom-skill"* ]]
}

@test "parses removal from supes block" {
  touch go.mod
  cat > CLAUDE.md <<'EOF'
```supes
tdd: -golang-testing my-custom-skill
```
EOF
  run bash "$HOOK" --parse-only tdd
  [[ "$output" != *"golang-testing"* ]]
  [[ "$output" == *"my-custom-skill"* ]]
}

@test "parses replace from supes block" {
  touch go.mod
  cat > CLAUDE.md <<'EOF'
```supes
tdd!: only-this-skill
```
EOF
  run bash "$HOOK" --parse-only tdd
  [[ "$output" == "only-this-skill" ]]
}

@test "returns defaults when no supes block present" {
  touch go.mod
  run bash "$HOOK" --parse-only tdd
  [[ "$output" == *"golang-testing"* ]]
}

@test "returns defaults when CLAUDE.md has no supes block" {
  touch go.mod
  echo "# Just a readme" > CLAUDE.md
  run bash "$HOOK" --parse-only tdd
  [[ "$output" == *"golang-testing"* ]]
}
```

**Step 2: Run new tests, verify they fail**

```bash
bats tests/session_start.bats
```

Expected: 5 new tests FAIL

**Step 3: Implement defaults lookup and supes block parsing**

Add to `hooks/session-start` after the `detect_stack` function:

```bash
# ── Default routing lookup ─────────────────────────────────────────────────────
# Returns space-separated skill names for a given stack + stage.
# Mirrors docs/routing-defaults.md exactly — update both together.

get_defaults() {
  local stack="$1" stage="$2"

  case "$stage" in
    brainstorm)
      echo "ai-first-engineering"
      ;;
    plan)
      if   [[ "$stack" == *django* ]]; then echo "backend-patterns database-migrations"
      elif [[ "$stack" == *react*  ]]; then echo "frontend-patterns api-design"
      elif [[ "$stack" == *spring* ]]; then echo "backend-patterns api-design"
      else                                   echo "backend-patterns"
      fi
      ;;
    tdd)
      if   [[ "$stack" == *django* ]]; then echo "django-tdd python-testing django-security"
      elif [[ "$stack" == *python* ]]; then echo "python-testing"
      elif [[ "$stack" == *go*     ]]; then echo "golang-testing"
      elif [[ "$stack" == *react*  ]]; then echo "tdd-workflow e2e-testing"
      elif [[ "$stack" == *spring* ]]; then echo "springboot-tdd"
      else                                   echo "tdd-workflow"
      fi
      ;;
    review)
      if   [[ "$stack" == *python* || "$stack" == *django* ]]; then echo "security-review python-reviewer"
      elif [[ "$stack" == *go*     ]]; then echo "security-review go-reviewer"
      elif [[ "$stack" == *spring* ]]; then echo "security-review springboot-security"
      else                                   echo "security-review"
      fi
      ;;
    execute)
      echo "multi-execute"
      ;;
    *)
      echo ""
      ;;
  esac
}

# ── supes block parser ─────────────────────────────────────────────────────────
# Reads CLAUDE.md, extracts the supes fenced block, applies merge logic.
# Merge modes: additive (default), removal (-skill), replace (stage!:)

get_stage_skills() {
  local stack="$1" stage="$2"
  local defaults
  defaults=$(get_defaults "$stack" "$stage")

  # No CLAUDE.md — return defaults
  [[ ! -f "CLAUDE.md" ]] && echo "$defaults" && return

  local block
  block=$(awk '/^```supes$/,/^```$/' CLAUDE.md | grep -v '^```')

  # No supes block — return defaults
  [[ -z "$block" ]] && echo "$defaults" && return

  # Check for replace mode (stage!:)
  local replace_line
  replace_line=$(echo "$block" | grep -E "^${stage}!:" | head -1)
  if [[ -n "$replace_line" ]]; then
    echo "$replace_line" | sed "s/^${stage}!://" | tr ',' ' ' | xargs
    return
  fi

  # Check for additive/removal mode (stage:)
  local override_line
  override_line=$(echo "$block" | grep -E "^${stage}:" | head -1)
  if [[ -z "$override_line" ]]; then
    echo "$defaults"
    return
  fi

  local overrides
  overrides=$(echo "$override_line" | sed "s/^${stage}://" | tr ',' ' ' | xargs)

  # Start from defaults, apply additions and removals
  local result="$defaults"
  for token in $overrides; do
    if [[ "$token" == -* ]]; then
      local remove="${token#-}"
      result=$(echo "$result" | tr ' ' '\n' | grep -v "^${remove}$" | tr '\n' ' ' | xargs)
    else
      result="$result $token"
    fi
  done

  echo "$result" | tr ' ' '\n' | grep -v '^$' | sort -u | tr '\n' ' ' | xargs
}

# ── Entry point for --parse-only flag (used by tests) ─────────────────────────

if [[ "${1:-}" == "--parse-only" ]]; then
  stage="${2:-tdd}"
  stack=$(detect_stack)
  [[ -z "$stack" ]] && stack="fallback"
  get_stage_skills "$stack" "$stage"
  exit 0
fi
```

**Step 4: Run all tests, verify they pass**

```bash
bats tests/session_start.bats
```

Expected: all 12 tests PASS

**Step 5: Commit**

```bash
git add hooks/session-start tests/session_start.bats
git commit -m "feat: add supes block parsing with merge/remove/replace modes"
```

---

### Task 6: Session-start hook — context injection

**Files:**
- Modify: `hooks/session-start`
- Modify: `tests/session_start.bats`

**Step 1: Write failing test for JSON output**

Append to `tests/session_start.bats`:

```bash
@test "outputs valid JSON with additionalContext" {
  touch go.mod
  run bash "$HOOK"
  echo "$output" | python3 -c "import sys,json; d=json.load(sys.stdin); assert 'additionalContext' in d"
}

@test "output contains Supes routing active" {
  touch go.mod
  run bash "$HOOK"
  [[ "$output" == *"Supes routing active"* ]]
}

@test "output contains bridge skill names for go stack" {
  touch go.mod
  run bash "$HOOK"
  [[ "$output" == *"bridge-tdd"* ]]
  [[ "$output" == *"golang-testing"* ]]
}
```

**Step 2: Run new tests, verify they fail**

```bash
bats tests/session_start.bats
```

Expected: 3 new tests FAIL

**Step 3: Implement context injection and JSON output**

Add to the end of `hooks/session-start`:

```bash
# ── JSON escaping ──────────────────────────────────────────────────────────────

escape_for_json() {
  local s="$1"
  s="${s//\\/\\\\}"
  s="${s//\"/\\\"}"
  s="${s//$'\n'/\\n}"
  s="${s//$'\r'/\\r}"
  s="${s//$'\t'/\\t}"
  printf '%s' "$s"
}

# ── Context builder ────────────────────────────────────────────────────────────

build_context() {
  local stack="$1"
  local display_stack="${stack:-fallback}"

  local brainstorm_skills plan_skills tdd_skills review_skills execute_skills
  brainstorm_skills=$(get_stage_skills "$stack" "brainstorm")
  plan_skills=$(get_stage_skills "$stack" "plan")
  tdd_skills=$(get_stage_skills "$stack" "tdd")
  review_skills=$(get_stage_skills "$stack" "review")
  execute_skills=$(get_stage_skills "$stack" "execute")

  cat <<EOF
EXTREMELY_IMPORTANT: Supes routing active.
Stack: ${display_stack}

At each Superpowers stage, invoke the corresponding Supes bridge skill FIRST:
  brainstorming           → bridge-brainstorm  (ECC: ${brainstorm_skills}, agent: architect)
  writing-plans           → bridge-plan        (ECC: ${plan_skills}, agent: planner)
  test-driven-development → bridge-tdd         (ECC: ${tdd_skills}, agent: tdd-guide)
  requesting-code-review  → bridge-review      (ECC: ${review_skills}, agent: code-reviewer)
  executing-plans         → bridge-execute     (ECC: ${execute_skills}, agent: chief-of-staff)

ECC ambient hooks active: quality-gate, auto-format, session-memory, cost-tracking.
EOF
}

# ── Main ───────────────────────────────────────────────────────────────────────

main() {
  local stack
  stack=$(detect_stack)

  local context
  context=$(build_context "$stack")

  local escaped
  escaped=$(escape_for_json "$context")

  printf '{"additionalContext": "%s", "hookSpecificOutput": {"additionalContext": "%s"}}' \
    "$escaped" "$escaped"
}

main
```

**Step 4: Run all tests, verify they pass**

```bash
bats tests/session_start.bats
```

Expected: all 15 tests PASS

**Step 5: Commit**

```bash
git add hooks/session-start tests/session_start.bats
git commit -m "feat: complete session-start hook with context injection"
```

---

### Task 7: hooks.json

**Files:**
- Create: `hooks/hooks.json`

**Step 1: Write hooks.json**

```json
{
  "hooks": {
    "SessionStart": [
      {
        "matcher": "",
        "hooks": [
          {
            "type": "command",
            "command": "\"${CLAUDE_PLUGIN_DIR}/hooks/session-start\"",
            "description": "Supes: inject stack-aware ECC routing into session context"
          }
        ]
      }
    ]
  }
}
```

Note: ECC's ambient hooks (quality-gate, auto-format, session-memory, cost-tracking, strategic-compact) are activated by ECC's own `hooks.json` when ECC is installed. Supes does not reimplement them — it relies on ECC being installed alongside it.

**Step 2: Commit**

```bash
git add hooks/hooks.json
git commit -m "feat: add hooks.json wiring session-start"
```

---

### Task 8: Bridge skills

**Files:**
- Create: `skills/bridge-brainstorm/skill.md`
- Create: `skills/bridge-plan/skill.md`
- Create: `skills/bridge-tdd/skill.md`
- Create: `skills/bridge-review/skill.md`
- Create: `skills/bridge-execute/skill.md`

**Step 1: Create skills directory**

```bash
mkdir -p skills/bridge-brainstorm skills/bridge-plan skills/bridge-tdd \
         skills/bridge-review skills/bridge-execute
```

**Step 2: Write bridge-brainstorm/skill.md**

```markdown
# bridge-brainstorm

You are preparing the brainstorming stage for this project.

1. Read the Supes routing context injected at session start (stack and ECC skill list for `brainstorm` stage).
2. Load and apply each listed ECC skill now to establish domain context before proceeding.
3. If the routing context lists an `architect` agent, note that it is available for delegation during this stage.
4. Once ECC skills are loaded, yield immediately to the Superpowers `brainstorming` skill — follow its process exactly from that point.

Do not add domain guidance of your own. Your role is routing, not expertise.
```

**Step 3: Write bridge-plan/skill.md**

```markdown
# bridge-plan

You are preparing the planning stage for this project.

1. Read the Supes routing context injected at session start (stack and ECC skill list for `plan` stage).
2. Load and apply each listed ECC skill now to establish domain context (patterns, database conventions, deployment constraints) before planning begins.
3. If the routing context lists a `planner` agent, note that it is available for delegation during this stage.
4. Once ECC skills are loaded, yield immediately to the Superpowers `writing-plans` skill — follow its process exactly from that point.

Do not add domain guidance of your own. Your role is routing, not expertise.
```

**Step 4: Write bridge-tdd/skill.md**

```markdown
# bridge-tdd

You are preparing the TDD stage for this project.

1. Read the Supes routing context injected at session start (stack and ECC skill list for `tdd` stage).
2. Load and apply each listed ECC skill now. These skills carry language-specific testing idioms, security test patterns, and framework test conventions. Apply them throughout the TDD cycle.
3. If the routing context lists a `tdd-guide` agent, note that it is available for delegation during this stage.
4. Once ECC skills are loaded, yield immediately to the Superpowers `test-driven-development` skill — follow its RED-GREEN-REFACTOR process exactly from that point.

Do not add domain guidance of your own. Your role is routing, not expertise.
```

**Step 5: Write bridge-review/skill.md**

```markdown
# bridge-review

You are preparing the code review stage for this project.

1. Read the Supes routing context injected at session start (stack and ECC skill list for `review` stage).
2. Load and apply each listed ECC skill now. These carry security review checklists and language-specific review patterns.
3. The routing context will list one or more review agents (e.g. `code-reviewer`, `python-reviewer`, `go-reviewer`). Dispatch to each listed agent in sequence for their domain perspective.
4. Once ECC skills are loaded and agent reviews are collected, yield to the Superpowers `requesting-code-review` skill for final synthesis and blocking-issue determination.

Do not add domain guidance of your own. Your role is routing, not expertise.
```

**Step 6: Write bridge-execute/skill.md**

```markdown
# bridge-execute

You are preparing the execution stage for this project.

1. Read the Supes routing context injected at session start (stack and ECC skill list for `execute` stage).
2. Load and apply each listed ECC skill now (typically `multi-execute`, `autonomous-loops`).
3. If the routing context lists a `chief-of-staff` agent, note that it is available to coordinate parallel subagent work during this stage.
4. Once ECC skills are loaded, yield immediately to the Superpowers `executing-plans` skill — follow its process exactly from that point.

Do not add domain guidance of your own. Your role is routing, not expertise.
```

**Step 7: Commit**

```bash
git add skills/
git commit -m "feat: add five bridge skills"
```

---

### Task 9: CLAUDE.md template

**Files:**
- Create: `docs/CLAUDE.md.template`

**Step 1: Write the annotated template**

````markdown
# CLAUDE.md — Supes Block Reference

Copy the block below into your project's CLAUDE.md.
All lines inside the block are optional. The block itself is optional — Supes works without it via auto-detection.

---

## Minimal (stack override only)

```supes
stack: python django postgresql
```

## Full override reference

```supes
# Optional: override auto-detected stack.
# List any combination of: node react next python django go rust java spring
stack: python django postgresql react-typescript

# Additive (default): listed skills are APPENDED to detected defaults.
# Works for: brainstorm, plan, tdd, review, execute
tdd: my-custom-testing-skill

# Removal: prefix a skill name with - to remove it from defaults.
review: -django-security my-stricter-security-skill

# Replace: suffix the key with ! to ignore defaults entirely for that stage.
tdd!: only-this-one-skill

# You can mix removal and addition on the same line.
plan: -backend-patterns our-team-planning-skill extra-skill
```

---

## Notes

- Skill names can come from ECC, Superpowers, other plugins, or your personal ~/.claude/skills/
- The hook does not validate skill names — unknown names surface naturally as "skill not found"
- See docs/routing-defaults.md for the full default mapping table
- Set ECC_HOOK_PROFILE=minimal to reduce ambient hook noise (ECC env var, not Supes-specific)
````

**Step 2: Commit**

```bash
git add docs/CLAUDE.md.template
git commit -m "docs: add annotated CLAUDE.md template"
```

---

### Task 10: README

**Files:**
- Create: `README.md`

**Step 1: Write README.md**

```markdown
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
```

**Step 2: Commit**

```bash
git add README.md
git commit -m "docs: add README with installation and configuration guide"
```

---

## Verification

After all tasks are complete:

```bash
# All tests pass
bats tests/session_start.bats

# Hook produces valid JSON
cd /tmp && touch go.mod && bash /path/to/hooks/session-start | python3 -m json.tool

# Hook detects django correctly
cd /tmp && touch requirements.txt manage.py && bash /path/to/hooks/session-start | grep -i django

# supes block merge works end-to-end
cd /tmp && touch go.mod && cat > CLAUDE.md <<'EOF'
```supes
tdd: my-extra-skill
```
EOF
bash /path/to/hooks/session-start | grep "my-extra-skill"
```
