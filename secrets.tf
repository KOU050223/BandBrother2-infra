resource "google_secret_manager_secret" "rails_master_key" {
  secret_id = "rails-master-key"

  replication {
    auto {}
  }

  depends_on = [google_project_service.apis]
}

resource "google_secret_manager_secret_version" "rails_master_key" {
  secret      = google_secret_manager_secret.rails_master_key.id
  secret_data = var.rails_master_key
}

resource "google_secret_manager_secret_iam_member" "run_rails_master_key" {
  secret_id = google_secret_manager_secret.rails_master_key.id
  role      = "roles/secretmanager.secretAccessor"
  member    = google_service_account.run.member
}
