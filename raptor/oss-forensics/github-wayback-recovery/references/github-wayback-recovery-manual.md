# GitHub Wayback Recovery Manual

## GitHub URL Patterns
Understanding GitHub's URL structure is essential for constructing archive queries.

| Content Type | URL Pattern |
|--------------|-------------|
| Homepage | `github.com/{owner}/{repo}` |
| Commits list | `github.com/{owner}/{repo}/commits/{branch}` |
| Individual commit | `github.com/{owner}/{repo}/commit/{full-sha}` |
| Fork network | `github.com/{owner}/{repo}/network/members` |
| File view | `github.com/{owner}/{repo}/blob/{branch}/{path/to/file}` |
| Directory view | `github.com/{owner}/{repo}/tree/{branch}/{directory}` |
| Raw file | `raw.githubusercontent.com/{owner}/{repo}/{branch}/{path}` |
| Pull request | `github.com/{owner}/{repo}/pull/{number}` |
| Issue | `github.com/{owner}/{repo}/issues/{number}` |
| Wiki page | `github.com/{owner}/{repo}/wiki/{page-name}` |
| Release | `github.com/{owner}/{repo}/releases/tag/{tag-name}` |

## CDX API Reference
The Capture Index (CDX) API provides structured search across all archived URLs.

```
https://web.archive.org/cdx/search/cdx?url={URL}&output=json
```

### Essential Parameters
| Parameter | Effect | Example |
|-----------|--------|---------|
| `matchType=prefix` | All URLs starting with path | All repo content |
| `url=.../*` | Wildcard (same as prefix) | `github.com/owner/repo/*` |
| `filter=statuscode:200` | Only successful captures | Skip redirects/errors |
| `collapse=urlkey` | Unique URLs only | List all archived pages |

### Query Examples
**Find all archived pages under a repository**:
```bash
curl -s "https://web.archive.org/cdx/search/cdx?url=github.com/facebook/react/*&matchType=prefix&output=json&collapse=urlkey"
```

## Investigation Patterns

### Recovering Deleted File Contents
1. **Search for blob URLs**: `curl -s "https://web.archive.org/cdx/search/cdx?url=github.com/owner/repo/blob/*/README.md&output=json"`
2. **Construct archive URL**: `https://web.archive.org/web/{TIMESTAMP}/https://github.com/owner/repo/blob/main/README.md`
3. **Extract content**: Use `waybackpack` or manual download.

### Finding Forks of Deleted Repositories
1. **Search for archived fork network page**: `curl -s "https://web.archive.org/cdx/search/cdx?url=github.com/owner/repo/network/members&output=json"`
2. **Extract fork usernames**: Parse the archived HTML for `href="/username/repo"`.
3. **Verify existence**: `curl -s -o /dev/null -w "%{http_code}" https://github.com/forker/repo`

## Python Implementation
```python
import requests
class WaybackGitHubRecovery:
    CDX_API = "https://web.archive.org/cdx/search/cdx"
    def search_cdx(self, url: str, match_type: str = "prefix"):
        params = {"url": url, "output": "json", "matchType": match_type, "filter": "statuscode:200"}
        resp = requests.get(self.CDX_API, params=params)
        return resp.json()
```

## Troubleshooting
- **No snapshots**: Repository may be too new, obscure, or always private.
- **Broken layout**: Common for JS-heavy pages; use "View Source" to extract text.
- **Rate limiting**: Archive.org limit is ~100 requests/minute.
