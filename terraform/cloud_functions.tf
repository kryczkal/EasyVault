# Cloud Storage bucket for storing Cloud Functions source code
resource "google_storage_bucket" "function_bucket" {
  name     = "${local.project_id}-function-bucket"
  location = local.location
}
# Service account for Cloud Functions
resource "google_service_account" "function_account" {
  account_id   = "cloud-function-sa"
  display_name = "Cloud Functions Service Account"
}

resource "google_cloudfunctions_function" "hash_gen" {
  name        = "hash_gen"
  description = "Generates a unique SHA-512 hash for event buckets"
  runtime     = "python39"

  available_memory_mb   = 256
  source_archive_bucket = google_storage_bucket.function_bucket.name
  source_archive_object = google_storage_bucket_object.function_zip["session_creation/hash_gen"].name
  trigger_http          = true
  entry_point           = "hash_gen"
  service_account_email = google_service_account.function_account.email
}

# CreateBucket Function
resource "google_cloudfunctions_function" "create_bucket" {
  name        = "create_bucket"
  description = "Creates a new Cloud Storage bucket for an event"
  runtime     = "python39"

  available_memory_mb   = 256
  source_archive_bucket = google_storage_bucket.function_bucket.name
  source_archive_object = google_storage_bucket_object.function_zip["session_creation/create_bucket"].name
  trigger_http          = true
  entry_point           = "create_bucket"
  service_account_email = google_service_account.function_account.email
}

# IAM binding for CreateBucket function to access Storage Admin role
resource "google_project_iam_member" "create_bucket_storage_admin" {
  project = local.project_id
  role    = "roles/storage.admin"
  member  = "serviceAccount:${google_service_account.function_account.email}"

  depends_on = [ google_cloudfunctions_function.create_bucket ]
}

# User Management Function
# resource "google_cloudfunctions_function" "user_management" {
#   name        = "user_management"
#   description = "Manages user creation and authentication"
#   runtime     = "python39"
# 
#   available_memory_mb   = 256
#   source_archive_bucket = google_storage_bucket.function_bucket.name
#   source_archive_object = google_storage_bucket_object.function_zip["auth/user_management"].name
#   trigger_http          = true
#   entry_point           = "user_management"
#   service_account_email = google_service_account.function_account.email
# 
#   environment_variables = {
#     INSTANCE_CONNECTION_NAME = google_secret_manager_secret_version.secret_versions["db-connection-name"].name
#     DB_USER                  = google_secret_manager_secret_version.secret_versions["db-username"].name
#     DB_PASS                  = google_secret_manager_secret_version.secret_versions["db-password"].name
#     DB_NAME                  = google_secret_manager_secret_version.secret_versions["db-name"].name
#     GOOGLE_CLOUD_PROJECT     = local.project_id
#   }
# }

# IAM binding for User Management function to access Cloud SQL
resource "google_project_iam_member" "user_management_cloudsql" {
  project = local.project_id
  role    = "roles/cloudsql.client"
  member  = "serviceAccount:${google_service_account.function_account.email}"
}

# IAM binding for User Management function to access Firebase Admin SDK
resource "google_project_iam_member" "user_management_firebase" {
  project = local.project_id
  role    = "roles/firebase.admin"
  member  = "serviceAccount:${google_service_account.function_account.email}"
}

# Database Setup Function
resource "google_cloudfunctions_function" "db_setup" {
  name        = "db_setup"
  description = "Sets up the database schema"
  runtime     = "python39"

  available_memory_mb   = 256
  source_archive_bucket = google_storage_bucket.function_bucket.name
  source_archive_object = google_storage_bucket_object.function_zip["db/db_setup"].name
  trigger_http          = true
  entry_point           = "setup_database"
  service_account_email = google_service_account.function_account.email

  environment_variables = {
    DB_CONNECTION_NAME       = google_secret_manager_secret.secrets["db-connection-name"].name
    DB_USER                  = google_secret_manager_secret.secrets["db-username"].name
    DB_PASSWORD              = google_secret_manager_secret.secrets["db-password"].name
    DB_NAME                  = google_secret_manager_secret.secrets["db-name"].name
  }
}

# IAM binding for Database Setup function to access Cloud SQL Admin
resource "google_project_iam_member" "db_setup_cloudsql_admin" {
  project = local.project_id
  role    = "roles/cloudsql.admin"
  member  = "serviceAccount:${google_service_account.function_account.email}"
  depends_on = [ google_cloudfunctions_function.db_setup ]
}

# IAM entry for all users to invoke the functions
resource "google_cloudfunctions_function_iam_member" "invoker" {
  # for_each       = toset(["hash_gen", "create_bucket", "user_management", "db_setup"])
  for_each       = toset(["hash_gen", "create_bucket"])
  project        = local.project_id
  region         = local.location
  cloud_function = each.key

  role   = "roles/cloudfunctions.invoker"
  member = "allUsers"
}

# Create ZIP archives for Cloud Functions
data "archive_file" "function_zip" {
  for_each    = toset(["session_creation/hash_gen", "session_creation/create_bucket", "auth/user_management", "db/db_setup"])
  type        = "zip"
  output_path = "${local.cloud_functions_zip_dir}/${each.key}.zip"
  source {
    content  = file("${local.cloud_functions_dir}/${each.key}.py")
    filename = "main.py"
  }
  source {
    content  = file("${local.cloud_functions_dir}/${each.key}.txt")
    filename = "requirements.txt"
  }
}

resource "google_storage_bucket_object" "function_zip" {
  for_each = toset(["session_creation/hash_gen", "session_creation/create_bucket", "auth/user_management", "db/db_setup"])
  name     = "${each.key}.zip"
  bucket   = google_storage_bucket.function_bucket.name
  source   = data.archive_file.function_zip[each.key].output_path
}

# Grant Secret Manager Secret Accessor role to the Cloud Functions service account
resource "google_project_iam_member" "secret_accessor" {
  project = local.project_id
  role    = "roles/secretmanager.secretAccessor"
  member  = "serviceAccount:${google_service_account.function_account.email}"
}