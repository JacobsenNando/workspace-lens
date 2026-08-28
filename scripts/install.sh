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
  '') enable_plugin=true ;;
  --no-enable) enable_plugin=false ;;
  *) usage ;;
esac

if (( $# > 1 )); then
  usage
fi

repo_root=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd -P)
install_root=${WORKSPACE_LENS_INSTALL_ROOT:-"${HOME:?HOME must be set}/.config/omarchy/plugins"}
install_root=$(realpath -m -- "$install_root")
case "$install_root" in
  /usr/share/omarchy|/usr/share/omarchy/*)
    printf 'Refusing to install under /usr/share/omarchy: %s\n' "$install_root" >&2
    exit 1
    ;;
esac

target="$install_root/$plugin_id"
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

cleanup() {
  local status=$?
  trap - EXIT
  if (( status != 0 )); then
    restore_previous_installation
  fi
  [[ -z "$staging_dir" || ! -d "$staging_dir" ]] || rm -rf -- "$staging_dir"
  [[ -z "$backup_dir" || ! -d "$backup_dir" ]] || rmdir -- "$backup_dir" 2>/dev/null || true
  exit "$status"
}

trap cleanup EXIT

for runtime_file in "${runtime_files[@]}"; do
  if [[ ! -f "$repo_root/$runtime_file" ]]; then
    printf 'Missing required runtime file: %s\n' "$repo_root/$runtime_file" >&2
    exit 1
  fi
done

mkdir -p -- "$install_root"

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

staging_dir=$(mktemp -d "$install_root/.${plugin_id}.install.XXXXXX")
for runtime_file in "${runtime_files[@]}"; do
  cp -- "$repo_root/$runtime_file" "$staging_dir/$runtime_file"
done

if [[ "$had_previous" == true ]]; then
  backup_dir=$(mktemp -d "$install_root/.${plugin_id}.backup.XXXXXX")
  mv -- "$target" "$backup_dir/previous"
fi

mv -- "$staging_dir" "$target"
staging_dir=""
installed=true

if [[ "$enable_plugin" == true ]]; then
  omarchy-shell shell rescanPlugins
  omarchy plugin enable "$plugin_id"
fi

[[ -z "$backup_dir" ]] || rm -rf -- "$backup_dir"
backup_dir=""
trap - EXIT

printf 'Installed Workspace Lens at %s\n' "$target"
if [[ "$enable_plugin" == true ]]; then
  printf 'Activation ran.\n'
else
  printf 'Activation skipped (--no-enable).\n'
fi
