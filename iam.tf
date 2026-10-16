# ==================================================
# Cloud Run 実行用サービスアカウント
# ==================================================
resource "google_service_account" "run" {
  account_id   = "bandbrother2-run"
  display_name = "BandBrother2 Cloud Run runtime"

  depends_on = [google_project_service.apis]
}

resource "google_project_iam_member" "run" {
  for_each = toset([
    "roles/datastore.user",
    "roles/pubsub.publisher",
    "roles/pubsub.subscriber",
    "roles/logging.logWriter",
  ])

  project = var.project_id
  role    = each.value
  member  = google_service_account.run.member
}

# ==================================================
# GitHub Actions からのデプロイ用 (Workload Identity Federation)
# サービスアカウントキーを発行せずにデプロイできるようにする
# ==================================================
resource "google_service_account" "deployer" {
  account_id   = "github-deployer"
  display_name = "GitHub Actions deployer"

  depends_on = [google_project_service.apis]
}

resource "google_project_iam_member" "deployer" {
  for_each = toset([
    "roles/run.developer",
    "roles/artifactregistry.writer",
  ])

  project = var.project_id
  role    = each.value
  member  = google_service_account.deployer.member
}

# デプロイ時に実行用SAを指定できるようにする
resource "google_service_account_iam_member" "deployer_act_as_run" {
  service_account_id = google_service_account.run.name
  role               = "roles/iam.serviceAccountUser"
  member             = google_service_account.deployer.member
}

resource "google_iam_workload_identity_pool" "github" {
  workload_identity_pool_id = "github"
  display_name              = "GitHub Actions"

  depends_on = [google_project_service.apis]
}

resource "google_iam_workload_identity_pool_provider" "github" {
  workload_identity_pool_id          = google_iam_workload_identity_pool.github.workload_identity_pool_id
  workload_identity_pool_provider_id = "github-actions"
  display_name                       = "GitHub Actions OIDC"

  attribute_mapping = {
    "google.subject"       = "assertion.sub"
    "attribute.repository" = "assertion.repository"
  }

  # 許可したリポジトリ以外からのトークンは受け付けない
  attribute_condition = "assertion.repository in [${join(", ", [for r in var.github_repositories : "'${r}'"])}]"

  oidc {
    issuer_uri = "https://token.actions.githubusercontent.com"
  }
}

resource "google_service_account_iam_member" "deployer_wif" {
  for_each = toset(var.github_repositories)

  service_account_id = google_service_account.deployer.name
  role               = "roles/iam.workloadIdentityUser"
  member             = "principalSet://iam.googleapis.com/${google_iam_workload_identity_pool.github.name}/attribute.repository/${each.value}"
}
