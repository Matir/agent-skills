# Checkov CI/CD Integration Guide

Complete guide for integrating Checkov into various CI/CD pipelines.

## GitHub Actions

Add Checkov scanning to pull request checks:

```yaml
# .github/workflows/checkov.yml
name: Checkov IaC Security Scan
on: [push, pull_request]

jobs:
  checkov-scan:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3

      - name: Run Checkov
        uses: bridgecrewio/checkov-action@master
        with:
          directory: infrastructure/
          framework: terraform
          output_format: sarif
          output_file_path: checkov-results.sarif
          soft_fail: false

      - name: Upload SARIF Report
        if: always()
        uses: github/codeql-action/upload-sarif@v2
        with:
          sarif_file: checkov-results.sarif
```

## Pre-Commit Hook

Prevent committing insecure IaC:

```yaml
# .pre-commit-config.yaml
repos:
  - repo: https://github.com/bridgecrewio/checkov
    rev: 2.5.0
    hooks:
      - id: checkov
        args: [--soft-fail]
        files: \.(tf|yaml|yml|json)$
```

Install pre-commit hooks:

```bash
uv pip install pre-commit
pre-commit install
```

## GitLab CI

```yaml
# .gitlab-ci.yml
checkov_scan:
  image: bridgecrew/checkov:latest
  stage: security
  script:
    - checkov -d ./terraform -o json -o junitxml
      --output-file-path $CI_PROJECT_DIR/checkov-report
  artifacts:
    reports:
      junit: checkov-report/results_junitxml.xml
    paths:
      - checkov-report/
    when: always
```

## Jenkins Pipeline

```groovy
// Jenkinsfile
pipeline {
    agent any
    stages {
        stage('Checkov Scan') {
            steps {
                sh 'uv pip install checkov'
                sh '''
                    checkov -d ./terraform \
                      -o cli -o junitxml \
                      --output-file-path ./reports
                '''
            }
        }
    }
    post {
        always {
            junit 'reports/results_junitxml.xml'
        }
    }
}
```

See `assets/` directory for complete CI/CD templates.
