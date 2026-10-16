# Firebase Authentication (Identity Platform)
# フロントはメール/パスワードとGitHubログインを使っている
resource "google_identity_platform_config" "default" {
  project = var.project_id

  authorized_domains = [
    "localhost",
    "${var.project_id}.firebaseapp.com",
    "${var.project_id}.web.app",
    trimprefix(google_cloud_run_v2_service.frontend.uri, "https://"),
  ]

  sign_in {
    allow_duplicate_emails = false

    email {
      enabled           = true
      password_required = true
    }

    # API側が既定で返すため、明示しないと毎回差分が出る
    phone_number {
      enabled = false
    }
  }

  depends_on = [google_firebase_project.default]
}

# GitHubログイン
# GitHub OAuth App の callback URL は https://<project_id>.firebaseapp.com/__/auth/handler
resource "google_identity_platform_default_supported_idp_config" "github" {
  count = var.github_oauth_client_id == "" ? 0 : 1

  project       = var.project_id
  idp_id        = "github.com"
  client_id     = var.github_oauth_client_id
  client_secret = var.github_oauth_client_secret
  enabled       = true

  depends_on = [google_identity_platform_config.default]
}
