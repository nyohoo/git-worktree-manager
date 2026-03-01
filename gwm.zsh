#!/usr/bin/env zsh
# ============================================================================
# Git Worktree Manager (gwm) - Claude Code 統合開発環境
# ============================================================================
#
# 使い方:
#   zclaude <task-name> <repo1> [repo2] ...  - タスク開始（worktree作成）
#   zclaude help                              - ヘルプ表示
#   ztest <task-name>                         - 動作確認（メインでcheckout）
#   zclean <task-name>                        - タスク終了（worktree削除）
#   ztasks                                    - タスク一覧表示（fzf）
#   zcursor [task-name]                       - Cursorで開く
#

# ============================================================================
# 設定
# ============================================================================

# リポジトリのルートディレクトリ（必須）
# インストール時に設定してください
export GWT_REPOS_ROOT="${GWT_REPOS_ROOT:-}"

# worktree を配置するディレクトリ
export GWT_WORKTREE_ROOT="${GWT_WORKTREE_ROOT:-${GWT_REPOS_ROOT}/worktrees}"

# デフォルトのベースブランチ
export GWT_BASE_BRANCH="${GWT_BASE_BRANCH:-main}"

# グループ定義ファイル（オプション）
export GWT_GROUPS_FILE="${GWT_GROUPS_FILE:-$HOME/.config/gwm/groups.conf}"

# ============================================================================
# ヘルパー関数
# ============================================================================

# エラーメッセージを表示して終了
_worktree_error() {
  echo "❌ エラー: $1" >&2
  return 1
}

# 成功メッセージを表示
_worktree_success() {
  echo "✅ $1"
}

# 情報メッセージを表示
_worktree_info() {
  echo "🔵 $1"
}

# Warpの新しいタブを開く（AppleScript使用）
_warp_new_tab() {
  local directory="$1"
  local tab_name="$2"

  osascript <<EOF 2>/dev/null
    tell application "Warp"
      activate
      tell application "System Events"
        keystroke "t" using command down
        delay 0.3
        keystroke "cd '$directory'"
        keystroke return
        delay 0.2
        keystroke "printf '\\e]0;$tab_name\\a'"
        keystroke return
      end tell
    end tell
EOF
}

# Warpのペインを分割
_warp_split_pane() {
  osascript <<EOF 2>/dev/null
    tell application "System Events"
      keystroke "d" using command down
    end tell
EOF
}

# 環境変数の検証
_check_environment() {
  if [[ -z "$GWT_REPOS_ROOT" ]]; then
    _worktree_error "GWT_REPOS_ROOT が設定されていません"
    echo ""
    echo "セットアップ方法:"
    echo "  1. .zshrc に以下を追加:"
    echo ""
    echo "     export GWT_REPOS_ROOT=\"\$HOME/repos\""
    echo "     export GWT_WORKTREE_ROOT=\"\$GWT_REPOS_ROOT/worktrees\""
    echo "     source ~/.config/gwm/gwm.zsh"
    echo ""
    echo "  2. シェルをリロード:"
    echo "     source ~/.zshrc"
    echo ""
    return 1
  fi

  if [[ ! -d "$GWT_REPOS_ROOT" ]]; then
    _worktree_error "リポジトリディレクトリが見つかりません: $GWT_REPOS_ROOT"
    echo "ディレクトリを作成するか、GWT_REPOS_ROOT を正しいパスに設定してください"
    return 1
  fi

  return 0
}

# ============================================================================
# メインコマンド: zclaude
# ============================================================================

_zclaude_impl() {
  # 環境変数チェック
  _check_environment || return 1

  # ヘルプ表示
  if [[ "$1" == "help" || "$1" == "-h" || "$1" == "--help" ]]; then
    cat << 'EOF'
╔════════════════════════════════════════════════════════════════╗
║  Git Worktree Manager - コマンド一覧                          ║
╚════════════════════════════════════════════════════════════════╝

📦 タスク管理:
  zclaude <task> [repo] [repo2...]  新しいタスクを開始
  zadd <repo> [repo2...]            カレントタスクにリポジトリを追加
  ztest <task>                      メインリポジトリで動作確認
  zclean <task>                     タスクを終了・削除
  ztasks                            タスク一覧（fzf）

🎨 エディタ:
  zcursor [task]                    Cursorで開く

📚 その他:
  zclaude help                      このヘルプを表示

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

📖 使用例:

  # カレントディレクトリのリポジトリで自動検出
  cd $GWT_REPOS_ROOT/my-backend
  zclaude feature-new-api

  # 明示的にリポジトリを指定
  zclaude feature-new-api my-backend

  # 複数リポジトリ（横断開発）
  zclaude feature-integration backend frontend

  # 後からリポジトリを追加
  cd $GWT_WORKTREE_ROOT/feature-new-api/backend
  zadd frontend auth-service

  # グループで一括追加
  zadd @backend @frontend

  # タスク一覧から選択
  ztasks

  # メインで動作確認
  ztest feature-new-api

  # タスク終了
  zclean feature-new-api

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

🔧 環境変数:
  GWT_REPOS_ROOT       リポジトリルート（必須）
  GWT_WORKTREE_ROOT    worktree配置先（デフォルト: $GWT_REPOS_ROOT/worktrees）
  GWT_BASE_BRANCH      ベースブランチ（デフォルト: main）
  GWT_GROUPS_FILE      グループ定義ファイル（デフォルト: ~/.config/gwm/groups.conf）

📚 ドキュメント:
  https://github.com/nyohoo/git-worktree-manager

EOF
    return 0
  fi

  # 引数チェック
  if [[ $# -lt 1 ]]; then
    _worktree_error "使い方: zclaude <タスク名> [リポジトリ1|@グループ名] ..."
    echo "例: zclaude feature-api backend frontend"
    echo "例: zclaude feature-api @backend @frontend"
    echo "または: zclaude feature-api （カレントディレクトリのリポジトリを自動検出）"
    echo ""
    echo "詳細は 'zclaude help' を実行してください"
    return 1
  fi

  local task_name="$1"
  shift

  # グループ定義を読み込み
  declare -A group_defs
  if [[ -f $GWT_GROUPS_FILE ]]; then
    while IFS='=' read -r key value; do
      # コメント行と空行をスキップ
      [[ "$key" =~ ^[[:space:]]*# ]] && continue
      [[ -z "$key" ]] && continue
      group_defs[$key]="$value"
    done < $GWT_GROUPS_FILE
  fi

  # 引数を展開（@グループ を実際のリポジトリリストに変換）
  local repos=()
  for arg in "$@"; do
    if [[ "$arg" == @* ]]; then
      # グループ名（@ を削除）
      local group_name="${arg#@}"
      if [[ -n "${group_defs[$group_name]}" ]]; then
        # カンマ区切りを配列に展開
        IFS=',' read -rA group_repos <<< "${group_defs[$group_name]}"
        repos+=("${group_repos[@]}")
        _worktree_info "グループ @$group_name を展開: ${group_repos[*]}"
      else
        _worktree_error "グループ @$group_name が見つかりません"
        echo "利用可能なグループ: ${(k)group_defs[@]}"
        return 1
      fi
    else
      # 通常のリポジトリ名
      repos+=("$arg")
    fi
  done

  # リポジトリ指定がない場合、カレントディレクトリを自動検出
  if [[ ${#repos[@]} -eq 0 ]]; then
    local current_dir="$PWD"

    # カレントディレクトリが $GWT_REPOS_ROOT 配下かチェック
    if [[ "$current_dir" == "$GWT_REPOS_ROOT"/* ]]; then
      # リポジトリ名を抽出（$GWT_REPOS_ROOT の直下のディレクトリ名）
      local relative_path="${current_dir#$GWT_REPOS_ROOT/}"
      local detected_repo="${relative_path%%/*}"

      # リポジトリディレクトリが存在するかチェック
      if [[ -d "$GWT_REPOS_ROOT/$detected_repo/.git" ]]; then
        repos=("$detected_repo")
        _worktree_info "カレントディレクトリから自動検出: $detected_repo"
      else
        _worktree_error "カレントディレクトリからリポジトリを検出できませんでした"
        echo "リポジトリを明示的に指定するか、リポジトリディレクトリ内で実行してください"
        return 1
      fi
    else
      _worktree_error "リポジトリが指定されておらず、カレントディレクトリも $GWT_REPOS_ROOT 配下ではありません"
      echo "使い方: zclaude <タスク名> <リポジトリ1> [リポジトリ2] ..."
      echo "例: zclaude feature-api rsv-rails"
      return 1
    fi
  fi

  # タスクディレクトリの作成
  local task_dir="${GWT_WORKTREE_ROOT}/${task_name}"

  if [[ -d "$task_dir" ]]; then
    _worktree_error "タスク '$task_name' は既に存在します: $task_dir"
    return 1
  fi

  _worktree_info "タスクを作成中: $task_name"
  mkdir -p "$task_dir"

  # 各リポジトリのworktreeを作成
  local created_repos=()
  for repo in "${repos[@]}"; do
    local repo_main="${GWT_REPOS_ROOT}/${repo}"
    local repo_worktree="${task_dir}/${repo}"

    if [[ ! -d "$repo_main" ]]; then
      _worktree_error "リポジトリが見つかりません: $repo_main"
      # クリーンアップ
      for created in "${created_repos[@]}"; do
        git -C "${GWT_REPOS_ROOT}/${created}" worktree remove "${task_dir}/${created}" 2>/dev/null
      done
      rm -rf "$task_dir"
      return 1
    fi

    _worktree_info "$repo の worktree を作成中..."

    # ベースブランチを検出（main or master）
    local base_branch
    if git -C "$repo_main" rev-parse --verify main >/dev/null 2>&1; then
      base_branch="main"
    elif git -C "$repo_main" rev-parse --verify master >/dev/null 2>&1; then
      base_branch="master"
    else
      base_branch="$GWT_BASE_BRANCH"
    fi

    # 最新の状態を取得（git pull）
    _worktree_info "$repo で最新の変更を取得中..."
    local current_branch=$(git -C "$repo_main" branch --show-current 2>/dev/null)

    # ベースブランチにいない場合は一時的に切り替え
    if [[ "$current_branch" != "$base_branch" ]]; then
      git -C "$repo_main" checkout "$base_branch" >/dev/null 2>&1
    fi

    # git pull を実行
    if git -C "$repo_main" pull origin "$base_branch" 2>&1 | grep -v "Already up to date"; then
      _worktree_success "$repo を最新化しました"
    else
      echo "⚠️  $repo の pull をスキップしました（既に最新 or エラー）"
    fi

    # 元のブランチに戻す（必要な場合）
    if [[ "$current_branch" != "$base_branch" ]] && [[ -n "$current_branch" ]]; then
      git -C "$repo_main" checkout "$current_branch" >/dev/null 2>&1
    fi

    # worktree作成
    git -C "$repo_main" worktree add -b "$task_name" "$repo_worktree" "$base_branch" 2>&1

    # Worktreeが実際に作成されたかチェック（post-checkoutフックのexit codeは無視）
    if [[ ! -d "$repo_worktree" ]]; then
      _worktree_error "$repo の worktree 作成に失敗しました"
      # クリーンアップ
      for created in "${created_repos[@]}"; do
        git -C "${GWT_REPOS_ROOT}/${created}" worktree remove "${task_dir}/${created}" 2>/dev/null
      done
      rm -rf "$task_dir"
      return 1
    fi

    created_repos+=("$repo")
  done

  # .workspaceファイルを作成（メタデータ）
  {
    echo "# Worktree metadata"
    echo "TASK_NAME=\"${task_name}\""
    echo "REPOS=(${repos[@]})"
    echo "BRANCH_NAME=\"${task_name}\""
    echo "CREATED_AT=\"$(date -u +"%Y-%m-%dT%H:%M:%SZ")\""
    echo "BASE_BRANCH=\"${base_branch}\""
    echo "NOTE=\"\""
    echo "LAST_ACCESSED=\"\""
    echo "TOTAL_TIME=0"
  } > "${task_dir}/.workspace"

  # Cursorワークスペースファイルを作成
  local workspace_file="${task_dir}/${task_name}.code-workspace"
  {
    echo '{'
    echo '  "folders": ['
    # zsh互換: 最後の要素を特定してカンマを制御
    local last_repo="${repos[-1]}"
    for repo in "${repos[@]}"; do
      echo -n "    { \"path\": \"./${repo}\" }"
      if [[ "$repo" != "$last_repo" ]]; then
        echo ","
      else
        echo ""
      fi
    done
    echo '  ],'
    echo '  "settings": {'
    echo '    "workbench.colorCustomizations": {'
    # タスク名のハッシュから色を生成（簡易版・macOS対応）
    local hash_output
    if command -v md5 >/dev/null 2>&1; then
      hash_output=$(echo -n "$task_name" | md5 -q)
    else
      hash_output=$(echo -n "$task_name" | md5sum | cut -d' ' -f1)
    fi
    local color_hash=$((16#${hash_output:0:6}))
    local hue=$(( color_hash % 360 ))
    echo "      \"titleBar.activeBackground\": \"hsl(${hue}, 60%, 50%)\""
    echo '    }'
    echo '  }'
    echo '}'
  } > "$workspace_file"

  # 最初のリポジトリを取得（zsh配列は1始まり）
  local first_repo="${repos[1]}"
  local target_path="$task_dir/$first_repo"

  # 成功メッセージと次のステップを表示
  echo ""
  _worktree_success "タスク '$task_name' を作成しました！"
  echo ""
  echo "📁 作成場所: $task_dir"
  echo "🔀 リポジトリ: ${repos[*]}"
  echo ""
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo ""
  echo "🚀 クイックスタート（コピー＆ペースト）:"
  echo ""
  echo "   cd $target_path && claude"
  echo ""
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo ""
  echo "📋 その他のコマンド:"
  echo "  • Cursorで開く:         zcursor $task_name"
  echo "  • メインでテスト:       ztest $task_name"
  echo "  • タスク一覧を表示:     ztasks"
  echo "  • タスクを削除:         zclean $task_name"
  echo ""

  # クリップボードにcdコマンドをコピー（macOS）
  if command -v pbcopy >/dev/null 2>&1; then
    echo "cd $target_path && claude" | pbcopy
    echo "💡 ヒント: コマンドをクリップボードにコピーしました！⌘+V で貼り付けられます。"
    echo ""
  fi

  # Warpタブの自動起動は無効化（環境依存のため）
  # _worktree_info "Opening Warp tab..."
  # _warp_new_tab "$task_dir" "[Edit] $task_name"
  # sleep 0.5
  # osascript <<EOF 2>/dev/null
  #   tell application "System Events"
  #     keystroke "claude"
  #     keystroke return
  #   end tell
  # EOF
  # sleep 0.3
  # _warp_split_pane
}

# Wrapper function to suppress errors from Claude context injection
zclaude() {
  _zclaude_impl "$@" 2>/dev/null
  return $?
}

# ============================================================================
# メインコマンド: ztest
# ============================================================================

ztest() {
  # 環境変数チェック
  _check_environment || return 1

  local task_name="$1"

  if [[ -z "$task_name" ]]; then
    _worktree_error "使い方: ztest <タスク名>"
    return 1
  fi

  local task_dir="${GWT_WORKTREE_ROOT}/${task_name}"

  if [[ ! -d "$task_dir" ]]; then
    _worktree_error "タスク '$task_name' が見つかりません: $task_dir"
    return 1
  fi

  # .workspaceファイルを読み込み
  if [[ ! -f "${task_dir}/.workspace" ]]; then
    _worktree_error "タスクのメタデータが見つかりません: ${task_dir}/.workspace"
    return 1
  fi

  source "${task_dir}/.workspace"

  _worktree_info "タスクに切り替え中: $task_name"

  # 各リポジトリでブランチをcheckout
  for repo in "${REPOS[@]}"; do
    local repo_main="${GWT_REPOS_ROOT}/${repo}"

    if [[ ! -d "$repo_main" ]]; then
      _worktree_error "リポジトリが見つかりません: $repo_main"
      continue
    fi

    _worktree_info "$repo で '$BRANCH_NAME' をチェックアウト中..."

    # 未コミットの変更があるかチェック
    if ! git -C "$repo_main" diff-index --quiet HEAD 2>/dev/null; then
      echo "⚠️  警告: $repo に未コミットの変更があります"
      echo "   詳細は $repo_main で 'git status' を実行してください"
      read -q "REPLY?続行しますか？ (y/n) "
      echo ""
      if [[ ! "$REPLY" =~ ^[Yy]$ ]]; then
        return 1
      fi
    fi

    # checkout
    if ! git -C "$repo_main" checkout "$BRANCH_NAME" 2>&1; then
      _worktree_error "$repo で '$BRANCH_NAME' のチェックアウトに失敗しました"
      return 1
    fi

    _worktree_success "$repo で '$BRANCH_NAME' をチェックアウトしました"
  done

  # 最初のリポジトリを取得
  local first_repo="${REPOS[1]}"

  echo ""
  _worktree_success "タスク '$task_name' に切り替えました"
  echo ""
  echo "📁 メインリポジトリは現在ブランチ: $BRANCH_NAME"
  echo ""
  echo "次のステップ:"
  echo "  1. リポジトリに移動:"
  echo "     cd ${GWT_REPOS_ROOT}/$first_repo"
  echo ""
  echo "  2. 開発サーバーを起動:"
  echo "     st dev"
  echo ""

  # Warpタブの自動起動は無効化（環境依存のため）
  # local first_repo="${REPOS[1]}"
  # local first_repo_main="${GWT_REPOS_ROOT}/${first_repo}"
  # _worktree_info "Opening Warp tab for $first_repo..."
  # _warp_new_tab "$first_repo_main" "[Main] $first_repo"
  # sleep 0.5
  # osascript <<EOF 2>/dev/null
  #   tell application "System Events"
  #     keystroke "st dev"
  #   end tell
  # EOF
}

# ============================================================================
# メインコマンド: zclean
# ============================================================================

zclean() {
  # 環境変数チェック
  _check_environment || return 1

  local task_name="$1"

  if [[ -z "$task_name" ]]; then
    _worktree_error "使い方: zclean <タスク名>"
    return 1
  fi

  local task_dir="${GWT_WORKTREE_ROOT}/${task_name}"

  if [[ ! -d "$task_dir" ]]; then
    _worktree_error "タスク '$task_name' が見つかりません: $task_dir"
    return 1
  fi

  # .workspaceファイルを読み込み
  if [[ ! -f "${task_dir}/.workspace" ]]; then
    _worktree_error "タスクのメタデータが見つかりません: ${task_dir}/.workspace"
    return 1
  fi

  source "${task_dir}/.workspace"

  echo "🧹 タスクをクリーンアップ: $task_name"
  echo "📁 作成場所: $task_dir"
  echo "🔀 リポジトリ: ${REPOS[*]}"
  echo ""

  read -q "REPLY?このタスクを削除してもよろしいですか？ (y/n) "
  echo ""

  if [[ ! "$REPLY" =~ ^[Yy]$ ]]; then
    echo "キャンセルしました。"
    return 0
  fi

  # 各リポジトリのworktreeを削除
  for repo in "${REPOS[@]}"; do
    local repo_main="${GWT_REPOS_ROOT}/${repo}"
    local repo_worktree="${task_dir}/${repo}"

    if [[ -d "$repo_worktree" ]]; then
      _worktree_info "$repo の worktree を削除中..."
      git -C "$repo_main" worktree remove "$repo_worktree" 2>&1 || {
        _worktree_error "$repo の worktree 削除に失敗しました (手動削除: git worktree remove $repo_worktree)"
      }
    fi
  done

  # タスクディレクトリを削除
  rm -rf "$task_dir"

  _worktree_success "タスク '$task_name' をクリーンアップしました！"
  echo ""

  # ブランチの状態を確認
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo ""
  echo "🌿 ブランチ '$BRANCH_NAME' のクリーンアップ"
  echo ""

  local has_unmerged=false
  for repo in "${REPOS[@]}"; do
    local repo_main="${GWT_REPOS_ROOT}/${repo}"

    # ブランチが存在するかチェック
    if git -C "$repo_main" rev-parse --verify "$BRANCH_NAME" >/dev/null 2>&1; then
      # マージ済みかチェック
      if git -C "$repo_main" branch --merged | grep -q "^[* ]*${BRANCH_NAME}$"; then
        echo "  ✅ $repo: マージ済み（安全に削除可能）"
      else
        echo "  ⚠️  $repo: 未マージ（独自のコミットを含みます）"
        has_unmerged=true
      fi
    else
      echo "  ℹ️  $repo: ブランチが見つかりません"
    fi
  done

  echo ""

  if [[ "$has_unmerged" == true ]]; then
    echo "⚠️  警告: いくつかのブランチにマージされていないコミットが含まれています。"
    echo "   削除すると、これらの変更は永久に失われます。"
    echo ""
  fi

  read -q "REPLY?全てのリポジトリからブランチ '$BRANCH_NAME' を削除しますか？ (y/n) "
  echo ""

  if [[ "$REPLY" =~ ^[Yy]$ ]]; then
    for repo in "${REPOS[@]}"; do
      local repo_main="${GWT_REPOS_ROOT}/${repo}"

      if git -C "$repo_main" rev-parse --verify "$BRANCH_NAME" >/dev/null 2>&1; then
        _worktree_info "$repo でブランチ '$BRANCH_NAME' を削除中..."
        git -C "$repo_main" branch -D "$BRANCH_NAME" 2>&1 || {
          echo "⚠️  $repo でブランチを削除できませんでした"
        }
      fi
    done
    echo ""
    _worktree_success "ブランチのクリーンアップが完了しました！"
  else
    echo ""
    echo "ℹ️  ブランチ '$BRANCH_NAME' を残しました"
    echo "   後で削除する場合: git branch -D $BRANCH_NAME"
  fi

  echo ""
}

# ============================================================================
# メインコマンド: ztasks
# ============================================================================

ztasks() {
  # 環境変数チェック
  _check_environment || return 1

  if [[ ! -d "$GWT_WORKTREE_ROOT" ]]; then
    _worktree_error "worktrees ディレクトリが見つかりません: $GWT_WORKTREE_ROOT"
    return 1
  fi

  # fzfがインストールされているかチェック
  if ! command -v fzf >/dev/null 2>&1; then
    _worktree_error "fzf がインストールされていません。インストール方法: brew install fzf"
    return 1
  fi

  # タスク一覧を取得（[Main] エントリを先頭に追加）
  local tasks=("[Main]  📁 メイン作業場所  📂 $GWT_REPOS_ROOT")

  for task_dir in "$GWT_WORKTREE_ROOT"/*; do
    if [[ -d "$task_dir" && -f "${task_dir}/.workspace" ]]; then
      local task_name=$(basename "$task_dir")

      # メタデータを読み込み
      source "${task_dir}/.workspace"

      # 表示用の文字列を作成
      local display="${task_name}  📁 ${REPOS[*]}  📅 ${CREATED_AT}"
      tasks+=("$display")
    fi
  done

  # fzfで選択
  local selected=$(printf '%s\n' "${tasks[@]}" | fzf \
    --prompt="タスク選択: " \
    --header="Enter: 切替 | 1: テスト | 2: 削除 | 3: Cursor" \
    --expect="1,2,3" \
    --preview="echo {} | awk '{print \$1}' | xargs -I {} sh -c 'if [[ \"\$1\" == \"[Main]\" ]]; then echo \"📂 メインリポジトリ\"; echo \"\"; ls -d $GWT_REPOS_ROOT/*/.git 2>/dev/null | sed \"s|/.git||\" | xargs -n1 basename | sed \"s/^/  - /\"; else echo \"━━━━━━━━━━━━━━━━━━━━━━━\"; cat ${GWT_WORKTREE_ROOT}/\$1/.workspace 2>/dev/null | grep -v \"^#\"; source ${GWT_WORKTREE_ROOT}/\$1/.workspace 2>/dev/null && if [[ -n \"\$NOTE\" ]]; then echo \"\"; echo \"━━━━━━━━━━━━━━━━━━━━━━━\"; echo \"📝 メモ:\"; echo \"\$NOTE\"; fi; fi' _ {}" \
    --preview-window=right:40%)

  if [[ -n "$selected" ]]; then
    local key=$(echo "$selected" | head -1)
    local task_line=$(echo "$selected" | tail -1)
    local task_name=$(echo "$task_line" | awk '{print $1}')

    # [Main] が選択された場合
    if [[ "$task_name" == "[Main]" ]]; then
      case "$key" in
        1|2|3)
          _worktree_info "[Main] では操作できません"
          return 0
          ;;
        *)
          # メインリポジトリに移動（リポジトリを選択）
          local repos=()
          for dir in "$GWT_REPOS_ROOT"/*; do
            if [[ -d "$dir/.git" ]]; then
              repos+=("$(basename "$dir")")
            fi
          done

          if [[ ${#repos[@]} -eq 0 ]]; then
            _worktree_info "メインリポジトリに移動: $GWT_REPOS_ROOT"
            cd "$GWT_REPOS_ROOT"
          else
            local repo=$(printf '%s\n' "${repos[@]}" | fzf --prompt="リポジトリを選択: " --height=10)
            if [[ -n "$repo" ]]; then
              _worktree_info "メインリポジトリに移動: $repo"
              cd "$GWT_REPOS_ROOT/$repo"
            fi
          fi
          ;;
      esac
      return 0
    fi

    # 通常のタスク処理
    case "$key" in
      1)
        ztest "$task_name"
        ;;
      2)
        zclean "$task_name"
        ;;
      3)
        zcursor "$task_name"
        ;;
      *)
        # Enter pressed - switch to task
        local task_dir="${GWT_WORKTREE_ROOT}/${task_name}"
        _worktree_info "タスクに切り替え中: $task_name"
        cd "$task_dir"
        ;;
    esac
  fi
}

# ============================================================================
# メインコマンド: zcursor
# ============================================================================

zcursor() {
  # 環境変数チェック
  _check_environment || return 1

  local task_name="$1"

  # 引数なしの場合はfzfで選択
  if [[ -z "$task_name" ]]; then
    if ! command -v fzf >/dev/null 2>&1; then
      _worktree_error "fzf がインストールされていません。インストール方法: brew install fzf"
      return 1
    fi

    local tasks=()
    for task_dir in "$GWT_WORKTREE_ROOT"/*; do
      if [[ -d "$task_dir" ]]; then
        tasks+=("$(basename "$task_dir")")
      fi
    done

    if [[ ${#tasks[@]} -eq 0 ]]; then
      _worktree_info "アクティブなタスクが見つかりません"
      return 0
    fi

    task_name=$(printf '%s\n' "${tasks[@]}" | fzf --prompt="Cursorで開くタスクを選択: ")

    if [[ -z "$task_name" ]]; then
      return 0
    fi
  fi

  local task_dir="${GWT_WORKTREE_ROOT}/${task_name}"
  local workspace_file="${task_dir}/${task_name}.code-workspace"

  if [[ ! -d "$task_dir" ]]; then
    _worktree_error "タスク '$task_name' が見つかりません: $task_dir"
    return 1
  fi

  if [[ ! -f "$workspace_file" ]]; then
    _worktree_error "ワークスペースファイルが見つかりません: $workspace_file"
    return 1
  fi

  _worktree_info "タスク '$task_name' を Cursor で開いています..."
  cursor "$workspace_file"
}

# ============================================================================
# メインコマンド: znote
# ============================================================================

znote() {
  # 環境変数チェック
  _check_environment || return 1

  local task_name=""
  local note_text=""

  # 引数解析
  if [[ $# -eq 0 ]]; then
    # 引数なし: カレントディレクトリからタスクを検出
    local current_dir="$PWD"
    if [[ "$current_dir" == "$GWT_WORKTREE_ROOT"/* ]]; then
      local relative_path="${current_dir#$GWT_WORKTREE_ROOT/}"
      task_name="${relative_path%%/*}"
    else
      _worktree_error "使い方: znote <タスク名> [メモ内容]"
      echo "または: タスクディレクトリ内で znote [メモ内容]"
      return 1
    fi
  elif [[ $# -eq 1 ]]; then
    # 引数1つ: タスク名 or メモ内容
    local current_dir="$PWD"
    if [[ "$current_dir" == "$GWT_WORKTREE_ROOT"/* ]]; then
      # カレントディレクトリがタスク配下 → 引数はメモ内容
      local relative_path="${current_dir#$GWT_WORKTREE_ROOT/}"
      task_name="${relative_path%%/*}"
      note_text="$1"
    else
      # カレントディレクトリがタスク配下でない → 引数はタスク名
      task_name="$1"
    fi
  else
    # 引数2つ以上: タスク名 + メモ内容
    task_name="$1"
    shift
    note_text="$*"
  fi

  local task_dir="${GWT_WORKTREE_ROOT}/${task_name}"

  if [[ ! -d "$task_dir" ]]; then
    _worktree_error "タスク '$task_name' が見つかりません: $task_dir"
    return 1
  fi

  if [[ ! -f "${task_dir}/.workspace" ]]; then
    _worktree_error "タスクのメタデータが見つかりません: ${task_dir}/.workspace"
    return 1
  fi

  # メタデータを読み込み
  source "${task_dir}/.workspace"

  # メモを表示または更新
  if [[ -z "$note_text" ]]; then
    # メモを表示
    if [[ -n "$NOTE" ]]; then
      echo "📝 メモ (タスク: $task_name)"
      echo ""
      echo "$NOTE"
    else
      echo "📝 メモが設定されていません (タスク: $task_name)"
      echo ""
      echo "メモを追加: znote $task_name \"メモ内容\""
    fi
  else
    # メモを更新
    NOTE="$note_text"

    # .workspace ファイルを更新
    {
      echo "# Worktree metadata"
      echo "TASK_NAME=\"${TASK_NAME}\""
      echo "REPOS=(${REPOS[@]})"
      echo "BRANCH_NAME=\"${BRANCH_NAME}\""
      echo "CREATED_AT=\"${CREATED_AT}\""
      echo "BASE_BRANCH=\"${BASE_BRANCH}\""
      echo "NOTE=\"${NOTE}\""
      echo "LAST_ACCESSED=\"${LAST_ACCESSED:-}\""
      echo "TOTAL_TIME=${TOTAL_TIME:-0}"
    } > "${task_dir}/.workspace"

    _worktree_success "メモを更新しました (タスク: $task_name)"
    echo ""
    echo "📝 $NOTE"
  fi
}

# ============================================================================
# メインコマンド: zadd
# ============================================================================

zadd() {
  # 環境変数チェック
  _check_environment || return 1

  # 引数チェック
  if [[ $# -lt 1 ]]; then
    _worktree_error "使い方: zadd <リポジトリ1> [リポジトリ2] ... or @グループ名"
    echo "例: zadd frontend auth-service"
    echo "例: zadd @backend @frontend"
    echo ""
    echo "利用可能なグループ:"
    if [[ -f $GWT_GROUPS_FILE ]]; then
      grep -E '^[a-z]' $GWT_GROUPS_FILE | sed 's/=.*//' | sed 's/^/  @/'
    fi
    echo ""
    echo "カレントディレクトリの worktree に新しいリポジトリを追加します"
    return 1
  fi

  # グループ定義を読み込み
  declare -A group_defs
  if [[ -f $GWT_GROUPS_FILE ]]; then
    while IFS='=' read -r key value; do
      # コメント行と空行をスキップ
      [[ "$key" =~ ^[[:space:]]*# ]] && continue
      [[ -z "$key" ]] && continue
      group_defs[$key]="$value"
    done < $GWT_GROUPS_FILE
  fi

  # 引数を展開（@グループ を実際のリポジトリリストに変換）
  local add_repos=()
  for arg in "$@"; do
    if [[ "$arg" == @* ]]; then
      # グループ名（@ を削除）
      local group_name="${arg#@}"
      if [[ -n "${group_defs[$group_name]}" ]]; then
        # カンマ区切りを配列に展開
        IFS=',' read -rA group_repos <<< "${group_defs[$group_name]}"
        add_repos+=("${group_repos[@]}")
        _worktree_info "グループ @$group_name を展開: ${group_repos[*]}"
      else
        _worktree_error "グループ @$group_name が見つかりません"
        echo "利用可能なグループ: ${(k)group_defs[@]}"
        return 1
      fi
    else
      # 通常のリポジトリ名
      add_repos+=("$arg")
    fi
  done

  local current_dir="$PWD"

  # カレントディレクトリが worktree 配下かチェック
  if [[ "$current_dir" != "$GWT_WORKTREE_ROOT"/* ]]; then
    _worktree_error "カレントディレクトリが worktree 配下ではありません"
    echo "worktree ディレクトリ内で実行してください"
    echo "例: cd $GWT_WORKTREE_ROOT/my-task/rsv-rails && zadd rsv-dashboard"
    return 1
  fi

  # タスク名を抽出（$GWT_WORKTREE_ROOT/<task-name>/... のパターン）
  local relative_path="${current_dir#$GWT_WORKTREE_ROOT/}"
  local task_name="${relative_path%%/*}"

  if [[ -z "$task_name" ]] || [[ "$task_name" == "$relative_path" ]]; then
    _worktree_error "タスク名を抽出できませんでした"
    echo "worktree のタスクディレクトリ内で実行してください"
    return 1
  fi

  local task_dir="${GWT_WORKTREE_ROOT}/${task_name}"

  # .workspace ファイルをチェック
  if [[ ! -f "${task_dir}/.workspace" ]]; then
    _worktree_error "タスクのメタデータが見つかりません: ${task_dir}/.workspace"
    return 1
  fi

  # 既存のメタデータを読み込み
  source "${task_dir}/.workspace"

  _worktree_info "タスク '$task_name' にリポジトリを追加中..."
  echo ""

  # 各リポジトリの worktree を作成
  local added_repos=()
  for repo in "${add_repos[@]}"; do
    local repo_main="${GWT_REPOS_ROOT}/${repo}"
    local repo_worktree="${task_dir}/${repo}"

    # リポジトリが存在するかチェック
    if [[ ! -d "$repo_main" ]]; then
      _worktree_error "リポジトリが見つかりません: $repo_main"
      continue
    fi

    # 既に worktree が存在するかチェック
    if [[ -d "$repo_worktree" ]]; then
      echo "⚠️  $repo: 既に存在します（スキップ）"
      continue
    fi

    # ベースブランチを検出
    local base_branch
    if git -C "$repo_main" rev-parse --verify main >/dev/null 2>&1; then
      base_branch="main"
    elif git -C "$repo_main" rev-parse --verify master >/dev/null 2>&1; then
      base_branch="master"
    else
      base_branch="$GWT_BASE_BRANCH"
    fi

    # ブランチが既に存在するかチェック
    if git -C "$repo_main" rev-parse --verify "$BRANCH_NAME" >/dev/null 2>&1; then
      echo ""
      echo "⚠️  警告: $repo に '$BRANCH_NAME' ブランチが既に存在します"
      echo ""

      # 既存ブランチの情報を表示
      local branch_info=$(git -C "$repo_main" log -1 --oneline "$BRANCH_NAME" 2>/dev/null)
      if [[ -n "$branch_info" ]]; then
        echo "   最新コミット: $branch_info"
      fi

      # ベースブランチとの差分を表示
      local commits_ahead=$(git -C "$repo_main" rev-list --count "$base_branch..$BRANCH_NAME" 2>/dev/null)
      if [[ -n "$commits_ahead" ]] && [[ "$commits_ahead" -gt 0 ]]; then
        echo "   差分: $base_branch より ${commits_ahead} コミット進んでいます"
      fi

      echo ""
      echo "選択してください:"
      echo "  1) 既存ブランチを使用する（内容を確認してから使用）"
      echo "  2) 新規作成（既存ブランチを削除して $base_branch から作り直し）"
      echo "  3) スキップ（このリポジトリは追加しない）"
      echo ""

      local choice
      read "choice?選択 (1/2/3): "

      case "$choice" in
        1)
          _worktree_info "既存ブランチ '$BRANCH_NAME' を使用します"
          git -C "$repo_main" worktree add "$repo_worktree" "$BRANCH_NAME" 2>&1
          ;;
        2)
          _worktree_info "既存ブランチを削除して新規作成します"
          # 既存ブランチを強制削除
          git -C "$repo_main" branch -D "$BRANCH_NAME" 2>&1 || {
            _worktree_error "既存ブランチの削除に失敗しました"
            continue
          }
          # 新しいブランチを作成
          git -C "$repo_main" worktree add -b "$BRANCH_NAME" "$repo_worktree" "$base_branch" 2>&1
          ;;
        3|*)
          echo "スキップしました: $repo"
          continue
          ;;
      esac
    else
      # 新しいブランチを作成
      _worktree_info "$repo の worktree を作成中..."
      git -C "$repo_main" worktree add -b "$BRANCH_NAME" "$repo_worktree" "$base_branch" 2>&1
    fi

    # Worktree が実際に作成されたかチェック
    if [[ ! -d "$repo_worktree" ]]; then
      _worktree_error "$repo の worktree 作成に失敗しました"
      continue
    fi

    added_repos+=("$repo")
  done

  if [[ ${#added_repos[@]} -eq 0 ]]; then
    echo ""
    _worktree_error "追加されたリポジトリはありません"
    return 1
  fi

  # REPOS 配列を更新
  local updated_repos=("${REPOS[@]}" "${added_repos[@]}")

  # .workspace ファイルを更新
  {
    echo "# Worktree metadata"
    echo "TASK_NAME=\"${TASK_NAME}\""
    echo "REPOS=(${updated_repos[@]})"
    echo "BRANCH_NAME=\"${BRANCH_NAME}\""
    echo "CREATED_AT=\"${CREATED_AT}\""
    echo "BASE_BRANCH=\"${BASE_BRANCH}\""
    echo "NOTE=\"${NOTE:-}\""
    echo "LAST_ACCESSED=\"${LAST_ACCESSED:-}\""
    echo "TOTAL_TIME=${TOTAL_TIME:-0}"
  } > "${task_dir}/.workspace"

  # .code-workspace ファイルを再生成
  local workspace_file="${task_dir}/${task_name}.code-workspace"
  {
    echo '{'
    echo '  "folders": ['
    # zsh互換: 最後の要素を特定してカンマを制御
    local last_repo="${updated_repos[-1]}"
    for repo in "${updated_repos[@]}"; do
      echo -n "    { \"path\": \"./${repo}\" }"
      if [[ "$repo" != "$last_repo" ]]; then
        echo ","
      else
        echo ""
      fi
    done
    echo '  ],'
    echo '  "settings": {'
    echo '    "workbench.colorCustomizations": {'
    # タスク名のハッシュから色を生成（簡易版・macOS対応）
    local hash_output
    if command -v md5 >/dev/null 2>&1; then
      hash_output=$(echo -n "$task_name" | md5 -q)
    else
      hash_output=$(echo -n "$task_name" | md5sum | cut -d' ' -f1)
    fi
    local color_hash=$((16#${hash_output:0:6}))
    local hue=$(( color_hash % 360 ))
    echo "      \"titleBar.activeBackground\": \"hsl(${hue}, 60%, 50%)\""
    echo '    }'
    echo '  }'
    echo '}'
  } > "$workspace_file"

  echo ""
  _worktree_success "リポジトリを追加しました: ${added_repos[*]}"
  echo ""
  echo "📁 作成場所: $task_dir"
  echo "🔀 全リポジトリ: ${updated_repos[*]}"
  echo ""
}

# ============================================================================
# エイリアス・補完設定
# ============================================================================

# タブ補完のヘルパー（compinitが実行されている場合のみ）
if (( ${+_comps} )); then
  # zclaude の補完関数
  _zclaude_completion() {
    local -a repos groups

    # 第1引数: タスク名（自由入力）
    if (( CURRENT == 2 )); then
      return 0
    fi

    # 第2引数以降: リポジトリ名 + グループ名
    repos=()
    groups=()

    # リポジトリ名
    for dir in "$GWT_REPOS_ROOT"/*; do
      if [[ -d "$dir/.git" ]]; then
        repos+=("$(basename "$dir")")
      fi
    done

    # グループ名（@ プレフィックス付き）
    if [[ -f $GWT_GROUPS_FILE ]]; then
      while IFS='=' read -r key value; do
        [[ "$key" =~ ^[[:space:]]*# ]] && continue
        [[ -z "$key" ]] && continue
        groups+=("@$key")
      done < $GWT_GROUPS_FILE
    fi

    # 両方を候補に追加
    compadd -a repos
    compadd -a groups
  }

  # 既存タスクの補完関数
  _ztasks_completion() {
    local -a tasks
    tasks=()
    for task_dir in "$GWT_WORKTREE_ROOT"/*; do
      if [[ -d "$task_dir" ]]; then
        tasks+=("$(basename "$task_dir")")
      fi
    done
    _describe 'タスク' tasks
  }

  # zadd の補完関数（リポジトリ名 + グループ名）
  _zadd_completion() {
    local -a repos groups
    repos=()
    groups=()

    # リポジトリ名
    for dir in "$GWT_REPOS_ROOT"/*; do
      if [[ -d "$dir/.git" ]]; then
        repos+=("$(basename "$dir")")
      fi
    done

    # グループ名（@ プレフィックス付き）
    if [[ -f $GWT_GROUPS_FILE ]]; then
      while IFS='=' read -r key value; do
        # コメント行と空行をスキップ
        [[ "$key" =~ ^[[:space:]]*# ]] && continue
        [[ -z "$key" ]] && continue
        groups+=("@$key")
      done < $GWT_GROUPS_FILE
    fi

    # 両方を候補に追加
    compadd -a repos
    compadd -a groups
  }

  # zsh補完の登録
  compdef _zclaude_completion zclaude
  compdef _ztasks_completion ztest
  compdef _ztasks_completion zclean
  compdef _ztasks_completion zcursor
  compdef _zadd_completion zadd
fi

# ============================================================================
# 初期化
# ============================================================================

# worktreesディレクトリが存在しない場合は作成
if [[ ! -d "$GWT_WORKTREE_ROOT" ]]; then
  mkdir -p "$GWT_WORKTREE_ROOT"
fi

# 初回読み込み時のメッセージ（環境変数で制御）
if [[ -z "$GWT_LOADED" ]]; then
  export GWT_LOADED=1
  # 静かに読み込む（メッセージなし）
fi
