#!/bin/bash

# Required parameters:
# @raycast.schemaVersion 1
# @raycast.title Open Task in Terminal
# @raycast.mode compact

# Optional parameters:
# @raycast.icon 🖥️
# @raycast.argument1 { "type": "text", "placeholder": "Task name", "optional": false }
# @raycast.packageName Git Worktree Manager

# Documentation:
# @raycast.description Open a worktree task directory in terminal
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

# Detect terminal application (Warp, iTerm2, or Terminal.app)
if [[ -d "/Applications/Warp.app" ]]; then
  # Open in Warp
  open -a "Warp" "$task_dir"
  echo "✅ Opened $task_name in Warp"
elif [[ -d "/Applications/iTerm.app" ]]; then
  # Open in iTerm2
  osascript <<EOF
    tell application "iTerm"
      create window with default profile
      tell current session of current window
        write text "cd \"$task_dir\""
      end tell
    end tell
EOF
  echo "✅ Opened $task_name in iTerm2"
else
  # Open in Terminal.app
  osascript <<EOF
    tell application "Terminal"
      do script "cd \"$task_dir\""
      activate
    end tell
EOF
  echo "✅ Opened $task_name in Terminal"
fi
