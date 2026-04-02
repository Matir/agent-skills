# Checkov Manual

## Installation

```bash
# Via uv
uv pip install checkov

# Via Homebrew (macOS)
brew install checkov

# Via Docker
docker pull bridgecrew/checkov
```

## Detailed Core Workflow

### Step 1: Understand Scan Scope
Identify IaC files and frameworks to scan:
```bash
checkov --list-frameworks
```

**Scope Considerations:**
- Scan entire infrastructure directory for comprehensive coverage
- Focus on specific frameworks during initial adoption
- Exclude generated or vendor files
- Include both production and non-production configurations

### Step 2: Run Basic Scan
Execute Checkov with appropriate output format:
```bash
# Save output to file
checkov -d ./terraform -o json --output-file-path ./reports
```

### Step 3: Filter and Prioritize Findings
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

### Step 4: Suppress False Positives
See [suppression_guide.md](suppression_guide.md) for strategy.
```hcl
# Terraform example
resource "aws_s3_bucket" "example" {
  # checkov:skip=CKV_AWS_18:This bucket is intentionally public for static website
  bucket = "my-public-website"
  acl    = "public-read"
}
```

### Step 5: Create Custom Policies
See [custom_policies.md](custom_policies.md) for advanced policy development.
```bash
checkov -d ./terraform --external-checks-dir ./custom_checks
```

### Step 6: Generate Compliance Reports
Map findings to compliance frameworks using [compliance_mapping.md](compliance_mapping.md).

## Framework-Specific Workflows
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
- **[compliance_mapping.md](compliance_mapping.md)** - Mapping of Checkov checks to CIS, PCI-DSS, HIPAA, SOC2, NIST
- **[custom_policies.md](custom_policies.md)** - Guide for writing custom Python and YAML policies
- **[suppression_guide.md](suppression_guide.md)** - Best practices for suppressing false positives
- **[ci_cd.md](ci_cd.md)** - CI/CD integration examples for GitHub, GitLab, and Jenkins
- **[frameworks.md](frameworks.md)** - Detailed workflows for Terraform, K8s, CloudFormation, and Docker
- **[patterns.md](patterns.md)** - Advanced patterns and troubleshooting guide
