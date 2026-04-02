# GitHub Commit Recovery Manual

## Detailed Access Methods

### Method 1: Direct Web & Raw Access
GitHub serves force-pushed or "deleted" commits at predictable URLs.
- **Commit View**: `https://github.com/{owner}/{repo}/commit/{sha}`
- **Patch**: `https://github.com/{owner}/{repo}/commit/{sha}.patch`
- **Diff**: `https://github.com/{owner}/{repo}/commit/{sha}.diff`

### Method 2: REST API
Retrieve structured metadata and file changes.
```bash
curl -H "Authorization: Bearer $GITHUB_TOKEN" \
     https://api.github.com/repos/{owner}/{repo}/commits/{sha}
```

### Method 3: Git Fetch
Fetch specific "deleted" commits even if they don't belong to any branch.
```bash
git clone --filter=blob:none --no-checkout https://github.com/org/repo.git
cd repo
git fetch origin <SHA>
git show FETCH_HEAD
```

## Investigation Patterns

### Batch Patch Download
```python
import requests
def download_patch(repo, sha):
    url = f"https://github.com/{repo}/commit/{sha}.patch"
    return requests.get(url).text
```

### Verifying Authorship
Check for discrepancies between `author` (who wrote it) and `committer` (who pushed it).
```bash
curl -s https://api.github.com/repos/org/repo/commits/SHA | \
  jq '{author: .commit.author, committer: .commit.committer, verified: .commit.verification.verified}'
```

## Secret Categories & File Targets
- **PATs & AWS Keys**: Most critical findings.
- **Target Files**: `.env`, `config.js`, `docker-compose.yml`, `hardhat.config.js`.

## Troubleshooting
- **403 Forbidden**: Verify token scopes or check rate limits (5,000/hr auth).
- **404 Not Found**: SHA may be incomplete (use 7+ chars) or repo was deleted.
- **Fetch fails**: Very old dangling commits may be garbage collected (rare).
