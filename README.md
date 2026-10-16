# BandBrother2-infra

BandBrother2 の GCP / Firebase インフラ（Terraform）。
すべて `bandbrother2` プロジェクトに構築する。

| ファイル | 内容 |
|---|---|
| `apis.tf` | 必要なAPIの有効化（destroyしても無効化しない） |
| `firebase.tf` | Firebase の追加・Webアプリ登録 |
| `auth.tf` | Firebase Auth（メール/パスワード、GitHub） |
| `firestore.tf` | Firestore（削除保護・日次バックアップ・ルール） |
| `storage.tf` | Firebase Storage（バケット・CORS・ルール） |
| `artifact_registry.tf` | コンテナイメージ置き場 |
| `cloud_run.tf` | rails-server / game-server / frontend |
| `pubsub.tf` | マッチング用 Pub/Sub |
| `iam.tf` | 実行用SA、GitHub Actions 用 Workload Identity Federation |
| `secrets.tf` | Rails master key (Secret Manager) |
| `rules/` | Firestore / Storage のセキュリティルール |

## 使い方

```bash
gcloud auth application-default login
cp terraform.tfvars.example terraform.tfvars   # 値を埋める
terraform init
terraform plan
terraform apply
```

state は今のところローカル（`terraform.tfstate`、git管理外）。

## アプリのデプロイ

Cloud Run は Terraform が placeholder イメージで作成し、イメージの更新は各アプリのリポジトリが行う（Terraform はイメージの変更を無視する）。

```bash
REPO=$(terraform output -raw image_repository)
SA=$(terraform output -raw run_service_account)

docker buildx build --platform linux/amd64 -t $REPO/rails-server:latest --push .
gcloud run deploy rails-server --image $REPO/rails-server:latest \
  --region asia-northeast1 --service-account $SA
```

GitHub Actions からは `terraform output github_actions_auth` の値を
[`google-github-actions/auth`](https://github.com/google-github-actions/auth) に渡す（サービスアカウントキー不要）。

## フロントの Firebase 設定

```bash
terraform output firebase_web_config
```

の値を `BandBrother2-Frontend/src/firebase.js` の `firebaseConfig` に貼る。

## 注意

- `rules/` のルールは旧プロジェクト（`bandbrother2-2764c`）から移したもので、**誰でも読み書きできる**設定になっている。要見直し。
- Firestore のロケーションは作成後に変更できない。

## 独自ドメイン (bandbrother2.uomi.dev)

`uomi.dev` は Cloudflare で管理している。Cloud Run は Host ヘッダでサービスを判別するため単純な CNAME では届かないので、
Cloudflare Worker `bandbrother2-frontend-proxy` を `bandbrother2.uomi.dev` の Custom Domain に設定し、
`frontend-ugx7tb3anq-an.a.run.app` に中継している（Cloudflare 側は Terraform 管理外）。

Worker の中身はホスト名を書き換えて `fetch` し直すだけ。Cloud Run の URL が変わったら Worker の `ORIGIN` も直すこと。
