# Pub/Subトピックとサブスクリプション設定
# マッチングシステム用
locals {
  pubsub_labels = {
    environment = var.environment
    project     = var.project_id
  }
}

# マッチング待機キュー用トピック
resource "google_pubsub_topic" "matching_queue" {
  name   = "bandbrother2-matching-queue"
  labels = local.pubsub_labels

  depends_on = [google_project_service.apis]
}

# マッチング結果通知用トピック
resource "google_pubsub_topic" "match_results" {
  name   = "bandbrother2-match-results"
  labels = local.pubsub_labels

  depends_on = [google_project_service.apis]
}

# ゲームルーム作成通知用トピック
resource "google_pubsub_topic" "room_events" {
  name   = "bandbrother2-room-events"
  labels = local.pubsub_labels

  depends_on = [google_project_service.apis]
}

# デッドレタートピック
resource "google_pubsub_topic" "dead_letter" {
  name   = "bandbrother2-dead-letter"
  labels = local.pubsub_labels

  depends_on = [google_project_service.apis]
}

# Rails サーバー用サブスクリプション（マッチング処理）
resource "google_pubsub_subscription" "rails_matching" {
  name  = "rails-matching-subscription"
  topic = google_pubsub_topic.matching_queue.id

  ack_deadline_seconds       = 60
  retain_acked_messages      = false
  message_retention_duration = "86400s" # 24時間

  # プッシュ設定（Cloud Runへ直接配信）
  push_config {
    push_endpoint = "${google_cloud_run_v2_service.rails.uri}/api/matchmaking/webhook"

    oidc_token {
      service_account_email = google_service_account.run.email
    }
  }

  dead_letter_policy {
    dead_letter_topic     = google_pubsub_topic.dead_letter.id
    max_delivery_attempts = 5
  }
}

# Game サーバー用サブスクリプション（ルーム管理）
resource "google_pubsub_subscription" "game_room_events" {
  name  = "game-room-events-subscription"
  topic = google_pubsub_topic.room_events.id

  ack_deadline_seconds       = 30
  retain_acked_messages      = false
  message_retention_duration = "86400s"

  push_config {
    push_endpoint = "${google_cloud_run_v2_service.game.uri}/webhook/room-events"

    oidc_token {
      service_account_email = google_service_account.run.email
    }
  }

  dead_letter_policy {
    dead_letter_topic     = google_pubsub_topic.dead_letter.id
    max_delivery_attempts = 5 # Pub/Sub の最小値
  }
}

# マッチング結果通知用サブスクリプション（WebSocketサーバーがプルする）
resource "google_pubsub_subscription" "match_results" {
  name  = "match-results-subscription"
  topic = google_pubsub_topic.match_results.id

  ack_deadline_seconds       = 30
  retain_acked_messages      = false
  message_retention_duration = "3600s" # 1時間
}

# デッドレター用サブスクリプション
resource "google_pubsub_subscription" "dead_letter" {
  name  = "dead-letter-subscription"
  topic = google_pubsub_topic.dead_letter.id

  ack_deadline_seconds       = 600
  retain_acked_messages      = true
  message_retention_duration = "604800s" # 7日間保持
}

# デッドレター転送のため Pub/Sub サービスエージェントに権限を付与
data "google_project" "this" {
  project_id = var.project_id

  depends_on = [google_project_service.apis]
}

locals {
  pubsub_service_agent = "serviceAccount:service-${data.google_project.this.number}@gcp-sa-pubsub.iam.gserviceaccount.com"
}

resource "google_pubsub_topic_iam_member" "dead_letter_publisher" {
  topic  = google_pubsub_topic.dead_letter.id
  role   = "roles/pubsub.publisher"
  member = local.pubsub_service_agent
}

resource "google_pubsub_subscription_iam_member" "dead_letter_subscriber" {
  for_each = {
    rails_matching   = google_pubsub_subscription.rails_matching.id
    game_room_events = google_pubsub_subscription.game_room_events.id
  }

  subscription = each.value
  role         = "roles/pubsub.subscriber"
  member       = local.pubsub_service_agent
}
