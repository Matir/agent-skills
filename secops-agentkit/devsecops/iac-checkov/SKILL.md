---
name: iac-checkov
description: 'Infrastructure as Code (IaC) security scanning using Checkov with 750+ built-in policies for Terraform, CloudFormation, Kubernetes, Dockerfile, and ARM templates. Use when: (1) Scanning IaC files for security misconfigurations and compliance violations, (2) Validating cloud infrastructure against CIS, PCI-DSS, HIPAA, and SOC2 benchmarks, (3) Detecting secrets and hardcoded credentials in IaC, (4) Implementing policy-as-code in CI/CD pipelines, (5) Generating compliance reports with remediation guidance for cloud security posture management.

  '
metadata:
  version: 0.1.0
  maintainer: SirAppSec
  category: devsecops
  tags:
  - iac
  - checkov
  - terraform
  - kubernetes
  - cloudformation
  - compliance
  - policy-as-code
  - cloud-security
  frameworks:
  - PCI-DSS
  - HIPAA
  - SOC2
  - NIST
  - GDPR
  dependencies:
    python: '>=3.8'
    packages:
    - checkov
  references:
  - https://www.checkov.io/
  - https://github.com/bridgecrewio/checkov
  - https://docs.paloaltonetworks.com/prisma/prisma-cloud
---
# Infrastructure as Code Security with Checkov

## Overview

Checkov is a static code analysis tool that scans Infrastructure as Code (IaC) files for security misconfigurations
and compliance violations before deployment. With 750+ built-in policies, Checkov helps prevent cloud security issues
by detecting problems in Terraform, CloudFormation, Kubernetes, Dockerfiles, Helm charts, and ARM templates.

Checkov performs graph-based scanning to understand resource relationships and detect complex misconfigurations that
span multiple resources, making it more powerful than simple pattern matching.

## Quick Start

### Install Checkov

```bash
# Via uv
uv pip install checkov

# Via Homebrew (macOS)
brew install checkov

# Via Docker
docker pull bridgecrew/checkov
```

### Scan Terraform Directory

```bash
# Scan all Terraform files in directory
checkov -d ./terraform

# Scan specific file
checkov -f ./terraform/main.tf

# Scan with specific framework
checkov -d ./infrastructure --framework terraform
```

### Scan Kubernetes Manifests

```bash
# Scan Kubernetes YAML files
checkov -d ./k8s --framework kubernetes

# Scan Helm chart
checkov -d ./helm-chart --framework helm
```

### Scan CloudFormation Template

```bash
# Scan CloudFormation template
checkov -f ./cloudformation/template.yaml --framework cloudformation
```

## Core Workflow

### Step 1: Understand Scan Scope

Identify IaC files and frameworks to scan:

```bash
# Supported frameworks
checkov --list-frameworks

# Output:
# terraform, cloudformation, kubernetes, dockerfile, helm,
# serverless, arm, secrets, ansible, github_actions, gitlab_ci
```

**Scope Considerations:**
- Scan entire infrastructure directory for comprehensive coverage
- Focus on specific frameworks during initial adoption
- Exclude generated or vendor files
- Include both production and non-production configurations

### Step 2: Run Basic Scan

Execute Checkov with appropriate output format:

```bash
# CLI output (human-readable)
checkov -d ./terraform

# JSON output (for automation)
checkov -d ./terraform -o json

# Multiple output formats
checkov -d ./terraform -o cli -o json -o sarif

# Save output to file
checkov -d ./terraform -o json --output-file-path ./reports
```

**What Checkov Detects:**
- Security misconfigurations (unencrypted resources, public access)
- Compliance violations (CIS benchmarks, industry standards)
- Secrets and hardcoded credentials
- Missing security controls (logging, monitoring, encryption)
- Insecure network configurations
- Resource relationship issues (via graph analysis)

### Step 3: Filter and Prioritize Findings

Focus on critical issues first:

```bash
# Show only high severity issues
checkov -d ./terraform --check CKV_AWS_*

# Skip specific checks (false positives)
checkov -d ./terraform --skip-check CKV_AWS_8,CKV_AWS_21

# Check against specific compliance framework
checkov -d ./terraform --compact --framework terraform \
  --check CIS_AWS,CIS_AZURE

# Run only checks with specific severity
checkov -d ./terraform --check HIGH,CRITICAL
```

**Severity Levels:**
- **CRITICAL**: Immediate security risks (public S3 buckets, unencrypted databases)
- **HIGH**: Significant security concerns (missing MFA, weak encryption)
- **MEDIUM**: Important security best practices (missing tags, logging disabled)
- **LOW**: Recommendations and hardening (resource naming conventions)

### Step 4: Suppress False Positives

Use inline suppression for legitimate exceptions. For comprehensive suppression strategies, see **[references/suppression_guide.md](references/suppression_guide.md)**.

```hcl
# Terraform example
resource "aws_s3_bucket" "example" {
  # checkov:skip=CKV_AWS_18:This bucket is intentionally public for static website
  bucket = "my-public-website"
  acl    = "public-read"
}
```

### Step 5: Create Custom Policies

Define organization-specific policies in Python or YAML. See **[references/custom_policies.md](references/custom_policies.md)** for advanced policy development and examples.

Run with custom policies:

```bash
checkov -d ./terraform --external-checks-dir ./custom_checks
```

### Step 6: Generate Compliance Reports

Create reports for audit and compliance (CLI, JSON, JUnit XML, SARIF, CycloneDX). Map findings to compliance frameworks using **[references/compliance_mapping.md](references/compliance_mapping.md)**.

```bash
# Generate comprehensive report
checkov -d ./terraform \
  -o cli -o json -o junitxml \
  --output-file-path ./compliance-reports \
  --repo-id my-infrastructure \
  --branch main
```

## CI/CD Integration

Integrate Checkov into your development lifecycle using GitHub Actions, GitLab CI, Jenkins, or pre-commit hooks. See **[references/ci_cd.md](references/ci_cd.md)** for complete templates and setup instructions.

## Framework-Specific Workflows

Checkov supports multiple IaC frameworks with specific scanning requirements. See **[references/frameworks.md](references/frameworks.md)** for detailed workflows on:
- **Terraform**: Variable files, external modules, and plan scanning.
- **Kubernetes**: Manifests, Helm charts, and Kustomize.
- **CloudFormation**: Templates and AWS SAM.
- **Dockerfile**: Security best practices for container images.
- **Baseline & Drift Detection**: Establish baselines and track new security debt.

## Security Considerations

- **Policy Suppression Governance**: Require security team approval for suppressing CRITICAL/HIGH findings.
- **CI/CD Failure Thresholds**: Configure `--hard-fail-on` for blocking deployments.
- **Secrets Management**: Never commit secrets; use secret managers.
- **Audit Logging**: Log all scan results and policy suppressions for compliance audits.

## Bundled Resources

### Scripts (`scripts/`)

- `checkov_scan.py` - Comprehensive scanning script with multiple frameworks and output formats
- `checkov_terraform_scan.sh` - Terraform-specific scanning with variable file support
- `checkov_k8s_scan.sh` - Kubernetes manifest scanning with cluster comparison
- `checkov_baseline_create.sh` - Baseline creation and drift detection workflow
- `checkov_compliance_report.py` - Generate compliance reports (CIS, PCI-DSS, HIPAA, SOC2)
- `ci_integration.sh` - CI/CD integration examples for multiple platforms

### References (`references/`)

- **[compliance_mapping.md](references/compliance_mapping.md)** - Mapping of Checkov checks to CIS, PCI-DSS, HIPAA, SOC2, NIST
- **[custom_policies.md](references/custom_policies.md)** - Guide for writing custom Python and YAML policies
- **[suppression_guide.md](references/suppression_guide.md)** - Best practices for suppressing false positives
- **[ci_cd.md](references/ci_cd.md)** - CI/CD integration examples for GitHub, GitLab, and Jenkins
- **[frameworks.md](references/frameworks.md)** - Detailed workflows for Terraform, K8s, CloudFormation, and Docker
- **[patterns.md](references/patterns.md)** - Advanced patterns and troubleshooting guide

### Assets (`assets/`)

- `checkov_config.yaml` - Checkov configuration file template
- `github_actions.yml` - Complete GitHub Actions workflow
- `gitlab_ci.yml` - Complete GitLab CI pipeline
- `jenkins_pipeline.groovy` - Jenkins pipeline template
- `pre_commit_config.yaml` - Pre-commit hook configuration
- `custom_policy_template.py` - Template for custom Python policies
- `policy_metadata.yaml` - Policy metadata for organization-specific policies

## Advanced Usage & Troubleshooting

For progressive compliance adoption, multi-framework infrastructure patterns, and troubleshooting common issues, see **[references/patterns.md](references/patterns.md)**.
