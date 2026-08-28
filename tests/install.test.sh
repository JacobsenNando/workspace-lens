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
