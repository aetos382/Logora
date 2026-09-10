# ADR-0006: Logora.Abstractions の外部依存を許可制にする

- 状態: 採用
- 日付: 2026-09-10

## 背景

`Logora.Abstractions` は契約だけを持つプロジェクトである（[ADR-0003](0003-pluggable-components.md)）。
そこに何を依存させるかは、Logora のすべての契約に影響する。

当初この方針は ADR-0003 に「実装ライブラリへの依存を一切持たない」と書かれていた。
しかし `Microsoft.Extensions.Logging.Abstractions` や
`Microsoft.Extensions.FileProviders.Abstractions` のように、
**それ自体が差し替え軸を抽象化しているパッケージ**をどう扱うかが、この書き方では決まらなかった。

検討した候補は 3 つ。

1. 実装ライブラリへの依存だけを禁じる（当初案）。
2. 外部依存を一切禁じる。
3. 外部依存を許可制にし、許可したものを列挙する。

## 決定

**`Logora.Abstractions` は外部依存を極力持たない。**
依存してよいパッケージは [abstractions-dependencies.md](../abstractions-dependencies.md) に
列挙したものだけとし、**追加には issue を要する。** 裁量で足さない。

- ここでいう外部依存は `PackageReference` を指す。.NET のクラス ライブラリ本体は対象に含めない。
- この制約は `Logora.Abstractions` にのみ課す。他のプロジェクトの依存はそれぞれの都合で決めてよい
  （ただし追加の手続きは [AGENTS.md](../../../AGENTS.md) に従う）。
- 許可そのものに ADR は要求しない。issue の記録で足りる。
  ただし依存の型が公開シグネチャに現れる場合は、[process.md](../process.md) の
  「後から変えるのが高くつく（公開 API）」に当たるため、一般則として ADR が必要になる。

**この ADR は「許可制にする」という規則だけを決め、個々の許可は持たない。**
許可済みのパッケージと追加の手続きは索引
（[abstractions-dependencies.md](../abstractions-dependencies.md)）にある。
索引を ADR の中に置かないのは、ADR がその時点の判断の記録であって台帳ではないため。
中に置くと、依存を 1 つ足すたびにこの ADR を書き換えることになり、
無関係な決定まで巻き込んで「置換」が発生する。

## 理由

`Logora.Abstractions` の依存を絞ることには、3 つの目的がある。

1. **差し替え軸を固定しない。** Abstractions が Markdig に依存すると、Markdig を使わない構成にも
   Markdig が入り、差し替えの意味が消える。
2. **公開契約に他者の型とバージョン制約を持ち込まない。** 公開シグネチャに現れた型は契約の一部になり、
   その型の破壊的変更が Logora の破壊的変更になる。バージョン制約も利用者へ伝播する。
3. **AST の設計が特定実装に引きずられない。** [ADR-0002](0002-document-ast.md) の
   「Markdown にある要素ではなく文書に必要な要素で定義する」は、Abstractions が Markdig の構造を
   知らないことで初めて守れる。

**候補 1（実装ライブラリへの依存だけを禁じる）を却下した理由。**
パッケージごとに「これは実装ライブラリなのか」を判断する必要があり、その基準が一貫しない。
`Microsoft.Extensions.Logging.Abstractions` のように、それ自体が差し替え軸を抽象化していて
目的 1 と 3 には触れないものが出てくると、判断は毎回の裁量になり、1 つ通れば次が通る。

**候補 2（一切禁じる）を却下した理由。**
判定は機械的で崩れないが、設計が歪む。`Microsoft.Extensions.FileProviders.Abstractions` を
許可できないなら、テーマの階層化と NuGet パッケージ内のテンプレート読み取りを自作することになり、
自作した抽象は実装側で `IFileProvider` との相互変換アダプターを伴う。
境界が増え、変換のたびに情報が落ちる。得られるのは「依存が 0 個」という数字だけである。

**候補 3 を採った理由。**
判定を各回の裁量から外し、許可したものを名前で列挙する。
数を数える代わりに名前を数えるので、判定は機械的なままである。
csproj の `PackageReference` を索引と照合すれば CI で検査できる。

## 代償

許可リスト方式は、依存を 1 つ増やすたびに issue を要求する。手続きの重さは実際の摩擦になり、
本来入れるべき依存の追加が遅れることがある。ADR まで要求すると摩擦が大きすぎると判断し、
必須は issue に留めた。それでも各回の裁量に委ねるより崩れにくい。

索引を ADR の外に置いたことで、索引と ADR がずれる余地が生まれる。
[overview.md](../overview.md) と同じ問題であり、CI での照合で埋める。

## 影響

- ADR-0003 からこの方針を切り出した。ADR-0003 は差し替え可能な構造・実装の選定・命名規約を持ち、
  依存方針は持たない。ADR-0003 の決定内容は変わっていないので、状態は「採用」のまま据え置く。
- 許可済みパッケージの索引と追加の手続きは
  [abstractions-dependencies.md](../abstractions-dependencies.md) に置く。
  この ADR は書き換えず、索引の側に行を足す。
- 索引と `Logora.Abstractions.csproj` の照合を CI で行う
  （[#2](https://github.com/aetos382/Logora/issues/2)）。
- 許可を検討中のものは
  [#7](https://github.com/aetos382/Logora/issues/7) /
  [#8](https://github.com/aetos382/Logora/issues/8) /
  [#9](https://github.com/aetos382/Logora/issues/9) にある。
