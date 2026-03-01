# Git Worktree Manager

**Claude Code と連携した、git worktree ベースの並行開発環境**

複数のタスクを並行して管理し、ブランチ切り替えの煩わしさから解放されます。

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Shell: zsh](https://img.shields.io/badge/Shell-zsh-blue.svg)](https://www.zsh.org/)

## ✨ Features

- 🌳 **git worktree ベース**: 各タスクが独立したディレクトリで管理される
- 🔀 **マルチリポジトリ対応**: 複数リポジトリの横断開発をサポート
- 🎨 **IDE 統合**: Cursor/VS Code のマルチルートワークスペース自動生成
- 🤖 **Claude Code 連携**: AI アシスタントとの統合開発環境
- 📦 **リポジトリグループ**: よく使う組み合わせを定義可能
- 🚀 **高速切り替え**: fzf による対話的なタスク選択

## 🎯 Use Cases

### Monorepo Development

```bash
zclaude feature-ui my-monorepo
```

### Microservices Development

```bash
# 複数サービスの横断開発
zclaude feature-api backend-api frontend-app auth-service

# またはグループを使用
zclaude feature-api @backend
```

### Open Source Contribution

```bash
# OSS プロジェクトへの貢献
zclaude bugfix-123 react

# 複数 PR を並行管理
zclaude feature-a react
zclaude bugfix-b react
ztasks  # タスク一覧から切り替え
```

## 📦 Installation

### Prerequisites

- zsh
- git
- fzf (for interactive task selection)
- Warp or any terminal emulator (optional, for enhanced UX)

### Quick Install

```bash
git clone https://github.com/nyohoo/git-worktree-manager.git
cd git-worktree-manager
./install.sh
```

The installer will guide you through:
1. Setting up your repository root directory
2. Configuring the worktree location
3. Adding configuration to `.zshrc`

### Manual Install

```bash
# 1. Copy files
mkdir -p ~/.config/gwm
cp gwm.zsh ~/.config/gwm/
cp groups.conf ~/.config/gwm/

# 2. Add to .zshrc
cat >> ~/.zshrc << 'EOF'

# Git Worktree Manager
export GWT_REPOS_ROOT="$HOME/repos"
export GWT_WORKTREE_ROOT="$GWT_REPOS_ROOT/worktrees"
export GWT_BASE_BRANCH="main"
export GWT_GROUPS_FILE="$HOME/.config/gwm/groups.conf"
source ~/.config/gwm/gwm.zsh
EOF

# 3. Reload shell
source ~/.zshrc
```

## 🚀 Quick Start

```bash
# 1. Create a task
zclaude feature-api backend

# 2. Edit with Claude Code (automatically launched)
cd $GWT_WORKTREE_ROOT/feature-api/backend
claude

# 3. Test in main repository
ztest feature-api

# 4. Clean up when done
zclean feature-api
```

## 📖 Documentation

- [User Guide](worktree-commands-README.md) - Detailed usage guide
- [Contributing](CONTRIBUTING.md) - How to contribute
- [License](LICENSE) - MIT License

## 💡 Commands Overview

| Command | Description |
|---------|-------------|
| `zclaude <task> [repos...]` | Create a new task with specified repositories |
| `zpull <PR-URL>` | Create worktree from GitHub PR URL |
| `zadd <repos...>` | Add repositories to current task |
| `ztest <task>` | Switch main repositories to task branch |
| `zclean <task>` | Clean up task and worktrees |
| `ztasks` | List and select tasks (fzf) |
| `zcursor [task]` | Open task in Cursor |
| `zprune` | Clean up branches and worktrees interactively |

## 🔧 Configuration

### Environment Variables

```bash
# Required
export GWT_REPOS_ROOT="$HOME/repos"              # Repository root directory

# Optional
export GWT_WORKTREE_ROOT="$GWT_REPOS_ROOT/wt"   # Worktree location (default: $GWT_REPOS_ROOT/worktrees)
export GWT_BASE_BRANCH="main"                    # Base branch (default: main)
export GWT_GROUPS_FILE="$HOME/.config/gwm/groups.conf"  # Groups file
```

### Repository Groups

Define common repository combinations in `~/.config/gwm/groups.conf`:

```conf
# Backend services
backend=api-gateway,auth-service,user-service

# Frontend apps
frontend=web-app,mobile-app

# Full stack
fullstack=api-gateway,auth-service,web-app
```

Usage:

```bash
zclaude feature-api @backend @frontend
zadd @fullstack
```

## 🌟 Examples

### Single Repository

```bash
zclaude feature-api backend
# Edit in worktree
cd $GWT_WORKTREE_ROOT/feature-api/backend
# Test in main
ztest feature-api
```

### Multiple Repositories

```bash
# Create task with multiple repos
zclaude feature-integration backend frontend

# Add more repos later
cd $GWT_WORKTREE_ROOT/feature-integration/backend
zadd auth-service

# Open all in Cursor
zcursor feature-integration
```

### Task Management

```bash
# List all tasks
ztasks

# Switch between tasks (no stash needed!)
cd $GWT_WORKTREE_ROOT/task-a/backend  # Work on task A
cd $GWT_WORKTREE_ROOT/task-b/frontend # Work on task B
```

### PR Review

```bash
# Create worktree from PR URL
zpull https://github.com/heyinc/rsv-rails/pull/27158

# Review the code
cd $GWT_WORKTREE_ROOT/fix-bug-urgent/rsv-rails

# Test the changes
ztest fix-bug-urgent

# Clean up after review
zclean fix-bug-urgent
```

## 🏗️ Project Structure

```
$GWT_REPOS_ROOT/
├── backend/                      # Main repository (for testing)
├── frontend/                     # Main repository
└── worktrees/                    # Worktree area
    ├── feature-api/
    │   ├── backend/              # git worktree
    │   ├── .workspace            # Metadata
    │   └── feature-api.code-workspace  # Cursor workspace
    └── bugfix-login/
        ├── auth-service/
        └── ...
```

## 🤔 FAQ

### Q: Difference from normal branch switching?

**Normal branch switching:**
- `git checkout feature-A`
- Requires stash when switching between branches
- "Which branch am I on?" confusion

**Worktree:**
- Each branch has its own physical directory
- Switching is just `cd`
- No stash needed, no confusion

### Q: Is the database shared?

Yes. Worktrees only manage code. The database is shared.
Be careful when testing migrations.

### Q: Can I run servers for multiple tasks simultaneously?

Technically yes, but watch out for port conflicts.
Generally recommended to run only one server at a time.

## 🚀 Raycast Integration

Git Worktree Manager includes Raycast Script Commands for quick access to your tasks.

### Available Commands

| Command | Description |
|---------|-------------|
| 📦 List Worktree Tasks | Show all active tasks with details |
| 🎨 Open Task in Cursor | Open a task in Cursor editor |
| 🖥️ Open Task in Terminal | Open a task directory in terminal |
| 📋 Copy Task Path | Copy task path to clipboard |

### Setup

1. Install Raycast:
   ```bash
   brew install --cask raycast
   ```

2. Add Script Commands directory:
   - Open Raycast → Extensions → "+" → Add Script Directory
   - Select: `~/.config/gwm/raycast`

3. Start using:
   - Press `⌘ + Space` to open Raycast
   - Type "list worktree" or "open task"

See [raycast/README.md](raycast/README.md) for detailed setup and customization.

## 🤝 Contributing

Contributions are welcome! See [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines.

## 📄 License

MIT License - see [LICENSE](LICENSE) for details.

## 🙏 Acknowledgments

- Built with love for developers tired of `git stash`
- Optimized for Claude Code integration
- Inspired by multi-repository development workflows

## 🔗 Links

- GitHub: https://github.com/nyohoo/git-worktree-manager
- Issues: https://github.com/nyohoo/git-worktree-manager/issues
- Discussions: https://github.com/nyohoo/git-worktree-manager/discussions

---

**Happy Coding! 🚀**
