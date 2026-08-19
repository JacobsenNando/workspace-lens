#!/usr/bin/env bash
set -euo pipefail

test_root=$(mktemp -d)
trap 'rm -rf "$test_root"' EXIT

WORKSPACE_LENS_INSTALL_ROOT="$test_root/plugins" bash scripts/install.sh --no-enable
target="$test_root/plugins/jacobsennando.workspace-lens"

test -f "$target/manifest.json"
test -f "$target/BarWidget.qml"
test -f "$target/WorkspaceModel.js"
test -f "$target/WorkspaceButton.qml"
test -f "$target/WorkspacePopover.qml"
test -f "$target/AppIcon.qml"
jq -e '.omarchy.clonedFrom == "omarchy.workspaces"' "$target/manifest.json" >/dev/null

touch "$target/previous-install-marker"
WORKSPACE_LENS_INSTALL_ROOT="$test_root/plugins" bash scripts/install.sh --no-enable
test ! -e "$target/previous-install-marker"

unknown_target="$test_root/unknown/plugins/jacobsennando.workspace-lens"
mkdir -p "$unknown_target"
touch "$unknown_target/keep-me"
if WORKSPACE_LENS_INSTALL_ROOT="$test_root/unknown/plugins" bash scripts/install.sh --no-enable; then
  printf 'installer replaced an unknown plugin\n' >&2
  exit 1
fi
test -f "$unknown_target/keep-me"

touch "$target/previous-install-marker"
fake_bin="$test_root/bin"
mkdir -p "$fake_bin"
printf '#!/usr/bin/env bash\nexit 0\n' >"$fake_bin/omarchy-shell"
printf '#!/usr/bin/env bash\nexit 1\n' >"$fake_bin/omarchy"
chmod +x "$fake_bin/omarchy-shell" "$fake_bin/omarchy"

if PATH="$fake_bin:$PATH" WORKSPACE_LENS_INSTALL_ROOT="$test_root/plugins" bash scripts/install.sh; then
  printf 'installer unexpectedly succeeded when activation failed\n' >&2
  exit 1
fi
test -f "$target/previous-install-marker"
