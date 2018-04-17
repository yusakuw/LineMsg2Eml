# LineMsg2Eml

暗号化されていないiOSのバックアップからLINE関連のファイルを抜き出し、Eメール形式(.eml)で出力します。
出力ファイルを確認の上、Gmail等にアップロードして横断検索等することを意図しています。

## 動作確認環境
- Ruby 2.5.1
- iOS 11
- macOS High Sierra
- iTunes 12.6.3.6
- LINE for iOS 8.4.1

## 制約
- 仕様が公開されていないため、本来の仕様とは異なるものや仕様から漏れているものが存在する可能性があります。自分自身のバックアップでの解析・動作検証のみ行っています。
- スタンプ画像や外部サーバに設置された画像は取り込み対象となるため、インターネット接続が必要です。
- 受信をしていない画像・添付ファイルなど、iPhoneローカルに保存されていないリソースは取り込み対象となりません。
- 動画の取り込みはサムネイルのみとなっています。
- ノート機能やアルバム機能には対応していません。
