locals {
  functions = {
    "session_creation" = {
      runtime = "python39"
      description = "Handles the service start event by creating a new bucket for the user and registering it in the database"
      entry_point = "session_creation"
      folder      = "buckets/"
      roles       = ["roles/storage.admin", "roles/cloudsql.editor"]
      environment = {}
      mem = "256Mi"
    },
    "session_deletion" = {
      runtime = "python39"
      description = "Handles the service end event by deleting the user's bucket"
      entry_point = "session_deletion"
      folder      = "buckets/"
      roles       = ["roles/storage.admin", "roles/cloudsql.editor"]
      environment = {}
      mem = "256Mi"
    },
    "create_user" = {
      runtime = "python39"
      description = "Manages user creation"
      entry_point = "create_user"
      folder      = "db/users/"
      roles       = ["roles/cloudsql.editor"]
      environment = {}
      mem = "256Mi"
    },
    "delete_user" = {
      runtime = "python39"
      description = "Manages user deletion"
      entry_point = "delete_user"
      folder      = "db/users/"
      roles       = ["roles/cloudsql.editor"]
      environment = {}
      mem = "256Mi"
    },
    "create_order" = {
      runtime = "python39"
      description = "Manages order creation"
      entry_point = "create_order"
      folder      = "db/orders/"
      roles       = ["roles/cloudsql.editor"]
      environment = {}
      mem = "256Mi"
    },
    "delete_order" = {
      runtime = "python39"
      description = "Manages order deletion"
      entry_point = "delete_order"
      folder      = "db/orders/"
      roles       = ["roles/cloudsql.editor"]
      environment = {}
      mem = "256Mi"
    },
    "db_setup" = {
      runtime = "python39"
      description = "Sets up the database schema"
      entry_point = "db_setup"
      folder      = "db/"
      roles       = ["roles/cloudsql.admin"]
      environment = {
      }
      mem = "256Mi"
    },
    "auto_sessions" = {
      runtime = "python39"
      description = "Activates pending orders that have started"
      entry_point = "auto_sessions"
      folder      = "db/db_triggers/"
      roles       = ["roles/cloudsql.client"]
      environment = {
        GCF_SESSION_CREATION_NAME = "session-creation"
        GCF_SESSION_DELETION_NAME = "session-deletion"
      },
      mem = "256Mi"
    },
    "list_bucket_files" = {
      runtime = "python39"
        description = "Fetches files from the user's bucket"
        entry_point = "list_bucket_files"
        folder      = "buckets/"
        roles       = ["roles/storage.admin"]
        environment = {}
      mem = "256Mi"
    },
    "list_bucket_files_2" = {
      runtime = "python39"
        description = "Fetches files from the user's bucket"
        entry_point = "list_bucket_files_2"
        folder      = "buckets/"
        roles       = ["roles/storage.admin"]
        environment = {}
      mem = "256Mi"
    },
    "list_bucket_files_3" = {
      runtime = "python39"
        description = "Fetches files from the user's bucket"
        entry_point = "list_bucket_files_3"
        folder      = "buckets/"
        roles       = ["roles/storage.admin",
                       "roles/storage.objectCreator",
                       "roles/storage.objectViewer",
                       "roles/iam.serviceAccountTokenCreator"
                       ]
        environment = {}
      mem = "256Mi"
    },
    "list_bucket_files_4" = {
      runtime = "go122"
        description = "Fetches files from the user's bucket"
        entry_point = "ListBucketFiles"
        folder      = "buckets/"
        roles       = ["roles/storage.admin",
                       "roles/storage.objectCreator",
                       "roles/storage.objectViewer",
                       "roles/iam.serviceAccountTokenCreator"
                       ]
        environment = {}
      mem = "256Mi"
    },
    "proxy_file" = {
      runtime = "python39"
        description = "Proxies a file from the user's bucket"
        entry_point = "proxy_file"
        folder      = "buckets/"
        roles       = ["roles/storage.admin"]
        environment = {}
      mem = "4Gi"
    },
    "upload_chunk" = {
      runtime = "python39"
        description = "Uploads a chunk of a file to the user's bucket"
        entry_point = "upload_chunk"
        folder      = "buckets/upload_file/"
        roles       = ["roles/storage.admin"]
        environment = {}
      mem = "256Mi"
    },
    "upload_finalize" = {
      runtime = "python39"
        description = "Finalizes the file upload"
        entry_point = "upload_finalize"
        folder      = "buckets/upload_file/"
        roles       = ["roles/storage.admin"]
        environment = {}
      mem = "4Gi"
    },
    "db_state" = {
      runtime = "python39"
        description = "Fetches the current state of the database"
        entry_point = "db_state"
        folder      = "db/"
        roles       = ["roles/cloudsql.client"]
        environment = {}
      mem = "256Mi"
    },
  }

  public_function_names = {
    "list_bucket_files" = {},
    "list_bucket_files_2" = {},
    "list_bucket_files_3" = {},
    "list_bucket_files_4" = {},
    "upload_chunk" = {},
    "upload_finalize" = {},
    "proxy_file" = {},
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

  common_environment = {
    GCP_PROJECT_ID = local.project_id
    GCP_REGION = local.location
  }
}

# Cloud Storage bucket for storing Cloud Functions source code
resource "google_storage_bucket" "function_bucket" {
  name     = "gcf-source-${local.project_id}"
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
    runtime = each.value.runtime
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
    available_memory = each.value.mem
    timeout_seconds = 60
    all_traffic_on_latest_revision = true
    service_account_email = google_service_account.function_accounts[each.key].email

    environment_variables = merge(
      local.common_environment,
      each.value.environment
    )

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
    google_storage_bucket_object.function_zip,
    google_service_account.function_accounts,
    google_project_iam_member.function_roles,
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

resource "google_service_account_key" "function_keys" {
  for_each = google_service_account.function_accounts

  service_account_id = each.value.id
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

# Enable public access to the Cloud Run service
resource "null_resource" "allow_unauthenticated" {
  for_each = local.public_function_names

  provisioner "local-exec" {
    command = <<EOT
      gcloud run services add-iam-policy-binding ${replace(lower(each.key), "_", "-")} \
      --region=${local.location} \
      --member="allUsers" \
      --role="roles/run.invoker" \
      --platform=managed
    EOT
  }

  depends_on = [google_cloudfunctions2_function.functions]

  lifecycle {
    replace_triggered_by = [
      google_cloudfunctions2_function.functions[each.key]
    ]
  }
}
