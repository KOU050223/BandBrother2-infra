output "frontend_url" {
  value = google_cloud_run_v2_service.frontend.uri
}

output "rails_server_url" {
  value = google_cloud_run_v2_service.rails.uri
}

output "game_server_url" {
  value = google_cloud_run_v2_service.game.uri
}

output "image_repository" {
  description = "docker push 先 (例: <これ>/rails-server:latest)"
  value       = "${var.region}-docker.pkg.dev/${var.project_id}/${google_artifact_registry_repository.images.repository_id}"
}

output "run_service_account" {
  description = "gcloud run deploy --service-account に指定する実行用SA"
  value       = google_service_account.run.email
}

# GitHub Actions の google-github-actions/auth に渡す値
output "github_actions_auth" {
  value = {
    workload_identity_provider = google_iam_workload_identity_pool_provider.github.name
    service_account            = google_service_account.deployer.email
  }
}

# フロントの src/firebase.js の firebaseConfig に貼る値（いずれも公開して問題ない値）
output "firebase_web_config" {
  value = {
    apiKey            = data.google_firebase_web_app_config.frontend.api_key
    authDomain        = data.google_firebase_web_app_config.frontend.auth_domain
    projectId         = var.project_id
    storageBucket     = google_storage_bucket.firebase.name
    messagingSenderId = data.google_firebase_web_app_config.frontend.messaging_sender_id
    appId             = google_firebase_web_app.frontend.app_id
    measurementId     = data.google_firebase_web_app_config.frontend.measurement_id
  }
}
