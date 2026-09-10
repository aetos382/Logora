# Logora.Abstractions の依存許可リスト

最終更新: 2026-09-10

[ADR-0006](adr/0006-abstractions-dependencies.md) が `Logora.Abstractions` の外部依存を許可制にした。
このファイルはその許可の索引である。

**正は許可を与えた issue または ADR である。** このファイルと矛盾したらそちらが正しい。
表を ADR の中に置かないのは、ADR がその時点の判断の記録であって、時間とともに増える台帳ではないため。
ADR に置くと、依存を 1 つ足すたびに ADR を書き換えることになる。

## 許可済み

| パッケージ | 許可の理由 | 許可の記録 |
| --- | --- | --- |
| （なし） | | |

**現時点では空である。** `Logora.Abstractions` は .NET のクラス ライブラリだけを使う。

ここでいう外部依存は `PackageReference` を指す。.NET のクラス ライブラリ本体は対象に含めない。
この制約は `Logora.Abstractions` にのみ課す。他のプロジェクトの依存はそれぞれの都合で決めてよい
（追加の手続きは [AGENTS.md](../../AGENTS.md) に従う）。

## 追加の手続き

1. **issue を立てる。必須である。** [ADR-0006](adr/0006-abstractions-dependencies.md) の「理由」にある
   3 つの目的のどれに触れるのかを明示し、
   **その依存を持たない場合に何を自作することになるのかを書く。**
   「便利だから」「標準的だから」は理由にならない。
2. **依存の型が公開シグネチャに現れる場合は ADR も起こす。**
   [process.md](process.md) の「後から変えるのが高くつく（公開 API）」に当たるため。
   内部に留まる依存なら issue の記録で足りる。
3. 許可が決まったら上の表に行を足し、「許可の記録」の欄に issue（ADR があればそれも）へのリンクを書く。
4. `Logora.Abstractions.csproj` に `PackageReference` を足す。
   バージョンは [Directory.Packages.props](../../Directory.Packages.props) で中央管理する。

「これは抽象パッケージだから良いはず」という判断を各自で行わない。
その判断基準が一貫しないことが、許可制にした理由である
（[ADR-0006](adr/0006-abstractions-dependencies.md) の「理由」）。

## 検討中

| パッケージ | 論点 |
| --- | --- |
| `Microsoft.Extensions.Logging.Abstractions` | [#8](https://github.com/aetos382/Logora/issues/8)。診断を流すためには要らない（[ADR-0007](adr/0007-diagnostics-as-data.md)）ので、論点は DI の採否だけである。 |
| `Microsoft.Extensions.FileProviders.Abstractions`（推移的に `Microsoft.Extensions.Primitives` を含む） | [#9](https://github.com/aetos382/Logora/issues/9) |

## 検査

CI で次を照合する（[#2](https://github.com/aetos382/Logora/issues/2)）。

- `Logora.Abstractions.csproj` の `PackageReference` が、すべて上の表に載っていること
- 表の各行が「許可した ADR」を持ち、その ADR が実在して状態が「採用」であること
- `Logora.Abstractions` が実装ライブラリのプロジェクト参照を持っていないこと

表が機械で読みにくくなったら、正の側を JSON に移してこのファイルを生成物にする。
