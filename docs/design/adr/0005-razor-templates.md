# ADR-0005: Razor テンプレートは HtmlRenderer で実装する

- 状態: 採用
- 日付: 2026-09-10

## 背景

プロジェクトの特色として Razor 系のテンプレートを持ちたかった。実装方式の候補は 3 つ。

1. テーマを Razor Class Library として事前ビルドし、アセンブリとして読み込む
2. Razor.Language と Roslyn を自前で叩き、`.cshtml` を実行時コンパイルする
3. `Microsoft.AspNetCore.Components.Web.HtmlRenderer` で Razor コンポーネントを静的にレンダリングする

RazorLight は 2.3.1（2023-01）で更新が止まっているため候補に含めなかった。

## 決定

**`HtmlRenderer`** を使い、`.razor` コンポーネントを静的レンダリングする。
プロジェクト名は `Logora.Templates.RazorComponents`。

## 理由

- [公式ドキュメント](https://learn.microsoft.com/aspnet/core/blazor/components/render-components-outside-of-aspnetcore)が
  用途として「静的サイト コンテンツの生成」と「コンテンツ テンプレート エンジンの構築」を明示している。想定用途が一致する。
- コンソール アプリで完結する。`Microsoft.NET.Sdk.Razor` への切り替えと
  `Microsoft.AspNetCore.Components.Web` のパッケージ参照だけで動き、`FrameworkReference` を必要としないため
  `dotnet tool` としての配布と衝突しない。
- `output.WriteHtmlTo(textWriter)` があり、文字列を経由せずファイルへ書き出せる。
- `ParameterView.FromDictionary` でサイト モデルを渡せるため、型付きテーマと動的モデルを両立できる。
- コンポーネント合成とレイアウトが言語機能として揃っており、自前の実行時コンパイル（案 2）を書く必要がない。

## 実装上の注意

- `RenderComponentAsync` は `HtmlRenderer.Dispatcher.InvokeAsync` の中で呼ぶ。
- 非同期ライフサイクルの完了を待つ必要がある場合は `BeginRenderingComponent` と
  `HtmlRootComponent.QuiescenceTask` を使う。
- 対話型レンダリングは使わない。SignalR 接続を要する機能はこの文脈で動作しない。

## 代償

- `.razor` は事前コンパイルが前提のため、テーマはアセンブリになる。テーマ作者に .NET SDK を要求する。
  そのため既定テーマは Scriban で提供し、Razor は上位の選択肢として置く（[ADR-0003](0003-pluggable-components.md)）。
- `serve --watch` での即時反映には、テーマの再ビルドとアンロード可能な `AssemblyLoadContext` での再読み込みが必要。
  M5 で設計する。
