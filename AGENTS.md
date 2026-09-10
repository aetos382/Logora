# AGENTS.md

Logora の実装ルール。Claude と GitHub Copilot の双方がこのファイルに従う。
設計判断・issue・PR の進め方は [docs/design/process.md](docs/design/process.md) にある。

## このリポジトリ

Markdown と AsciiDoc を入力とし、静的サイトを生成する汎用ジェネレーターを C# で作る。
最初の到達目標はブログだが、ブログ固有の概念をコアに埋め込まない。
全体像は [docs/design/overview.md](docs/design/overview.md)。

## ADR が設計の正

- [docs/design/adr/](docs/design/adr/) にある ADR が設計判断の唯一の正である。
- [docs/design/overview.md](docs/design/overview.md) は ADR の要約ビューにすぎない。両者が矛盾したら ADR が勝つ。
- **ADR に反する実装をしてはならない。** 反する必要が出たら、コードを書く前に ADR を追加または更新する。手順は [docs/design/process.md](docs/design/process.md)。
- 実装 issue には関連 ADR が書かれている。着手前に必ず読む。

## 確定している設計制約

実装時に守るべき点を ADR から抜き出したもの。理由と経緯は各 ADR を読む。

- 中間表現は独自のドキュメント AST とする（[ADR-0002](docs/design/adr/0002-document-ast.md)）。
  パーサーの責務は AST の構築までで、HTML の生成は Render 段階に置く。Parse 段階で HTML を作らない。
- AST ノードは「Markdown にある要素」ではなく「文書に必要な要素」で定義する（[ADR-0002](docs/design/adr/0002-document-ast.md)）。
  **ノードの追加は「2 つ以上の入力形式で必要であること」を要件とする。** 1 形式のためだけにノードを増やさない。
- パーサー固有の情報は任意の key/value を持つ `Attributes` に保持し、表現できない構造は `UnknownNode` として原文とともに残す。情報を捨てない。
- `Logora.Abstractions` は外部依存を極力持たない（[ADR-0006](docs/design/adr/0006-abstractions-dependencies.md)）。
  依存してよいパッケージは [abstractions-dependencies.md](docs/design/abstractions-dependencies.md) に
  列挙されたものだけで、**現時点では空**。
  Markdig や Scriban の型を、公開シグネチャにも `PackageReference` にも持ち込まない。
  「これは抽象パッケージだから良いはず」と自分で判断しない。追加には issue が必要で、
  公開シグネチャに型が現れる場合は ADR も必要になる。
- プロジェクト名は `Logora.<差し替え軸>.<実装ライブラリ名>` とする（[ADR-0003](docs/design/adr/0003-pluggable-components.md)）。
  `Logora.Markdown` のような入力形式名は使わない。同一形式に複数の実装が並び得るため。
- AsciiDoc は NAsciidoc.Core の AST を経由してマップし、その HTML レンダリング機能は使わない（[ADR-0004](docs/design/adr/0004-asciidoc-parser.md)）。
  AST 側で表現できなかった構造はマッピング表に記録する。この記録が AST 設計の改善材料になる。
- Razor は `HtmlRenderer` による静的レンダリングのみに使う（[ADR-0005](docs/design/adr/0005-razor-templates.md)）。
  対話型レンダリングと SignalR を要する機能は使わない。
- **診断（パース警告、`UnknownNode` の発生、相互参照の解決失敗など）は `IDiagnosticSink` へ報告する**
  （[ADR-0007](docs/design/adr/0007-diagnostics-as-data.md)）。
  - **`ILogger` に流さない。** 診断はビルド結果を構成するデータであり、
    ログの出力設定によって件数が変わってはならない。
  - シンクは呼び出しごとのコンテキスト引数で受け取る。
    **コンストラクターで受け取ってフィールドに保持しない。** 別のビルドの診断が混ざる。
  - 戻り値に診断を含めない。重複排除・ソート・打ち切り・ビルド失敗の判定は `Logora.Core` の責務で、
    プラグイン側で行わない。

## ディレクトリ

| パス | 内容 |
| --- | --- |
| `sources/` | 製品コード。1 プロジェクト 1 ディレクトリ。 |
| `tests/` | テスト コード。`<テスト対象プロジェクト名>.Tests` を既定の命名とする。 |
| `docs/design/` | 設計ドキュメントと ADR |
| `eng/` | ビルド・テスト用のスクリプトと、開発環境の設定（`rulesets/` の ruleset 定義など） |
| `artifacts/` | ビルド出力（`UseArtifactsOutput`）。Git 管理外。`bin` / `obj` を探さない。 |

## ビルドとテスト

SDK は [global.json](global.json) で固定している（.NET 10）。テストは MSTest.Sdk と Microsoft.Testing.Platform。

| 目的 | コマンド |
| --- | --- |
| ビルド | `bash eng/build.sh` |
| テスト（全体） | `bash eng/test.sh` |
| テスト（単一プロジェクト） | そのプロジェクト ディレクトリで `dotnet test` |
| テスト（単一ケース） | そのプロジェクト ディレクトリで `dotnet test --filter FullyQualifiedName=<テスト メソッドの完全修飾名>` |
| 書式・命名の検査 | `bash eng/format.sh`（`--fix` を付けると修正する） |

スクリプトは実行権限に依存しないよう `bash` 経由で呼ぶ。

### プロジェクトを追加したとき

1. `dotnet sln add <csproj のパス>` で [Logora.slnx](Logora.slnx) に登録する。**忘れるとビルドも CI もそのプロジェクトを見ない。**
2. パッケージ化する場合のみ、その csproj で `IsPackable` を `true` にする（既定は `false`）。

### パッケージ参照

- バージョンは [Directory.Packages.props](Directory.Packages.props) で中央管理している。csproj に `Version` を書かない。`PackageVersion` を追加する。
- `packages.lock.json` を使う。依存を変えたら `dotnet restore` でロックファイルを更新し、コミットに含める。
  CI は `RestoreLockedMode` で走るため、更新漏れは restore の失敗になる。ロックファイルを手で編集しない。
- **新しい NuGet パッケージの追加は勝手に行わない。** 必要になったら issue か PR で先に提案する。

## エラーと警告

- コンパイル エラーは修正する。
- テストの失敗は修正する。特記事項がない限り、テストを消したり緩めたりして通すことはしない。
- 警告はビルドを失敗させない設定だが（`TreatWarningsAsErrors` は `false`、`AnalysisLevel` は `latest-all`）、放置しない。
  自分の変更で増えた警告は消す。消すべきでないと判断したら、その理由を PR に書く。
- 抑制（`#pragma warning disable` / `SuppressMessageAttribute`）を入れるときは、必ず理由をコメントで添える。
- 情報（suggestion / silent）は触らない。

## コーディング規約

**規約の正は [.editorconfig](.editorconfig) と [.globalconfig](.globalconfig) である。**
書式と命名の違反はビルド時の警告として出るので、それらの内容をここに書き写さない。
以下は機械で検出できないことだけを挙げる。

- `ImplicitUsings` は無効。`using` は明示する。
- 自分のメンバーへのアクセスは `this.` または型名で修飾する（`.globalconfig` が警告として強制する）。
- 公開 API には XML ドキュメント コメントを日本語で書く（`GenerateDocumentationFile` が有効）。
- コメントは日本語で書く。「なぜそうしたか」を書き、コードを読めば分かることは書かない。
- **GitHub Actions のワークフローだけは英語で書く。** ジョブ名とステップ名がステータス チェックの
  名前として GitHub の UI と API に現れ、[eng/rulesets/main.json](eng/rulesets/main.json) の
  `required_status_checks` からも参照されるため。コメントも合わせて英語にする。
- 「例外を投げる」を単に「投げる」と書かない。
- まだ何も公開していない。互換性を保つための小細工より、今のうちに素直な形に直すことを優先する。

## テスト

- フレームワークは MSTest。
- **テスト メソッドの概要コメント（`///`）には、そのテストが何を保証・確認したいのかを明確に書く。**
  メソッド名の言い換えにしない。
- `CancellationToken` を受け取るメソッドを呼ぶときは、テスト クラスのコンストラクター経由で受け取った
  `TestContext` の `TestContext.CancellationToken` を渡す。
- 自分で作った `CancellationTokenSource` に由来するトークンを渡す必要がある場合は、
  `TestContext.CancellationToken` と Link させて渡す。
- [ADR-0002](docs/design/adr/0002-document-ast.md) の合格条件（同一の AST 変換が Markdown と AsciiDoc で同じ結果を返すこと）は
  M3 の受け入れ条件である。この種の横断テストを削除したり緩めたりしない。

## Git

- `main` に直接コミットしない。1 issue = 1 ブランチとし、1 つのブランチを複数のエージェントで触らない。
- まとめて対応したい場合も、1 PR に複数の issue を詰めない。issue の側を統合してから 1 つの PR を出す。
  手順は [docs/design/process.md](docs/design/process.md)。
- ブランチ名は `<kind>/<issue 番号>-<短い英語スラッグ>`（例: `feat/12-markdig-mapping`）。
- 改行は LF。[.gitattributes](.gitattributes) で強制している。
- `git config --list` や `git config --get` は使わない。`git config list` と `git config get` を使う。
- [.gitconfig](.gitconfig) にマージ ドライバーの定義がある。[.gitattributes](.gitattributes) の `merge=ours` がこれに依存するため、
  クローン後に一度 `git config set --append include.path ../.gitconfig` を実行する（devcontainer では自動で入る）。
- コミット メッセージは日本語。1 行目に要約を書き、理由が必要なら空行の後に続ける。

## やってはいけないこと

- ADR に反する設計変更を、ADR を更新せずに実装すること。
- `Logora.Abstractions` に、[許可リスト](docs/design/abstractions-dependencies.md)に無いパッケージへの依存を追加すること。
- 1 つの入力形式のためだけに AST ノードを追加すること。
- `packages.lock.json` を手で編集すること。
- 相談なく NuGet パッケージを追加すること。
- 指示なくコミットまたはプッシュすること。
