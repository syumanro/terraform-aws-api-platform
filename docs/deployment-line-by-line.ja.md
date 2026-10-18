# ビルド・デプロイ設定の行別解説

[中文版本](deployment-line-by-line.md) · [日本語学習ガイド](learning-guide.ja.md)

元のファイルを維持し、元の行番号ごとに役割と理由を説明します。空行は区切り、括弧・インデント・YAML のハイフンは構造を表します。過去の設計意図に裏付けがない場合は、現在の動作と選択の意味を説明します。

## Dockerfile

元ファイル：[Dockerfile](../Dockerfile)

| 行番号 | 元のコード | 役割と設計理由 |
| --- | --- | --- |

| 1 | <code>FROM nginx:1.27-alpine</code> | 役割：Nginx Alpine をベースイメージにします。理由：デモは静的ページなので、比較的小さい Web サーバーのイメージで配信できます。1.27 系列を指定していますが、digest までは固定していません。 |
| 2 | （空行） | 読みやすく区切るための空行です。実行には影響しません。 |
| 3 | <code>COPY app/index.html /usr/share/nginx/html/index.html</code> | 役割：トップページを Nginx の既定サイトディレクトリにコピーします。理由：ページをイメージに含め、イメージとページのバージョンを対応させるためです。 |
| 4 | <code>COPY app/health /usr/share/nginx/html/health</code> | 役割：ヘルスチェック用ファイルをコピーします。理由：/health が固定内容を返し、ビルドテストとコンテナの監視に使えます。静的ファイルの確認で、DB などの依存先は確認しません。 |
| 5 | <code>COPY app/styles.css /usr/share/nginx/html/styles.css</code> | 役割：CSS をコピーします。理由：ページが参照するため、HTML と一緒に含めないとスタイルが欠けます。 |
| 6 | <code>COPY app/momo-hero.png /usr/share/nginx/html/momo-hero.png</code> | 役割：ページの画像をコピーします。理由：コンテナ単独でもページが参照する画像を提供できるようにします。 |
| 7 | （空行） | 読みやすく区切るための空行です。実行には影響しません。 |
| 8 | <code>EXPOSE 80</code> | 役割：コンテナが 80 ポートを使うことを宣言します。理由：利用者へアプリケーションのポートを示します。ホストのポート公開は行わず、docker run または ECS が実際の接続を設定します。 |
| 9 | （空行） | 読みやすく区切るための空行です。実行には影響しません。 |
| 10 | <code>HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \</code> | 役割：30 秒間隔、1 回 3 秒の上限、起動猶予 5 秒、連続失敗 3 回でヘルスチェックします。理由：間隔と再試行で一時的な障害の誤判定を減らします。末尾のバックスラッシュで次の行と同じ命令にします。 |
| 11 | <code>CMD wget --quiet --tries=1 --spider http://127.0.0.1/health &#124;&#124; exit 1</code> | 役割：コンテナ内部から /health にアクセスし、失敗時に終了コード 1 を返します。理由：wget で HTTP の到達性を確認しますが、内容が OK かは確認しません。これは HEALTHCHECK の CMD で、別の起動コマンドではありません。 |

## buildspec.yml

元ファイル：[buildspec.yml](../buildspec.yml)

| 行番号 | 元のコード | 役割と設計理由 |
| --- | --- | --- |

| 1 | <code>version: 0.2</code> | 役割：CodeBuild buildspec 0.2 形式を選びます。理由：同じビルドのシェルコマンドで前に設定した変数や環境を共有し、イメージアドレスを渡せるようにします。 |
| 2 | （空行） | 読みやすく区切るための空行です。実行には影響しません。 |
| 3 | <code>env:</code> | 役割：ビルドの環境設定を始めます。理由：実行ステージとは分けて、シェル環境を定義します。 |
| 4 | <code>shell: bash</code> | 役割：Bash を選びます。理由：後で使うコミット ID の部分文字列、ループ、pipefail は Bash の構文です。 |
| 5 | （空行） | 読みやすく区切るための空行です。実行には影響しません。 |
| 6 | <code>phases:</code> | 役割：ビルドステージの一覧を始めます。理由：準備、ビルド、後処理を分け、失敗した段階を見つけやすくします。 |
| 7 | <code>pre_build:</code> | 役割：ビルド前の準備段階を定義します。理由：先に ECR ログインとイメージタグの決定を済ませます。 |
| 8 | <code>commands:</code> | 役割：現在の段階で実行するコマンド一覧です。理由：YAML の各リスト項目をシェルに渡し、インデントで所属ステージを表します。 |
| 9 | <code>- aws --version</code> | 役割：AWS CLI バージョンを出力します。理由：ログにツールの情報を残し、環境差の調査に使います。 |
| 10 | <code>- aws ecr get-login-password --region "$AWS_DEFAULT_REGION" &#124; docker login --username AWS --password-stdin "$ECR_REGISTRY"</code> | 役割：ECR ログインパスワードを取得して標準入力で Docker に渡します。理由：ソース内の固定パスワードではなく CodeBuild ロールを使います。リージョンと registry の対応が必要です。 |
| 11 | <code>- IMAGE_TAG="${CODEBUILD_RESOLVED_SOURCE_VERSION:0:12}"</code> | 役割：今回のソースバージョンの先頭 12 文字をタグにします。理由：イメージをコミットに関連付けます。短いタグは絶対に一意とは限らず、ECR の不変タグは同じタグの再 push を拒否します。 |
| 12 | <code>- IMAGE_URI="$ECR_REPOSITORY_URI:$IMAGE_TAG"</code> | 役割：リポジトリアドレス:タグ を作ります。理由：build、run、push で同じイメージを使い、テスト対象とアップロード対象がずれるのを防ぎます。 |
| 13 | （空行） | 読みやすく区切るための空行です。実行には影響しません。 |
| 14 | <code>build:</code> | 役割：ビルド・テスト段階を始めます。理由：テスト成功後にだけアップロードを許可するマーカーを作ります。 |
| 15 | <code>commands:</code> | 役割：このステージのコマンド一覧です。理由：リスト項目を順にシェルへ渡し、インデントで所属を決めます。 |
| 16 | <code>- docker build --tag "$IMAGE_URI" .</code> | 役割：現在のディレクトリの Dockerfile からイメージを作り、URI でタグ付けします。理由：コード、静的ファイル、健康確認ファイルを今回のイメージへまとめます。 |
| 17 | <code>- docker run --detach --name test-app --publish 8080:80 "$IMAGE_URI"</code> | 役割：作成したイメージをバックグラウンド実行し、ビルド環境の 8080 をコンテナの 80 に接続します。理由：コンテナ外から HTTP を確認し、固定名で最後に削除しやすくします。 |
| 18 | <code>- &#124;</code> | 役割：以下の複数行を 1 つの YAML リテラルブロックにします。理由：ループと条件分岐を同じ Bash スクリプト内で実行する必要があります。 |
| 19 | <code>set -o pipefail</code> | 役割：パイプ内のいずれかのコマンドの失敗を、全体の終了コードにも反映します。理由：curl の失敗が末尾コマンドの結果に隠れないようにします。 |
| 20 | <code>for i in {1..10}; do</code> | 役割：最大 10 回試します。理由：起動の待ち時間を許容しつつ、即時の誤判定や無限待機を避けます。 |
| 21 | <code>if curl --fail --silent http://127.0.0.1:8080/health &#124; grep --quiet '^OK$'; then</code> | 役割：テストコンテナの /health に要求し、応答に OK だけの行があるか確認します。理由：HTTP 成功と期待内容を両方確認し、if はパイプの終了コードで判断します。 |
| 22 | <code>echo "Health check passed"</code> | 役割：ヘルスチェック成功を表示します。理由：ログにテスト結果を明確に残します。 |
| 23 | <code>break</code> | 役割：再試行ループを抜けます。理由：一度成功したら、残りの試行を待たず先へ進みます。 |
| 24 | <code>fi</code> | 役割：現在の if を閉じます。理由：Bash の if と fi を対応させ、成功側と失敗側の範囲を正しくします。 |
| 25 | <code>if [ "$i" -eq 10 ]; then</code> | 役割：最後の試行かを判断します。理由：上限に達した場合だけ最終失敗とし、それ以前の失敗は再試行します。 |
| 26 | <code>echo "Health check failed"</code> | 役割：最終失敗を表示します。理由：ログから停止理由を確認できるようにします。 |
| 27 | <code>exit 1</code> | 役割：非ゼロの終了コードでスクリプトを止めます。理由：CodeBuild にテスト失敗を伝え、失敗イメージを検証済みとして扱わないためです。 |
| 28 | <code>fi</code> | 役割：if の分岐を閉じます。理由：Bash の条件分岐の範囲を明確にします。 |
| 29 | <code>sleep 2</code> | 役割：失敗後に 2 秒待ちます。理由：起動時間を確保し、要求を連発しないためです。curl の要求時間もかかり、単発タイムアウトは未設定なので、合計が正確に 20 秒以内になるわけではありません。 |
| 30 | <code>done</code> | 役割：for ループを閉じます。理由：成功マーカーの作成はループの外で、ループが正常に終わった後に行います。 |
| 31 | <code>- touch /tmp/health-check-passed</code> | 役割：テスト成功マーカーを作ります。理由：post_build でファイルの存在を確認できます。最後の試行が失敗すれば exit 1 によりこの行へ進みません。 |
| 32 | （空行） | 読みやすく区切るための空行です。実行には影響しません。 |
| 33 | <code>finally:</code> | 役割：ステージの後片付けを定義します。理由：テストが失敗してもテストコンテナを削除する必要があります。 |
| 34 | <code>- docker rm --force test-app &#124;&#124; true</code> | 役割：テストコンテナを強制削除し、削除失敗時も true で成功終了にします。理由：コンテナ未作成などの片付けエラーで元のテスト失敗を上書きしないためです。 |
| 35 | （空行） | 読みやすく区切るための空行です。実行には影響しません。 |
| 36 | <code>post_build:</code> | 役割：イメージ送信と成果物生成の段階です。理由：ここでも成功マーカーを明示的に確認し、前段失敗後の push を避けます。 |
| 37 | <code>commands:</code> | 役割：このステージのコマンド一覧です。理由：成功確認、push、成果物生成を順に実行します。 |
| 38 | <code>- test -f /tmp/health-check-passed</code> | 役割：成功マーカーがファイルとして存在するか確認します。理由：なければコマンドが失敗し、アップロード前のテスト通過条件にします。 |
| 39 | <code>- docker push "$IMAGE_URI"</code> | 役割：テスト済みイメージを ECR に push します。理由：Fargate はビルド端末ではなくイメージリポジトリから取得します。 |
| 40 | <code>- printf '{"ImageURI":"%s"}' "$IMAGE_URI" &gt; imageDetail.json</code> | 役割：ImageURI を含む JSON を出力します。理由：CodePipeline の ECS Blue/Green アクションが実 URI を読み、タスクテンプレートのプレースホルダーを置き換えます。 |
| 41 | （空行） | 読みやすく区切るための空行です。実行には影響しません。 |
| 42 | <code>artifacts:</code> | 役割：CodeBuild がパイプラインへ渡すファイル成果物を定義します。理由：イメージは ECR、テンプレートとイメージアドレスは成果物として渡します。 |
| 43 | <code>files:</code> | 役割：成果物に含めるファイル一覧です。理由：後続の Deploy が読めるファイルを明示します。 |
| 44 | <code>- appspec.yaml</code> | 役割：CodeDeploy の説明ファイルを成果物へ追加します。理由：対象コンテナのポートと新タスク定義を伝えます。 |
| 45 | <code>- taskdef.json</code> | 役割：ECS タスク定義テンプレートを追加します。理由：Deploy がイメージのプレースホルダーを置換して新リビジョンを登録します。 |
| 46 | <code>- imageDetail.json</code> | 役割：今回のイメージ URI ファイルを追加します。理由：テスト済み・push 済みのイメージをデプロイへ正確に渡します。 |

## appspec.yaml

元ファイル：[appspec.yaml](../appspec.yaml)

| 行番号 | 元のコード | 役割と設計理由 |
| --- | --- | --- |

| 1 | <code>version: 0.0</code> | 役割：CodeDeploy AppSpec の形式バージョンです。理由：buildspec の 0.2 やアプリケーションの公開バージョンとは別です。 |
| 2 | <code>Resources:</code> | 役割：デプロイ対象リソースの一覧を始めます。理由：AppSpec 独自の大文字・小文字と構造を使い、buildspec とは区別します。 |
| 3 | <code>- TargetService:</code> | 役割：今回更新する ECS 対象サービスを宣言します。理由：タスク定義と負荷分散用のコンテナ情報をまとめます。 |
| 4 | <code>Type: AWS::ECS::Service</code> | 役割：対象を ECS サービスとします。理由：EC2 へのファイル配置ではなく ECS のデプロイフローを使わせます。 |
| 5 | <code>Properties:</code> | 役割：サービスのデプロイ属性を始めます。理由：タスク定義、ポート、プラットフォームを同じ対象の下に置きます。 |
| 6 | <code>TaskDefinition: &lt;TASK_DEFINITION&gt;</code> | 役割：タスク定義 ARN のプレースホルダーです。理由：新しいリビジョンの登録後に ARN が決まるため、古い ARN を固定記述しません。 |
| 7 | <code>LoadBalancerInfo:</code> | 役割：対象コンテナとポートを定義します。理由：CodeDeploy が新タスクセットのどのコンテナへ転送するかを知る必要があります。 |
| 8 | <code>ContainerName: zhu-prd-container-test2</code> | 役割：ターゲットグループへ登録するコンテナ名です。理由：taskdef.json の name と完全一致しないと対象を識別できません。 |
| 9 | <code>ContainerPort: 80</code> | 役割：コンテナの 80 ポートへ流量を送ります。理由：Nginx、ECS ポートマッピング、ALB ターゲットグループと一致させます。 |
| 10 | <code>PlatformVersion: 1.4.0</code> | 役割：Fargate のデプロイプラットフォームを 1.4.0 に固定します。理由：実行環境を明確にし、更新時は Terraform の初期サービス設定も合わせて確認します。 |

## taskdef.json

元ファイル：[taskdef.json](../taskdef.json)

| 行番号 | 元のコード | 役割と設計理由 |
| --- | --- | --- |

| 1 | <code>{</code> | JSON オブジェクトを始めます。項目はキーと値で表し、入れ子のオブジェクトはコンテナやポートマッピングを定義します。 |
| 2 | <code>"family": "zhu-prd-ecs-test2",</code> | タスク定義の各リビジョンを同じ family に属させ、同一アプリケーションの公開バージョンをまとめます。 |
| 3 | <code>"executionRoleArn": "arn:aws:iam::043300555595:role/zhu-prd-ecs-task-execution-role",</code> | 既存の実行ロールを指定し、ECS のイメージ取得とログ送信に使います。アプリケーションが AWS API を呼ぶロールとは異なります。 |
| 4 | <code>"taskRoleArn": "arn:aws:iam::043300555595:role/zhu-prd-ecs-task-role",</code> | アプリケーション用タスクロールを指定し、実行中コンテナに AWS API 権限を提供します。事前作成と最小限の権限設定が必要です。 |
| 5 | <code>"networkMode": "awsvpc",</code> | awsvpc を使い、タスクに独立したネットワークインターフェースと IP を付け、タスクのセキュリティグループで制限します。 |
| 6 | <code>"requiresCompatibilities": ["FARGATE"],</code> | FARGATE 互換を要求し、自分で管理する EC2 ホストに依存しない実行方式にします。 |
| 7 | <code>"cpu": "256",</code> | 256 CPU 単位を設定します。タスクレベルでは 0.25 vCPU、コンテナレベルではそのコンテナの CPU 配分です。初期値なので実負荷で検証します。 |
| 8 | <code>"memory": "512",</code> | タスク全体に 512 MiB を割り当て、CPU と合わせて Fargate のリソース仕様を決めます。 |
| 9 | <code>"runtimePlatform": {</code> | 実行プラットフォームのオブジェクトを始め、イメージが必要とする OS と CPU アーキテクチャを明示します。 |
| 10 | <code>"operatingSystemFamily": "LINUX",</code> | Linux を選び、Nginx Alpine イメージに合わせます。 |
| 11 | <code>"cpuArchitecture": "X86_64"</code> | X86_64 を選びます。ビルドしたイメージも同じアーキテクチャが必要で、ARM のみに対応するイメージはそのまま使えません。 |
| 12 | <code>},</code> | 現在の JSON オブジェクトを閉じます。カンマで次の項目を区切り、最後の項目の後には余分なカンマを付けません。 |
| 13 | <code>"containerDefinitions": [</code> | コンテナ定義のリストです。1 タスクに複数コンテナを入れられますが、現在は 1 つだけです。 |
| 14 | <code>{</code> | コンテナを表す JSON オブジェクトを始め、名前、イメージ、リソースを同じコンテナの設定としてまとめます。 |
| 15 | <code>"name": "zhu-prd-container-test2",</code> | コンテナ名を指定します。AppSpec の ContainerName と ECS サービスの関連付け名に一致させます。 |
| 16 | <code>"image": "&lt;IMAGE1_NAME&gt;",</code> | `<IMAGE1_NAME>` を残し、パイプラインが imageDetail.json の ECR URI に置換します。この文字列自体は取得可能なイメージではありません。 |
| 17 | <code>"essential": true,</code> | 必須コンテナにします。終了するとタスク全体の正常稼働に影響します。 |
| 18 | <code>"cpu": 256,</code> | コンテナの CPU を 256 単位にします。タスクレベルの CPU 仕様とは設定の階層が異なり、実負荷で妥当性を確認します。 |
| 19 | <code>"memoryReservation": 512,</code> | コンテナに 512 MiB をソフト予約します。タスクレベルの memory は別途タスク全体のメモリを定めます。 |
| 20 | <code>"portMappings": [</code> | ポートマッピングのリストを始め、ECS と負荷分散がコンテナ入口を識別できるようにします。 |
| 21 | <code>{</code> | 1 件のポートマッピングオブジェクトを始め、内部ポート、ホスト側ポート、プロトコルをまとめます。 |
| 22 | <code>"containerPort": 80,</code> | コンテナの 80 ポートを指定し、Nginx の待受ポートに合わせます。 |
| 23 | <code>"hostPort": 80,</code> | ホスト側も 80 にし、awsvpc モードのポートマッピングに合わせます。 |
| 24 | <code>"protocol": "tcp"</code> | HTTP 通信のトランスポートとして TCP を選びます。 |
| 25 | <code>}</code> | ポートマッピングのオブジェクトを閉じます。最後の要素の後に余分なカンマは付けません。 |
| 26 | <code>],</code> | ポートマッピングのリストを閉じ、カンマで次のコンテナ属性を区切ります。 |
| 27 | <code>"logConfiguration": {</code> | ログ設定を始め、出力をタスク内だけに残さず集中ログへ送ります。 |
| 28 | <code>"logDriver": "awslogs",</code> | awslogs を使い CloudWatch にログを送り、タスク終了後も問題を調査できるようにします。 |
| 29 | <code>"options": {</code> | ログドライバーのオプションを始め、ロググループ、リージョン、ストリームの接頭辞を指定します。 |
| 30 | <code>"awslogs-group": "/ecs/zhu-prd-ecs-test2",</code> | ECS モジュールで作るロググループ名を指定します。名前が一致しても、IAM 権限やネットワーク経路が満たされている証明にはなりません。 |
| 31 | <code>"awslogs-region": "ap-northeast-1",</code> | ログを東京リージョンに送り、現在の ECS 環境に合わせます。 |
| 32 | <code>"awslogs-stream-prefix": "ecs"</code> | ecs を接頭辞にし、コンテナ名とタスク ID で各タスクのログを区別します。 |
| 33 | <code>}</code> | ログドライバーの options オブジェクトを閉じます。 |
| 34 | <code>}</code> | logConfiguration オブジェクトを閉じます。 |
| 35 | <code>}</code> | このコンテナの定義オブジェクトを閉じます。 |
| 36 | <code>]</code> | containerDefinitions のリストを閉じます。現在は 1 コンテナだけを定義しています。 |
| 37 | <code>}</code> | タスク定義全体の JSON オブジェクトを閉じます。 |

## common/prd_test2/prd.tfvars.example

元ファイル：[common/prd_test2/prd.tfvars.example](../common/prd_test2/prd.tfvars.example)

| 行番号 | 元のコード | 役割と設計理由 |
| --- | --- | --- |

| 1 | <code># 環境固有の値を入力してから prd.tfvars として保存する。</code> | 実環境の値を入力して prd.tfvars として保存する説明です。example はそのまま使えるネットワーク設計ではありません。 |
| 2 | <code>ecs_a_subnet_cidr        = "10.x.x.x/24"</code> | 1 つ目の ECS サブネット CIDR を入力します。10.x.x.x/24 は仮の文字列なので、既存 VPC 内の有効で重複しない範囲に置き換えます。 |
| 3 | <code>ecs_c_subnet_cidr        = "10.x.x.x/24"</code> | 2 つ目の ECS サブネット CIDR を入力します。1 つ目とは異なり、VPC 内に収まる範囲が必要です。 |
| 4 | <code>github_repository = "syumanro/terraform-aws-api-platform"</code> | GitHub リポジトリを指定し、パイプラインの Source アクションの取得先にします。 |
| 5 | <code>github_branch     = "main"</code> | main を変更監視ブランチにし、このブランチの変更でビルドとデプロイを起動します。 |
| 6 | （空行） | 読みやすく区切るための空行です。実行には影響しません。 |
| 7 | <code># 既存接続を再利用する場合のみ指定する。未指定なら Terraform が接続を作成する。</code> | 既存接続の再利用を説明します。未指定時は Terraform が新規作成しますが、コンソールで GitHub 認証を完了する必要があります。 |
| 8 | <code># github_connection_arn = "arn:aws:codeconnections:ap-northeast-1:123456789012:connection/xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"</code> | 接続 ARN の記述例です。# コメントなので実行されず、サンプルのアカウント ID と UUID は実際の値に置き換えます。 |

## scripts/preview.ps1

元ファイル：[scripts/preview.ps1](../scripts/preview.ps1)

| 行番号 | 元のコード | 役割と設計理由 |
| --- | --- | --- |

| 1 | <code>$ErrorActionPreference = "Stop"</code> | エラー時にスクリプトを停止し、ファイル読み取りなどが失敗した後に不完全な応答を続けないようにします。 |
| 2 | <code>$root = [System.IO.Path]::GetFullPath((Join-Path $PSScriptRoot "..\app"))</code> | スクリプトの場所から app の絶対パスを求め、別の作業ディレクトリから起動しても静的ファイルを見つけられるようにします。 |
| 3 | <code>$listener = [System.Net.HttpListener]::new()</code> | .NET の HTTP リスナーを作り、イメージをビルドせずにローカルプレビューを提供します。 |
| 4 | <code>$listener.Prefixes.Add("http://localhost:8080/")</code> | localhost:8080 を登録し、端末内のブラウザーからプレビューします。Docker のポートマッピングとは別の方法です。 |
| 5 | <code>$listener.Start()</code> | リスナーを開始し、ブラウザーの要求を待てるようにします。 |
| 6 | <code>Write-Host "Preview: http://localhost:8080/"</code> | プレビュー URL を表示し、開くアドレスを利用者へ伝えます。 |
| 7 | （空行） | 読みやすく区切るための空行です。実行には影響しません。 |
| 8 | <code>$contentTypes = @{</code> | 拡張子と MIME タイプの対応表を始め、ブラウザーがテキストリソースを正しい形式で解釈できるようにします。 |
| 9 | <code>".html" = "text/html; charset=utf-8"</code> | HTML に text/html と UTF-8 を指定し、ページの文字を正しく表示します。 |
| 10 | <code>".css"  = "text/css; charset=utf-8"</code> | CSS に text/css と UTF-8 を指定し、スタイルシートとして解釈させます。 |
| 11 | <code>".js"   = "application/javascript; charset=utf-8"</code> | JavaScript の MIME タイプと UTF-8 を指定し、後でスクリプトを追加した場合に使えるようにします。 |
| 12 | <code>}</code> | MIME 対応表を閉じます。画像と拡張子のない健康確認ファイルのタイプは、この表で明示していません。 |
| 13 | （空行） | 読みやすく区切るための空行です。実行には影響しません。 |
| 14 | <code>try {</code> | try を始め、finally と組み合わせて終了時にリスナーを止めます。 |
| 15 | <code>while ($listener.IsListening) {</code> | リスナー稼働中に要求を繰り返し処理します。単純な逐次処理のプレビューで、本番 Web サーバーではありません。 |
| 16 | <code>$context = $listener.GetContext()</code> | 次の要求を待ち、今回の要求と応答を扱うコンテキストを取得します。 |
| 17 | <code>$relativePath = $context.Request.Url.AbsolutePath.TrimStart("/")</code> | URL のパスから先頭の / を取り除き、相対ファイルパスにします。 |
| 18 | <code>if ([string]::IsNullOrWhiteSpace($relativePath)) { $relativePath = "index.html" }</code> | ルートパスへのアクセスには index.html を使い、既定のトップページを提供します。 |
| 19 | <code>$filePath = [System.IO.Path]::GetFullPath((Join-Path $root $relativePath))</code> | 相対パスを完全パスに変換し、ディスク上のファイルを特定します。 |
| 20 | （空行） | 読みやすく区切るための空行です。実行には影響しません。 |
| 21 | <code>if ($filePath.StartsWith($root) -and [System.IO.File]::Exists($filePath)) {</code> | パスが app のパスで始まり、ファイルが存在するか確認します。サイト内に制限する意図ですが、文字列の前方一致だけではディレクトリ境界を判定できず、本番の安全な検証としてそのまま使わないでください。 |
| 22 | <code>$bytes = [System.IO.File]::ReadAllBytes($filePath)</code> | ファイル全体をバイト配列で読み、HTML、CSS、画像をそのまま出力できるようにします。 |
| 23 | <code>$extension = [System.IO.Path]::GetExtension($filePath)</code> | 拡張子を取得し、応答の MIME タイプを選ぶために使います。 |
| 24 | <code>$context.Response.ContentType = $contentTypes[$extension]</code> | 対応表から Content-Type を設定します。表にない拡張子には対応するタイプ指定がありません。 |
| 25 | <code>$context.Response.StatusCode = 200</code> | HTTP 200 を返し、ファイル要求が成功したことを示します。 |
| 26 | <code>$context.Response.OutputStream.Write($bytes, 0, $bytes.Length)</code> | バイト列を応答ストリームへ書き、ブラウザーへファイル内容を送ります。 |
| 27 | <code>} else {</code> | ファイルがない、またはパス確認に通らない場合の分岐です。 |
| 28 | <code>$context.Response.StatusCode = 404</code> | HTTP 404 を返し、リソースが見つからないことを示します。 |
| 29 | <code>}</code> | ファイルを読み取れるかの条件分岐を閉じます。 |
| 30 | <code>$context.Response.Close()</code> | 今回の応答を閉じ、ブラウザーへ送信完了を伝えます。 |
| 31 | <code>}</code> | ループ本体を閉じ、次の要求を処理します。 |
| 32 | <code>} finally {</code> | try を閉じて finally に入り、例外終了時も後片付けを行います。 |
| 33 | <code>$listener.Stop()</code> | リスナーを停止し、ローカルの待受リソースを解放します。 |
| 34 | <code>}</code> | finally を閉じ、スクリプトの待受ライフサイクルを終了します。 |
