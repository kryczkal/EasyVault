# Cloud SQL instance for PostgreSQL
resource "google_sql_database_instance" "event_db" {
  name             = "event-db-instance"
  database_version = "POSTGRES_13"
  region           = local.location

  settings {
    tier = "db-f1-micro"
  }
}

# Database
resource "google_sql_database" "event_database" {
  name     = "event_database"
  instance = google_sql_database_instance.event_db.name
}

