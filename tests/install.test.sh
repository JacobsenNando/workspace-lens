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

root_probe_bin="$test_root/root-probe-bin"
mkdir -p "$root_probe_bin"
printf '#!/usr/bin/env bash\ntouch "$INSTALL_ROOT_PROBE"\nexit 93\n' >"$root_probe_bin/mkdir"
chmod +x "$root_probe_bin/mkdir"

expect_protected_root_rejection() {
  local install_root=$1
  local probe=$2
  local output

  if output=$(PATH="$root_probe_bin:$PATH" INSTALL_ROOT_PROBE="$probe" WORKSPACE_LENS_INSTALL_ROOT="$install_root" bash scripts/install.sh --no-enable 2>&1); then
    printf 'installer accepted protected root: %s\n' "$install_root" >&2
    exit 1
  fi
  test ! -e "$probe"
  [[ "$output" == *'Refusing to install under /usr/share/omarchy'* ]]
}

expect_protected_root_rejection /usr/share/omarchy "$test_root/direct-root-mkdir-called"
ln -s /usr/share/omarchy "$test_root/packaged-root-link"
expect_protected_root_rejection "$test_root/packaged-root-link" "$test_root/symlink-root-mkdir-called"

broken_plugin_root="$test_root/broken-target/plugins"
broken_target="$broken_plugin_root/jacobsennando.workspace-lens"
mkdir -p "$broken_plugin_root"
ln -s "$test_root/missing-plugin" "$broken_target"
symlink_probe_bin="$test_root/symlink-probe-bin"
mkdir -p "$symlink_probe_bin"
printf '#!/usr/bin/env bash\ntouch "$SYMLINK_PROBE"\nexit 94\n' >"$symlink_probe_bin/mktemp"
chmod +x "$symlink_probe_bin/mktemp"

if output=$(PATH="$symlink_probe_bin:$PATH" SYMLINK_PROBE="$test_root/broken-target-mktemp-called" WORKSPACE_LENS_INSTALL_ROOT="$broken_plugin_root" bash scripts/install.sh --no-enable 2>&1); then
  printf 'installer accepted a broken target symlink\n' >&2
  exit 1
fi
test -L "$broken_target"
test "$(readlink "$broken_target")" = "$test_root/missing-plugin"
test ! -e "$test_root/broken-target-mktemp-called"
[[ "$output" == *'Refusing to replace symlinked plugin target'* ]]
