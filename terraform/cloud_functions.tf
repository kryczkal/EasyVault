locals {
  functions = {
    "session_creation" = {
      description = "Handles the service start event by creating a new bucket for the user and registering it in the database"
      entry_point = "session_creation"
      folder      = "buckets/"
      roles       = ["roles/storage.admin", "roles/cloudsql.client"]
    },
    "session_deletion" = {
      description = "Handles the service end event by deleting the user's bucket"
      entry_point = "session_deletion"
      folder      = "buckets/"
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
    "create_order" = {
      description = "Manages order creation"
      entry_point = "create_order"
      folder      = "orders/"
      roles       = ["roles/cloudsql.editor"]
    },
    "delete_order" = {
      description = "Manages order deletion"
      entry_point = "delete_order"
      folder      = "orders/"
      roles       = ["roles/cloudsql.editor"]
    },
    "db_setup" = {
      description = "Sets up the database schema"
      entry_point = "db_setup"
      folder      = "db/"
      roles       = ["roles/cloudsql.admin"]
    },
    # "create_sessions" = {
    #   description = "Checks for new sessions and creates them"
    #   entry_point = "create_sessions"
    #   folder      = "db/db_triggers/"
    #   roles       = ["roles/cloudsql.client"]
    # }
  }

  common_roles = [
    "roles/cloudfunctions.invoker",
    "roles/run.invoker",
    "roles/secretmanager.secretAccessor"
  ]

  builder_roles = [
    "roles/storage.objectAdmin",
    "roles/artifactregistry.writer",
    "roles/secretmanager.secretAccessor",
    "roles/logging.logWriter"
  ]
}

# Cloud Storage bucket for storing Cloud Functions source code
resource "google_storage_bucket" "function_bucket" {
  name     = "${local.project_id}-gcf-source"
  location = local.location
  uniform_bucket_level_access = true
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
  name = "${each.key}.zip"

  bucket   = google_storage_bucket.function_bucket.name
  source   = data.archive_file.function_zip[each.key].output_path

  depends_on = [ 
    data.archive_file.function_zip,
    google_storage_bucket.function_bucket
  ]
}

# Create service account for building Cloud Functions
resource "google_service_account" "function_builder" {
  project = local.project_id
  account_id   = "function-builder"
  display_name = "Service Account for building Cloud Functions"
}

resource "google_project_iam_member" "function_builder_roles" {
  for_each = toset(local.builder_roles)
  project = local.project_id
  role    = each.value
  member  = "serviceAccount:${google_service_account.function_builder.email}"
}



# Create Cloud Functions
resource "google_cloudfunctions2_function" "functions" {
  for_each    = local.functions
  name        = replace(lower(each.key), "_", "-")
  location    = local.location
  description = each.value.description
  build_config {
    runtime = "python39"
    entry_point = each.value.entry_point
    source {
      storage_source {
      bucket = google_storage_bucket.function_bucket.name
      object = google_storage_bucket_object.function_zip[each.key].name
      }
    }
    service_account = google_service_account.function_builder.id
  }

  service_config {
    max_instance_count = 1
    available_memory = "256Mi"
    timeout_seconds = 60
    all_traffic_on_latest_revision = true
    service_account_email = google_service_account.function_accounts[each.key].email

    secret_environment_variables {
      key = "DB_CONNECTION_NAME"
      project_id = local.project_id
      secret = google_secret_manager_secret.secrets["db-connection-name"].secret_id
      version = "latest"
    }
    secret_environment_variables {
      key = "DB_USER"
      project_id = local.project_id
      secret = google_secret_manager_secret.secrets["db-username"].secret_id
      version = "latest"
    }
    secret_environment_variables {
      key = "DB_PASSWORD"
      project_id = local.project_id
      secret = google_secret_manager_secret.secrets["db-password"].secret_id
      version = "latest"
    }
    secret_environment_variables {
      key = "DB_NAME"
      project_id = local.project_id
      secret = google_secret_manager_secret.secrets["db-name"].secret_id
      version = "latest"
    }
  }

  depends_on = [ 
    data.archive_file.function_zip,
    google_storage_bucket_object.function_zip,
    google_service_account.function_accounts,
    google_project_iam_member.function_roles
    ]

    # Update the function when the source code changes
    lifecycle {
      replace_triggered_by = [
        google_storage_bucket_object.function_zip[each.key]
       ]
    }
}

# Create service accounts for each Cloud Function
resource "google_service_account" "function_accounts" {
  for_each     = local.functions
  project = local.project_id
  account_id   = "sa-${replace(lower(each.key), "_", "-")}"
  display_name = "Service Account for ${each.key} function"
}

# Grant Secret Manager Secret Accessor role to each Cloud Function's service account
resource "google_project_iam_member" "function_roles" {
  for_each = {
    for pair in flatten(
      [
        for func_name, func in local.functions : concat([
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
      ]
    ) : "${pair.func_name}-${pair.role}" => pair
  }

  project = local.project_id
  role     = each.value.role
  member  = "serviceAccount:${google_service_account.function_accounts[each.value.func_name].email}"

  depends_on =  [google_service_account.function_accounts]
}

resource "google_cloudfunctions2_function_iam_member" "invoker" {
  for_each = local.functions

  location = google_cloudfunctions2_function.functions[each.key].location
  project  = google_cloudfunctions2_function.functions[each.key].project
  cloud_function = google_cloudfunctions2_function.functions[each.key].name

  role = "roles/cloudfunctions.invoker"

  member = "allUsers"

  depends_on =  [google_service_account.function_accounts]
}

# Enable SQL connection for the underlying Cloud Run service
resource "null_resource" "deploy_new_cloud_run_revision" {
  for_each = google_cloudfunctions2_function.functions

  triggers = {
    function_deployed = each.value.name
  }

  provisioner "local-exec" {
    command = <<EOT
      gcloud run services update \
        ${replace(lower(each.key), "_", "-")} \
        --add-cloudsql-instances=${google_sql_database_instance.event_db.connection_name} \
        --region=${local.location} \
        --platform=managed
    EOT
  }

  depends_on = [google_cloudfunctions2_function.functions]

  lifecycle {
    replace_triggered_by = [
      google_cloudfunctions2_function.functions[each.key],
      google_sql_database_instance.event_db
    ]
  }
}