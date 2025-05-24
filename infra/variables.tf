variable "project_id" {
  description = "ID do projeto GCP"
  type        = string
}

variable "region" {
  description = "Região onde os recursos serão criados (ex: us-central1)"
  type        = string
}

variable "log_bucket_name" {
  description = "Nome do bucket GCS para armazenar logs do Cloud Build"
  type        = string
}

variable "image_uri" {
  description = "URI completa da imagem Docker principal (ETL)"
  type        = string
}

variable "invoker_member" {
  description = "Identidade autorizada a invocar o serviço ETL diretamente"
  type        = string
}

variable "cloudbuild_service_account_email" {
  description = "Email da conta de serviço do Cloud Build"
  type        = string
}

variable "compute_engine_service_account_email" {
  description = "Email da conta de serviço do Compute Engine"
  type        = string
}

variable "schedule_cron" {
  description = "Cron para agendar o ETL principal"
  type        = string
}

variable "time_zone" {
  description = "Fuso horário para Cloud Scheduler"
  type        = string
  default     = "America/Sao_Paulo"
}

variable "dbt_runner_image_uri" {
  description = "URI da imagem Docker do DBT Runner"
  type        = string
}

variable "dbt_schedule_cron" {
  description = "Cron para agendar o job do DBT Runner"
  type        = string
  default     = "0 3 * * *"
}

# Contas de serviço específicas
variable "etl_crm_service_account_id" {
  description = "ID da service account para ETL CRM"
  type        = string
  default     = "etl-crm-runner-sa"
}

variable "etl_crm_service_account_display_name" {
  description = "Display name da service account ETL CRM"
  type        = string
  default     = "ETL CRM Runner Service Account"
}

variable "dbt_runner_service_account_id" {
  description = "ID da service account para DBT Runner"
  type        = string
  default     = "dbt-runner-sa"
}

variable "dbt_runner_service_account_display_name" {
  description = "Display name da service account DBT Runner"
  type        = string
  default     = "DBT Runner Service Account"
}
