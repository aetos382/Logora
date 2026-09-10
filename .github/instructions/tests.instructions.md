---
applyTo: 'tests/**/*.cs'
---

# テスト コードの指示

フレームワークは MSTest（MSTest.Sdk と Microsoft.Testing.Platform）。
[csharp.instructions.md](csharp.instructions.md) の内容も適用される。

## 概要コメント

**テスト メソッドの `///` には、そのテストが何を保証・確認したいのかを明確に書く。**
メソッド名を日本語に言い換えただけのコメントは書かない。

```csharp
/// <summary>
/// 見出し ID の付与が、Markdown と AsciiDoc のどちらから来た AST でも同じ結果になることを確認する。
/// AST が Markdown の構造に引きずられていないことの検証であり、ADR-0002 の合格条件にあたる。
/// </summary>
```

## 取り消し

- `CancellationToken` を受け取るメソッドを呼ぶときは、テスト クラスのコンストラクター経由で受け取った
  `TestContext` の `TestContext.CancellationToken` を渡す。`CancellationToken.None` を渡さない。
- 自分で作った `CancellationTokenSource` に由来するトークンを渡す必要がある場合は、
  `TestContext.CancellationToken` と Link させて渡す。

## そのほか

- テストは実行順序に依存させない。共有状態を持たない。
- 失敗したときに何が起きたか分かるアサーションを書く。真偽値だけを検査して終わらない。
- 既存のテストを消したり緩めたりして通さない。
  特に Markdown と AsciiDoc の結果を突き合わせる横断テストは、AST 設計の検証装置なので弱めない。
- テスト プロジェクトは `<テスト対象プロジェクト名>.Tests` を既定の命名とし、`tests/` 配下に置く。
  作ったら `dotnet sln add` で [Logora.slnx](../../Logora.slnx) に登録する。
