#!/usr/bin/env bash
#
# Install this repo's rules and skills into an agent harness.
#
#   ./install.sh                    install for Claude Code
#   ./install.sh --dry-run          show what would change, touch nothing
#   ./install.sh --uninstall        remove the symlinks this script created
#   ./install.sh --harness NAME     target a specific harness
#
# Everything is installed as a symlink back into the repo, so editing a file
# here takes effect immediately with no reinstall.

set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
RULES_FILE="$REPO_DIR/rules/global.md"
SKILLS_DIR="$REPO_DIR/skills"

SUPPORTED_HARNESSES=(claude-code)
HARNESS=claude-code
DRY_RUN=0
UNINSTALL=0
STAMP="$(date +%Y%m%d%H%M%S)"

die() { printf 'error: %s\n' "$1" >&2; exit 1; }
note() { printf '%s\n' "$1"; }

run() {
  if [ "$DRY_RUN" -eq 0 ]; then
    "$@"
  fi
}

# Past tense when acting, future tense when only reporting.
verb() {
  if [ "$DRY_RUN" -eq 1 ]; then printf 'would %s' "$1"; else printf '%s' "$2"; fi
}

usage() {
  awk 'NR>2 && /^#/ { sub(/^# ?/, ""); print; next } NR>2 { exit }' "${BASH_SOURCE[0]}"
  printf 'Supported harnesses: %s\n' "${SUPPORTED_HARNESSES[*]}"
}

# Symlink $1 to $2, moving anything already there out of the way.
link() {
  local src=$1 dest=$2

  [ -e "$src" ] || die "missing source: $src"

  if [ -L "$dest" ] && [ "$(readlink "$dest")" = "$src" ]; then
    note "  $(verb 'keep  ' 'ok    ')    ${dest/#$HOME/~} (already linked)"
    return
  fi

  [ -d "$(dirname "$dest")" ] || run mkdir -p "$(dirname "$dest")"

  if [ -e "$dest" ] || [ -L "$dest" ]; then
    local backup="$dest.backup.$STAMP"
    note "  $(verb 'back up' 'backup ')   ${dest/#$HOME/~} -> ${backup##*/}"
    run mv "$dest" "$backup"
  fi

  run ln -s "$src" "$dest"
  note "  $(verb 'link  ' 'linked')    ${dest/#$HOME/~}"
}

# Remove $1 only if it is a symlink pointing into this repo.
unlink_ours() {
  local dest=$1
  if [ ! -L "$dest" ]; then
    if [ -e "$dest" ]; then
      note "  skipped   ${dest/#$HOME/~} (not a symlink, left alone)"
    fi
    return 0
  fi
  case "$(readlink "$dest")" in
    "$REPO_DIR"/*)
      note "  $(verb 'remove ' 'removed')   ${dest/#$HOME/~}"
      run rm "$dest"
      ;;
    *)
      note "  skipped   ${dest/#$HOME/~} (points elsewhere, left alone)"
      ;;
  esac
}

each_skill() {
  local skill
  for skill in "$SKILLS_DIR"/*/; do
    [ -f "$skill/SKILL.md" ] || continue
    printf '%s\n' "$(basename "$skill")"
  done
}

# --- harnesses -------------------------------------------------------------
# To add one, write a harness_<name> function that calls link (or unlink_ours
# when UNINSTALL is set) for each destination, then list the name in
# SUPPORTED_HARNESSES above.

harness_claude_code() {
  local root="${CLAUDE_CONFIG_DIR:-$HOME/.claude}"
  local action=link
  [ "$UNINSTALL" -eq 1 ] && action=unlink_ours

  note "Claude Code (${root/#$HOME/~})"

  if [ "$action" = link ]; then
    link "$RULES_FILE" "$root/CLAUDE.md"
  else
    unlink_ours "$root/CLAUDE.md"
  fi

  local name
  while IFS= read -r name; do
    if [ "$action" = link ]; then
      link "$SKILLS_DIR/$name" "$root/skills/$name"
    else
      unlink_ours "$root/skills/$name"
    fi
  done < <(each_skill)
}

# --- main ------------------------------------------------------------------

while [ $# -gt 0 ]; do
  case "$1" in
    --dry-run) DRY_RUN=1 ;;
    --uninstall) UNINSTALL=1 ;;
    --harness) shift; [ $# -gt 0 ] || die "--harness needs a value"; HARNESS=$1 ;;
    -h|--help) usage; exit 0 ;;
    *) die "unknown argument: $1 (try --help)" ;;
  esac
  shift
done

found=0
for h in "${SUPPORTED_HARNESSES[@]}"; do
  [ "$h" = "$HARNESS" ] && found=1
done
[ "$found" -eq 1 ] || die "unsupported harness: $HARNESS (supported: ${SUPPORTED_HARNESSES[*]})"

[ "$DRY_RUN" -eq 1 ] && note "dry run, nothing will be written"

"harness_${HARNESS//-/_}"

if [ "$UNINSTALL" -eq 1 ]; then
  note ""
  note "Backups from previous installs were left in place. Restore one by hand if you want it back."
else
  note ""
  note "Done. Restart Claude Code, then check the skills with /skills."
fi
