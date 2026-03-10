# tests/test_helper.bash
# Sets up a temp project directory for each test.
# Usage: load 'test_helper' in each .bats file.

setup() {
  TEST_TMPDIR=$(mktemp -d)
  cd "$TEST_TMPDIR" || exit 1
}

teardown() {
  rm -rf "$TEST_TMPDIR"
}
