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

## 記憶をリポジトリの外に置かない

**セッション メモリに重要事項を記録しない。** 決めたこと、決めていないこと、詰まっている理由は、
すべてリポジトリの中か GitHub の issue に置く。セッションの記憶は次のセッションに引き継がれず、
引き継がれたつもりで進めると、失われたときに経緯だけが消えて結論が浮くため。

判断の基準は「**リポジトリを新しく clone し直しても、前のタスクを継続できるか**」。
できないなら、足りない情報をリポジトリか issue に書いてから先へ進む。

| 残したいもの | 置き場所 |
| --- | --- |
| 設計判断とその理由 | `docs/design/adr/` の ADR |
| 進め方のルール | [docs/design/process.md](docs/design/process.md) |
| 実装時に守ること | [AGENTS.md](AGENTS.md) |
| 未着手・未決の作業とその経緯 | GitHub issue |
| 人間の対話操作が必要なこと（`gh auth refresh` など） | GitHub issue に手順ごと書く |

## 実装のレビューとテストを自分で兼ねない

- 実装を終えたら、コミットや PR を作る前に
  [implementation-reviewer](.claude/agents/implementation-reviewer.md) に渡す。
  自分が書いたコードのレビューを自分で済ませない。
- テストは [test-author](.claude/agents/test-author.md) に渡す。
  受け入れ条件が固まった時点で、実装より先に呼べるならそうする。

理由は [docs/design/process.md](docs/design/process.md) の「工程の分離」にある。

## ADR を書くとき

- 実装より先に書く。
- テンプレートは [docs/design/adr/0000-template.md](docs/design/adr/0000-template.md)。
- 却下した候補とその理由を必ず残す。
- 外部ライブラリを調査したら、その調査日を明記する。
- 代償の節を省かない。採用案の欠点が書かれていない ADR は後から信用できない。

## 環境

開発環境は 2 つある。**主開発環境は Codespaces。** どちらで動いているかを最初に把握する。

### どちらでも共通

- GitHub 上のファイルを読むときは GitHub MCP サーバーの `get_file_contents` を使う。`WebFetch` や `gh api` は使わない。
- issue の検索には `gh search issues` または GitHub MCP サーバーの `search_issues` / `issue_read` を使う。
- GitHub MCP サーバーや gh CLI が使えなかった場合は、迂回策を探す前に報告する。
- `jq` / `rg` / coreutils が使える。
- ビルドとテストは `bash eng/*.sh` を通す。環境の違いはスクリプトの中に閉じる。

### Codespaces

- Debian なので、下の Windows 固有の制約は当てはまらない。シンボリック リンクは `ln -s`、SSH は標準のものを使う。
- `.gitconfig` の取り込みと `dotnet restore` は
  [.devcontainer/post-create.sh](.devcontainer/post-create.sh) が済ませている。手で設定しない。
- `gh` の認証は Codespaces が渡すトークンに依存する。スコープが足りない操作
  （Projects の読み書きなど）は `gh auth refresh` が必要で、これは対話が要るため自分では行わない。
  スコープ不足に当たったら、必要なスコープを添えてユーザーに報告する。

### ローカル（Windows）

- シェルは git bash。
- シンボリック リンクの作成には `cmd /c mklink` を使う。git bash の `ln` や PowerShell の `New-Item` は使わない。
- git bash 同梱の SSH は使わない（1Password SSH Agent と互換性がないため）。
