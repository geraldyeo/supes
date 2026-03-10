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

@test "detects java from build.gradle" {
  touch build.gradle
  run bash "$HOOK" --detect-only
  [[ "$output" == *"java"* ]]
}

@test "detects spring from build.gradle with spring content" {
  echo "implementation 'org.springframework.boot:spring-boot-starter'" > build.gradle
  run bash "$HOOK" --detect-only
  [[ "$output" == *"spring"* ]]
}

@test "detects java from pom.xml" {
  touch pom.xml
  run bash "$HOOK" --detect-only
  [[ "$output" == *"java"* ]]
}

@test "detects python from pyproject.toml" {
  touch pyproject.toml
  run bash "$HOOK" --detect-only
  [[ "$output" == *"python"* ]]
}

@test "detects next from package.json next dep" {
  echo '{"dependencies":{"next":"^14.0.0"}}' > package.json
  run bash "$HOOK" --detect-only
  [[ "$output" == *"next"* ]]
}

@test "additive: appends custom skill to go defaults for tdd" {
  touch go.mod
  cat > CLAUDE.md <<'EOF'
```supes
tdd: my-custom-skill
```
EOF
  run bash "$HOOK" --parse-only tdd
  [[ "$output" == *"golang-testing"* ]]
  [[ "$output" == *"my-custom-skill"* ]]
}

@test "removal: strips a default skill with - prefix" {
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

@test "replace: ignores defaults entirely with ! suffix" {
  touch go.mod
  cat > CLAUDE.md <<'EOF'
```supes
tdd!: only-this-skill
```
EOF
  run bash "$HOOK" --parse-only tdd
  [[ "$output" == "only-this-skill" ]]
}

@test "returns defaults when no CLAUDE.md present" {
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

@test "node plan includes api-design" {
  echo '{}' > package.json
  run bash "$HOOK" --parse-only plan
  [[ "$output" == *"api-design"* ]]
}

@test "stack: override in supes block replaces auto-detected stack" {
  touch go.mod
  cat > CLAUDE.md <<'EOF'
```supes
stack: python django
```
EOF
  run bash "$HOOK" --parse-only tdd
  [[ "$output" == *"django-tdd"* ]]
  [[ "$output" != *"golang-testing"* ]]
}

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
