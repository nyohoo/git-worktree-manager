#!/usr/bin/env zsh

# Required parameters:
# @raycast.schemaVersion 1
# @raycast.title Copy Task Path
# @raycast.mode silent

# Optional parameters:
# @raycast.icon 📋
# @raycast.argument1 { "type": "text", "placeholder": "Task name", "optional": false }
# @raycast.packageName Git Worktree Manager

# Documentation:
# @raycast.description Copy task directory path to clipboard
# @raycast.author nyohoo
# @raycast.authorURL https://github.com/nyohoo/git-worktree-manager

# Load environment variables
if [[ -f "$HOME/.zshrc" ]]; then
  source "$HOME/.zshrc" 2>/dev/null
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

# Load workspace metadata to get the first repo
workspace_file="${task_dir}/.workspace"
if [[ -f "$workspace_file" ]]; then
  source "$workspace_file" 2>/dev/null
  if [[ -n "${REPOS[0]}" ]]; then
    target_dir="${task_dir}/${REPOS[0]}"
    if [[ -d "$target_dir" ]]; then
      task_dir="$target_dir"
    fi
  fi
fi

# Copy to clipboard
echo -n "$task_dir" | pbcopy

echo "✅ Copied path to clipboard: $task_dir"
