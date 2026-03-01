# Git Worktree Manager - 使い方ガイド

## 概要

git worktree を活用して、複数のタスクを並行して管理するための CLI ツールです。
**編集は worktree で、動作確認はメインリポジトリで** という明確な役割分担により、ブランチ切り替えの煩わしさから解放されます。

## ✨ 特徴

- 🌳 **git worktree ベース**: 各タスクが独立したディレクトリで管理
- 🔀 **マルチリポジトリ対応**: 複数リポジトリの横断開発をサポート
- 🎨 **IDE 統合**: Cursor/VS Code のマルチルートワークスペース自動生成
- 🤖 **Claude Code 連携**: AI アシスタントとの統合開発環境
- 📦 **リポジトリグループ**: よく使う組み合わせを定義可能

## インストール

### 前提条件

- zsh
- git
- fzf (タスク一覧表示に使用)
- Warp または任意のターミナル（オプション）

### セットアップ

1. **ファイルを配置**

```bash
mkdir -p ~/.config/gwm
cp worktree-commands.zsh ~/.config/gwm/gwm.zsh
```

2. **.zshrc に設定を追加**

```bash
# リポジトリのルートディレクトリ（必須）
export GWT_REPOS_ROOT="$HOME/repos"

# worktree を配置するディレクトリ
export GWT_WORKTREE_ROOT="$GWT_REPOS_ROOT/worktrees"

# デフォルトのベースブランチ
export GWT_BASE_BRANCH="main"

# スクリプトを読み込み
source ~/.config/gwm/gwm.zsh
```

3. **シェルをリロード**

```bash
source ~/.zshrc
```

4. **グループ定義（オプション）**

よく使うリポジトリの組み合わせを定義できます：

```bash
# ~/.config/gwm/groups.conf
backend=api-gateway,auth-service,user-service
frontend=web-app,mobile-app
fullstack=api-gateway,auth-service,web-app
```

## コマンド一覧

### `zclaude` - タスク開始

新しいタスクを開始します。指定したリポジトリの worktree を作成し、Cursor ワークスペースを準備します。

```bash
zclaude <task-name> <repo1> [repo2] [repo3] ...
```

**例:**

```bash
# 単一リポジトリ
zclaude feature-api backend

# 複数リポジトリ（横断開発）
zclaude feature-api backend frontend

# グループを使用
zclaude feature-api @backend @frontend

# カレントディレクトリから自動検出
cd $GWT_REPOS_ROOT/backend
zclaude feature-api
```

**実行内容:**
1. `worktrees/<task-name>/` ディレクトリを作成
2. 各リポジトリの worktree を作成（ブランチ名: `<task-name>`）
3. Cursor ワークスペースファイル (`.code-workspace`) を生成
4. タスク起動コマンドをクリップボードにコピー

**作業場所:**
- `worktrees/<task-name>/backend/` - ここで編集
- `worktrees/<task-name>/frontend/` - ここで編集

### `zadd` - リポジトリ追加

既存のタスクに新しいリポジトリを追加します。

```bash
zadd <repo1> [repo2] ... or @group
```

**例:**

```bash
# タスクディレクトリ内で実行
cd $GWT_WORKTREE_ROOT/feature-api/backend
zadd frontend auth-service

# グループで一括追加
zadd @frontend
```

### `ztest` - 動作確認

タスクのコードをメインリポジトリで動作確認します。

```bash
ztest <task-name>
```

**例:**

```bash
ztest feature-api
```

**実行内容:**
1. メインリポジトリで該当ブランチに checkout
2. 次のステップを表示（開発サーバー起動など）

**注意:**
- メインリポジトリに未コミットの変更がある場合、警告が表示されます
- 複数リポジトリの場合、全てのリポジトリがブランチ切り替えされます

### `zclean` - タスク終了

タスクを終了し、worktree を削除します。

```bash
zclean <task-name>
```

**例:**

```bash
zclean feature-api
```

**実行内容:**
1. 確認プロンプトを表示
2. 各リポジトリの worktree を削除
3. タスクディレクトリを削除
4. （オプション）ブランチも削除

### `ztasks` - タスク一覧

現在アクティブなタスクを fzf で一覧表示・選択します。

```bash
ztasks
```

**操作:**
- `Enter`: タスクディレクトリに移動
- `1`: 動作確認（`ztest` 実行）
- `2`: タスク削除（`zclean` 実行）
- `3`: Cursor で開く（`zcursor` 実行）

### `zcursor` - Cursor で開く

タスクを Cursor で開きます。

```bash
# 引数なし: fzf でタスクを選択
zcursor

# 引数あり: 指定したタスクを開く
zcursor feature-api
```

## 典型的なワークフロー

### 1. 新機能開発（単一リポジトリ）

```bash
# 1. タスク開始
zclaude feature-new-endpoint backend

# 2. Claude Code で編集
cd $GWT_WORKTREE_ROOT/feature-new-endpoint/backend
claude

# 3. 動作確認したくなったら
ztest feature-new-endpoint

# 4. メインリポジトリで開発サーバー起動
cd $GWT_REPOS_ROOT/backend
npm run dev  # または st dev など

# 5. ブラウザで動作確認

# 6. worktree に戻って編集継続（Warp タブ切り替え）

# 7. PR 作成・マージ
cd $GWT_WORKTREE_ROOT/feature-new-endpoint/backend
git push origin feature-new-endpoint
gh pr create

# 8. タスク終了
zclean feature-new-endpoint
```

### 2. 横断開発（複数リポジトリ）

```bash
# 1. タスク開始（API + フロントエンド）
zclaude feature-ui-integration backend frontend

# 2. Cursor で開く（両方のリポジトリが1つのワークスペースに）
zcursor feature-ui-integration

# 3. Claude Code で編集
cd $GWT_WORKTREE_ROOT/feature-ui-integration/backend
claude
# backend: API エンドポイント追加
# frontend: UI コンポーネント作成

# 4. 動作確認
ztest feature-ui-integration

# 5. backend で開発サーバー起動
cd $GWT_REPOS_ROOT/backend
npm run dev

# 6. 別ペインで frontend も起動
cd $GWT_REPOS_ROOT/frontend
npm run dev

# 7. ブラウザで統合テスト

# 8. 終了
zclean feature-ui-integration
```

### 3. 複数タスクの並行管理

```bash
# タスクA: API 実装
zclaude feature-api backend

# タスクB: バグ修正
zclaude bugfix-login auth-service

# タスクC: フロントエンド改善
zclaude improve-ui frontend

# タスク一覧を確認
ztasks
# → fzf で選択して切り替え

# タスクA の動作確認
ztest feature-api

# タスクB の編集に戻る
cd $GWT_WORKTREE_ROOT/bugfix-login/auth-service

# または ztasks で選択
```

### 4. リポジトリグループを使った開発

```bash
# グループ定義（~/.config/gwm/groups.conf）
# backend=api-gateway,auth-service,user-service
# frontend=web-app,mobile-app

# バックエンドサービス全体で作業
zclaude feature-payment @backend

# フロントエンドも追加
cd $GWT_WORKTREE_ROOT/feature-payment/api-gateway
zadd @frontend

# 全リポジトリが1つのタスクに統合される
```

## ディレクトリ構造

### 基本レイアウト

```
$GWT_REPOS_ROOT/
├── backend/                      # メイン（動作確認用）
├── frontend/                     # メイン（動作確認用）
├── auth-service/                 # メイン
└── worktrees/                    # 編集専用エリア
    ├── feature-api/
    │   ├── backend/              # git worktree
    │   ├── frontend/             # git worktree
    │   ├── .workspace            # メタデータ
    │   └── feature-api.code-workspace  # Cursor ワークスペース
    └── bugfix-login/
        ├── auth-service/
        ├── .workspace
        └── bugfix-login.code-workspace
```

### プロジェクト構造の例

#### 1. ghq レイアウト

```bash
# リポジトリ配置
~/repos/github.com/myorg/
├── backend/
├── frontend/
└── worktrees/

# 設定
export GWT_REPOS_ROOT="$HOME/repos/github.com/myorg"
```

#### 2. シンプルレイアウト

```bash
# リポジトリ配置
~/projects/
├── api/
├── web/
├── mobile/
└── worktrees/

# 設定
export GWT_REPOS_ROOT="$HOME/projects"
```

#### 3. モノレポ

```bash
# リポジトリ配置
~/work/
├── monorepo/
└── worktrees/

# 設定
export GWT_REPOS_ROOT="$HOME/work"
```

## Cursor の使い方

### マルチルートワークスペース

横断開発の場合、1つの Cursor ウィンドウで複数リポジトリを扱えます：

```json
// feature-api.code-workspace
{
  "folders": [
    { "path": "./backend" },
    { "path": "./frontend" }
  ],
  "settings": {
    "workbench.colorCustomizations": {
      "titleBar.activeBackground": "hsl(180, 60%, 50%)"
    }
  }
}
```

### タイトルバーの色

各タスクごとに自動で異なる色が設定されます（タスク名のハッシュから生成）。

- **feature-api**: 青系
- **bugfix-login**: 赤系
- **improve-ui**: 緑系

視覚的に「今どのタスクか」が瞬時に分かります。

## トラブルシューティング

### コマンドが見つからない

```bash
# .zshrc をリロード
source ~/.zshrc

# または新しいターミナルセッションを開く
```

### 環境変数が設定されていない

```bash
# エラーメッセージが表示された場合
❌ エラー: GWT_REPOS_ROOT が設定されていません

# .zshrc に追加
export GWT_REPOS_ROOT="$HOME/repos"
source ~/.config/gwm/gwm.zsh
```

### worktree 作成に失敗する

```bash
# ブランチが既に存在する場合
git branch -d <task-name>

# worktree が残っている場合
git worktree list
git worktree remove <path>
```

### メインリポジトリに未コミットの変更がある

`ztest` 実行時に警告が表示されます。以下のいずれかを選択：

1. **コミットする**: `git add . && git commit -m "..."`
2. **stash する**: `git stash`（ただし、これを避けるための仕組みです！）
3. **worktree で作業する**: メインではなく worktree で編集

## Tips

### 効率的な使い方

1. **編集は常に worktree で**: メインリポジトリは「動作確認専用」と割り切る
2. **こまめにコミット**: worktree 内でこまめにコミットすることで、メインへの切り替えがスムーズ
3. **ztasks を活用**: タスク一覧から素早く切り替え
4. **Cursor のワークスペース**: 横断開発では Cursor のマルチルート機能が強力

### fzf のキーバインド

`ztasks` では以下のキーバインドが使えます：

- `1`: Test（動作確認）
- `2`: Delete（削除）
- `3`: Cursor（開く）
- `?`: プレビュー表示切り替え

## 設定のカスタマイズ

### 環境変数

```bash
# .zshrc に追加
export GWT_REPOS_ROOT="$HOME/repos"              # リポジトリルート（必須）
export GWT_WORKTREE_ROOT="$GWT_REPOS_ROOT/wt"   # worktree配置先（デフォルト: $GWT_REPOS_ROOT/worktrees）
export GWT_BASE_BRANCH="main"                    # ベースブランチ（デフォルト: main）
export GWT_GROUPS_FILE="$HOME/.config/gwm/groups.conf"  # グループ定義ファイル
```

## よくある質問

### Q: worktree と通常のブランチ切り替えの違いは？

**通常のブランチ切り替え:**
- `git checkout feature-A`
- 作業中に別のブランチに切り替える際、stash が必要
- 「今どのブランチ？」と混乱しやすい

**worktree:**
- 各ブランチが物理的に別のディレクトリ
- 切り替えは単に `cd` するだけ
- stash 不要、混乱なし

### Q: データベースは共有される？

はい。worktree はコードの管理のみで、データベースは共有されます。
マイグレーションをテストする場合は注意が必要です。

### Q: 複数のタスクで同時にサーバーを起動できる？

技術的には可能ですが、ポート番号の衝突に注意が必要です。
基本的には「アクティブなタスク1つだけサーバー起動」を推奨します。

### Q: PR はどう作る？

worktree でコミット後、通常通り PR を作成できます：

```bash
cd $GWT_WORKTREE_ROOT/feature-api/backend
git push origin feature-api
gh pr create
```

または、メインリポジトリから：

```bash
cd $GWT_REPOS_ROOT/backend
git checkout feature-api
gh pr create
```

### Q: 他の IDE でも使える？

はい。Cursor 以外の IDE でも使えます：

- **VS Code**: `.code-workspace` ファイルをそのまま使用可能
- **IntelliJ/WebStorm**: 各リポジトリディレクトリを個別に開く
- **vim/neovim**: タスクディレクトリで直接編集

## まとめ

このツールセットにより、以下が実現されます：

✅ **ブランチ切り替えの煩わしさから解放**
✅ **複数タスクの並行管理が容易**
✅ **Claude Code との親和性が高い**
✅ **横断開発がスムーズ**
✅ **視覚的に分かりやすい**（Cursor の色分け）

Happy Coding! 🚀

## ライセンス

MIT License

## コントリビューション

Issue や Pull Request をお待ちしています！

- GitHub: https://github.com/YOUR_ORG/git-worktree-manager
