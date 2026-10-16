resource "google_firestore_database" "default" {
  project     = var.project_id
  name        = "(default)"
  location_id = var.firestore_location
  type        = "FIRESTORE_NATIVE"

  # 誤削除防止。terraform destroy してもDBは残す
  delete_protection_state = "DELETE_PROTECTION_ENABLED"
  deletion_policy         = "ABANDON"

  depends_on = [google_firebase_project.default]
}

# 毎日バックアップを取り、7日間保持する
resource "google_firestore_backup_schedule" "daily" {
  project   = var.project_id
  database  = google_firestore_database.default.name
  retention = "604800s"

  daily_recurrence {}
}

resource "google_firebaserules_ruleset" "firestore" {
  project = var.project_id

  source {
    files {
      name    = "firestore.rules"
      content = file("${path.module}/rules/firestore.rules")
    }
  }

  lifecycle {
    create_before_destroy = true
  }

  depends_on = [google_firestore_database.default]
}

resource "google_firebaserules_release" "firestore" {
  project      = var.project_id
  name         = "cloud.firestore"
  ruleset_name = "projects/${var.project_id}/rulesets/${google_firebaserules_ruleset.firestore.name}"

  lifecycle {
    replace_triggered_by = [google_firebaserules_ruleset.firestore]
  }
}
