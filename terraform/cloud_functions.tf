# Cloud Storage bucket for storing Cloud Functions source code
resource "google_storage_bucket" "function_bucket" {
  name     = "${local.project_id}-function-bucket"
  location = local.location
}

locals {
  functions = {
    "session_creation" = {
      description = "Handles the service start event by creating a new bucket for the user and registering it in the database"
      entry_point = "session_creation"
      folder      = ""
      roles       = ["roles/storage.admin", "roles/cloudsql.client"]
    },
    "session_deletion" = {
      description = "Handles the service end event by deleting the user's bucket"
      entry_point = "session_deletion"
      folder      = ""
      roles       = ["roles/storage.admin", "roles/cloudsql.client"]
    },
    "create_user" = {
      description = "Manages user creation"
      entry_point = "create_user"
      folder      = "auth/"
      roles       = ["roles/cloudsql.editor"]
    },
    "delete_user" = {
      description = "Manages user deletion"
      entry_point = "delete_user"
      folder      = "auth/"
      roles       = ["roles/cloudsql.editor"]
    },
    "db_setup" = {
      description = "Sets up the database schema"
      entry_point = "db_setup"
      folder      = "db/"
      roles       = ["roles/cloudsql.admin"]
    },
  }

  common_environment_variables = {
    DB_CONNECTION_NAME = google_secret_manager_secret.secrets["db-connection-name"].name
    DB_USER            = google_secret_manager_secret.secrets["db-username"].name
    DB_PASSWORD        = google_secret_manager_secret.secrets["db-password"].name
    DB_NAME            = google_secret_manager_secret.secrets["db-name"].name
  }

  common_roles = ["roles/cloudfunctions.invoker", "roles/secretmanager.secretAccessor"]
}

# Create service accounts for each Cloud Function
resource "google_service_account" "function_accounts" {
  for_each     = local.functions
  account_id   = "sa-${replace(lower(each.key), "_", "-")}"
  display_name = "Service Account for ${each.key} function"
}

# Create Cloud Functions
resource "google_cloudfunctions_function" "functions" {
  for_each    = local.functions
  name        = each.key
  description = each.value.description
  runtime     = "python39"

  available_memory_mb   = 256
  source_archive_bucket = google_storage_bucket.function_bucket.name
  source_archive_object = google_storage_bucket_object.function_zip[each.key].name
  trigger_http          = true
  entry_point           = each.value.entry_point
  service_account_email = google_service_account.function_accounts[each.key].email

  environment_variables = {
    DB_CONNECTION_NAME = google_secret_manager_secret.secrets["db-connection-name"].name
    DB_USER            = google_secret_manager_secret.secrets["db-username"].name
    DB_PASSWORD        = google_secret_manager_secret.secrets["db-password"].name
    DB_NAME            = google_secret_manager_secret.secrets["db-name"].name
  }

  depends_on = [google_storage_bucket_object.function_zip]
}

# IAM bindings for functions
resource "google_project_iam_member" "function_roles" {
  for_each = {
    for pair in flatten([
      for func_name, func in local.functions : concat(
        [
        for role in func.roles : {
          func_name = func_name
          role      = role
        }
      ],
      [
        for role in local.common_roles : {
          func_name = func_name
          role      = role
        }
      ]
      )
    ]) : "${pair.func_name}-${pair.role}" => pair
  }

  project = local.project_id
  role    = each.value.role
  member  = "serviceAccount:${google_service_account.function_accounts[each.value.func_name].email}"

  depends_on = [google_cloudfunctions_function.functions]
}

# Create ZIP archives for Cloud Functions
data "archive_file" "function_zip" {
  for_each    = local.functions
  type        = "zip"
  output_path = "${local.cloud_functions_zip_dir}/${each.key}.zip"
  source_dir  = "${local.cloud_functions_dir}/${each.value.folder}${each.key}"
}

resource "google_storage_bucket_object" "function_zip" {
  for_each = local.functions
  name     = "${each.key}.zip"
  bucket   = google_storage_bucket.function_bucket.name
  source   = data.archive_file.function_zip[each.key].output_path
}