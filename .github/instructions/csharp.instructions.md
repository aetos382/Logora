---
applyTo: '**/*.cs'
---

# C# コードの指示

書式と命名の正は [.editorconfig](../../.editorconfig) と [.globalconfig](../../.globalconfig) で、違反はビルド警告として出る。
以下は機械で検出できないことだけを挙げる。

- `ImplicitUsings` は無効。`using` は明示する。
- 自分のメンバーへのアクセスは `this.` または型名で修飾する。
- 公開 API には XML ドキュメント コメントを日本語で書く。
- コメントは日本語で書く。「なぜそうしたか」を書き、コードを読めば分かることは書かない。
- 「例外を投げる」を単に「投げる」と書かない。
- 警告を抑制する場合（`#pragma warning disable` / `SuppressMessageAttribute`）は、必ず理由をコメントで添える。

## 設計上の制約

- `Logora.Abstractions` には実装ライブラリ（Markdig、NAsciidoc、Scriban など）の型を持ち込まない。
  公開シグネチャにも `PackageReference` にも出さない。
- パーサーは AST を構築するところまでを責務とする。HTML を生成しない。
- AST ノードを新設するのは、2 つ以上の入力形式で必要なときだけ。
- パーサー固有の情報は `Attributes` に、AST で表現できない構造は `UnknownNode` に原文とともに残す。情報を捨てない。
- Razor は静的レンダリングのみに使う。対話型レンダリングや SignalR を要する機能を使わない。

## 非同期と取り消し

- 非同期メソッドは `CancellationToken` を受け取り、呼び出し先へ伝播させる。
- `.Result` や `.Wait()` で同期待ちしない。
- 例外を握り潰さない。捨てるなら理由をコメントに書く。
