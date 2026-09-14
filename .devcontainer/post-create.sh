#!/usr/bin/env bash
# devcontainer / Codespaces の初期化。
set -euo pipefail

cd "$(dirname "$0")/.."

# .gitattributes の merge=ours が参照するマージ ドライバーの定義を取り込む。
# 取り込まないと packages.lock.json のマージが期待どおりに解決されない。
# 何度実行しても値が重複しないよう、既に入っているかを確認する。
if ! git config get --all include.path 2>/dev/null | grep -qxF '../.gitconfig'; then
  git config set --append include.path ../.gitconfig
fi

# Claude Code CLI。認証は初回起動時に各自で行う。
npm install -g @anthropic-ai/claude-code

# ~/.claude（設定・認証・セッション メモリ）は rebuild container のたびに消えるコンテナ側の
# ホーム ディレクトリにある。/workspaces 配下は rebuild をまたいで残るディスクなので、
# 実体をそちらに逃がし、~/.claude をそこへのシンボリック リンクに差し替える。
CLAUDE_HOME_PERSIST="$(pwd)/.claude-home"
if [ ! -L "$HOME/.claude" ]; then
  mkdir -p "$CLAUDE_HOME_PERSIST"
  if [ -d "$HOME/.claude" ]; then
    cp -a "$HOME/.claude/." "$CLAUDE_HOME_PERSIST/"
    rm -rf "$HOME/.claude"
  fi
  ln -s "$CLAUDE_HOME_PERSIST" "$HOME/.claude"
fi

dotnet restore Logora.slnx
