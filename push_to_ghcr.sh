#!/bin/bash

# Step 1: Set variables
REPO_NAME="ctama-automation-devsecops"  # Your GitHub repo name in lowercase
IMAGE_NAME="myapp"                       # Desired Docker image name (you can keep it as is)
GITHUB_USERNAME="meriem1601"             # Your GitHub username in lowercase

# Ensure the GITHUB_TOKEN is provided via an environment variable
if [ -z "$GITHUB_TOKEN" ]; then
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
echo "$GITHUB_TOKEN" | docker login ghcr.io -u "$GITHUB_USERNAME" --password-stdin || error_exit "Login failed!"

echo "Login successful."

# Step 3: Build your Docker image
echo "Building Docker image..."
docker build -t "$IMAGE_NAME:latest" . || error_exit "Docker build failed!"

echo "Docker image built successfully."

# Step 4: Tag your image for GitHub Packages
echo "Tagging Docker image..."
docker tag "$IMAGE_NAME:latest" "ghcr.io/$GITHUB_USERNAME/$REPO_NAME:latest" || error_exit "Tagging failed!"

echo "Docker image tagged successfully."

# Step 5: Push the image to GitHub Packages
echo "Pushing to GitHub Packages..."
docker push "ghcr.io/$GITHUB_USERNAME/$REPO_NAME:latest" || error_exit "Pushing to GitHub Packages failed!"

echo "Docker image pushed to GitHub Packages successfully."

echo "Done! Your image is now available on GitHub Container Registry."
