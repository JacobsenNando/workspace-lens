#!/usr/bin/env bash
set -euo pipefail

plugin_id="jacobsennando.workspace-lens"
runtime_files=(
  manifest.json
  BarWidget.qml
  WorkspaceModel.js
  WorkspaceButton.qml
  WorkspacePopover.qml
  AppIcon.qml
)

usage() {
  printf 'Usage: %s [--no-enable]\n' "${0##*/}" >&2
  exit 2
}

case "${1:-}" in
  "") enable_plugin=true ;;
  --no-enable) enable_plugin=false ;;
  *) usage ;;
esac

if (( $# > 1 )); then
  usage
fi

repo_root=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd -P)
plugin_root=${WORKSPACE_LENS_INSTALL_ROOT:-"${HOME:?HOME must be set}"/.config/omarchy/plugins}
plugin_root=$(realpath -m -- "$plugin_root")
case "$plugin_root" in
  /usr/share/omarchy|/usr/share/omarchy/*)
    printf 'Refusing to install under /usr/share/omarchy: %s\n' "$plugin_root" >&2
    exit 1
    ;;
esac
target="$plugin_root/$plugin_id"
staging_dir=""
backup_dir=""
had_previous=false
installed=false

restore_previous_installation() {
  if [[ "$had_previous" == true && -d "$backup_dir/previous" ]]; then
    rm -rf -- "$target"
    mv -- "$backup_dir/previous" "$target"
    printf 'Workspace Lens installation failed; restored the previous installation.\n' >&2
  elif [[ "$installed" == true ]]; then
    rm -rf -- "$target"
  fi
}

wait_for_plugin_discovery() {
  local attempt
  for ((attempt = 0; attempt < 50; attempt++)); do
    if omarchy plugin list | awk -v expected="$plugin_id" '
      $1 == expected { found = 1 }
      END { exit !found }
    '; then
      return 0
    fi
    sleep 0.1
  done

  printf 'Timed out waiting for Omarchy to discover plugin: %s\n' "$plugin_id" >&2
  return 1
}

cleanup() {
  local status=$?
  trap - EXIT

  if (( status != 0 )); then
    restore_previous_installation
  fi

  if [[ -n "$staging_dir" && -d "$staging_dir" ]]; then
    rm -rf -- "$staging_dir"
  fi
  if [[ -n "$backup_dir" && -d "$backup_dir" ]]; then
    rmdir -- "$backup_dir" 2>/dev/null || true
  fi

  exit "$status"
}

trap cleanup EXIT

for runtime_file in "${runtime_files[@]}"; do
  if [[ ! -f "$repo_root/$runtime_file" ]]; then
    printf 'Missing required runtime file: %s\n' "$repo_root/$runtime_file" >&2
    exit 1
  fi
done

mkdir -p -- "$plugin_root"

if [[ -L "$target" ]]; then
  printf 'Refusing to replace symlinked plugin target: %s\n' "$target" >&2
  exit 1
fi

if [[ -e "$target" ]]; then
  if [[ ! -f "$target/manifest.json" ]] \
    || ! jq -e --arg id "$plugin_id" '.id == $id' "$target/manifest.json" >/dev/null; then
    printf 'Refusing to replace unknown existing plugin: %s\n' "$target" >&2
    exit 1
  fi
  had_previous=true
fi

staging_dir=$(mktemp -d "$plugin_root/.${plugin_id}.install.XXXXXX")
for runtime_file in "${runtime_files[@]}"; do
  cp -- "$repo_root/$runtime_file" "$staging_dir/$runtime_file"
done

if [[ "$had_previous" == true ]]; then
  backup_dir=$(mktemp -d "$plugin_root/.${plugin_id}.backup.XXXXXX")
  mv -- "$target" "$backup_dir/previous"
fi

mv -- "$staging_dir" "$target"
staging_dir=""
installed=true

if [[ "$enable_plugin" == true ]]; then
  omarchy-shell shell rescanPlugins
  wait_for_plugin_discovery
  omarchy plugin enable "$plugin_id"
fi

if [[ -n "$backup_dir" ]]; then
  rm -rf -- "$backup_dir"
fi
backup_dir=""
trap - EXIT

printf 'Installed Workspace Lens at %s\n' "$target"
if [[ "$enable_plugin" == true ]]; then
  printf 'Activation ran.\n'
else
  printf 'Activation skipped (--no-enable).\n'
fi
