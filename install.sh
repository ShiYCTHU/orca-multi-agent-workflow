#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BIN_DIR="${HOME}/.local/bin"
SKILL_DIR="${HOME}/.codex/skills/orca-multi-agent"
STATE_DIR="${HOME}/.local/state/orca-multi-agent-installer"
MODE="${1:-install}"

sources=(
  bin/orca-supervisor
  bin/orca-kimi
  bin/orca-terra
  bin/orca-init
  bin/dsh-orca
  skill/orca-multi-agent/SKILL.md
  skill/orca-multi-agent/references/workflow.md
  skill/orca-multi-agent/references/current_system.md
)

target_for() {
  case "$1" in
    bin/*) printf '%s/%s\n' "$BIN_DIR" "${1#bin/}" ;;
    skill/orca-multi-agent/*) printf '%s/%s\n' "$SKILL_DIR" "${1#skill/orca-multi-agent/}" ;;
  esac
}

check() {
  local failed=0 command_name orca_command="${ORCA_CLI_COMMAND:-orca-ide}"
  for command_name in python3 "$orca_command" claude codex dsh; do
    if command -v "$command_name" >/dev/null; then
      printf 'OK      %s\n' "$command_name"
    else
      printf 'MISSING %s\n' "$command_name"
      failed=1
    fi
  done
  if [[ -f "${HOME}/.config/dsh/orca.env" ]]; then
    printf 'OK      %s\n' "~/.config/dsh/orca.env"
  else
    printf 'MISSING %s\n' "~/.config/dsh/orca.env"
    failed=1
  fi
  return "$failed"
}

install_files() {
  local force="$1" src rel target backup="" conflicts=()
  for rel in "${sources[@]}"; do
    target="$(target_for "$rel")"
    [[ -e "$target" ]] && conflicts+=("$target")
  done
  if ((${#conflicts[@]})) && [[ "$force" != force ]]; then
    printf 'Existing targets found; no files changed:\n' >&2
    printf '  %s\n' "${conflicts[@]}" >&2
    printf 'Review them, then use ./install.sh --force to back up and replace them.\n' >&2
    return 2
  fi
  if ((${#conflicts[@]})); then
    backup="$STATE_DIR/backups/$(date +%Y%m%d-%H%M%S)"
    for target in "${conflicts[@]}"; do
      mkdir -p "$backup$(dirname "${target#"$HOME"}")"
      cp -a "$target" "$backup${target#"$HOME"}"
    done
    printf 'Backup: %s\n' "$backup"
  fi
  for rel in "${sources[@]}"; do
    src="$ROOT/$rel"
    target="$(target_for "$rel")"
    mkdir -p "$(dirname "$target")"
    install -m "$([[ "$rel" == bin/* ]] && printf 755 || printf 644)" "$src" "$target"
  done
  printf 'Installed. Restart Codex Desktop and ensure %s is in PATH.\n' "$BIN_DIR"
}

uninstall_files() {
  local rel target backup="$STATE_DIR/backups/uninstall-$(date +%Y%m%d-%H%M%S)" moved=0
  for rel in "${sources[@]}"; do
    target="$(target_for "$rel")"
    [[ -e "$target" ]] || continue
    if cmp -s "$ROOT/$rel" "$target"; then
      mkdir -p "$backup$(dirname "${target#"$HOME"}")"
      mv "$target" "$backup${target#"$HOME"}"
      moved=1
    else
      printf 'KEEP modified file: %s\n' "$target"
    fi
  done
  if ((moved)); then
    printf 'Uninstalled matching files. Backup: %s\n' "$backup"
  else
    printf 'No matching installed files found.\n'
  fi
}

case "$MODE" in
  install) install_files no-force ;;
  --force) install_files force ;;
  --check) check ;;
  --uninstall) uninstall_files ;;
  *) printf 'Usage: %s [--force|--check|--uninstall]\n' "$0" >&2; exit 2 ;;
esac
