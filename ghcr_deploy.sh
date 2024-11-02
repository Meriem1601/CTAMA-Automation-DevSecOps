#!/bin/bash

# Step 1: Set variables
REPO_NAME="ctama-js-backend-app"         # Your GitHub repo name in lowercase
IMAGE_NAME="ctama-js-backend-app"        # Desired Docker image name
GITHUB_USERNAME="meriem1601"             # Your GitHub username in lowercase
IMAGE_TAG="staging"                      # Desired image tag 
GHCR_IMAGE="ghcr.io/$GITHUB_USERNAME/$REPO_NAME:$IMAGE_TAG"

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

# Function to check if image exists locally
check_local_image() {
    local image_id=$(docker images -q "$1" 2>/dev/null)
    [[ ! -z "$image_id" ]]
}

# Function to check if image exists in GHCR
check_ghcr_image() {
    local response
    response=$(curl -s -H "Authorization: Bearer $GITHUB_TOKEN" \
        "https://api.github.com/user/packages/container/$REPO_NAME/versions" | \
        grep -q "\"tags\".*\"$IMAGE_TAG\"")
    return $?
}

# Function to pull image from GHCR
pull_from_ghcr() {
    echo "Pulling image from GHCR..."
    if ! docker pull "$GHCR_IMAGE"; then
        error_exit "Failed to pull image from GHCR!"
    fi
    echo "Successfully pulled image from GHCR."
}

# Step 2: Login to GitHub Container Registry
echo "Logging in to GitHub Container Registry..."
if ! echo "$GITHUB_TOKEN" | docker login ghcr.io -u "$GITHUB_USERNAME" --password-stdin; then
    error_exit "Login to GitHub Container Registry failed!"
fi
echo "Login successful."

# Step 3: Check image existence and handle accordingly
echo "Checking image existence..."

if check_local_image "$IMAGE_NAME:$IMAGE_TAG"; then
    echo "✅ Image exists locally as $IMAGE_NAME:$IMAGE_TAG"
    
    # Check if local image is already tagged for GHCR
    if check_local_image "$GHCR_IMAGE"; then
        echo "✅ Image is already tagged for GHCR"
    else
        echo "Tagging local image for GHCR..."
        if ! docker tag "$IMAGE_NAME:$IMAGE_TAG" "$GHCR_IMAGE"; then
            error_exit "Tagging Docker image failed!"
        fi
        echo "Docker image tagged successfully."
    fi
    
elif check_ghcr_image; then
    echo "🔄 Image exists in GHCR but not locally. Pulling..."
    pull_from_ghcr
    
else
    echo "🏗️ Image not found locally or in GHCR. Building new image..."
    
    # Build your Docker image
    echo "Building Docker image..."
    if ! docker build -t "$IMAGE_NAME:$IMAGE_TAG" .; then
        error_exit "Docker build failed!"
    fi
    echo "Docker image built successfully."
    
    # Tag your image for GitHub Packages
    echo "Tagging Docker image for GitHub Packages..."
    if ! docker tag "$IMAGE_NAME:$IMAGE_TAG" "$GHCR_IMAGE"; then
        error_exit "Tagging Docker image failed!"
    fi
    echo "Docker image tagged successfully."
    
    # Push the image to GitHub Packages
    echo "Pushing Docker image to GitHub Packages..."
    if ! docker push "$GHCR_IMAGE"; then
        error_exit "Pushing to GitHub Packages failed!"
    fi
    echo "Docker image pushed to GitHub Packages successfully."
fi

# Final verification
echo "Performing final verification..."
if check_local_image "$GHCR_IMAGE"; then
    echo "✅ Final verification: Image is available locally as $GHCR_IMAGE"
else
    error_exit "Final verification failed: Image not available locally!"
fi

# Logout from GHCR
echo "Logging out from GitHub Container Registry..."
docker logout ghcr.io

echo "Done! Your image is now available both locally and on GitHub Container Registry."
