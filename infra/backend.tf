terraform {
  required_version = ">= 1.0"

  backend "gcs" {
    bucket = "pelagic-gist-311517-tfstate"
    # Prefixo para agrupar seus estados de Terraform
    prefix = "etl-crm-bigquery/pipeline/terraform/state"
  }
}
