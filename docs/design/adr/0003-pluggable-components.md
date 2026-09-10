# ADR-0003: パーサーとテンプレート エンジンを差し替え可能にする

- 状態: 採用
- 日付: 2026-09-10

## 背景

Markdown と AsciiDoc を入力とし、静的サイトを生成する（[overview.md](../overview.md)）。
パーサーもテンプレート エンジンも、外部ライブラリをそのまま使うか、自作するか、
複数を並べられるようにするかを決める必要があった。

特に AsciiDoc は、既存の .NET 製パーサーがいずれも仕様を完全には満たさない
（[ADR-0004](0004-asciidoc-parser.md)）。将来の自作を見込む必要がある。

検討した候補は 3 つ。

1. 単一の実装に固定する。Markdig とテンプレート エンジン 1 つを直接呼ぶ。
2. 抽象を置いて実装を差し替え可能にし、複数の実装を並置できるようにする。
3. 抽象は置くが、実装は同時に 1 つだけとする。

## 決定

`Logora.Abstractions` に `IContentParser` と `ITemplateEngine` を置き、実装を別アセンブリとして提供する。

テンプレート エンジンは 2 系統を用意する。

- `Logora.Templates.RazorComponents` — プロジェクトの特色となる型付きテーマ（[ADR-0005](0005-razor-templates.md)）
- `Logora.Templates.Scriban` — 広く使われるテンプレート言語。Scriban は独自構文と Liquid 互換モードの両方を 1 パッケージで賄えるため、Fluid（Liquid 専用）ではなくこちらを採る

`Logora.Abstractions` が持てる外部依存は [ADR-0006](0006-abstractions-dependencies.md) が定める。

## 理由

**候補 2 を採った理由。**

- AsciiDoc パーサーの差し替えが確実に来る。既存実装を「抽象の検証役」と位置付けており
  （[ADR-0004](0004-asciidoc-parser.md)）、差し替えを後付けするより先に抽象を置く方が安い。
- 抽象を先に置くことで、[ADR-0002](0002-document-ast.md) の AST が特定パーサーの構造に
  引きずられるのを防げる。パーサーが 1 つだけなら、その構造がそのまま AST に染み出す。
- テンプレート エンジンは利用者の好みが分かれる。Razor の型付きテーマは Logora の特色になるが、
  それだけでは Liquid 系のテンプレートに慣れた利用者を取り込めない。

**候補 1 を却下した理由。** AsciiDoc の自作パーサーを入れる時点で、結局この抽象を作ることになる。
その時点では Markdig の都合が AST に染み込んでおり、抽象の切り出しが高くつく。

**候補 3 を却下した理由。** 同時に 1 つに限ると、同一形式に複数の実装を並べられない。
AsciiDoc を既存実装から自作へ移す移行期に、両方を動かして出力を比べることができなくなる。

## 命名規約

プロジェクト名は `Logora.<差し替え軸>.<実装ライブラリ名>` とする。

| プロジェクト | 実装 |
| --- | --- |
| `Logora.Parsers.Markdig` | Markdig |
| `Logora.Parsers.NAsciidoc` | NAsciidoc.Core |
| `Logora.Templates.RazorComponents` | `HtmlRenderer` |
| `Logora.Templates.Scriban` | Scriban |

入力形式名（`Logora.Markdown` など）を使わない理由は、差し替え対象が形式ではなく実装だから。
同一形式に複数の実装が並び得るため、形式名では将来の追加を並置できない。
特に AsciiDoc は自作パーサーへの差し替えを予定しているため、この差は実際に効いてくる。

## 代償

Scriban の Liquid 互換は 100% ではない。Liquid の忠実な実装が必要になった時点で
`Logora.Templates.Fluid` を追加する余地を残す。

抽象を先に置く分、実装が 1 つしかない段階では余分な間接層になる。
M1 の時点では Markdig と Scriban しかないため、抽象の妥当性は検証されない。
検証は AsciiDoc を入れる M3 まで先送りされる。

## 影響

- `Logora.Abstractions` の外部依存の方針は [ADR-0006](0006-abstractions-dependencies.md) に切り出した。
  当初この ADR に「実装ライブラリへの依存を一切持たない」と書いていた部分がそれに当たる。
- 具体的な実装の選定は [ADR-0004](0004-asciidoc-parser.md)（AsciiDoc）と
  [ADR-0005](0005-razor-templates.md)（Razor）が持つ。
