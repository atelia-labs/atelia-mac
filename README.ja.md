# Atelia Mac

[English README](README.md)

Atelia Mac は、Atelia Secretary beta を操作するための macOS 向けネイティブクライアントです。

このリポジトリは、macOS native な Atelia shell と Surface Protocol Resolver を扱います。windowing、project space、built-in package resolution、presentation hosting、permissions、approvals、audit visibility、extension inspection、platform integration が責務です。Git、review、terminal、browser、documents、calendar、tasks、media などの豊かな product area は、bundled official package または third-party extension package として提供されます。共有ロジックは `atelia-kit` に置きます。

AEP において、Atelia Mac は reference presentation host です。semantic で permission-aware な AEP presentation surface を native Swift component で描画します。任意に download された client UI code の install / execute は行いません。

Atelia Mac の default UI は、extension-provided UI と同じ Surface Protocol によって宣言されなければなりません。既定の Mac 体験は minimal built-in package set であり、native shell はそれを extension package と同じ Surface Protocol で resolve します。extension とは別の特権的な UI layer ではありません。詳しくは [Standard Surfaces](docs/standard-surfaces.ja.md) を参照してください。

## 最初の操作面

beta は Atelia project space で起動します。minimal client baseline は、project selection、project conversation、extension installation / inspection、settings、connection management、permissions、approvals、audit visibility、recovery surfaces を提供します。

日々の作業は、同じ project space に参加する bundled official packages と third-party extension packages によって豊かになります。Git や terminal の体験が Atelia に同梱される場合でも、それは hidden client core ではなく、同じ presentation、context、permission、action model を使う official package として扱います。

## 初期スコープ

- Atelia project space
- Project home surface
- Project conversation
- Minimal project navigation
- Atelia Secretary daemon への接続管理
- permission、approval、audit、recovery の built-in package surface
- extension installation、inspection、disabling、rollback、safe mode
- AEP semantic presentation renderer subset
- settings

## 将来スコープ

- Git、review、terminal、documents、browser、tasks、calendar、notes、media など高価値 workflow の bundled official packages
- third-party package ecosystem
- 将来の host-extension integration profile（platform policy review を前提とする）

## 開発

この段階では Xcode app target ではなく、client core の Swift package から始めます。

```sh
swift test
```
