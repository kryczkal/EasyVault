locals {
  config = jsondecode(file("${path.module}/variables.json"))

  project_id              = local.config.project_id
  tfstate_bucket_url      = local.config.tfstate_bucket_url
  credentials_file_path   = coalesce(local.config.credentials_file_path, "credentials.json")
  location                = coalesce(local.config.location, "europe-west1")
  cloud_functions_zip_dir = "${path.module}/cloud_functions_zip"
  cloud_functions_dir     = "${path.module}/../backend_functions"

  # Fetch database credentials from Secret Manager
  db_username = data.google_secret_manager_secret_version.db_username.secret_data
  db_password = data.google_secret_manager_secret_version.db_password.secret_data
}

data "google_secret_manager_secret_version" "db_username" {
  secret = google_secret_manager_secret.secrets["db-username"].id
  project = local.project_id
  depends_on = [ google_secret_manager_secret.secrets ]
}

data "google_secret_manager_secret_version" "db_password" {
  secret  = google_secret_manager_secret.secrets["db-password"].id
  project = local.project_id
  depends_on = [ google_secret_manager_secret.secrets ]
}