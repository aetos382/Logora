#!/usr/bin/env bash
# ソリューション全体をビルドし、診断用のログを artifacts/log に残す。
# 追加の引数はそのまま dotnet build に渡す。
set -euo pipefail

cd "$(dirname "$0")/.."

mkdir -p artifacts/log

# ログはビルドの成否にかかわらず残したいので、警告集計はビルドとは別のステップに分けている。
dotnet build Logora.slnx \
  -bl:artifacts/log/build.binlog \
  "-flp:logfile=artifacts/log/build.log;verbosity=normal" \
  "$@"
