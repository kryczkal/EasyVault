# FullStack Web Application

This project is a full-featured fullstack web application designed for file sharing with friends on events like weddings or parties. It leverages Google Cloud for a serverless architecture, using Terraform for infrastructure management, Go and Python for the backend, and Flutter for the frontend.

## Project Structure

- **Backend**: Contains all server-side logic divided into functions, database management scripts, and Terraform configuration files for deploying to Google Cloud.
- **Frontend**: Flutter-based UI components for a responsive web and mobile experience.

### Backend Details

- **Functions**: Serverless functions to handle operations like file uploads/downloads, user management, and session handling.
- **Database**: Scripts for database setup, state management, and trigger setups.
- **Terraform**: Infrastructure as Code files to manage resources on Google Cloud Platform.

### Frontend Details

- **Flutter App**: A cross-platform application providing a user-friendly interface for interacting with the backend services.

## Setup and Deployment

### Prerequisites

- Google Cloud Account
- Terraform installed
- Flutter SDK
- Go and Python environments set up

## Configuring the Backend
### Terraform Setup:
1. Create a new project in Google Cloud Platform
2. Authorize the Google Cloud SDK
```bash
gcloud auth login (on machines without a browser the --no-browser flag can be used)
```
2. Select the project in the Google Cloud SDK
```bash
gcloud config set project <project-id>
```

3. Create a new service account and download the key file [create-gcloud-credentials.sh](backend/scripts/create-gcloud-credentials.sh)) (ensure you have the necessary permissions on the google cloud)

4. Tweak the terraform [variables.tf](backend/terraform/variables.tf) file to match your project id and service account key file path

5. Prepare terraform for migrating the backend to google cloud
You will need to disable the "gcs" backend in the [terraform_backend.tf](backend/terraform/terraform_backend.tf) file (comment it out), run `terraform init` once, and then uncomment it, so we can migrate the backend from local to gcloud

5. Create a Google Cloud Bucket for the terraform state
```bash
cd backend/terraform
./migrate_backend_to_gcloud.sh
```

6. Deploy the infrastructure using terraform:
```bash
cd backend/terraform
terraform init
terraform apply
```

### Configuring the Frontend

1. **Flutter Setup**:
   - Navigate to the `frontend` directory.
   - Run `flutter pub get` to install dependencies.
   - Start the application with `flutter run`.

## Usage

- The web application allows users to securely share files with their friends. 
- Functions like file upload/download, session management, and user creation/deletion are handled through the serverless backend.
- There is currently no in-app ordering method, so "sessions" are created manually through the "create_order" function, followed by a call to "auto-sessions" to automatically create and destroy the sessions 

## Contributing

Contributions are welcome. Please fork the project and submit a pull request with your changes.
