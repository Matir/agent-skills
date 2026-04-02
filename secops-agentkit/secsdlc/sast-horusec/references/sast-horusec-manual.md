# Horusec Manual

## Detailed Workflows

### Git History Secret Scanning
1. **Run scan**: `horusec start -p . --enable-git-history-analysis`
2. **Review**: Identify exposed credentials.
3. **Remediation**: Rotate compromised keys immediately; remove from history using BFG or git-filter-branch if necessary.

### False Positive Management
Create `.horusec/config.json` with ignore rules:
```json
{
  "horusecCliRiskAcceptHashes": ["hash1", "hash2"],
  "horusecCliFilesOrPathsToIgnore": ["**/test/**", "**/vendor/**"]
}
```

## Configuration Reference (.horusec/config.json)
| Key | Description |
|-----|-------------|
| `horusecCliJsonOutputFilePath` | Path for JSON report |
| `horusecCliSeverityThreshold` | Minimum severity to report |
| `horusecCliReturnErrorIfFoundVulnerability` | Exit non-zero if found |
| `horusecCliTimeoutInSecondsAnalysis` | Scan timeout |

## Common Patterns

### Fail Build on High Severity
```bash
horusec start -p . \
  --return-error-if-found-vulnerability \
  --severity-threshold="HIGH"
```

### Monorepo Scanning
```bash
for project in service1 service2; do
  horusec start -p ./$project -o json -O horusec-$project.json
done
```

## Report Analysis
```bash
# Extract high-severity findings
cat report.json | jq '.analysisVulnerabilities[] | select(.severity == "HIGH")'

# Count vulnerabilities by language
cat report.json | jq '.analysisVulnerabilities | group_by(.language) | map({language: .[0].language, count: length})'
```

## Troubleshooting
- **Docker Socket**: `sudo chmod 666 /var/run/docker.sock` if permission denied.
- **Timeouts**: Increase `horusecCliTimeoutInSecondsAnalysis` in config for large repos.
- **Missing Languages**: Run `horusec version --check-for-updates` and pull latest images.
