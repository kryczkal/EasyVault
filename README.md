# FullStack Web Application

This project is a full-featured fullstack web application designed for file sharing with friends. It leverages Google Cloud for a serverless architecture, using Terraform for infrastructure management, Go and Python for the backend, and Flutter for the frontend.

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

### Configuring the Backend

1. **Terraform Setup**:
   - Navigate to the `backend/terraform` directory.
   - Initialize Terraform with `terraform init`.
   - Apply configuration with `terraform apply`.

### Configuring the Frontend

1. **Flutter Setup**:
   - Navigate to the `frontend` directory.
   - Run `flutter pub get` to install dependencies.
   - Start the application with `flutter run`.

## Usage

- The web application allows users to securely share files with their friends. 
- Functions like file upload/download, session management, and user creation/deletion are handled through the serverless backend.

## Contributing

Contributions are welcome. Please fork the project and submit a pull request with your changes.
