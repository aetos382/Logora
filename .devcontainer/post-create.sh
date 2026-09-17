#!/usr/bin/env bash
# devcontainer / Codespaces の初期化。
set -euo pipefail

cd "$(dirname "$0")/.."

if ! git config get --all include.path 2>/dev/null | grep -qxF '../.gitconfig'; then
  git config set --append include.path ../.gitconfig
fi

claude plugin marketplace add 'anthropics/claude-plugins-official'
claude plugin marketplace add 'aetos382/dotnet-skills#fix-lsp-servers-entry'

claude plugin install 'commit-commands@claude-plugins-official' -y
claude plugin install 'pr-review-toolkit@claude-plugins-official' -y
claude plugin install 'claude-md-management@claude-plugins-official' -y
claude plugin install 'claude-code-setup@claude-plugins-official' -y

claude plugin install 'dotnet@dotnet-agent-skills' -y
claude plugin install 'dotnet-msbuild@dotnet-agent-skills' -y
claude plugin install 'dotnet-test@dotnet-agent-skills' -y

dotnet restore Logora.slnx
