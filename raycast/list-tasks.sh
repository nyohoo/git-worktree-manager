#!/usr/bin/env zsh

# Required parameters:
# @raycast.schemaVersion 1
# @raycast.title List Worktree Tasks
# @raycast.mode fullOutput

# Optional parameters:
# @raycast.icon 🌳
# @raycast.packageName Git Worktree Manager

# Documentation:
# @raycast.description Show all active worktree tasks
# @raycast.author nyohoo
# @raycast.authorURL https://github.com/nyohoo/git-worktree-manager

# Load environment variables
if [[ -f "$HOME/.zshrc" ]]; then
  source "$HOME/.zshrc" 2>/dev/null
fi

# Load gwm configuration if available
if [[ -f "$HOME/.config/gwm/gwm.zsh" ]]; then
  source "$HOME/.config/gwm/gwm.zsh" 2>/dev/null
fi

# Check if GWT_WORKTREE_ROOT is set
if [[ -z "$GWT_WORKTREE_ROOT" ]]; then
  echo "❌ Error: GWT_WORKTREE_ROOT is not set"
  echo ""
  echo "Please set GWT_WORKTREE_ROOT in your ~/.zshrc:"
  echo "  export GWT_WORKTREE_ROOT=\"\$HOME/path/to/worktrees\""
  exit 1
fi

# Check if worktree directory exists
if [[ ! -d "$GWT_WORKTREE_ROOT" ]]; then
  echo "📭 No worktree directory found"
  echo ""
  echo "Directory: $GWT_WORKTREE_ROOT"
  exit 0
fi

# Find all tasks
tasks=()
for task_dir in "$GWT_WORKTREE_ROOT"/*/; do
  if [[ -d "$task_dir" && -f "${task_dir}/.workspace" ]]; then
    task_name=$(basename "$task_dir")
    tasks+=("$task_name")
  fi
done

if [[ ${#tasks[@]} -eq 0 ]]; then
  echo "📭 No active tasks"
  echo ""
  echo "Create a new task with:"
  echo "  zclaude <task-name> <repo>"
  exit 0
fi

echo "🌳 Active Worktree Tasks (${#tasks[@]})"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Display each task with details
for task_name in "${tasks[@]}"; do
  task_dir="${GWT_WORKTREE_ROOT}/${task_name}"
  workspace_file="${task_dir}/.workspace"

  # Load workspace metadata
  source "$workspace_file" 2>/dev/null

  echo "📦 $task_name"
  echo "   Path: $task_dir"

  if [[ -n "$REPOS" ]]; then
    echo "   Repos: ${REPOS[@]}"
  fi

  if [[ -n "$BRANCH_NAME" ]]; then
    echo "   Branch: $BRANCH_NAME"
  fi

  if [[ -n "$NOTE" ]]; then
    echo "   Note: $NOTE"
  fi

  if [[ -n "$CREATED_AT" ]]; then
    echo "   Created: $CREATED_AT"
  fi

  echo ""
done

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "💡 Commands:"
echo "  ztasks          - Interactive task list with fzf"
echo "  zcursor <task>  - Open task in Cursor"
echo "  zclean <task>   - Delete task"
