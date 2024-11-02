#!/bin/bash

# Step 1: Set variables
REPO_NAME="ctama-js-backend-app"         # Your GitHub repo name in lowercase
IMAGE_NAME="ctama-js-backend-app"        # Desired Docker image name
GITHUB_USERNAME="meriem1601"             # Your GitHub username in lowercase
IMAGE_TAG="staging"                      # Desired image tag 

# Ensure the GITHUB_TOKEN is provided via an environment variable
if [[ -z "$GITHUB_TOKEN" ]]; then
    echo "Error: GITHUB_TOKEN environment variable is not set." >&2
    exit 1
fi

# Function to handle errors
error_exit() {
    echo "Error: $1" >&2
    exit 1
}

# Step 2: Login to GitHub Container Registry
echo "Logging in to GitHub Container Registry..."
if ! echo "$GITHUB_TOKEN" | docker login ghcr.io -u "$GITHUB_USERNAME" --password-stdin; then
    error_exit "Login to GitHub Container Registry failed!"
fi
echo "Login successful."

# Step 3: Build your Docker image
echo "Building Docker image..."
if ! docker build -t "$IMAGE_NAME:$IMAGE_TAG" .; then
    error_exit "Docker build failed!"
fi
echo "Docker image built successfully."

# Step 4: Tag your image for GitHub Packages
echo "Tagging Docker image for GitHub Packages..."
if ! docker tag "$IMAGE_NAME:$IMAGE_TAG" "ghcr.io/$GITHUB_USERNAME/$REPO_NAME:$IMAGE_TAG"; then
    error_exit "Tagging Docker image failed!"
fi
echo "Docker image tagged successfully."

# Step 5: Push the image to GitHub Packages
echo "Pushing Docker image to GitHub Packages..."
if ! docker push "ghcr.io/$GITHUB_USERNAME/$REPO_NAME:$IMAGE_TAG"; then
    error_exit "Pushing to GitHub Packages failed!"
fi
echo "Docker image pushed to GitHub Packages successfully."

# Completion message
echo "Done! Your image is now available on GitHub Container Registry."
