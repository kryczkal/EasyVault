locals {
  config = jsondecode(file("${path.module}/variables.json"))

  project_id              = local.config.project_id
  tfstate_bucket_url      = local.config.tfstate_bucket_url
  credentials_file_path   = coalesce(local.config.credentials_file_path, "credentials.json")
  location                = coalesce(local.config.location, "europe-west1")
  cloud_functions_zip_dir = "${path.module}/cloud_functions_zip"
  cloud_functions_dir     = "${path.module}/../functions"
}
