#!/usr/bin/env bash
# ============================================================================
# Git Worktree Manager - インストールスクリプト
# ============================================================================

set -e

# 色付き出力
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

info() {
  echo -e "${BLUE}ℹ️  $1${NC}"
}

success() {
  echo -e "${GREEN}✅ $1${NC}"
}

error() {
  echo -e "${RED}❌ エラー: $1${NC}"
  exit 1
}

warning() {
  echo -e "${YELLOW}⚠️  $1${NC}"
}

# ============================================================================
# 前提条件チェック
# ============================================================================

info "前提条件をチェック中..."

# zsh のチェック
if ! command -v zsh >/dev/null 2>&1; then
  error "zsh がインストールされていません"
fi

# git のチェック
if ! command -v git >/dev/null 2>&1; then
  error "git がインストールされていません"
fi

# fzf のチェック（オプション）
if ! command -v fzf >/dev/null 2>&1; then
  warning "fzf がインストールされていません（ztasks コマンドに必要）"
  echo "  インストール: brew install fzf （macOS）"
  echo "  続行しますか？ (y/n)"
  read -r response
  if [[ ! "$response" =~ ^[Yy]$ ]]; then
    exit 0
  fi
fi

success "前提条件チェック完了"
echo ""

# ============================================================================
# インストール開始
# ============================================================================

echo "╔════════════════════════════════════════════════════════════════╗"
echo "║  Git Worktree Manager - インストール                          ║"
echo "╚════════════════════════════════════════════════════════════════╝"
echo ""

# ============================================================================
# 設定の質問
# ============================================================================

info "環境設定を行います"
echo ""

# リポジトリルートの質問
echo "リポジトリのルートディレクトリを指定してください。"
echo "（例: $HOME/repos, $HOME/projects, $HOME/ghq/github.com/yourorg）"
read -p "リポジトリルート [デフォルト: $HOME/repos]: " repos_root
repos_root=${repos_root:-$HOME/repos}

# 絶対パスに展開
repos_root=$(eval echo "$repos_root")

# worktree 配置先の質問
echo ""
echo "worktree を配置するディレクトリを指定してください。"
read -p "worktree配置先 [デフォルト: ${repos_root}/worktrees]: " worktree_root
worktree_root=${worktree_root:-${repos_root}/worktrees}

# 絶対パスに展開
worktree_root=$(eval echo "$worktree_root")

# ベースブランチの質問
echo ""
echo "デフォルトのベースブランチを指定してください。"
read -p "ベースブランチ [デフォルト: main]: " base_branch
base_branch=${base_branch:-main}

echo ""
info "設定内容を確認してください："
echo "  リポジトリルート: $repos_root"
echo "  worktree配置先:   $worktree_root"
echo "  ベースブランチ:    $base_branch"
echo ""
read -p "この設定でインストールしますか？ (y/n): " confirm

if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
  echo "インストールをキャンセルしました"
  exit 0
fi

echo ""

# ============================================================================
# ファイルのコピー
# ============================================================================

info "ファイルをインストール中..."

# インストール先ディレクトリを作成
mkdir -p ~/.config/gwm

# スクリプトのディレクトリを取得
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# メインスクリプトをコピー
if [[ -f "$SCRIPT_DIR/gwm.zsh" ]]; then
  cp "$SCRIPT_DIR/gwm.zsh" ~/.config/gwm/
  success "gwm.zsh をコピーしました"
elif [[ -f "$SCRIPT_DIR/worktree-commands.zsh" ]]; then
  # 旧ファイル名から変換
  cp "$SCRIPT_DIR/worktree-commands.zsh" ~/.config/gwm/gwm.zsh
  success "gwm.zsh をコピーしました"
else
  error "gwm.zsh が見つかりません"
fi

# グループ定義ファイルをコピー（存在する場合）
if [[ -f "$SCRIPT_DIR/groups.conf" ]]; then
  if [[ -f ~/.config/gwm/groups.conf ]]; then
    warning "既存の groups.conf が見つかりました（上書きしません）"
  else
    cp "$SCRIPT_DIR/groups.conf" ~/.config/gwm/
    success "groups.conf をコピーしました"
  fi
elif [[ -f "$SCRIPT_DIR/groups.conf.example" ]]; then
  cp "$SCRIPT_DIR/groups.conf.example" ~/.config/gwm/groups.conf
  success "groups.conf をコピーしました"
fi

# README をコピー（オプション）
if [[ -f "$SCRIPT_DIR/README.md" ]]; then
  cp "$SCRIPT_DIR/README.md" ~/.config/gwm/
fi

echo ""

# ============================================================================
# .zshrc への追加
# ============================================================================

info ".zshrc に設定を追加中..."

ZSHRC="$HOME/.zshrc"

# バックアップを作成
if [[ -f "$ZSHRC" ]]; then
  cp "$ZSHRC" "${ZSHRC}.backup.$(date +%Y%m%d_%H%M%S)"
  success ".zshrc のバックアップを作成しました"
fi

# 既存の設定をチェック
if grep -q "# Git Worktree Manager" "$ZSHRC" 2>/dev/null; then
  warning ".zshrc に既存の設定が見つかりました"
  echo "  既存の設定を更新しますか？ (y/n)"
  read -r update_config

  if [[ "$update_config" =~ ^[Yy]$ ]]; then
    # 既存のセクションを削除
    sed -i.bak '/# Git Worktree Manager/,/source ~\/.config\/gwm\/gwm.zsh/d' "$ZSHRC"
    info "既存の設定を削除しました"
  else
    warning "設定の追加をスキップしました"
    echo ""
    info "手動で以下を .zshrc に追加してください："
    echo ""
    echo "# Git Worktree Manager"
    echo "export GWT_REPOS_ROOT=\"$repos_root\""
    echo "export GWT_WORKTREE_ROOT=\"$worktree_root\""
    echo "export GWT_BASE_BRANCH=\"$base_branch\""
    echo "export GWT_GROUPS_FILE=\"\$HOME/.config/gwm/groups.conf\""
    echo "source ~/.config/gwm/gwm.zsh"
    echo ""
    exit 0
  fi
fi

# 新しい設定を追加
cat >> "$ZSHRC" << EOF

# Git Worktree Manager
export GWT_REPOS_ROOT="$repos_root"
export GWT_WORKTREE_ROOT="$worktree_root"
export GWT_BASE_BRANCH="$base_branch"
export GWT_GROUPS_FILE="\$HOME/.config/gwm/groups.conf"
source ~/.config/gwm/gwm.zsh
EOF

success ".zshrc に設定を追加しました"
echo ""

# ============================================================================
# ディレクトリ作成
# ============================================================================

info "ディレクトリを作成中..."

# リポジトリルートを作成
if [[ ! -d "$repos_root" ]]; then
  mkdir -p "$repos_root"
  success "リポジトリルート を作成しました: $repos_root"
else
  info "リポジトリルート が既に存在します: $repos_root"
fi

# worktree ディレクトリを作成
if [[ ! -d "$worktree_root" ]]; then
  mkdir -p "$worktree_root"
  success "worktree ディレクトリを作成しました: $worktree_root"
else
  info "worktree ディレクトリが既に存在します: $worktree_root"
fi

echo ""

# ============================================================================
# 完了
# ============================================================================

success "インストールが完了しました！"
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "🚀 次のステップ:"
echo ""
echo "  1. シェルをリロード:"
echo "     source ~/.zshrc"
echo ""
echo "  2. ヘルプを表示:"
echo "     zclaude help"
echo ""
echo "  3. 最初のタスクを作成:"
echo "     zclaude my-first-task my-repo"
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "📚 ドキュメント:"
echo "  - README: ~/.config/gwm/README.md"
echo "  - GitHub: https://github.com/YOUR_ORG/git-worktree-manager"
echo ""
echo "💡 Tips:"
echo "  - リポジトリグループを定義: ~/.config/gwm/groups.conf"
echo "  - タスク一覧を表示: ztasks"
echo ""

success "Happy Coding! 🎉"
