# Raycast Script Commands for Git Worktree Manager

Raycast から Git Worktree Manager のタスクを管理できる Script Commands です。

## セットアップ

### 1. Raycast のインストール

```bash
brew install --cask raycast
```

### 2. Script Commands を有効化

1. Raycast を開く（⌘ + Space）
2. "Extensions" を検索して開く
3. 左下の "+" ボタンをクリック → "Add Script Directory"
4. このディレクトリを選択: `~/.config/gwm/raycast`

または、Raycast の設定ファイルに直接追加：

```bash
# Raycast の設定を開く
open ~/.config/raycast/
```

### 3. 動作確認

Raycast を開いて以下のコマンドを検索：
- "List Worktree Tasks"
- "Open Task in Cursor"
- "Open Task in Terminal"
- "Copy Task Path"

## 利用可能なコマンド

### 📦 List Worktree Tasks

全てのアクティブなタスクを一覧表示します。

**使い方:**
1. Raycast を開く
2. "list" と入力
3. "List Worktree Tasks" を選択

**表示内容:**
- タスク名
- パス
- リポジトリ一覧
- ブランチ名
- メモ
- 作成日時

---

### 🎨 Open Task in Cursor

指定したタスクを Cursor で開きます。

**使い方:**
1. Raycast を開く
2. "open cursor" と入力
3. タスク名を入力（例: `feature-api`）
4. Enter で Cursor が起動

---

### 🖥️ Open Task in Terminal

指定したタスクのディレクトリをターミナルで開きます。

**対応ターミナル:**
- Warp（優先）
- iTerm2
- Terminal.app（macOS 標準）

**使い方:**
1. Raycast を開く
2. "open terminal" と入力
3. タスク名を入力
4. Enter でターミナルが起動

---

### 📋 Copy Task Path

タスクのディレクトリパスをクリップボードにコピーします。

**使い方:**
1. Raycast を開く
2. "copy path" と入力
3. タスク名を入力
4. Enter でパスがコピーされる

## Tips

### エイリアスの設定

Raycast では各コマンドにエイリアスを設定できます：

1. Raycast Extensions を開く
2. Script Commands セクションで対象コマンドを右クリック
3. "Edit Alias" を選択
4. 短いエイリアスを設定（例: "wt" → "List Worktree Tasks"）

### キーボードショートカット

頻繁に使うコマンドにはショートカットを設定できます：

1. Raycast Extensions を開く
2. Script Commands セクションで対象コマンドを右クリック
3. "Record Hotkey" を選択
4. ショートカットキーを入力（例: `⌘ + Shift + W`）

### Quicklinks との組み合わせ

Raycast の Quicklinks 機能と組み合わせると、さらに便利です：

```
名前: Open Main Repo
URL: file:///Users/nyohoo/ghq/github.com/heyinc

名前: Open Worktrees
URL: file:///Users/nyohoo/ghq/github.com/heyinc/worktrees
```

## トラブルシューティング

### 環境変数が読み込まれない

Raycast は `.zshrc` を読み込みますが、一部の環境変数が反映されない場合：

```bash
# ~/.zshrc の先頭に追加
export GWT_REPOS_ROOT="$HOME/ghq/github.com/heyinc"
export GWT_WORKTREE_ROOT="$GWT_REPOS_ROOT/worktrees"
export GWT_BASE_BRANCH="main"
```

### スクリプトが表示されない

1. スクリプトに実行権限があるか確認:
   ```bash
   ls -la ~/.config/gwm/raycast/
   ```

2. 権限がない場合は付与:
   ```bash
   chmod +x ~/.config/gwm/raycast/*.sh
   ```

3. Raycast の Extensions を再読み込み:
   - Raycast を開く → Extensions → 右上の更新ボタン

### Cursor が開かない

Cursor がインストールされているか確認:
```bash
ls /Applications/Cursor.app
```

インストールされていない場合:
```bash
brew install --cask cursor
```

## カスタマイズ

スクリプトは自由にカスタマイズできます。例えば：

- タスクのフィルタリング追加
- PR 情報の表示拡張
- Slack 通知の追加
- GitHub Issues との連携

各スクリプトのメタデータ（`@raycast.`で始まる行）を編集することで、タイトルやアイコンをカスタマイズできます。

## 参考リンク

- [Raycast Script Commands Documentation](https://github.com/raycast/script-commands)
- [Git Worktree Manager](https://github.com/nyohoo/git-worktree-manager)
