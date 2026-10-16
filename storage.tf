# Firebase Storage（譜面エディタの音楽ファイルなど）
resource "google_storage_bucket" "firebase" {
  name                        = "${var.project_id}-storage"
  location                    = var.region
  uniform_bucket_level_access = true

  cors {
    origin = [
      "http://localhost:5173",
      "http://127.0.0.1:5173",
      google_cloud_run_v2_service.frontend.uri,
      "https://${var.custom_domain}",
    ]
    method = ["GET", "POST", "PUT", "DELETE", "HEAD", "OPTIONS"]
    response_header = [
      "Content-Type",
      "Authorization",
      "Content-Length",
      "User-Agent",
      "X-Requested-With",
      "x-goog-resumable",
      "x-goog-upload-url",
      "x-goog-upload-protocol",
      "x-goog-upload-status",
      "x-goog-upload-size-received",
      "x-goog-upload-command",
    ]
    max_age_seconds = 3600
  }

  depends_on = [google_project_service.apis]
}

resource "google_firebase_storage_bucket" "default" {
  provider  = google-beta
  project   = var.project_id
  bucket_id = google_storage_bucket.firebase.name

  depends_on = [google_firebase_project.default]
}

resource "google_firebaserules_ruleset" "storage" {
  project = var.project_id

  source {
    files {
      name    = "storage.rules"
      content = file("${path.module}/rules/storage.rules")
    }
  }

  lifecycle {
    create_before_destroy = true
  }

  depends_on = [google_firebase_storage_bucket.default]
}

resource "google_firebaserules_release" "storage" {
  project      = var.project_id
  name         = "firebase.storage/${google_storage_bucket.firebase.name}"
  ruleset_name = "projects/${var.project_id}/rulesets/${google_firebaserules_ruleset.storage.name}"

  lifecycle {
    replace_triggered_by = [google_firebaserules_ruleset.storage]
  }
}
