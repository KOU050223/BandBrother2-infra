# Cloud Run サービス
#
# イメージは各アプリのリポジトリの GitHub Actions がデプロイする。
# Terraform は初回だけ placeholder イメージで作成し、以降のイメージ変更は無視する。
locals {
  placeholder_image = "us-docker.pkg.dev/cloudrun/container/hello"
}

# ==================================================
# Rails API
# ==================================================
resource "google_cloud_run_v2_service" "rails" {
  name                = "rails-server"
  location            = var.region
  ingress             = "INGRESS_TRAFFIC_ALL"
  deletion_protection = false

  template {
    service_account                  = google_service_account.run.email
    max_instance_request_concurrency = var.container_concurrency
    timeout                          = "300s"

    scaling {
      min_instance_count = var.cloud_run_min_instances
      max_instance_count = var.cloud_run_max_instances
    }

    containers {
      image = local.placeholder_image

      ports {
        container_port = 8080
      }

      resources {
        limits = {
          cpu    = var.cloud_run_cpu
          memory = var.cloud_run_memory
        }
        cpu_idle = true
      }

      env {
        name  = "RAILS_ENV"
        value = "production"
      }
      env {
        name = "RAILS_MASTER_KEY"
        value_source {
          secret_key_ref {
            secret  = google_secret_manager_secret.rails_master_key.secret_id
            version = "latest"
          }
        }
      }
      env {
        name  = "RAILS_LOG_LEVEL"
        value = "info"
      }
      env {
        name  = "RAILS_MAX_THREADS"
        value = "5"
      }
      env {
        name  = "JOB_CONCURRENCY"
        value = "1"
      }
      env {
        name  = "GOOGLE_CLOUD_PROJECT"
        value = var.project_id
      }
      env {
        name  = "MATCHING_QUEUE_TOPIC"
        value = google_pubsub_topic.matching_queue.name
      }
      env {
        name  = "MATCH_RESULTS_TOPIC"
        value = google_pubsub_topic.match_results.name
      }
      env {
        name  = "ROOM_EVENTS_TOPIC"
        value = google_pubsub_topic.room_events.name
      }
    }
  }

  lifecycle {
    ignore_changes = [
      template[0].containers[0].image,
      client,
      client_version,
    ]
  }

  depends_on = [
    google_project_service.apis,
    google_secret_manager_secret_iam_member.run_rails_master_key,
    google_secret_manager_secret_version.rails_master_key,
  ]
}

# ==================================================
# Go WebSocket サーバー
# ==================================================
resource "google_cloud_run_v2_service" "game" {
  name                = "game-server"
  location            = var.region
  ingress             = "INGRESS_TRAFFIC_ALL"
  deletion_protection = false

  template {
    service_account                  = google_service_account.run.email
    max_instance_request_concurrency = var.container_concurrency
    # WebSocket接続はこの時間で切れるため最大値(60分)にする
    timeout          = "3600s"
    session_affinity = true

    scaling {
      min_instance_count = var.cloud_run_min_instances
      max_instance_count = var.cloud_run_max_instances
    }

    containers {
      image = local.placeholder_image

      ports {
        container_port = 8080
      }

      resources {
        limits = {
          cpu    = var.cloud_run_cpu
          memory = var.cloud_run_memory
        }
        cpu_idle = true
      }

      env {
        name  = "WS_PORT"
        value = "8080"
      }
      env {
        name  = "RAILS_API_URL"
        value = google_cloud_run_v2_service.rails.uri
      }
      env {
        name  = "GOOGLE_CLOUD_PROJECT"
        value = var.project_id
      }
      env {
        name  = "MATCH_RESULTS_SUBSCRIPTION"
        value = google_pubsub_subscription.match_results.name
      }
      env {
        name  = "ROOM_EVENTS_TOPIC"
        value = google_pubsub_topic.room_events.name
      }
    }
  }

  lifecycle {
    ignore_changes = [
      template[0].containers[0].image,
      client,
      client_version,
    ]
  }

  depends_on = [google_project_service.apis]
}

# ==================================================
# フロントエンド (nginx で Vite のビルド成果物を配信)
# ==================================================
resource "google_cloud_run_v2_service" "frontend" {
  name                = "frontend"
  location            = var.region
  ingress             = "INGRESS_TRAFFIC_ALL"
  deletion_protection = false

  template {
    service_account = google_service_account.run.email

    scaling {
      min_instance_count = 0
      max_instance_count = var.cloud_run_max_instances
    }

    containers {
      image = local.placeholder_image

      ports {
        container_port = 8080
      }

      resources {
        limits = {
          cpu    = "1"
          memory = "256Mi"
        }
        cpu_idle = true
      }
    }
  }

  lifecycle {
    ignore_changes = [
      template[0].containers[0].image,
      client,
      client_version,
    ]
  }

  depends_on = [google_project_service.apis]
}

# ==================================================
# 公開設定（誰でもアクセス可）
# ==================================================
resource "google_cloud_run_v2_service_iam_member" "public" {
  for_each = {
    rails    = google_cloud_run_v2_service.rails.name
    game     = google_cloud_run_v2_service.game.name
    frontend = google_cloud_run_v2_service.frontend.name
  }

  location = var.region
  name     = each.value
  role     = "roles/run.invoker"
  member   = "allUsers"
}
