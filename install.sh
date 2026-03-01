#!/usr/bin/env bash
# ============================================================================
# Git Worktree Manager - セットアップウィザード
# ============================================================================

set -e

# 色付き出力
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
BOLD='\033[1m'
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

highlight() {
  echo -e "${CYAN}${BOLD}$1${NC}"
}

# ============================================================================
# 既存設定のチェック
# ============================================================================

check_existing_config() {
  if [[ -n "$GWT_REPOS_ROOT" ]]; then
    echo ""
    highlight "既存の設定が検出されました"
    echo ""
    echo "  GWT_REPOS_ROOT:      $GWT_REPOS_ROOT"
    echo "  GWT_WORKTREE_ROOT:   ${GWT_WORKTREE_ROOT:-未設定}"
    echo "  GWT_BASE_BRANCH:     ${GWT_BASE_BRANCH:-未設定}"
    echo ""
    read -p "再設定しますか？ (y/n): " response
    if [[ ! "$response" =~ ^[Yy]$ ]]; then
      echo ""
      success "既存の設定を維持します"
      exit 0
    fi
    echo ""
  fi
}

# ============================================================================
# プロジェクト構造の自動検出
# ============================================================================

detect_project_roots() {
  local candidates=()
  local candidate_repos=()

  info "プロジェクト構造を検出中..."
  echo ""

  # 候補1: ~/repos
  if [[ -d "$HOME/repos" ]]; then
    local count=$(find "$HOME/repos" -maxdepth 2 -name ".git" -type d 2>/dev/null | wc -l | tr -d ' ')
    candidates+=("$HOME/repos")
    candidate_repos+=("$count")
  fi

  # 候補2: ~/projects
  if [[ -d "$HOME/projects" ]]; then
    local count=$(find "$HOME/projects" -maxdepth 2 -name ".git" -type d 2>/dev/null | wc -l | tr -d ' ')
    candidates+=("$HOME/projects")
    candidate_repos+=("$count")
  fi

  # 候補3: ~/ghq/github.com/* (複数の組織)
  if [[ -d "$HOME/ghq/github.com" ]]; then
    for org_dir in "$HOME/ghq/github.com"/*; do
      if [[ -d "$org_dir" ]]; then
        local count=$(find "$org_dir" -maxdepth 1 -name ".git" -type d 2>/dev/null | wc -l | tr -d ' ')
        if [[ "$count" -gt 0 ]]; then
          candidates+=("$org_dir")
          candidate_repos+=("$count")
        fi
      fi
    done
  fi

  # 候補4: ~/src
  if [[ -d "$HOME/src" ]]; then
    local count=$(find "$HOME/src" -maxdepth 2 -name ".git" -type d 2>/dev/null | wc -l | tr -d ' ')
    candidates+=("$HOME/src")
    candidate_repos+=("$count")
  fi

  # 結果を表示
  if [[ ${#candidates[@]} -gt 0 ]]; then
    highlight "以下の候補が見つかりました："
    echo ""
    for i in "${!candidates[@]}"; do
      local idx=$((i + 1))
      local path="${candidates[$i]}"
      local count="${candidate_repos[$i]}"
      echo "  $idx) $path"
      if [[ "$count" -gt 0 ]]; then
        echo "     (${count}個のリポジトリ)"
      else
        echo "     (リポジトリなし)"
      fi
    done
    echo "  $((${#candidates[@]} + 1))) カスタムパスを入力"
    echo ""

    # 選択
    while true; do
      read -p "どれを使いますか？ [1-$((${#candidates[@]} + 1))]: " choice

      if [[ "$choice" =~ ^[0-9]+$ ]] && [[ "$choice" -ge 1 ]] && [[ "$choice" -le $((${#candidates[@]} + 1)) ]]; then
        if [[ "$choice" -eq $((${#candidates[@]} + 1)) ]]; then
          # カスタムパス入力
          echo ""
          read -p "リポジトリルートのパスを入力: " custom_path
          custom_path=$(eval echo "$custom_path")
          if [[ -d "$custom_path" ]]; then
            echo "$custom_path"
            return 0
          else
            warning "ディレクトリが見つかりません: $custom_path"
            read -p "作成しますか？ (y/n): " create
            if [[ "$create" =~ ^[Yy]$ ]]; then
              mkdir -p "$custom_path"
              echo "$custom_path"
              return 0
            fi
          fi
        else
          # 候補から選択
          local selected="${candidates[$((choice - 1))]}"
          echo "$selected"
          return 0
        fi
      else
        warning "無効な選択です"
      fi
    done
  else
    # 候補が見つからない場合
    warning "プロジェクトディレクトリが見つかりませんでした"
    echo ""
    echo "リポジトリのルートディレクトリを指定してください。"
    echo "（例: $HOME/repos, $HOME/projects, $HOME/ghq/github.com/yourorg）"
    read -p "リポジトリルート: " repos_root
    repos_root=$(eval echo "${repos_root:-$HOME/repos}")
    echo "$repos_root"
    return 0
  fi
}

# ============================================================================
# リポジトリ一覧のプレビュー
# ============================================================================

preview_repositories() {
  local repos_root="$1"

  echo ""
  info "リポジトリ一覧:"

  local repos=()
  for dir in "$repos_root"/*; do
    if [[ -d "$dir/.git" ]]; then
      repos+=("$(basename "$dir")")
    fi
  done

  if [[ ${#repos[@]} -eq 0 ]]; then
    warning "git リポジトリが見つかりませんでした"
    echo "  このディレクトリにリポジトリを clone してから使用してください"
  else
    local display_count=5
    for i in "${!repos[@]}"; do
      if [[ $i -lt $display_count ]]; then
        echo "  - ${repos[$i]}"
      fi
    done
    if [[ ${#repos[@]} -gt $display_count ]]; then
      echo "  ... (他 $((${#repos[@]} - display_count)) 個)"
    fi
  fi
  echo ""
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
  echo ""
fi

success "前提条件チェック完了"
echo ""

# ============================================================================
# インストール開始
# ============================================================================

echo "╔════════════════════════════════════════════════════════════════╗"
echo "║  Git Worktree Manager - セットアップウィザード                ║"
echo "╚════════════════════════════════════════════════════════════════╝"
echo ""

# 既存設定のチェック
check_existing_config

# ============================================================================
# 設定の質問
# ============================================================================

# プロジェクト構造の自動検出
repos_root=$(detect_project_roots)

# 絶対パスに展開
repos_root=$(eval echo "$repos_root")

echo ""
success "リポジトリルート: $repos_root"

# リポジトリ一覧のプレビュー
preview_repositories "$repos_root"

# worktree 配置先の質問
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
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
highlight "⚙️  設定内容:"
echo "  リポジトリルート: $repos_root"
echo "  worktree配置先:   $worktree_root"
echo "  ベースブランチ:    $base_branch"
echo ""

while true; do
  read -p "この設定でインストールしますか？ (y/n/e[編集]): " confirm

  case "$confirm" in
    [Yy]*)
      break
      ;;
    [Ee]*)
      echo ""
      read -p "リポジトリルート [$repos_root]: " new_repos_root
      repos_root=${new_repos_root:-$repos_root}
      repos_root=$(eval echo "$repos_root")

      read -p "worktree配置先 [$worktree_root]: " new_worktree_root
      worktree_root=${new_worktree_root:-$worktree_root}
      worktree_root=$(eval echo "$worktree_root")

      read -p "ベースブランチ [$base_branch]: " new_base_branch
      base_branch=${new_base_branch:-$base_branch}

      echo ""
      highlight "⚙️  更新後の設定:"
      echo "  リポジトリルート: $repos_root"
      echo "  worktree配置先:   $worktree_root"
      echo "  ベースブランチ:    $base_branch"
      echo ""
      ;;
    [Nn]*)
      echo ""
      info "インストールをキャンセルしました"
      exit 0
      ;;
    *)
      warning "y, n, e のいずれかを入力してください"
      ;;
  esac
done

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
if [[ -f "$SCRIPT_DIR/USAGE.md" ]]; then
  cp "$SCRIPT_DIR/USAGE.md" ~/.config/gwm/
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
    # 古いフォーマットも削除
    sed -i.bak '/# ============================================/,/^fi$/d' "$ZSHRC"
    sed -i.bak '/# Claude Code 並列開発環境/d' "$ZSHRC"
    rm -f "${ZSHRC}.bak"
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

# ============================================================================
# Git Worktree Manager
# ============================================================================
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
highlight "🚀 次のステップ:"
echo ""
echo "  1. シェルをリロード:"
echo "     ${CYAN}source ~/.zshrc${NC}"
echo ""
echo "  2. ヘルプを表示:"
echo "     ${CYAN}zclaude help${NC}"
echo ""
echo "  3. 最初のタスクを作成:"
echo "     ${CYAN}zclaude my-first-task my-repo${NC}"
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "📚 ドキュメント:"
echo "  - 詳細ガイド: ~/.config/gwm/USAGE.md"
echo "  - GitHub: https://github.com/nyohoo/git-worktree-manager"
echo ""
echo "💡 Tips:"
echo "  - リポジトリグループを定義: ~/.config/gwm/groups.conf"
echo "  - タスク一覧を表示: ${CYAN}ztasks${NC}"
echo "  - メインに戻る: ${CYAN}ztasks${NC} → [Main] を選択"
echo ""

success "Happy Coding! 🎉"
