# Atelia Mac

[English README](README.md)

Atelia Mac は、Atelia Secretary を通じて user-owned Atelia harness を操作するための macOS 向けネイティブクライアントです。ここでいう harness は、ユーザー自身の workspace にある packages、surfaces、workflows、agents、brokered actions のまとまりです。

このリポジトリは、macOS native な Atelia shell と Surface Protocol Resolver を扱います。windowing、project space、built-in package resolution、presentation hosting、permissions、approvals、audit visibility、package inspection、platform integration が責務です。documents、browser、tasks、calendar、notes、media、GitHub、review、terminal、automations などの豊かな product area は、`bundled-official`、`verified-registry`、`user-selected` packages として提供されます。共有ロジックは `atelia-kit` に置きます。

AEP において、Atelia Mac は reference presentation host です。semantic で permission-aware な AEP presentation surface を native Swift component で描画します。Secretary は実行せず、executable package code を install せず、package-supplied web runtime UI を load せず、platform API access を package に提供しません。

Atelia Mac の default UI は、package-provided UI と同じ Surface Protocol によって宣言されなければなりません。既定の Mac 体験は minimal built-in package set であり、native shell はそれを他の package と同じ Surface Protocol で resolve します。package とは別の特権的な UI layer ではありません。詳しくは [Standard Surfaces](docs/standard-surfaces.ja.md) を参照してください。

## 最初の操作面

beta は Atelia project space で起動します。minimal client baseline は、project selection、project conversation、package installation / inspection、settings、connection management、permissions、approvals、audit visibility、recovery surfaces を提供します。

日々の作業は、同じ project space に参加する `bundled-official`、`verified-registry`、`user-selected` packages によって豊かになります。Git や terminal の体験が Atelia に同梱される場合でも、hidden client core ではなく、同じ presentation、context、permission、action model を使わなければなりません。

## 初期スコープ

- Atelia project space (`project-space`)
- Project home surface (`project-home`)
- Project conversation (`project-conversation`)
- Project selection and onboarding (`project-selection-onboarding`)
- Minimal project navigation (`project-navigation`)
- Atelia Secretary daemon への接続管理 (`secretary-connection`)
- permission、approval、audit、recovery の built-in package surfaces (`permission-recovery`)
- package installation、inspection、disabling、rollback、safe mode (`package-management`)
- AEP semantic presentation renderer subset (`presentation-renderer`)
- Settings (`settings`)

## 将来スコープ

- documents、browser、tasks、calendar、notes、media、GitHub、review、terminal、automations など高価値 workflow の `bundled-official` packages
- package install、inspect、validate、remix、GitHub-backed publication flow
- registry search と trust-index review surface

## 開発

このリポジトリは現在、共有 `AteliaMacCore` library と
`AteliaMacClient` executable を含む Swift package として build します。

```sh
swift build
swift test
```

bootstrap client executable を build して起動するには、次を実行します。

```sh
script/run_client_app.sh
```
