#!/bin/bash
set -euo pipefail

# Get the root directory of the repository
GIT_ROOT=$(git rev-parse --show-toplevel)

echo "Setting up git hooks..."

# Configure git to look for hooks in the .githooks directory
git -C "$GIT_ROOT" config core.hooksPath .githooks

# Ensure the hook dispatcher and sub-hooks are executable
chmod +x "$GIT_ROOT"/.githooks/pre-commit
if [ -d "$GIT_ROOT/.githooks/pre-commit.d" ]; then
    chmod +x "$GIT_ROOT"/.githooks/pre-commit.d/*
fi

echo "Git hooks configured successfully! Hooks will now run automatically on commit."
