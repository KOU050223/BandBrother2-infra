# ==================================================
# 基本設定
# ==================================================
variable "project_id" {
  description = "Google Cloud project ID"
  type        = string
  default     = "bandbrother2"
}

variable "region" {
  description = "Cloud Run / Artifact Registry / Storage のリージョン"
  type        = string
  default     = "asia-northeast1"
}

variable "firestore_location" {
  description = "Firestore のロケーション（作成後は変更不可）"
  type        = string
  default     = "asia-northeast1"
}

variable "environment" {
  description = "Environment (production, staging, development)"
  type        = string
  default     = "production"
}

# ==================================================
# シークレット
# ==================================================
variable "rails_master_key" {
  description = "Rails master key（Secret Manager に格納される）"
  type        = string
  sensitive   = true
}

variable "github_oauth_client_id" {
  description = "Firebase Auth の GitHub ログイン用 OAuth App の Client ID（空ならGitHubログインを作らない）"
  type        = string
  default     = ""
}

variable "github_oauth_client_secret" {
  description = "Firebase Auth の GitHub ログイン用 OAuth App の Client Secret"
  type        = string
  default     = ""
  sensitive   = true
}

# ==================================================
# GitHub Actions からのデプロイ (Workload Identity Federation)
# ==================================================
variable "github_repositories" {
  description = "Cloud Run へのデプロイを許可する GitHub リポジトリ (owner/name)"
  type        = list(string)
  default = [
    "KOU050223/BandBrother2-Backend",
    "ruirui23/BandBrother2-Frontend",
  ]
}

# ==================================================
# Cloud Run設定
# ==================================================
variable "cloud_run_max_instances" {
  description = "Cloud Runの最大インスタンス数"
  type        = number
  default     = 3
}

variable "cloud_run_min_instances" {
  description = "Cloud Runの最小インスタンス数（0なら待機中は課金されない）"
  type        = number
  default     = 0
}

variable "cloud_run_memory" {
  description = "Rails / Go サーバーのメモリ"
  type        = string
  default     = "512Mi"
}

variable "cloud_run_cpu" {
  description = "Rails / Go サーバーのCPU"
  type        = string
  default     = "1"
}

variable "container_concurrency" {
  description = "Cloud Runのコンテナ並行数"
  type        = number
  default     = 80
}
