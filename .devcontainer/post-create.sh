#!/usr/bin/env bash
# devcontainer / Codespaces の初期化。
set -euo pipefail

cd "$(dirname "$0")/.."

# .gitattributes の merge=ours が参照するマージ ドライバーの定義と、
# main への直接コミットを止める pre-commit hook（Config-based hooks、Git 2.54 以降が必要）の
# 定義を .gitconfig から取り込む。取り込まないと packages.lock.json のマージが期待どおりに
# 解決されず、pre-commit hook も有効にならない。
# 何度実行しても値が重複しないよう、既に入っているかを確認する。
if ! git config get --all include.path 2>/dev/null | grep -qxF '../.gitconfig'; then
  git config set --append include.path ../.gitconfig
fi

# 旧方式（core.hooksPath）で設定していた環境の後始末。
git config unset core.hooksPath 2>/dev/null || true

# Config-based hooks は Git 2.54 未満では静かに無視され、main への直接コミット防止が
# 効かなくなる。検知できる範囲で警告する。
git_version="$(git --version | awk '{print $3}')"
min_git_version="2.54.0"
oldest="$(printf '%s\n%s\n' "$git_version" "$min_git_version" | sort -V | head -n1)"
if [ "$oldest" != "$min_git_version" ]; then
  echo "Warning: Git ${git_version} does not support Config-based hooks (requires Git 2.54+). The pre-commit protection against direct commits to main will not work." >&2
fi

# Claude Code CLI。認証は初回起動時に各自で行う。
npm install -g @anthropic-ai/claude-code

# ~/.claude（設定・認証・セッション メモリ）は devcontainer.json の containerEnv で
# CLAUDE_CONFIG_DIR を /workspaces 配下に向けているため、rebuild container をまたいで
# 自然に永続化される。~/.claude.json（認証・グローバル設定）だけは CLAUDE_CONFIG_DIR の
# 対象外でホーム ディレクトリ直下に固定されるため、個別に同じ永続領域へのシンボリック
# リンクに差し替える。永続側に既にファイルがある場合は、コンテナ再構築直後の初期状態で
# 上書きしないよう、永続側を優先する no-clobber コピーにする。
# CLAUDE_HOME_PERSIST は CLAUDE_CONFIG_DIR と同じ場所を指す必要があるため、
# devcontainer.json 側の値をそのまま参照する（未設定時のみ既定値にフォールバック）。
CLAUDE_HOME_PERSIST="${CLAUDE_CONFIG_DIR:-$(pwd)/.claude-home}"
mkdir -p "$CLAUDE_HOME_PERSIST"

CLAUDE_JSON_PERSIST="$CLAUDE_HOME_PERSIST/claude.json"
if [ ! -L "$HOME/.claude.json" ]; then
  if [ -f "$HOME/.claude.json" ]; then
    cp -n "$HOME/.claude.json" "$CLAUDE_JSON_PERSIST"
    rm -f "$HOME/.claude.json"
  fi
  ln -s "$CLAUDE_JSON_PERSIST" "$HOME/.claude.json"
fi

dotnet restore Logora.slnx
