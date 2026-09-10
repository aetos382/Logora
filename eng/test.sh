#!/usr/bin/env bash
# ソリューション全体のテストを実行する。
# 追加の引数はそのまま dotnet test に渡す。
set -euo pipefail

cd "$(dirname "$0")/.."

# テスト プロジェクトが 1 つもないと dotnet test はソリューション構成を解決できずクラッシュする
# （The solution configuration '|' is invalid.）ため、存在を確認してからスキップする。
# 最初のテスト プロジェクトが入ったら、この分岐は消してよい。
shopt -s nullglob
projects=(tests/*/*.csproj)
shopt -u nullglob

if [[ ${#projects[@]} -eq 0 ]]; then
  echo "tests/ にテスト プロジェクトがないため、テストをスキップします。"
  exit 0
fi

dotnet test Logora.slnx "$@"
