#!/usr/bin/env bash
# 書式と命名の違反を検査する。--fix を付けると修正する。
# CI では実行しない（警告でビルドを落とさない方針のため）。手元で使う。
set -euo pipefail

cd "$(dirname "$0")/.."

if [[ "${1:-}" == "--fix" ]]; then
  shift
  dotnet format Logora.slnx "$@"
else
  dotnet format Logora.slnx --verify-no-changes "$@"
fi
