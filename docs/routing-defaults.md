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
| execute | `multi-execute`, `autonomous-loops` | `chief-of-staff` |

### django (extends python)

| Stage | ECC Skills | ECC Agent |
|---|---|---|
| plan | `backend-patterns`, `database-migrations` | `planner` |
| tdd | `django-tdd`, `python-testing`, `django-security` | `tdd-guide` |

### go

| Stage | ECC Skills | ECC Agent |
|---|---|---|
| brainstorm | `ai-first-engineering` | `architect` |
| plan | `backend-patterns` | `planner` |
| tdd | `golang-testing` | `tdd-guide` |
| review | `security-review`, `go-reviewer` | `code-reviewer` |
| execute | `multi-execute`, `autonomous-loops` | `chief-of-staff` |

### node / typescript

| Stage | ECC Skills | ECC Agent |
|---|---|---|
| brainstorm | `ai-first-engineering` | `architect` |
| plan | `backend-patterns`, `api-design` | `planner` |
| tdd | `tdd-workflow` | `tdd-guide` |
| review | `security-review` | `code-reviewer` |
| execute | `multi-execute`, `autonomous-loops` | `chief-of-staff` |

### react (extends node/typescript)

| Stage | ECC Skills | ECC Agent |
|---|---|---|
| plan | `frontend-patterns`, `api-design` | `planner` |
| tdd | `tdd-workflow`, `e2e-testing` | `tdd-guide` |
| review | `security-review` | `code-reviewer` |

### next (extends react)

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
| execute | `multi-execute`, `autonomous-loops` | `chief-of-staff` |

### java / spring

| Stage | ECC Skills | ECC Agent |
|---|---|---|
| brainstorm | `ai-first-engineering` | `architect` |
| plan | `backend-patterns`, `api-design` | `planner` |
| tdd | `springboot-tdd` | `tdd-guide` |
| review | `security-review`, `springboot-security` | `code-reviewer` |
| execute | `multi-execute`, `autonomous-loops` | `chief-of-staff` |

### fallback (no stack detected)

| Stage | ECC Skills | ECC Agent |
|---|---|---|
| brainstorm | `ai-first-engineering` | `architect` |
| plan | `backend-patterns` | `planner` |
| tdd | `tdd-workflow` | `tdd-guide` |
| review | `security-review` | `code-reviewer` |
| execute | `multi-execute`, `autonomous-loops` | `chief-of-staff` |
