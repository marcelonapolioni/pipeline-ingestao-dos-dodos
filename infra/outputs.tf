# outputs.tf

# ===================================================================
# Output das URLs dos serviços Cloud Run
# ===================================================================

output "etl_crm_service_url" {
  description = "URL pública do serviço Cloud Run ETL CRM"
  value       = google_cloud_run_service.etl_crm.status[0].url
}

output "dbt_runner_service_url" {
  description = "URL pública do serviço Cloud Run DBT Runner"
  value       = google_cloud_run_service.dbt_runner.status[0].url
}

# ===================================================================
# Output dos nomes dos serviços
# ===================================================================

output "etl_crm_service_name" {
  description = "Nome do serviço Cloud Run ETL CRM"
  value       = google_cloud_run_service.etl_crm.name
}

output "dbt_runner_service_name" {
  description = "Nome do serviço Cloud Run DBT Runner"
  value       = google_cloud_run_service.dbt_runner.name
}

# ===================================================================
# Output dos e-mails das service accounts
# ===================================================================

output "etl_crm_runner_sa_email" {
  description = "E-mail da service account do ETL CRM"
  value       = google_service_account.etl_crm_runner_sa.email
}

output "dbt_runner_sa_email" {
  description = "E-mail da service account do DBT Runner"
  value       = google_service_account.dbt_runner_sa.email
}
