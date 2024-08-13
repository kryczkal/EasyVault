# Enable Identity Platform API
resource "google_project_service" "identity_platform" {
  project = local.project_id
  service = "identitytoolkit.googleapis.com"
}

# Create Identity Platform Config
resource "google_identity_platform_config" "default" {
  project = local.project_id
  
  sign_in {
    allow_duplicate_emails = false

    email {
      enabled = true
      password_required = true
    }
  }

  multi_tenant {
    allow_tenants = true
  }

  depends_on = [google_project_service.identity_platform]
}

# Create a default Identity Platform tenant
resource "google_identity_platform_tenant" "default" {
  project               = local.project_id
  display_name          = "tenant" 
  allow_password_signup = true

  depends_on = [google_identity_platform_config.default]
}