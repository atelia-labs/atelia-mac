# Atelia Mac

[English README](README.md)

Atelia Mac は、Atelia Secretary beta を操作するための macOS 向けネイティブクライアントです。

このリポジトリは、macOS 固有の UI、ウィンドウ管理、通知、ファイルアクセス、Git / review interface、terminal、Hook / automation / extension 管理、音声による操作を扱います。共有ロジックは `atelia-kit` に置きます。

AEP において、Atelia Mac は reference presentation host です。semantic で permission-aware な AEP presentation surface を native Swift component で描画します。任意に download された client UI code の install / execute は行いません。

## 最初の操作面

beta は Atelia surface で起動します。Secretary を Mac で操作するための既定の作業面で、project / thread の切り替え、agent task の状態、Git branch / worktree / diff / commit / push / PR 操作、アプリ内ターミナル、review queue、音声操作、接続管理を 1 か所にまとめます。

この最初の操作面は、日々の operator 作業に合わせて設計します。いま進んでいる作業を見失わず、変更内容と review 結果を確認し、client から離れずに次の task へ進めるようにします。browser use、computer use、より詳細な extension 管理は初期 beta の操作面には含めません。

## 初期スコープ

- Atelia surface
- Projects and threads
- 複数 agent 作業の状態表示
- Git review surface
- 自動レビュー結果の表示
- アプリ内ターミナル
- review queue
- 音声による操作
- Hooks, automations, and extensions
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
