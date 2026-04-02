### Common Investigation Patterns: Cost Comparison

| Investigation Type | Expensive Approach | Cost | Optimized Approach | Cost |
|-------------------|-------------------|------|-------------------|------|
| **Verify user opened PR in June** | `SELECT * FROM githubarchive.day.202506*` | ~$5.00 | `SELECT created_at, repo.name, payload FROM githubarchive.day.202506* WHERE actor.login='user' AND type='PullRequestEvent'` | ~$0.30 |
| **Find all actor activity in 2025** | `SELECT * FROM githubarchive.day.2025*` | ~$60.00 | `SELECT type, created_at, repo.name FROM githubarchive.month.2025*` | ~$5.00 |
| **Recover deleted PR content** | `SELECT * FROM githubarchive.day.20250615` | ~$0.20 | `SELECT created_at, payload FROM githubarchive.day.20250615 WHERE repo.name='target/repo' AND type='PullRequestEvent'` | ~$0.02 |
| **Cross-repo behavioral analysis** | `SELECT * FROM githubarchive.day.202506*` | ~$5.00 | Start with `githubarchive.month.202506`, identify specific repos, then query daily tables | ~$0.50 |

### Development vs Production Queries

**During investigation/development**:
1. Start with single-day queries to test pattern: `githubarchive.day.20250615`
2. Verify query returns expected results
3. Expand to date range only after validation: `githubarchive.day.202506*`

**Production checklist**:
- [ ] Used specific column names (no `SELECT *`)
- [ ] Included narrowest possible date range
- [ ] Added `repo.name` filter if investigating specific repository
- [ ] Ran dry run and verified cost < $1.00 (or got user approval)
- [ ] Set `maximum_bytes_billed` in query config

### Cost Monitoring

Track your BigQuery spending with this query:

```sql
-- View GitHub Archive query costs (last 7 days)
SELECT
    DATE(creation_time) as query_date,
    COUNT(*) as queries,
    ROUND(SUM(total_bytes_billed) / (1024*1024*1024), 2) as total_gb,
    ROUND(SUM(total_bytes_billed) / (1024*1024*1024*1024) * 6.25, 2) as cost_usd
FROM `region-us`.INFORMATION_SCHEMA.JOBS_BY_PROJECT
WHERE
    creation_time >= TIMESTAMP_SUB(CURRENT_TIMESTAMP(), INTERVAL 7 DAY)
    AND job_type = 'QUERY'
    AND REGEXP_CONTAINS(query, r'githubarchive\.')
GROUP BY query_date
ORDER BY query_date DESC
```

## Schema Reference

### Table Organization

**Dataset**: `githubarchive`

**Table Patterns**:
- **Daily tables**: `githubarchive.day.YYYYMMDD` (e.g., `githubarchive.day.20250713`)
- **Monthly tables**: `githubarchive.month.YYYYMM` (e.g., `githubarchive.month.202507`)
- **Yearly tables**: `githubarchive.year.YYYY` (e.g., `githubarchive.year.2025`)

**Wildcard Patterns**:
- All days in June 2025: `githubarchive.day.202506*`
- All months in 2025: `githubarchive.month.2025*`
- All data in 2025: `githubarchive.year.2025*`

**Data Availability**: February 12, 2011 to present (updated hourly)

### Schema Structure

**Top-Level Fields**:
```sql
type              -- Event type (PushEvent, IssuesEvent, etc.)
created_at        -- Timestamp when event occurred (UTC)
actor.login       -- GitHub username who performed the action
actor.id          -- GitHub user ID
repo.name         -- Repository name (org/repo format)
repo.id           -- Repository ID
org.login         -- Organization login (if applicable)
org.id            -- Organization ID
payload           -- JSON string with event-specific data
```

**Payload Field**: JSON-encoded string containing event-specific details. Must be parsed with `JSON_EXTRACT_SCALAR()` in SQL or `json.loads()` in Python.

### Event Types Reference

#### Repository Events

**PushEvent** - Commits pushed to a repository
```sql
-- Payload fields:
JSON_EXTRACT_SCALAR(payload, '$.ref')        -- Branch (refs/heads/master)
JSON_EXTRACT_SCALAR(payload, '$.before')     -- SHA before push
JSON_EXTRACT_SCALAR(payload, '$.after')      -- SHA after push
JSON_EXTRACT_SCALAR(payload, '$.size')       -- Number of commits
-- payload.commits[] contains array of commit objects with sha, message, author
```

**PullRequestEvent** - Pull request opened, closed, merged
```sql
-- Payload fields:
JSON_EXTRACT_SCALAR(payload, '$.action')              -- opened, closed, merged
JSON_EXTRACT_SCALAR(payload, '$.pull_request.number')
JSON_EXTRACT_SCALAR(payload, '$.pull_request.title')
JSON_EXTRACT_SCALAR(payload, '$.pull_request.merged') -- true/false
```

**CreateEvent** - Branch or tag created
```sql
-- Payload fields:
JSON_EXTRACT_SCALAR(payload, '$.ref_type')   -- branch, tag, repository
JSON_EXTRACT_SCALAR(payload, '$.ref')        -- Name of branch/tag
```

**DeleteEvent** - Branch or tag deleted
```sql
-- Payload fields:
JSON_EXTRACT_SCALAR(payload, '$.ref_type')   -- branch or tag
JSON_EXTRACT_SCALAR(payload, '$.ref')        -- Name of deleted ref
```

**ForkEvent** - Repository forked
```sql
-- Payload fields:
JSON_EXTRACT_SCALAR(payload, '$.forkee.full_name')  -- New fork name
```

#### Automation & CI/CD Events

**WorkflowRunEvent** - GitHub Actions workflow run status changes
```sql
-- Payload fields:
JSON_EXTRACT_SCALAR(payload, '$.action')               -- requested, completed
JSON_EXTRACT_SCALAR(payload, '$.workflow_run.name')
JSON_EXTRACT_SCALAR(payload, '$.workflow_run.path')    -- .github/workflows/file.yml
JSON_EXTRACT_SCALAR(payload, '$.workflow_run.status')  -- queued, in_progress, completed
JSON_EXTRACT_SCALAR(payload, '$.workflow_run.conclusion') -- success, failure, cancelled
JSON_EXTRACT_SCALAR(payload, '$.workflow_run.head_sha')
JSON_EXTRACT_SCALAR(payload, '$.workflow_run.head_branch')
```

**WorkflowJobEvent** - Individual job within workflow
**CheckRunEvent** - Check run status (CI systems)
**CheckSuiteEvent** - Check suite for commits

#### Issue & Discussion Events

**IssuesEvent** - Issue opened, closed, edited
```sql
-- Payload fields:
JSON_EXTRACT_SCALAR(payload, '$.action')        -- opened, closed, reopened
JSON_EXTRACT_SCALAR(payload, '$.issue.number')
JSON_EXTRACT_SCALAR(payload, '$.issue.title')
JSON_EXTRACT_SCALAR(payload, '$.issue.body')
```

**IssueCommentEvent** - Comment on issue or pull request
**PullRequestReviewEvent** - PR review submitted
**PullRequestReviewCommentEvent** - Comment on PR diff

#### Other Events

**WatchEvent** - Repository starred
**ReleaseEvent** - Release published
**MemberEvent** - Collaborator added/removed
**PublicEvent** - Repository made public

## Investigation Patterns

### Deleted Issue & PR Text Recovery

**Scenario**: Issue or PR was deleted from GitHub (by author, maintainer, or moderation) but you need to recover the original title and body text for investigation, compliance, or historical reference.

**Step 1: Recover Deleted Issue Content**
```sql
SELECT
    created_at,
    actor.login,
    JSON_EXTRACT_SCALAR(payload, '$.action') as action,
    JSON_EXTRACT_SCALAR(payload, '$.issue.number') as issue_number,
    JSON_EXTRACT_SCALAR(payload, '$.issue.title') as title,
    JSON_EXTRACT_SCALAR(payload, '$.issue.body') as body
FROM `githubarchive.day.20250713`
WHERE
    repo.name = 'aws/aws-toolkit-vscode'
    AND actor.login = 'lkmanka58'
    AND type = 'IssuesEvent'
ORDER BY created_at
```

**Step 2: Recover Deleted PR Description**
```sql
SELECT
    created_at,
    actor.login,
    JSON_EXTRACT_SCALAR(payload, '$.action') as action,
    JSON_EXTRACT_SCALAR(payload, '$.pull_request.number') as pr_number,
    JSON_EXTRACT_SCALAR(payload, '$.pull_request.title') as title,
    JSON_EXTRACT_SCALAR(payload, '$.pull_request.body') as body,
    JSON_EXTRACT_SCALAR(payload, '$.pull_request.merged') as merged
FROM `githubarchive.day.202506*`
WHERE
    repo.name = 'target/repository'
    AND actor.login = 'target-user'
    AND type = 'PullRequestEvent'
ORDER BY created_at
```

**Evidence Recovery**:
- **Issue/PR Title**: Full title text preserved in `$.issue.title` or `$.pull_request.title`
- **Issue/PR Body**: Complete body text preserved in `$.issue.body` or `$.pull_request.body`
- **Comments**: `IssueCommentEvent` preserves comment text in `$.comment.body`
- **Actor Attribution**: `actor.login` identifies who created the content
- **Timestamps**: Exact creation time in `created_at`

**Real Example**: Amazon Q investigation recovered deleted issue content from `lkmanka58`. The issue titled "aws amazon donkey aaaaaaiii aaaaaaaiii" contained a rant calling Amazon Q "deceptive" and "scripted fakery". The full issue body was preserved in GitHub Archive despite deletion from github.com, providing context for the timeline reconstruction.

### Deleted PRs

**Scenario**: Media claims attacker submitted a PR in "late June" containing malicious code, but PR is now deleted and cannot be found on github.com.

**Step 1: Query Archive**
```python
query = """
SELECT
    type,
    created_at,
    repo.name,
    JSON_EXTRACT_SCALAR(payload, '$.action') as action,
    JSON_EXTRACT_SCALAR(payload, '$.pull_request.number') as pr_number,
    JSON_EXTRACT_SCALAR(payload, '$.pull_request.title') as pr_title
FROM `githubarchive.day.202506*`
WHERE
    actor.login = 'suspected-actor'
    AND repo.name = 'target/repository'
    AND type = 'PullRequestEvent'
ORDER BY created_at
"""

results = client.query(query)
pr_events = list(results)
```

**Step 2: Analyze Results**
```python
if not pr_events:
    print("❌ CLAIM DISPROVEN: No PR activity found in June 2025")
else:
    for event in pr_events:
        print(f"✓ VERIFIED: PR #{event.pr_number} {event.action} on {event.created_at}")
