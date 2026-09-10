# 利用シナリオ

最終更新: 2026-09-10

## このドキュメントの位置づけ

**これは決定ではない。** 利用モデル（CLI 主体か、利用者のプロジェクト主体か）と
サイト定義の形式を ADR で決めるための材料として、想定する利用者の姿を具体化したものである。

ここに書いたコマンド名・ファイル名・設定キーはいずれも仮であり、実装の約束ではない。
決定は ADR に書き、確定した内容は [overview.md](overview.md) に反映する。

## 前提

- Logora の CLI は `dotnet tool` として配布する（[overview.md](overview.md) の目標）。
  **`dotnet tool install` は .NET SDK のコマンドであるため、CLI を使う場合でも利用者には SDK が必要になる。**
  SDK なしで使えるようにするなら、self-contained な単一ファイルを別途配布する形になり、これは未検討である。
  したがって以下の 4 通りの違いは「SDK が要るかどうか」ではなく、**利用者がプロジェクト ファイルを書くかどうか**にある。
- Razor テーマの作成に .NET SDK が必要であることは既に受け入れている（[ADR-0005](adr/0005-razor-templates.md)、
  [overview.md](overview.md) のリスク表）。既定テーマを Scriban で提供するのはこのためである。

以下、テーマの実体（Scriban / Razor）と自作アドオンの有無で 4 通りを並べる。

## S1: Scriban テーマ / アドオンなし

ブログを書きたい人。C# は書かない。**最も多い想定であり、既定の経路。**

```sh
dotnet tool install -g Logora.Cli
logora new site myblog
cd myblog
logora serve
```

```
myblog/
  logora.yaml                  # サイト設定
  content/posts/2026-09-10-hello.md
  themes/default/
    layouts/post.html          # Scriban。テキストのまま編集できる
    assets/style.css
  static/
  output/
```

C# のコードは一行もない。見た目を変えたければ `layouts/*.html` を直すだけで、手順は増えない。
Hugo に最も近い体験になる。

## S2: Razor テーマ / アドオンなし

C# を書ける人。型付きのテンプレートと補完が欲しい。

```
myblog/
  logora.yaml
  content/posts/...
  theme/
    MyTheme.csproj             # Logora.Templates.RazorComponents を参照
    Layouts/Post.razor
    wwwroot/style.css
  output/
```

**論点**: テーマのビルドを誰が行うか。

| 案 | 内容 | 評価 |
| --- | --- | --- |
| (a) CLI がビルドする | `logora build` が `theme/*.csproj` を MSBuild で建て、出力アセンブリを読み込む | S1 と操作が変わらない。CLI が MSBuild を呼ぶ複雑さを抱える |
| (b) 利用者がビルドする | 利用者が自分のプロジェクトから Logora を呼ぶ（Statiq 方式） | 仕組みは単純だが、S1 と体験が別物になる |

S1 からの連続性を重視するなら (a)。ただし S4 では (b) の方が素直になる（後述）。

## S3: Scriban テーマ / 自作アドオンあり

独自のショートコードを足したい、外部から取得したデータを埋め込みたい人。
**テキストのままでよい部分はテキストで書き、拡張したい部分だけが C# になる。**

```
myblog/
  logora.yaml                  # 使うアドオンを宣言する
  content/...
  themes/default/...
  plugins/MyPlugin/
    MyPlugin.csproj            # Logora.Abstractions を参照
    MyShortcode.cs
```

拡張点は `Logora.Abstractions` の契約（[ADR-0003](adr/0003-pluggable-components.md)）に載る。
アドオンのアセンブリは `AssemblyLoadContext` で読み込むことになるが、
**`Logora.Abstractions` を CLI 側と共有しないと型の同一性が壊れる**ため、
`AssemblyDependencyResolver` で解決する必要がある。この仕組みは未設計であり、需要が見えてから作る。

## S4: Razor テーマ / 自作アドオンあり

全部自分で組みたい人。テーマもアドオンもどうせ csproj になるため、
**ここが利用者のプロジェクト主体（S2 の案 (b)）に移る境界になる。**

```
myblog/
  Site/
    Site.csproj                # Logora.Core と Logora.Templates.RazorComponents を参照
    Program.cs
    logora.yaml
    Layouts/*.razor
    Extensions/*.cs
    content/...
```

`dotnet run` で生成し、CLI を使わない。ソリューションが 1 つになるため、
アドオンは単に同じプロジェクトの 1 クラスであり、**プラグイン読み込みの仕組みが要らない。**
デバッガーでブレークポイントも張れる。

S3 で必要になる `AssemblyLoadContext` の設計を先送りできるのは、
拡張を本気でやる利用者がこの経路に来られるからである。

## 一覧

| | テーマの実体 | 拡張 | 利用者が書くもの | 実行 | 追加で必要な仕組み |
| --- | --- | --- | --- | --- | --- |
| S1 | テキスト | なし | YAML と Markdown | `logora build` | なし |
| S2 | csproj | なし | + `.razor` | `logora build` | テーマのビルドと読み込み |
| S3 | テキスト | csproj | + `.cs` | `logora build` | アドオンのビルドと読み込み |
| S4 | csproj | csproj | + `Program.cs` | `dotnet run` | なし（利用者のビルドに乗る） |

## ここから導かれること

1. **S1〜S3 を CLI で一貫させ、S4 で利用者のプロジェクト主体に移す**のが自然な線引きになる。
   S1 が既定であることは [overview.md](overview.md) の M6（`dotnet tool` としての配布）から出ており、
   S4 が成立することは [ADR-0005](adr/0005-razor-templates.md) が Razor テーマに SDK を要求していることから出ている。
2. **`logora.yaml` と `content/` の形を 4 通りすべてで同じにする。**
   これを守れば、S1 で始めた人が S4 まで移れる。逆にここが分かれると、
   S1 の利用者は拡張したくなった時点で作り直すことになる。
3. **拡張の余地は段階で用意する。** 一度に全部作らない。
   1. 設定による選択（同梱された実装から選ぶ）— S1
   2. テンプレート側の式とカスタム関数 — S1 と S3 の中間。Hugo は実質ここで足りている
   3. アセンブリの読み込み — S3。需要が見えてから
4. アドオンの読み込みを後から足せる条件は、**`Logora.Abstractions` の契約が安定していて、
   すべて DI で解決されていること**である。これは [ADR-0003](adr/0003-pluggable-components.md) が既に定めている。
