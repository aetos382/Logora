# ADR-0003: パーサーとテンプレート エンジンを差し替え可能にする

- 状態: 採用
- 日付: 2026-09-10

## 決定

`Logora.Abstractions` に `IContentParser` と `ITemplateEngine` を置き、実装を別アセンブリとして提供する。
`Logora.Abstractions` は実装ライブラリへの依存を一切持たない。

テンプレート エンジンは 2 系統を用意する。

- `Logora.Templates.RazorComponents` — プロジェクトの特色となる型付きテーマ（[ADR-0005](0005-razor-templates.md)）
- `Logora.Templates.Scriban` — 広く使われるテンプレート言語。Scriban は独自構文と Liquid 互換モードの両方を 1 パッケージで賄えるため、Fluid（Liquid 専用）ではなくこちらを採る

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
