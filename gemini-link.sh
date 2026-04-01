#!/bin/bash
set -euo pipefail

# Get the directory where the script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Get the canonical path for ~/.agents/skills for comparison
SKILLS_DIR="$(cd "$HOME/.agents/skills" 2>/dev/null && pwd)"

# Initialize find options
FIND_OPTS=("-type" "f" "-name" "SKILL.md")

# If script is in ~/.agents/skills, only link skills that are nested (a/b/SKILL.md)
if [ "$SCRIPT_DIR" = "$SKILLS_DIR" ]; then
    # find's -mindepth 3 includes a/b/SKILL.md but not a/SKILL.md
    FIND_OPTS=("-mindepth" "3" "${FIND_OPTS[@]}")
fi

# Find all directories containing SKILL.md and run the link command
find "$SCRIPT_DIR" "${FIND_OPTS[@]}" | while read -r skill_file; do
    skill_dir=$(dirname "$skill_file")
    echo "Linking skill in: $skill_dir"
    gemini skills link --consent "$skill_dir"
done
