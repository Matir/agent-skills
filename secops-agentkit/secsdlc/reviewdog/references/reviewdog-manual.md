# Reviewdog Manual

## Detailed CI/CD Integration

### GitHub Actions
```yaml
- name: Run reviewdog
  uses: reviewdog/action-setup@v1
- name: Security scan with reviewdog
  env:
    REVIEWDOG_GITHUB_API_TOKEN: ${{ secrets.GITHUB_TOKEN }}
  run: |
    bandit -r . -f json | reviewdog -f=bandit -reporter=github-pr-review
```

### GitLab CI
```yaml
security_review:
  stage: test
  script:
    - uv pip install bandit reviewdog
    - bandit -r . -f json |
        reviewdog -f=bandit
                 -reporter=gitlab-mr-discussion
                 -filter-mode=diff_context
  only:
    - merge_requests
```

## Advanced Configuration

### Custom .reviewdog.yml
```yaml
runner:
  bandit:
    cmd: bandit -r . -f json
    format: bandit
    name: Python Security
    level: warning
```

### Behavior Flags
- `-filter-mode=added`: Only show issues in added lines.
- `-filter-mode=diff_context`: Show issues in changed lines and surrounding context.
- `-fail-on-error`: Exit with non-zero code if findings exist.
- `-level=warning`: Set severity threshold.

## Common Patterns

### Multi-Tool Aggregation
```bash
bandit -r . -f json | reviewdog -f=bandit -name="Python SAST" -reporter=github-pr-review &
gitleaks detect --report-format json | reviewdog -f=gitleaks -name="Secret Scan" -reporter=github-pr-review &
wait
```

### Custom Security Rules
```bash
grep -nH -R "eval(" . --include="*.py" | \
  reviewdog -f=grep -name="Dangerous Functions" -reporter=github-pr-review
```

## Troubleshooting
- **No comments posted**: Check if `REVIEWDOG_GITHUB_API_TOKEN` is set and has `repo` or `public_repo` scope.
- **False positives**: Use `-filter-mode=added` or configure suppressions in `.reviewdog.yml`.
- **Performance**: Run on changed files only using `filter-mode=diff_context`.
