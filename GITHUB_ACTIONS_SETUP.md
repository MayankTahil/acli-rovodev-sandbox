# GitHub Actions Setup for Automatic Docker Image Building

This repository is configured to automatically build Docker images for both x86_64 (AMD64) and ARM64 architectures whenever there's a change to the Dockerfile. The built images are pushed to Docker Hub with appropriate tags.

## How It Works

1. When changes are pushed to the `Dockerfile` in the main branch, GitHub Actions automatically triggers a workflow.
2. The workflow builds Docker images for both x86_64 and ARM64 architectures.
3. Images are tagged according to the conventions used in the `run-rovodev.sh` script:
   - `username/rovodev:x86_64` and `username/rovodev-x86_64:latest` for x86_64 architecture
   - `username/rovodev:arm64` and `username/rovodev-arm64:latest` for ARM64 architecture
   - `username/rovodev:latest` for a multi-platform image that works on both architectures

## Setup Instructions

To enable automatic Docker image building, you need to set up GitHub Secrets:

1. Go to your GitHub repository
2. Click on "Settings" > "Secrets and variables" > "Actions"
3. Add the following secrets:
   - `DOCKERHUB_USERNAME`: Your Docker Hub username
   - `DOCKERHUB_TOKEN`: Your Docker Hub access token (not your password)

### Getting a Docker Hub Access Token

1. Log in to [Docker Hub](https://hub.docker.com/)
2. Click on your username > "Account Settings" > "Security"
3. Click "New Access Token"
4. Give it a description like "GitHub Actions"
5. Copy the generated token and add it as the `DOCKERHUB_TOKEN` secret in GitHub

## Manual Triggering

You can also manually trigger the workflow:

1. Go to the "Actions" tab in your GitHub repository
2. Select the "Build and Push Docker Images" workflow
3. Click "Run workflow"

## Testing Locally

To test the Docker image building process locally before pushing to GitHub:

```bash
# Build for x86_64 (AMD64)
docker build --platform linux/amd64 -t rovodev:x86_64 .

# Build for ARM64
docker build --platform linux/arm64 -t rovodev:arm64 .
```

## Workflow File

The workflow is defined in `.github/workflows/docker-build.yml`. You can modify this file to adjust the build process, change tags, or add additional steps as needed.