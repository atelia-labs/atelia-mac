# Atelia Mac

[English README](README.md)

Atelia Mac は、Atelia を操作するための macOS 向けネイティブクライアントです。

このリポジトリは、macOS 固有の UI、ウィンドウ管理、通知、ファイルアクセス、Git / review interface、terminal、Hook / automation / extension 管理、音声による操作を扱います。共有ロジックは `atelia-kit` に置きます。

AEP において、Atelia Mac は reference presentation host です。semantic で permission-aware な AEP presentation surface を native Swift component で描画します。任意に download された client UI code の install / execute は行いません。

## 初期スコープ

- project / thread の一覧と切り替え
- 複数 agent 作業の状態表示
- Git branch / worktree / diff / commit / push / PR のインターフェース
- 自動レビュー結果の表示
- アプリ内ターミナル
- review queue
- 音声による操作
- Hook / automation / extension の確認
- Atelia Secretary daemon への接続管理
- AEP semantic presentation renderer subset
- extension install、permission diff、approval、review、settings、audit surface

## 将来スコープ

- アプリ内ブラウザ
- browser use / computer use
- plugin / skill / automation / extension の詳細管理
- 将来の high-trust native client extension profile（別途承認された場合）
- memory、policy、audit log の確認

## 開発

この段階では Xcode app target ではなく、client core の Swift package から始めます。

```sh
swift test
```
