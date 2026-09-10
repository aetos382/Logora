# ADR-0004: AsciiDoc は NAsciidoc.Core 経由で AST にマップする

- 状態: 採用
- 日付: 2026-09-10

## 背景

[ADR-0002](0002-document-ast.md) の独自 AST が Markdown に寄っていないことを確かめるには、
性質の異なる入力形式の実装を早期に 1 つ載せる必要がある。
AsciiDoc のフル仕様パーサーは将来別プロジェクトとして作る方針のため、当面は既存の .NET 実装を使う。

## 調査結果（2026-09-10 時点）

| 候補 | 状況 | 評価 |
| --- | --- | --- |
| [NAsciidoc.Core](https://github.com/rmannibucau/NAsciidoc) | NuGet 0.0.35（2026-06 公開）。パーサーとレンダラーを持ち、AST を公開 | 採用 |
| [AsciiDocSharp](https://github.com/AsciiDocSharp/AsciiDocSharp) | NuGet 0.1.0（2025-07 公開）。仕様の 85〜88% 実装を主張し構造化モデルを持つ。単独開発でスターは少なく、README は「NuGet 未公開」のままで情報が古い | 次点 |
| [AsciiDocNet](https://github.com/russcam/asciidocnet) | NuGet 1.0.0-alpha6（2018-02）が最後 | 除外 |

## 決定

`Logora.Parsers.NAsciidoc` を実装し、NAsciidoc.Core の AST を Logora のドキュメント AST へマップする。
HTML レンダリング機能は使わない。

## 理由

- 更新が最も新しく、NuGet パッケージが存在する。
- AST を公開しているため、HTML を経由せず Logora の AST へ直接マップできる。これは [ADR-0002](0002-document-ast.md) の前提。
- asciidoctor.js を外部プロセスで呼ぶ案は、Node への依存が増えるうえ出力が HTML 固定になり、AST 抽象の検証に使えない。

## 影響

- カバー率の不足は許容する。目的は AsciiDoc の完全対応ではなく抽象の検証。
- 将来の自作パーサーは `Logora.Parsers.<名前>` として並置し、差し替えられるようにする。
- マッピング表を `docs/design` に置き、AST 側で表現できなかった構造を記録する。この記録が AST 設計の改善材料になる。
