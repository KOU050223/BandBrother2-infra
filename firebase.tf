# GCPプロジェクトにFirebaseを追加し、フロントエンド用のWebアプリを登録する
resource "google_firebase_project" "default" {
  provider = google-beta
  project  = var.project_id

  depends_on = [google_project_service.apis]
}

resource "google_firebase_web_app" "frontend" {
  provider     = google-beta
  project      = var.project_id
  display_name = "BandBrother2 Frontend"

  depends_on = [google_firebase_project.default]
}

# フロントの firebaseConfig に貼る値（outputs.tf で出力）
data "google_firebase_web_app_config" "frontend" {
  provider   = google-beta
  project    = var.project_id
  web_app_id = google_firebase_web_app.frontend.app_id
}
