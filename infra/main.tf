terraform {
  required_version = ">= 1.0"
}

# ===================================================================
# Recursos Comuns (Bucket de Logs, Contas de Serviço, etc.)
# ===================================================================

resource "google_storage_bucket" "cloudbuild_logs" {
  name                        = var.log_bucket_name
  project                     = var.project_id
  location                    = var.region
  uniform_bucket_level_access = true

  lifecycle_rule {
    condition { age = 30 }
    action    { type = "Delete" }
  }
}

resource "google_storage_bucket_iam_member" "cloudbuild_logs_writer" {
  bucket = google_storage_bucket.cloudbuild_logs.name
  role   = "roles/storage.objectCreator"
  member = var.cloudbuild_service_account_email
}

resource "google_storage_bucket_iam_member" "compute_sa_logs_writer" {
  bucket = google_storage_bucket.cloudbuild_logs.name
  role   = "roles/storage.objectCreator"
  member = var.compute_engine_service_account_email
}

# ===================================================================
# Contas de serviço
# ===================================================================

resource "google_service_account" "etl_crm_runner_sa" {
  account_id   = var.etl_crm_service_account_id
  display_name = var.etl_crm_service_account_display_name
  project      = var.project_id
}

resource "google_service_account" "dbt_runner_sa" {
  account_id   = var.dbt_runner_service_account_id
  display_name = var.dbt_runner_service_account_display_name
  project      = var.project_id
}

# ===================================================================
# Cloud Run Service – ETL CRM
# ===================================================================

resource "google_cloud_run_service" "etl_crm" {
  name     = "etl-crm"
  project  = var.project_id
  location = var.region

  template {
    spec {
      containers {
        image          = var.image_uri
        ports {
          container_port = 8080
        }
      }
      service_account_name = google_service_account.etl_crm_runner_sa.email
    }
  }

  traffic {
    percent         = 100
    latest_revision = true
  }

  depends_on = [google_service_account.etl_crm_runner_sa]
}

resource "google_cloud_run_service_iam_member" "scheduler_invoker_for_etl_crm" {
  service  = google_cloud_run_service.etl_crm.name
  location = var.region
  project  = var.project_id
  role     = "roles/run.invoker"
  member   = "serviceAccount:${google_service_account.etl_crm_runner_sa.email}"
}

resource "google_cloud_run_service_iam_member" "generic_invoker_for_etl_crm" {
  service  = google_cloud_run_service.etl_crm.name
  location = var.region
  project  = var.project_id
  role     = "roles/run.invoker"
  member   = var.invoker_member
}

# ===================================================================
# Scheduler – dispara o ETL CRM
# ===================================================================

resource "google_cloud_scheduler_job" "etl_crm_scheduler" {
  name        = "etl-crm-scheduler"
  project     = var.project_id
  description = "Dispara o serviço ETL-CRM via HTTP"
  schedule    = var.schedule_cron
  time_zone   = var.time_zone

  http_target {
    http_method = "GET"
    uri         = google_cloud_run_service.etl_crm.status[0].url

    oidc_token {
      service_account_email = google_service_account.etl_crm_runner_sa.email
      audience              = google_cloud_run_service.etl_crm.status[0].url
    }
  }

  depends_on = [
    google_cloud_run_service_iam_member.scheduler_invoker_for_etl_crm
  ]
}

# ===================================================================
# Cloud Run Service – DBT Runner (substitui o Job)
# ===================================================================

resource "google_cloud_run_service" "dbt_runner" {
  name     = "dbt-runner"
  project  = var.project_id
  location = var.region

  template {
    spec {
      containers {
        image          = var.dbt_runner_image_uri
        ports {
          container_port = 8080
        }
      }
      service_account_name = google_service_account.dbt_runner_sa.email
    }
  }

  traffic {
    percent         = 100
    latest_revision = true
  }

  depends_on = [google_service_account.dbt_runner_sa]
}

resource "google_cloud_run_service_iam_member" "scheduler_invoker_for_dbt_runner" {
  service  = google_cloud_run_service.dbt_runner.name
  location = var.region
  project  = var.project_id
  role     = "roles/run.invoker"
  member   = "serviceAccount:${google_service_account.dbt_runner_sa.email}"
}

# ===================================================================
# Scheduler – dispara o DBT Runner via HTTP
# ===================================================================

resource "google_cloud_scheduler_job" "dbt_runner_scheduler" {
  name        = "dbt-runner-scheduler"
  project     = var.project_id
  description = "Dispara o serviço DBT Runner via HTTP"
  schedule    = var.dbt_schedule_cron
  time_zone   = var.time_zone

  http_target {
    http_method = "GET"
    uri         = google_cloud_run_service.dbt_runner.status[0].url

    oidc_token {
      service_account_email = google_service_account.dbt_runner_sa.email
      audience              = google_cloud_run_service.dbt_runner.status[0].url
    }
  }

  depends_on = [
    google_cloud_run_service_iam_member.scheduler_invoker_for_dbt_runner
  ]
}
