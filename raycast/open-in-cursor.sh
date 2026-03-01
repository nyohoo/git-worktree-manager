#!/bin/bash

# Required parameters:
# @raycast.schemaVersion 1
# @raycast.title Open Task in Cursor
# @raycast.mode compact

# Optional parameters:
# @raycast.icon 🎨
# @raycast.argument1 { "type": "text", "placeholder": "Task name", "optional": false }
# @raycast.packageName Git Worktree Manager

# Documentation:
# @raycast.description Open a worktree task in Cursor
# @raycast.author nyohoo
# @raycast.authorURL https://github.com/nyohoo/git-worktree-manager

# Load environment variables
if [[ -f "$HOME/.zshrc" ]]; then
  source "$HOME/.zshrc"
fi

task_name="$1"

if [[ -z "$task_name" ]]; then
  echo "❌ Error: Task name is required"
  exit 1
fi

if [[ -z "$GWT_WORKTREE_ROOT" ]]; then
  echo "❌ Error: GWT_WORKTREE_ROOT is not set"
  exit 1
fi

task_dir="${GWT_WORKTREE_ROOT}/${task_name}"

if [[ ! -d "$task_dir" ]]; then
  echo "❌ Error: Task '$task_name' not found"
  exit 1
fi

workspace_file="${task_dir}/${task_name}.code-workspace"

if [[ -f "$workspace_file" ]]; then
  open -a "Cursor" "$workspace_file"
  echo "✅ Opened $task_name in Cursor"
else
  # Fallback: open the directory
  open -a "Cursor" "$task_dir"
  echo "✅ Opened $task_name directory in Cursor"
fi
