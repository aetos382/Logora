#!/usr/bin/env bash
# ビルド ログの警告を診断 ID ごとに集計する。
# 警告でビルドを落とさない方針のため、傾向を見るための仕組みとして用意している。
# CI ではジョブ サマリにも出す。
set -euo pipefail

cd "$(dirname "$0")/.."

log=artifacts/log/build.log

if [[ ! -f "$log" ]]; then
  echo "ビルド ログが見つかりません: $log" >&2
  echo "先に eng/build.sh を実行してください。" >&2
  exit 1
fi

# MSBuild は同じ警告を対象フレームワークやプロジェクトごとに繰り返し出すため、
# ここで数えているのはログ中の出現回数であり、一意な警告の件数ではない。
# 診断 ID を持たない警告（NuGet の復元警告など）もあるので、総数は ID の有無を問わず数える。
total=$(grep -cE ': warning ' "$log" || true)
: "${total:=0}"

by_id=$(grep -oE ': warning [A-Za-z]+[0-9]+' "$log" | sed -E 's/^: warning //' | sort | uniq -c | sort -rn || true)
tagged=$(printf '%s\n' "$by_id" | awk '{ sum += $1 } END { print sum + 0 }')
untagged=$(( total - tagged ))

output=artifacts/log/warnings.md

{
  echo "## ビルド警告"
  echo
  if [[ "$total" -eq 0 ]]; then
    echo "警告はありません。"
  else
    echo "合計 ${total} 件。"
    echo
    echo "| 件数 | 診断 ID |"
    echo "| --- | --- |"
    if [[ -n "$by_id" ]]; then
      printf '%s\n' "$by_id" | sed -E 's/^ *([0-9]+) ([A-Za-z]+[0-9]+)$/| \1 | \2 |/'
    fi
    if [[ "$untagged" -gt 0 ]]; then
      echo "| ${untagged} | （診断 ID なし） |"
    fi
    echo
    echo "件数はログ中の出現回数。同じ警告が対象フレームワークごとに複数回現れることがある。"
  fi
} > "$output"

cat "$output"

if [[ -n "${GITHUB_STEP_SUMMARY:-}" ]]; then
  cat "$output" >> "$GITHUB_STEP_SUMMARY"
fi
