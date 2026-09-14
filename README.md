# Logora

Markdown と AsciiDoc を入力とし、静的なサイトを生成する汎用のジェネレーター。C# 製。

最初の到達目標はブログだが、ブログ固有の概念をコアに埋め込まない。
入力形式・テンプレート エンジン・出力はいずれも差し替え可能にする。

**現在は設計段階であり、動くものはまだない。**

## ドキュメント

- [設計概要](docs/design/overview.md) — 目的、パッケージ構成、パイプライン、マイルストーン
- [ADR 一覧](docs/design/adr/README.md) — 設計判断の記録。ここが設計の正である
- [進め方](docs/design/process.md) — ADR・issue・PR の運用と、AI エージェントへの作業の割り振り

## 開発

GitHub Codespaces を主開発環境とする。
Codespace を作れば、.NET SDK・gh CLI・Claude Code CLI が入った状態で始められる。

ローカルで作業する場合は .NET SDK が必要（必要なバージョンは [global.json](global.json) を参照）。
クローン後に一度、マージ ドライバーの定義を取り込む。

```sh
git config set --append include.path ../.gitconfig
git config set core.hooksPath .githooks
```

| 目的 | コマンド |
| --- | --- |
| ビルド | `bash eng/build.sh` |
| テスト | `bash eng/test.sh` |
| 書式・命名の検査 | `bash eng/format.sh` |

AI エージェントに作業させる際の規約は [AGENTS.md](AGENTS.md) にある。

## ライセンス

BSD-2-Clause-Patent。[LICENSE](LICENSE) を参照。
