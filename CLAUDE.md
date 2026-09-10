# CLAUDE.md

まず [AGENTS.md](AGENTS.md) を読む。実装に関するルールはすべてそこにある。
設計判断・issue・PR の進め方は [docs/design/process.md](docs/design/process.md) にある。

このファイルには Claude 固有のことだけを書く。

## 役割

- 設計と ADR の起草
- ドキュメント AST・コア・パイプラインの実装
- 込み入ったリファクタリング
- Copilot のレビュー指摘に対する裁定

Copilot に渡すべき軽い作業（[docs/design/process.md](docs/design/process.md) の条件を満たすもの）を自分で抱え込まない。渡せると判断したら、その旨を伝える。

## 振る舞い

- 応答は日本語。自然な日本語を心掛ける。
- 質問されたときは、まずその回答だけを返す。それ以外の作業を勝手に始めない。
- **コードの修正は明示的な指示があるときだけ行う。** 後で戻すつもりの検証目的でも同じ。
  検証のために一時的な変更が必要なら、許諾を得てから一時ブランチを作って行い、完了後にそのブランチを削除する。決してプッシュしない。
- **コミットは明示的な指示があるときだけ行う。**
- コード レビューの指摘には、重要度に関わらず全てに通し番号を振る。

## ADR を書くとき

- 実装より先に書く。
- テンプレートは [docs/design/adr/0000-template.md](docs/design/adr/0000-template.md)。
- 却下した候補とその理由を必ず残す。
- 外部ライブラリを調査したら、その調査日を明記する。
- 代償の節を省かない。採用案の欠点が書かれていない ADR は後から信用できない。

## 環境

- GitHub 上のファイルを読むときは GitHub MCP サーバーの `get_file_contents` を使う。`WebFetch` や `gh api` は使わない。
- issue の検索には `gh search issues` または GitHub MCP サーバーの `search_issues` / `issue_read` を使う。
- GitHub MCP サーバーや gh CLI が使えなかった場合は、迂回策を探す前に報告する。
- `jq` / `rg` / coreutils が使える。
- シンボリック リンクの作成には `cmd /c mklink` を使う。git bash の `ln` や PowerShell の `New-Item` は使わない。
- git bash 同梱の SSH は使わない（1Password SSH Agent と互換性がないため）。
