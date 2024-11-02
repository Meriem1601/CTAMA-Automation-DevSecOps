#!/bin/bash

# ═══════════════════════════════════════════════════════════════
# 🔒 Enhanced Trivy Security Scanner Script
# Author: Mariem BENMABROUK
# Description: Comprehensive security scanning with custom reporting
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
TEMPLATES_DIR="./trivy-templates"
IMAGE_NAME="ghcr.io/meriem1601/ctama-js-backend-app"
IMAGE_TAG="staging"
SEVERITY_LEVEL="CRITICAL,HIGH"

# Define large files to skip
SKIP_FILES=(
    "dependency-check-report/dependency-check-report.html"
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

# Create necessary directories
create_directories() {
    print_progress "Creating necessary directories..."
    mkdir -p "${REPORTS_DIR}" "${TEMPLATES_DIR}" || handle_error "Failed to create directories"
    print_styled "${GREEN}" "✓ Directories created successfully"
}

# Create custom HTML template
create_custom_template() {
    print_progress "Creating custom HTML template..."
    cat > "${TEMPLATES_DIR}/custom.html" << 'EOL'
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Trivy Security Report</title>
    <style>
        :root {
            --primary-color: #2563eb;
            --danger-color: #dc2626;
            --warning-color: #f59e0b;
            --success-color: #16a34a;
            --info-color: #3b82f6;
        }
        
        body {
            font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Oxygen, Ubuntu, Cantarell, sans-serif;
            line-height: 1.6;
            margin: 0;
            padding: 20px;
            background: #f8fafc;
            color: #1e293b;
        }
        
        .container {
            max-width: 1200px;
            margin: 0 auto;
            background: white;
            padding: 2rem;
            border-radius: 8px;
            box-shadow: 0 1px 3px rgba(0,0,0,0.1);
        }
        
        .header {
            text-align: center;
            margin-bottom: 2rem;
            padding-bottom: 1rem;
            border-bottom: 2px solid #e2e8f0;
        }
        
        .vulnerability-card {
            background: white;
            border: 1px solid #e2e8f0;
            border-radius: 6px;
            padding: 1rem;
            margin-bottom: 1rem;
        }
        
        .severity {
            display: inline-block;
            padding: 0.25rem 0.75rem;
            border-radius: 4px;
            font-weight: bold;
            margin-right: 1rem;
        }
        
        .severity.HIGH {
            background: #fecaca;
            color: #dc2626;
        }
        
        .severity.CRITICAL {
            background: #fee2e2;
            color: #991b1b;
        }
        
        .severity.MEDIUM {
            background: #fef3c7;
            color: #b45309;
        }
        
        .severity.LOW {
            background: #e0f2fe;
            color: #0369a1;
        }
        
        .metadata {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(200px, 1fr));
            gap: 1rem;
            margin: 1rem 0;
            padding: 1rem;
            background: #f8fafc;
            border-radius: 4px;
        }
        
        .links {
            margin-top: 1rem;
            padding-top: 1rem;
            border-top: 1px solid #e2e8f0;
        }
        
        .links a {
            display: inline-block;
            margin-right: 1rem;
            color: var(--primary-color);
            text-decoration: none;
        }
        
        .links a:hover {
            text-decoration: underline;
        }
        
        .summary {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(150px, 1fr));
            gap: 1rem;
            margin-bottom: 2rem;
        }
        
        .summary-card {
            padding: 1rem;
            border-radius: 6px;
            text-align: center;
            color: white;
        }
        
        /* [CHANGED] Updated CSS classes to match uppercase severity levels */
        .summary-card.CRITICAL {
            background: var(--danger-color);
        }
        
        .summary-card.HIGH {
            background: var(--warning-color);
        }
        
        .summary-card.MEDIUM {
            background: var(--info-color);
        }
        
        .summary-card.LOW {
            background: var(--success-color);
        }
    </style>
</head>
<body>
    <div class="container">
        <div class="header">
            <h1>Trivy Security Scan Report</h1>
            <p>Generated on {{ .Date }}</p>
        </div>

        <div class="summary">
            {{ range .Severities }}
            <!-- [CHANGED] Removed ToLower function -->
            <div class="summary-card {{ .Level }}">
                <h3>{{ .Level }}</h3>
                <p>{{ .Count }} vulnerabilities</p>
            </div>
            {{ end }}
        </div>

        {{ range .Vulnerabilities }}
        <div class="vulnerability-card">
            <div class="severity {{ .Severity }}">{{ .Severity }}</div>
            <h3>{{ .ID }}</h3>
            
            <div class="metadata">
                <div>
                    <strong>Package:</strong> {{ .Package }}
                </div>
                <div>
                    <strong>Installed Version:</strong> {{ .InstalledVersion }}
                </div>
                <div>
                    <strong>Fixed Version:</strong> {{ .FixedVersion }}
                </div>
            </div>
            
            <p>{{ .Description }}</p>
            
            <div class="links">
                {{ range .References }}
                <a href="{{ . }}" target="_blank" rel="noopener noreferrer">Reference</a>
                {{ end }}
            </div>
        </div>
        {{ end }}
    </div>
</body>
</html>
EOL
    print_styled "${GREEN}" "✓ Custom HTML template created successfully"
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
        --format template \
        --template "@${TEMPLATES_DIR}/custom.html" \
        -o "${REPORTS_DIR}/filesystem-report.html" || handle_error "Filesystem scan failed"
    
    trivy fs . \
        --severity "${SEVERITY_LEVEL}" \
        --skip-files "${SKIP_FILES[*]}" \
        --format json \
        -o "${REPORTS_DIR}/filesystem-report.json" || handle_error "Filesystem JSON report generation failed"
    
    print_styled "${GREEN}" "✓ Filesystem scan completed"
}

# Scan Docker image
scan_docker_image() {
    print_header "🐳 Scanning Docker Image"
    
    print_progress "Running Docker image scan..."
    trivy image "${IMAGE_NAME}:${IMAGE_TAG}" \
        --severity "${SEVERITY_LEVEL}" \
        --skip-files "${SKIP_FILES[*]}" \
        --format template \
        --template "@${TEMPLATES_DIR}/custom.html" \
        -o "${REPORTS_DIR}/docker-report.html" || handle_error "Docker image scan failed"
    
    trivy image "${IMAGE_NAME}:${IMAGE_TAG}" \
        --severity "${SEVERITY_LEVEL}" \
        --skip-files "${SKIP_FILES[*]}" \
        --format json \
        -o "${REPORTS_DIR}/docker-report.json" || handle_error "Docker JSON report generation failed"
    
    print_styled "${GREEN}" "✓ Docker image scan completed"
}

# Analyze results
analyze_results() {
    print_header "📊 Analyzing Results"
    
    print_progress "Processing scan results..."
    
    # Count vulnerabilities from filesystem scan
    local fs_critical=$(jq '.Results[].Vulnerabilities[] | select(.Severity=="CRITICAL") | .VulnerabilityID' "${REPORTS_DIR}/filesystem-report.json" | wc -l)
    local fs_high=$(jq '.Results[].Vulnerabilities[] | select(.Severity=="HIGH") | .VulnerabilityID' "${REPORTS_DIR}/filesystem-report.json" | wc -l)
    
    # Count vulnerabilities from Docker scan
    local docker_critical=$(jq '.Results[].Vulnerabilities[] | select(.Severity=="CRITICAL") | .VulnerabilityID' "${REPORTS_DIR}/docker-report.json" | wc -l)
    local docker_high=$(jq '.Results[].Vulnerabilities[] | select(.Severity=="HIGH") | .VulnerabilityID' "${REPORTS_DIR}/docker-report.json" | wc -l)
    
    echo -e "\n📊 ${BOLD}Summary of Findings:${NC}"
    echo -e "╔════════════════════╦══════════════╦═════════════╗"
    echo -e "║      Scan Type     ║   Critical   ║    High     ║"
    echo -e "╠════════════════════╬══════════════╬═════════════╣"
    echo -e "║ Filesystem         ║     ${fs_critical}        ║     ${fs_high}       ║"
    echo -e "║ Docker Image       ║     ${docker_critical}        ║     ${docker_high}       ║"
    echo -e "╚════════════════════╩══════════════╩═════════════╝"
    
    # Check if we should fail
    local total_critical=$((fs_critical + docker_critical))
    if [ ${total_critical} -gt 0 ]; then
        handle_error "Found ${total_critical} critical vulnerabilities!"
    fi
    
    print_styled "${GREEN}" "✓ Analysis completed successfully"
}

# Main execution
main() {
    print_header "🚀 Starting Enhanced Security Scan"
    
    create_directories
    create_custom_template
    install_trivy
    scan_filesystem
    scan_docker_image
    analyze_results
    
    print_header "✨ Security Scan Completed Successfully"
    print_styled "${GREEN}" "Reports are available in: ${REPORTS_DIR}"
    print_styled "${BLUE}" "HTML Reports:"
    echo "  - Filesystem: ${REPORTS_DIR}/filesystem-report.html"
    echo "  - Docker: ${REPORTS_DIR}/docker-report.html"
}

# Run main function
main "$@"
