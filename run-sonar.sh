#!/bin/bash

# Exit immediately if a command exits with a non-zero status
set -e

# Run SonarQube analysis
sonar-scanner \
  -Dsonar.projectKey=CTAMA-Automation-DevSecOps \
  -Dsonar.sources=. \
  -Dsonar.host.url=http://16.16.118.25:9000 \
  -Dsonar.token="$SONAR_TOKEN"
