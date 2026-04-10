#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Remove broken symlinks at the top level
while IFS= read -r -d '' link; do
    if [ ! -e "$link" ]; then
        echo "Removing broken symlink: $link"
        rm "$link"
    fi
done < <(find "$SCRIPT_DIR" -maxdepth 1 -mindepth 1 -type l -print0)

# Find SKILL.md files at depth >= 3 (so containing dir is not a direct child of SCRIPT_DIR).
# depth 0: SCRIPT_DIR, depth 1: foo, depth 2: foo/SKILL.md (skip), depth 3: foo/bar/SKILL.md (include)
while IFS= read -r -d '' skill_md; do
    skill_dir="$(cd "$(dirname "$skill_md")" && pwd)"
    link_name="$(basename "$skill_dir")"
    link_path="$SCRIPT_DIR/$link_name"

    if [ -L "$link_path" ]; then
        # Resolve existing symlink target to an absolute path
        target="$(readlink "$link_path")"
        if [[ "$target" != /* ]]; then
            target="$(cd "$SCRIPT_DIR" && cd "$target" 2>/dev/null && pwd)" || true
        fi
        if [ "$target" = "$skill_dir" ]; then
            : # Already correct, do nothing
        else
            echo "Error: symlink '$link_path' already exists but points to '$target', expected '$skill_dir'" >&2
            exit 1
        fi
    elif [ -e "$link_path" ]; then
        echo "Error: '$link_path' exists and is not a symlink" >&2
        exit 1
    else
        echo "Creating symlink: $link_path -> $skill_dir"
        ln -s "$skill_dir" "$link_path"
    fi
done < <(find "$SCRIPT_DIR" -mindepth 3 -name "SKILL.md" -print0)
