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

# main への直接コミットを止める pre-commit hook を有効化する。
git config set core.hooksPath .githooks

# Claude Code CLI。認証は初回起動時に各自で行う。
npm install -g @anthropic-ai/claude-code

dotnet restore Logora.slnx
