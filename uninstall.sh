#!/usr/bin/env bash
# ============================================================================
# Git Worktree Manager - アンインストールスクリプト
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
# アンインストール開始
# ============================================================================

echo "╔════════════════════════════════════════════════════════════════╗"
echo "║  Git Worktree Manager - アンインストール                      ║"
echo "╚════════════════════════════════════════════════════════════════╝"
echo ""

warning "以下のファイル・設定が削除されます："
echo "  - ~/.config/gwm/"
echo "  - .zshrc 内の Git Worktree Manager 設定"
echo ""
echo "⚠️  worktree ディレクトリと リポジトリは削除されません"
echo ""

read -p "アンインストールを続行しますか？ (y/n): " confirm

if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
  echo "アンインストールをキャンセルしました"
  exit 0
fi

echo ""

# ============================================================================
# .zshrc からの削除
# ============================================================================

info ".zshrc から設定を削除中..."

ZSHRC="$HOME/.zshrc"

if [[ -f "$ZSHRC" ]]; then
  # バックアップを作成
  cp "$ZSHRC" "${ZSHRC}.backup.$(date +%Y%m%d_%H%M%S)"
  success ".zshrc のバックアップを作成しました"

  # Git Worktree Manager のセクションを削除
  if grep -q "# Git Worktree Manager" "$ZSHRC"; then
    sed -i.bak '/# Git Worktree Manager/,/source ~\/.config\/gwm\/gwm.zsh/d' "$ZSHRC"
    # 空行を削除（連続する空行を1つにする）
    sed -i.bak '/^$/N;/^\n$/D' "$ZSHRC"
    rm -f "${ZSHRC}.bak"
    success ".zshrc から設定を削除しました"
  else
    info ".zshrc に設定が見つかりませんでした"
  fi
else
  warning ".zshrc が見つかりません"
fi

echo ""

# ============================================================================
# ファイルの削除
# ============================================================================

info "ファイルを削除中..."

if [[ -d ~/.config/gwm ]]; then
  # groups.conf のバックアップ確認
  if [[ -f ~/.config/gwm/groups.conf ]]; then
    echo ""
    warning "カスタマイズした groups.conf が見つかりました"
    read -p "バックアップを作成しますか？ (y/n): " backup_groups

    if [[ "$backup_groups" =~ ^[Yy]$ ]]; then
      backup_path="$HOME/gwm-groups.conf.backup.$(date +%Y%m%d_%H%M%S)"
      cp ~/.config/gwm/groups.conf "$backup_path"
      success "groups.conf をバックアップしました: $backup_path"
    fi
  fi

  rm -rf ~/.config/gwm
  success "~/.config/gwm を削除しました"
else
  info "~/.config/gwm が見つかりません"
fi

echo ""

# ============================================================================
# worktree の確認
# ============================================================================

info "アクティブな worktree を確認中..."

# .zshrc から GWT_WORKTREE_ROOT を取得（削除前のバックアップから）
worktree_root=""
if [[ -f "${ZSHRC}.backup."* ]]; then
  latest_backup=$(ls -t "${ZSHRC}.backup."* | head -1)
  worktree_root=$(grep "export GWT_WORKTREE_ROOT=" "$latest_backup" 2>/dev/null | cut -d'"' -f2)
fi

if [[ -n "$worktree_root" ]] && [[ -d "$worktree_root" ]]; then
  task_count=$(find "$worktree_root" -maxdepth 1 -type d ! -path "$worktree_root" | wc -l | tr -d ' ')

  if [[ "$task_count" -gt 0 ]]; then
    echo ""
    warning "アクティブなタスクが ${task_count} 個見つかりました: $worktree_root"
    echo ""
    echo "これらのタスクディレクトリは削除されません。"
    echo "必要に応じて手動で削除してください："
    echo "  rm -rf $worktree_root"
    echo ""
    echo "または、各リポジトリで worktree を削除："
    echo "  git worktree list"
    echo "  git worktree remove <path>"
    echo ""
  else
    info "アクティブなタスクはありません"
  fi
fi

# ============================================================================
# 完了
# ============================================================================

success "アンインストールが完了しました"
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "🔄 次のステップ:"
echo ""
echo "  1. シェルをリロード:"
echo "     source ~/.zshrc"
echo ""
echo "  2. （オプション）worktree ディレクトリを削除:"
if [[ -n "$worktree_root" ]]; then
  echo "     rm -rf $worktree_root"
else
  echo "     rm -rf <your-worktree-directory>"
fi
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

success "ご利用ありがとうございました！"
