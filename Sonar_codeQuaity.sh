#!/bin/bash

# Strict error handling
set -euo pipefail

# Configuration
SONAR_URL="http://16.16.118.25:9000"
PROJECT_KEY="CTAMA-Automation-DevSecOps"

# Connectivity and Prerequisite Checks
pre_flight_checks() {
    echo "🕹️ Pre-flight SonarQube Connectivity Check"
    
    # Check if sonar-scanner is installed
    if ! command -v sonar-scanner &> /dev/null; then
        echo "❌ Error: sonar-scanner not installed"
        exit 1
    fi
    
    # Test SonarQube server connectivity
    if ! curl -sf "${SONAR_URL}/api/system/status" &> /dev/null; then
        echo "❌ Error: Cannot connect to SonarQube server at ${SONAR_URL}"
        exit 1
    fi
    
    # Validate token
    if [ -z "${SONAR_TOKEN:-}" ]; then
        echo "❌ Error: SONAR_TOKEN environment variable is not set"
        exit 1
    fi
}

# Main SonarQube Analysis Function
run_sonar_analysis() {
    echo "🚀 Starting SonarQube Analysis for ${PROJECT_KEY}"
    
    sonar-scanner \
        -Dsonar.projectKey="${PROJECT_KEY}" \
        -Dsonar.sources=. \
        -Dsonar.host.url="${SONAR_URL}" \
        -Dsonar.token="${SONAR_TOKEN}" \
        -Dsonar.exclusions=**/node_modules/**,**/*.test.js \
        -Dsonar.javascript.coverage.reportPaths=coverage/lcov.info
}

# Execution
main() {
    pre_flight_checks
    run_sonar_analysis
    
    # Check SonarQube analysis result
    if [ $? -eq 0 ]; then
        echo "✅ SonarQube Analysis Completed Successfully"
    else
        echo "❌ SonarQube Analysis Failed"
        exit 1
    fi
}

main
