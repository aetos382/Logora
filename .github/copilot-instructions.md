# GitHub Copilot への指示

実装ルールは [AGENTS.md](../AGENTS.md) にある。作業前に必ず読む。
設計判断の正は [docs/design/adr/](../docs/design/adr/) にある ADR で、進め方は [docs/design/process.md](../docs/design/process.md) にある。

パスごとの追加指示は [.github/instructions/](instructions/) にある。

## 役割

- PR の一次レビュー
- ラベル `agent:copilot` が付いた issue の実装

`agent:copilot` が付いていない issue の実装を引き受けない。

## 実装するとき

- issue の「関連 ADR」を読み、それに従う。ADR に書かれていない設計判断が必要になったら、実装せずに issue にコメントで論点を挙げる。
- 触るファイルを issue の範囲に留める。ついでの改善やリファクタリングを混ぜない。
- 新しい NuGet パッケージを追加しない。必要なら issue にコメントで提案する。
- 新しいプロジェクトを作ったら `dotnet sln add` で [Logora.slnx](../Logora.slnx) に登録する。
- 依存を変えたら `dotnet restore` で `packages.lock.json` を更新し、コミットに含める。
- PR 本文に、従った ADR と、ADR から逸脱した点（あれば理由つき）を書く。

## レビューの観点

上から優先順。

1. **ADR 違反。** 特に次の 3 つ。
   - `Logora.Abstractions` への、[許可リスト](../docs/design/abstractions-dependencies.md)に無い依存の混入（[ADR-0006](../docs/design/adr/0006-abstractions-dependencies.md)）
   - HTML 生成が Parse 段階に漏れ出していること（[ADR-0002](../docs/design/adr/0002-document-ast.md)）
   - 1 つの入力形式のためだけの AST ノード追加（[ADR-0002](../docs/design/adr/0002-document-ast.md)）
2. **誤り。** null 許容性の破り、例外の握り潰し、`CancellationToken` の未伝播、非同期の同期待ち、
   パーサー固有情報の取りこぼし（`Attributes` / `UnknownNode` に残すべきものを捨てている）。
3. **テスト。** 新しい分岐にテストがあるか。テスト メソッドの概要コメントが、
   メソッド名の言い換えではなく「何を保証したいのか」を述べているか。
4. **生成物の追随。** `packages.lock.json` が依存変更に追随しているか。新規プロジェクトが `Logora.slnx` に登録されているか。
5. **規約。** [.editorconfig](../.editorconfig) / [.globalconfig](../.globalconfig) 違反。

## レビューで指摘しないこと

- ビルド警告として既に出るもの。二重に指摘しない。
- [.globalconfig](../.globalconfig) で `suggestion` や `silent` に落としている診断。
- 好みの問題。
- PR の範囲外にある既存コードのリファクタリング提案。
- コメントや識別子の英語化。このリポジトリのコメントとドキュメントは日本語で書く。
