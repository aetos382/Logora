# Logora 設計概要

最終更新: 2026-09-10

## このドキュメントの位置づけ

これは [ADR](adr/README.md) の要約ビューである。設計判断の正は ADR にあり、
このドキュメントと ADR が矛盾した場合は ADR が正しい。

ADR を追加・変更したときは、このドキュメントも追随させる。
ここに ADR のない新しい決定を書かない。進め方は [進め方](process.md) にある。

## 目的

Markdown と AsciiDoc を入力とし、静的なサイトを生成する汎用のジェネレーターを C# で作る。
最初の到達目標はブログだが、ブログ固有の概念をコアに埋め込まない。

## 目標

- 入力形式・テンプレート エンジン・出力を差し替え可能にする。
- 目次生成や相互参照の解決といった文書変換を、入力形式に依存せず一度だけ書けるようにする。
- CLI を `dotnet tool` として配布する。
- Logora 自身のドキュメント サイトを Logora で生成する（self-hosting）。

## 非目標

- AsciiDoc のフル仕様実装。既存の .NET 実装を利用し、完全な自作パーサーは別プロジェクトとして扱う（[ADR-0004](adr/0004-asciidoc-parser.md)）。
- 対話型 UI。Razor コンポーネントは静的レンダリングのみに使う（[ADR-0005](adr/0005-razor-templates.md)）。
- 既存 SSG（Statiq など）との設定互換。

## パッケージ構成

| プロジェクト | 役割 |
| --- | --- |
| `Logora.Abstractions` | `IContentParser` / `ITemplateEngine` / `IOutputWriter` とドキュメント AST の契約のみ。外部依存は[許可リスト](abstractions-dependencies.md)にあるものだけ（現時点では空）。 |
| `Logora.Core` | AST 実装、パイプライン、サイト モデル、増分ビルド |
| `Logora.Parsers.Markdig` | Markdig を AST へマップ |
| `Logora.Parsers.NAsciidoc` | NAsciidoc.Core を AST へマップ |
| `Logora.Templates.RazorComponents` | `HtmlRenderer` による Razor コンポーネントのレンダリング |
| `Logora.Templates.Scriban` | Scriban（Liquid 互換モードを含む） |
| `Logora.Cli` | `logora new` / `build` / `serve` |

プロジェクト名の第 2 セグメントは差し替え軸（`Parsers` / `Templates`）、第 3 セグメントは採用した実装ライブラリ名とする。
入力形式名（`Markdown` など）を使わないのは、同一形式に複数の実装が並び得るため（[ADR-0003](adr/0003-pluggable-components.md)）。

`Logora.Abstractions` の外部依存は許可制とし、許可したものを
[abstractions-dependencies.md](abstractions-dependencies.md) に列挙する
（[ADR-0006](adr/0006-abstractions-dependencies.md)）。現時点では空である。
追加には issue が必要で、依存の型が公開シグネチャに現れる場合は ADR も必要になる。

## パイプライン

```
Discover → Parse → Transform → Model → Render → Emit
```

| 段階 | 内容 |
| --- | --- |
| Discover | ソース ファイルと静的アセットの列挙 |
| Parse | `IContentParser` によるドキュメント AST への変換 |
| Transform | AST 変換。見出し ID の付与、目次の構築、相互参照の解決 |
| Model | front matter の解釈、ページ間の関係、タクソノミの構築 |
| Render | AST から HTML 断片を生成し、`ITemplateEngine` でページに埋め込む |
| Emit | 出力ファイルの書き出しとアセットのコピー |

## ドキュメント AST の設計指針

抽象が Markdown へ寄ることを防ぐため、次を守る。

1. ノードは「Markdown にある要素」ではなく「文書に必要な要素」で定義する。
   `Section` / `Block` / `Inline` / `Admonition` / `DescriptionList` / `Table` / `CrossReference` を第一級として持つ。
2. パーサー固有の情報は捨てず、任意の key/value を持つ `Attributes` に保持する。
   表現できない構造は `UnknownNode` として原文とともに残す。
3. **合格条件**: 目次生成と相互参照解決という同一の AST 変換が、Markdown と AsciiDoc の双方で同じ結果を返すことをテストで担保する。
   これを M3 の受け入れ条件とする。

## マイルストーン

| | 内容 | 完了条件 |
| --- | --- | --- |
| M0 | 設計ドキュメントと AST 仕様の確定 | AST のノード一覧と各パーサーからのマッピング表がある |
| M1 | 最短経路 | Markdown 1 ファイルが Scriban 経由で HTML として出力される |
| M2 | サイト モデル | front matter・記事一覧・タクソノミが動き、ブログ テーマが 1 つある |
| M3 | AsciiDoc 投入 | 上記「合格条件」を満たす |
| M4 | Razor コンポーネント | 同じサイトを両エンジンで生成でき、出力が一致する |
| M5 | watch / serve / 増分ビルド | ソース変更が差分ビルドで反映される |
| M6 | 配布と self-hosting | `dotnet tool` として入り、ドキュメント サイトを Logora で生成する |

## リスク

| リスク | 対処 |
| --- | --- |
| 既存の .NET 製 AsciiDoc パーサーはいずれも仕様を完全に満たさない | 抽象の検証役と位置付け、差し替え可能にしておく（[ADR-0004](adr/0004-asciidoc-parser.md)） |
| Razor テーマはアセンブリになるため、`serve --watch` での即時反映が難しい | テーマの再ビルドとアンロード可能な `AssemblyLoadContext` での再読み込みを M5 で設計する |
| Razor テーマの作成に .NET SDK が必要 | 既定テーマは Scriban で提供し、Razor は上位の選択肢として置く |
| AST が肥大化する | ノード追加は「2 つ以上の入力形式で必要」を要件とする |
| GitHub に同名の organization（Logora）が存在する | 公開前に商標を確認する |

## 参照

- [Render Razor components outside of ASP.NET Core](https://learn.microsoft.com/aspnet/core/blazor/components/render-components-outside-of-aspnetcore)
- [NAsciidoc](https://github.com/rmannibucau/NAsciidoc)
- [Scriban](https://github.com/scriban/scriban)
- [Markdig](https://github.com/xoofx/markdig)
