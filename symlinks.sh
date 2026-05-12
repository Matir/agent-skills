#!/usr/bin/env bash
set -euo pipefail

# Default values
DRY_RUN=false
VERBOSE=false

usage() {
    cat <<EOF
Usage: $(basename "$0") [options] [target_directory]

Symlinks skills to the specified target directory.

Options:
  -n, --dry-run    Show what would be done without making changes
  -v, --verbose    Enable verbose output
  -h, --help       Show this help message

Arguments:
  target_directory  Directory to place symlinks in. Defaults to script directory.
                    If the target is not the git root, all skills are symlinked (depth 2+).
                    Otherwise, only nested skills are symlinked (depth 3+).
EOF
}

# Parse options
while [[ $# -gt 0 ]]; do
    case "$1" in
        -n|--dry-run) DRY_RUN=true; shift ;;
        -v|--verbose) VERBOSE=true; shift ;;
        -h|--help) usage; exit 0 ;;
        -*) echo "Error: Unknown option $1" >&2; usage; exit 1 ;;
        *) break ;;
    esac
done

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TARGET_ARG="${1:-}"
TARGET_DIR="${TARGET_ARG:-$SCRIPT_DIR}"

# Ensure TARGET_DIR exists and get absolute path
if [ "$DRY_RUN" = false ]; then
    mkdir -p "$TARGET_DIR"
fi

if [ -d "$TARGET_DIR" ]; then
    TARGET_DIR="$(cd "$TARGET_DIR" && pwd)"
else
    # Fallback for dry-run or newly created dir
    TARGET_DIR="$(mkdir -p "$TARGET_DIR" 2>/dev/null && cd "$TARGET_DIR" && pwd || echo "$TARGET_DIR")"
fi

GIT_ROOT="$(git rev-parse --show-toplevel 2>/dev/null || true)"

# Determine search depth.
# If a target is specified and it's not the git root, include all skills (depth 2+).
# Otherwise, default to only nested skills (depth 3+).
MIN_DEPTH=3
if [ -n "$TARGET_ARG" ] && [ "$TARGET_DIR" != "$GIT_ROOT" ]; then
    MIN_DEPTH=2
fi

log() { echo "$@"; }
vlog() { [ "$VERBOSE" = true ] && echo "$@"; }

# Remove broken symlinks in the target directory
while IFS= read -r -d '' link; do
    if [ ! -e "$link" ]; then
        log "Removing broken symlink: $link"
        [ "$DRY_RUN" = false ] && rm "$link"
    fi
done < <(find "$TARGET_DIR" -maxdepth 1 -mindepth 1 -type l -print0)

# Find SKILL.md files. Skip hidden directories.
# depth 2: skill/SKILL.md
# depth 3: org/skill/SKILL.md
while IFS= read -r -d '' skill_md; do
    skill_dir="$(cd "$(dirname "$skill_md")" && pwd)"
    skill_name="$(basename "$skill_dir")"
    link_path="$TARGET_DIR/$skill_name"

    if [ -L "$link_path" ]; then
        # Resolve existing symlink target to an absolute path
        target="$(readlink "$link_path")"
        if [[ "$target" != /* ]]; then
            # Resolve relative to TARGET_DIR
            target="$(cd "$TARGET_DIR" && cd "$target" 2>/dev/null && pwd)" || true
        fi
        
        if [ "$target" = "$skill_dir" ]; then
            vlog "Symlink already correct: $link_path -> $target"
            continue
        fi
        
        echo "Error: symlink '$link_path' already exists but points to '$target', expected '$skill_dir'" >&2
        exit 1
    elif [ -e "$link_path" ]; then
        echo "Error: '$link_path' exists and is not a symlink" >&2
        exit 1
    else
        # Determine the link target path
        if [ "$TARGET_DIR" = "$SCRIPT_DIR" ]; then
            # Use relative path if we are in the same directory as the script
            rel_target="./${skill_dir#$SCRIPT_DIR/}"
        else
            # For other directories, use absolute paths for stability
            rel_target="$skill_dir"
        fi
        
        log "Creating symlink: $link_path -> $rel_target"
        [ "$DRY_RUN" = false ] && ln -s "$rel_target" "$link_path"
    fi
done < <(find "$SCRIPT_DIR" -mindepth "$MIN_DEPTH" -name "SKILL.md" -print0)
