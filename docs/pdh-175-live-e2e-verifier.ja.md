# PDH-175 Live E2E Evidence (Mac + Secretary)

このワークツリーでは、UI操作までを完全に自動化せず、**ライブ Secretary デーモンを叩く AppModel 検証ハーネス**を追加しています。
実デーモンを起動できる場合、次の 1 連鎖を `ClientAppModel` 経由で検証します。

1. 既存フォルダ選択でローカルプロジェクトを登録
2. `filesystem.search` でジョブを submit
3. 会話に tool output が render 経由で表示されることを確認

## 実行コマンド

```bash
cd /Users/yohaku/atelia-labs/atelia-mac-live-e2e
ATELIA_MAC_LIVE_E2E=1 \
ATELIA_DAEMON_HOST=127.0.0.1 \
ATELIA_DAEMON_PORT=8080 \
ATELIA_DAEMON_AUTH_TOKEN=<secretary token or unset only if daemon auth is disabled> \
ATELIA_E2E_PROJECT_PATH=/Users/yohaku/atelia-labs/atelia-mac-live-e2e \
ATELIA_E2E_COMMAND='search package' \
ATELIA_E2E_MAX_WAIT_MS=30000 \
./Scripts/pdh175-live-secretary-verifier.sh
```

`./Scripts/pdh175-live-secretary-verifier.sh` は実行時に以下を記録します。

- Mac ワークツリー SHA
- atelia-kit SHA（隣接 repo が存在する場合）
- atelia-secretary SHA（隣接 repo が存在する場合）
- 使用デーモン endpoint
- 使用 project path と送信 command
- 使用テスト: `clientAppModelLiveSecretaryFilesystemSearchSmoke` (`AteliaMacClientTests`)
- 実行コマンド（正確な文字列）
- 結果（`swift test` の成功 / 失敗）

## テスト名

- `clientAppModelLiveSecretaryFilesystemSearchSmoke`

## 補足（UI 自動化できない理由）

これは fixture-only coverage より強い検証ですが、認証済みのライブ Secretary
デーモンに対して成功するまでは、単独では最終 MDP evidence ではありません。
daemon が `401` やその他 HTTP error を返した場合、このハーネスは fail closed します。

この環境では、Mac UI を AppKit/SwiftUI の実行体として起動して
会話ビューまで到達させる自動化ハーネスが同時導入されていません（スナップショット UI
フレームワークや macOS UI オートメーション側のラッパー整備が別レーンで進行中）。
そのため、同じ契約フローを忠実に再現する **最短のライブ経路**として
`ClientAppModel` + live HTTP client の検証を採用しています。
