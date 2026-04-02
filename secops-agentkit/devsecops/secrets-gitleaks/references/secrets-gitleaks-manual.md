# Secrets Detection with Gitleaks Manual

## Core Workflows

### 1. Repository Scanning
Scan existing repositories to identify exposed secrets:
```bash
# Full repository scan with verbose output
gitleaks detect -v --source /path/to/repo

# Scan with custom configuration
gitleaks detect --config .gitleaks.toml -v

# Generate JSON report for further analysis
gitleaks detect --report-path findings.json --report-format json

# Generate SARIF report for GitHub/GitLab integration
gitleaks detect --report-path findings.sarif --report-format sarif
```

### 2. Pre-Commit Hook Protection
Prevent secrets from being committed:
```bash
# Install pre-commit hook (run in repository root)
cat << 'EOF' > .git/hooks/pre-commit
#!/bin/sh
gitleaks protect --verbose --redact --staged
EOF

chmod +x .git/hooks/pre-commit
```

### 3. CI/CD Pipeline Integration
#### GitHub Actions
```yaml
name: gitleaks
on: [push, pull_request]
jobs:
  scan:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
        with:
          fetch-depth: 0
      - uses: gitleaks/gitleaks-action@v2
        env:
          GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
```

#### GitLab CI
```yaml
gitleaks:
  image: zricethezav/gitleaks:latest
  stage: test
  script:
    - gitleaks detect --report-path gitleaks.json --report-format json --verbose
  artifacts:
    paths:
      - gitleaks.json
    when: always
  allow_failure: false
```

### 4. Baseline and Incremental Scanning
```bash
# Create initial baseline
gitleaks detect --report-path baseline.json --report-format json

# Subsequent scans detect only new secrets
gitleaks detect --baseline-path baseline.json --report-path new-findings.json -v
```

### 5. Configuration Customization
Create custom `.gitleaks.toml` configuration:
```toml
title = "Custom Gitleaks Configuration"

[extend]
useDefault = true

[[rules]]
id = "custom-api-key"
description = "Custom API Key Pattern"
regex = '''(?i)(custom_api_key|custom_secret)[\s]*[=:][\s]*['"][a-zA-Z0-9]{32,}['"]'''
tags = ["api-key", "custom"]

[allowlist]
description = "Global allowlist"
paths = [
  '''\.md$''',           # Ignore markdown files
  '''test/fixtures/''',  # Ignore test fixtures
]
stopwords = [
  '''EXAMPLE''',         # Ignore example keys
  '''PLACEHOLDER''',
]
```

## Security Considerations
- **Secret Redaction**: Always use `--redact` flag in logs and reports to prevent accidental secret exposure.
- **Report Security**: Gitleaks reports contain detected secrets - treat as confidential, encrypt at rest.
- **Git History**: Detected secrets in git history require complete removal using tools like `git filter-repo` or `BFG Repo-Cleaner`.
- **Credential Rotation**: All exposed secrets must be rotated immediately, even if removed from code.
- **CI/CD Permissions**: Gitleaks scans require read access to repository content and git history.
- **Audit Logging**: Log scan execution timestamps, scope, findings, and remediation actions for compliance.

## Common Patterns

### Pattern 1: Initial Repository Audit
1. Clone repository with full history: `git clone --mirror https://github.com/org/repo.git audit-repo`
2. Run comprehensive scan: `gitleaks detect --report-path audit-report.json --report-format json -v`
3. Generate human-readable report: `./scripts/scan_and_report.py --input audit-report.json --format markdown --output audit-report.md`
4. Review findings and classify false positives.
5. Create baseline for future scans: `cp audit-report.json baseline.json`

### Pattern 2: Developer Workstation Setup
1. Install gitleaks locally.
2. Install pre-commit hook using `./scripts/install_precommit.sh`.
3. Test hook with dummy commit containing an API key pattern.
4. Clean up test.

### Pattern 3: CI/CD Pipeline with Baseline
1. Check if baseline exists.
2. If yes, run incremental scan; if no, create baseline.
3. Generate SARIF for GitHub Security tab if findings are new.

## Troubleshooting

### Issue: Too Many False Positives
- **Solution**: Review findings to identify patterns, then add to allowlist in `.gitleaks.toml` under `paths`, `stopwords`, or `commits`.

### Issue: Performance Issues on Large Repositories
- **Solution**: Limit git history using `--log-opts` (e.g., `--since=2024-01-01`), scan specific branches, use baseline approach, or use a shallow clone.

### Issue: Pre-commit Hook Blocking Valid Commits
- **Solution**: Add inline comment `# gitleaks:allow`, update allowlist, use `--redact` for review, or use `--no-verify` (with caution).

### Issue: Secrets Found in Git History
- **Solution**: Rotate credentials immediately. Use `git filter-repo` or BFG to rewrite history and force-push.

## Advanced Configuration

### Entropy-Based Detection
```toml
[[rules]]
id = "high-entropy-strings"
description = "High entropy strings that may be secrets"
regex = '''[a-zA-Z0-9]{32,}'''
entropy = 4.5
secretGroup = 0
```

### Composite Rules (v8.28.0+)
```toml
[[rules]]
id = "multi-line-secret"
description = "API key with usage context"
regex = '''api_key[\s]*='''

[[rules.composite]]
pattern = '''initialize_client'''
location = "line"
distance = 5
```

## References
- [Gitleaks Official Documentation](https://github.com/gitleaks/gitleaks)
- [OWASP A07:2021 - Identification and Authentication Failures](https://owasp.org/Top10/A07_2021-Identification_and_Authentication_Failures/)
- [CWE-798: Use of Hard-coded Credentials](https://cwe.mitre.org/data/definitions/798.html)
