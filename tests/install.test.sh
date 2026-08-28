#!/usr/bin/env bash
set -euo pipefail

test_root=$(mktemp -d)
trap 'rm -rf "$test_root"' EXIT

plugin_id="jacobsennando.workspace-lens"
root="$test_root/plugins"
target="$root/$plugin_id"

install() {
  WORKSPACE_LENS_INSTALL_ROOT="$root" bash scripts/install.sh --no-enable "$@"
}

expect_failure() {
  local label="$1"
  shift
  if "$@" 2>/dev/null; then
    printf 'FAIL: %s should have been refused\n' "$label" >&2
    exit 1
  fi
}

# Fresh install copies every runtime file and the clone relationship.
install
for file in manifest.json LICENSE BarWidget.qml WorkspaceModel.js WorkspaceButton.qml WorkspacePopover.qml AppIcon.qml; do
  test -f "$target/$file"
done
jq -e '.omarchy.clonedFrom == "omarchy.workspaces"' "$target/manifest.json" >/dev/null
test -z "$(find "$root" -mindepth 1 -maxdepth 1 -name '.*')"

# Reinstall over a previous Workspace Lens copy replaces it and leaves no
# staging or backup directories behind.
touch "$target/stale-file"
install
test ! -e "$target/stale-file"
test -f "$target/BarWidget.qml"
test -z "$(find "$root" -mindepth 1 -maxdepth 1 -name '.*')"

# A git checkout is Omarchy's to update; refuse to flatten it.
mkdir "$target/.git"
expect_failure "git checkout" install
test -d "$target/.git"
rm -rf "$target/.git"

# A different plugin at the same path is never overwritten.
jq '.id = "someone.else"' "$target/manifest.json" > "$target/manifest.tmp"
mv "$target/manifest.tmp" "$target/manifest.json"
expect_failure "foreign plugin" install
jq -e '.id == "someone.else"' "$target/manifest.json" >/dev/null
rm -rf "$target"

# A symlinked target is refused.
mkdir "$root/elsewhere"
ln -s "$root/elsewhere" "$target"
expect_failure "symlinked target" install
test -L "$target"
rm "$target"

# Packaged Omarchy files are never a valid destination.
expect_failure "/usr/share/omarchy" env WORKSPACE_LENS_INSTALL_ROOT=/usr/share/omarchy/plugins bash scripts/install.sh --no-enable

echo "install.test.sh: ok"
