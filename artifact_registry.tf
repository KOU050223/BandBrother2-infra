# rails-server / game-server / frontend のイメージをまとめて置く
resource "google_artifact_registry_repository" "images" {
  location      = var.region
  repository_id = "bandbrother2"
  format        = "DOCKER"
  description   = "BandBrother2 container images"

  # 無料枠(0.5GB)に収めるため、各イメージ最新3件だけ残して古いものは消す
  cleanup_policy_dry_run = false

  cleanup_policies {
    id     = "keep-recent"
    action = "KEEP"
    most_recent_versions {
      keep_count = 3
    }
  }

  cleanup_policies {
    id     = "delete-old"
    action = "DELETE"
    condition {
      older_than = "604800s"
    }
  }

  depends_on = [google_project_service.apis]
}
