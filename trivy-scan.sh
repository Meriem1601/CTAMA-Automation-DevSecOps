#!/bin/bash

# ═══════════════════════════════════════════════════════════════
# 🔒 Trivy Security Scanner Script
# Author: Mariem BENMABROUK
# Description: Comprehensive security scanning for Docker images, 
# filesystem, and Dockerfile with table format for results.
# ═══════════════════════════════════════════════════════════════
# This script now includes table format for output display.
# ═══════════════════════════════════════════════════════════════

# Color codes for pretty output
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color
BOLD='\033[1m'

# Configuration variables
REPORTS_DIR="./trivy-reports"
IMAGE_NAME="ghcr.io/meriem1601/ctama-js-backend-app"
IMAGE_TAG="staging"
SEVERITY_LEVEL="CRITICAL,HIGH"

# Define large files to skip
SKIP_FILES=( "dependency-check-report/dependency-check-report.html"
             "dependency-check-report/dependency-check-report.json"
             "dependency-check-report/dependency-check-report.xml"
             "dependency-check.log"
)

# Function for styled echo
print_styled() {
    local style=$1
    local message=$2
    echo -e "${style}${message}${NC}"
}

# Function for section headers
print_header() {
    local title=$1
    echo -e "\n${BLUE}╔═══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${BLUE}║${NC} ${BOLD}$title${NC}"
    echo -e "${BLUE}╚═══════════════════════════════════════════════════════════════╝${NC}"
}

# Function for progress messages
print_progress() {
    echo -e "${YELLOW}➜${NC} $1"
}

# Function to check if a command exists
check_command() {
    if ! command -v $1 &> /dev/null; then
        return 1
    fi
    return 0
}

# Function to handle errors
handle_error() {
    print_styled "${RED}" "❌ Error: $1"
    exit 1
}

# Create reports directory
create_reports_dir() {
    print_progress "Creating reports directory..."
    mkdir -p "${REPORTS_DIR}" || handle_error "Failed to create reports directory"
    print_styled "${GREEN}" "✓ Reports directory created successfully"
}

# Create contrib directory and download the html.tpl template
download_html_template() {
    print_progress "Creating contrib directory and downloading HTML template..."
    mkdir -p contrib
    curl -o contrib/html.tpl https://raw.githubusercontent.com/aquasecurity/trivy/main/contrib/html.tpl || handle_error "Failed to download HTML template"
    print_styled "${GREEN}" "✓ HTML template downloaded successfully"
}

# Install Trivy if not present
install_trivy() {
    if ! check_command trivy; then
        print_progress "Installing Trivy..."
        curl -sfL https://raw.githubusercontent.com/aquasecurity/trivy/main/contrib/install.sh | sh -s -- -b /usr/local/bin || handle_error "Failed to install Trivy"
        print_styled "${GREEN}" "✓ Trivy installed successfully"
    else
        print_styled "${GREEN}" "✓ Trivy is already installed"
    fi
}

# Scan filesystem
scan_filesystem() {
    print_header "🔍 Scanning Filesystem"
    
    print_progress "Running filesystem scan..."
    trivy fs . \
        --severity "${SEVERITY_LEVEL}" \
        --skip-files "${SKIP_FILES[*]}" \
        --format table \
        || handle_error "Filesystem scan failed"
    
    print_styled "${GREEN}" "✓ Filesystem scan completed"
}

# Scan Docker image
scan_docker_image() {
    print_header "🐳 Scanning Docker Image"
    
    print_progress "Running Docker image scan..."
    trivy image "${IMAGE_NAME}:${IMAGE_TAG}" \
        --severity "${SEVERITY_LEVEL}" \
        --skip-files "${SKIP_FILES[*]}" \
        --format table \
        || handle_error "Docker image scan failed"
    
    print_styled "${GREEN}" "✓ Docker image scan completed"
}

# Removed Dockerfile scan (scan_dockerfile function has been deleted)

# Detailed vulnerability information in the analysis
analyze_results() {
    print_header "📊 Analyzing Results"
    
    print_progress "Processing scan results..."
    
    # Count vulnerabilities from filesystem scan
    local fs_critical=$(grep -o "CRITICAL" "${REPORTS_DIR}/filesystem-report.table" | wc -l)
    local fs_high=$(grep -o "HIGH" "${REPORTS_DIR}/filesystem-report.table" | wc -l)
    
    # Count vulnerabilities from Docker scan
    local docker_critical=$(grep -o "CRITICAL" "${REPORTS_DIR}/docker-image-report.table" | wc -l)
    local docker_high=$(grep -o "HIGH" "${REPORTS_DIR}/docker-image-report.table" | wc -l)
    
    echo -e "\n📊 ${BOLD}Summary of Findings:${NC}"
    echo -e "╔════════════════════╦══════════════╦═════════════╦═══════════════════╗"
    echo -e "║      Scan Type     ║   Critical   ║    High     ║ Vulnerabilities   ║"
    echo -e "╠════════════════════╬══════════════╬═════════════╬═══════════════════╣"
    echo -e "║ Filesystem         ║     ${fs_critical}        ║     ${fs_high}       ║ $(grep -o "CRITICAL" "${REPORTS_DIR}/filesystem-report.table" | wc -l) critical, $(grep -o "HIGH" "${REPORTS_DIR}/filesystem-report.table" | wc -l) high ║"
    echo -e "║ Docker Image       ║     ${docker_critical}        ║     ${docker_high}       ║ $(grep -o "CRITICAL" "${REPORTS_DIR}/docker-image-report.table" | wc -l) critical, $(grep -o "HIGH" "${REPORTS_DIR}/docker-image-report.table" | wc -l) high ║"
    echo -e "╚════════════════════╩══════════════╩═════════════╩═══════════════════╝"
    
    print_styled "${GREEN}" "✓ Analysis completed"
}

# Main function to execute all steps
main() {
    print_header "🚀 Starting Trivy Scan"
    create_reports_dir
    download_html_template
    install_trivy
    scan_filesystem
    scan_docker_image
    analyze_results
    print_styled "${GREEN}" "✅ Trivy Scan Completed Successfully!"
}

# Execute main function
main
