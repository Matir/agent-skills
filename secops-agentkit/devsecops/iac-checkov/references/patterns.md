# Checkov Common Patterns and Troubleshooting

Advanced patterns and solutions to common issues.

## Common Patterns

### Pattern 1: Progressive Compliance Adoption

Gradually increase security posture:

```bash
# Phase 1: Scan without failing (awareness)
checkov -d ./terraform --soft-fail

# Phase 2: Fail only on CRITICAL issues
checkov -d ./terraform --hard-fail-on CRITICAL

# Phase 3: Fail on CRITICAL and HIGH
checkov -d ./terraform --hard-fail-on CRITICAL,HIGH

# Phase 4: Full enforcement with baseline
checkov -d ./terraform --baseline .checkov.baseline
```

### Pattern 2: Multi-Framework Infrastructure

Scan complete infrastructure stack:

```bash
# Use bundled script for comprehensive scanning
python3 scripts/checkov_scan.py \
  --infrastructure-dir ./infrastructure \
  --frameworks terraform,kubernetes,dockerfile \
  --output-dir ./security-reports \
  --compliance CIS,PCI-DSS
```

### Pattern 3: Policy-as-Code Repository

Maintain centralized policy repository:

```
policies/
├── custom_checks/
│   ├── aws/
│   │   ├── require_encryption.py
│   │   └── require_tags.py
│   ├── kubernetes/
│   │   └── require_psp.py
├── .checkov.yaml          # Global config
└── suppression_list.txt   # Approved suppressions
```

### Pattern 4: Compliance-Driven Scanning

Focus on specific compliance requirements:

```bash
# CIS AWS Foundations Benchmark
checkov -d ./terraform --check CIS_AWS

# PCI-DSS compliance
checkov -d ./terraform --framework terraform \
  --check CKV_AWS_19,CKV_AWS_21,CKV_AWS_61 \
  -o json --output-file-path ./pci-dss-report

# HIPAA compliance
checkov -d ./terraform --framework terraform \
  --compact --check CKV_AWS_17,CKV_AWS_19,CKV_AWS_61,CKV_AWS_93
```

## Troubleshooting

### Issue: Too Many Findings Overwhelming Team

**Solution**: Use progressive adoption with baselines:

```bash
# Create baseline with current state
checkov -d ./terraform --create-baseline

# Only fail on new issues
checkov -d ./terraform --baseline .checkov.baseline --soft-fail-on LOW,MEDIUM
```

### Issue: False Positives for Legitimate Use Cases

**Solution**: Use inline suppressions with justification:

```hcl
# Provide clear business justification
resource "aws_security_group" "allow_office" {
  # checkov:skip=CKV_AWS_23:Office IP range needs SSH access for developers
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["203.0.113.0/24"]  # Office IP range
  }
}
```

### Issue: Scan Takes Too Long

**Solution**: Optimize scan scope:

```bash
# Skip unnecessary paths
checkov -d ./terraform \
  --skip-path .terraform/ \
  --skip-path modules/vendor/ \
  --skip-framework secrets

# Use compact output
checkov -d ./terraform --compact --quiet
```

### Issue: Custom Policies Not Loading

**Solution**: Verify policy structure and loading:

```bash
# Check policy syntax
python3 custom_checks/my_policy.py

# Ensure proper directory structure
checkov -d ./terraform \
  --external-checks-dir ./custom_checks \
  --list

# Debug with verbose output
checkov -d ./terraform --external-checks-dir ./custom_checks -v
```

### Issue: Integration with Private Terraform Modules

**Solution**: Configure module access:

```bash
# Set up Terraform credentials
export TF_TOKEN_app_terraform_io="your-token"

# Download external modules
checkov -d ./terraform --download-external-modules true

# Or scan after terraform init
cd ./terraform && terraform init
checkov -d .
```
