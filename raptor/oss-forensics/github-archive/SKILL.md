---
name: github-archive
description: Investigate GitHub security incidents using tamper-proof GitHub Archive data via BigQuery. Use when verifying repository activity claims, recovering deleted PRs/branches/tags/repos, attributing actions to actors, or reconstructing attack timelines. Provides immutable forensic evidence of all public GitHub events since 2011.
metadata:
  user-invocable: false
  version: 1.0
  author: mbrg
  tags:
  - github
  - gharchive
  - security
  - osint
  - forensics
  - git
---
# GitHub Archive

**Purpose**: Query immutable GitHub event history via BigQuery to obtain tamper-proof forensic evidence for security investigations.

## When to Use This Skill

- Investigating security incidents involving GitHub repositories
- Building threat actor attribution profiles
- Verifying claims about repository activity (media reports, incident reports)
- Reconstructing attack timelines with definitive timestamps
- Analyzing automation system compromises
- Detecting supply chain reconnaissance
- Cross-repository behavioral analysis
- Workflow execution verification (legitimate vs API abuse)
- Pattern-based anomaly detection
- **Recovering deleted content**: PRs, issues, branches, tags, entire repositories

GitHub Archive analysis should be your **FIRST step** in any GitHub-related security investigation. Start with the immutable record, then enrich with additional sources.

## Core Principles

**ALWAYS PREFER GitHub Archive as forensic evidence over**:
- Local git command outputs (`git log`, `git show`) - commits can be backdated/forged
- Unverified claims from articles or reports - require independent confirmation
- GitHub web interface screenshots - can be manipulated
- Single-source evidence - always cross-verify

**GitHub Archive IS your ground truth for**:
- Actor attribution (who performed actions)
- Timeline reconstruction (when events occurred)
- Event verification (what actually happened)
- Pattern analysis (behavioral fingerprinting)
- Cross-repository activity tracking
- **Deleted content recovery** (issues, PRs, tags, commit references remain in archive)
- **Repository deletion forensics** (commit SHAs persist even after repo deletion and history rewrites)

### What Persists After Deletion

**Deleted Issues & PRs**:
- Issue creation events (`IssuesEvent`) remain in archive
- Issue comments (`IssueCommentEvent`) remain accessible
- PR open/close/merge events (`PullRequestEvent`) persist
- **Forensic Value**: Recover deleted evidence of social engineering, reconnaissance, or coordination

**Deleted Tags & Branches**:
- `CreateEvent` records for tag/branch creation persist
- `DeleteEvent` records document when deletion occurred
- **Forensic Value**: Reconstruct attack staging infrastructure (e.g., malicious payload delivery tags)

**Deleted Repositories**:
- All `PushEvent` records to the repository remain queryable
- Commit SHAs are permanently recorded in archive
- Fork relationships (`ForkEvent`) survive deletion
- **Forensic Value**: Access commit metadata even after threat actor deletes evidence

**Deleted User Accounts**:
- All activity events remain attributed to deleted username
- Timeline reconstruction remains possible
- **Limitation**: Direct code access lost, but commit SHAs can be searched elsewhere

## Quick Start

**Investigate if user opened PRs in June 2025:**

```python
from google.cloud import bigquery
from google.oauth2 import service_account

# Initialize client (see Setup section for credentials)
credentials = service_account.Credentials.from_service_account_file(
    'path/to/credentials.json',
    scopes=['https://www.googleapis.com/auth/bigquery']
)
client = bigquery.Client(credentials=credentials, project=credentials.project_id)

# Query for PR events
query = """
SELECT
    created_at,
    repo.name,
    JSON_EXTRACT_SCALAR(payload, '$.pull_request.number') as pr_number,
    JSON_EXTRACT_SCALAR(payload, '$.pull_request.title') as pr_title,
    JSON_EXTRACT_SCALAR(payload, '$.action') as action
FROM `githubarchive.day.202506*`
WHERE
    actor.login = 'suspected-actor'
    AND repo.name = 'target/repository'
    AND type = 'PullRequestEvent'
ORDER BY created_at
"""

results = client.query(query)
for row in results:
    print(f"{row.created_at}: PR #{row.pr_number} - {row.action}")
    print(f"  Title: {row.pr_title}")
```

**Expected Output (if PR exists)**:
```
2025-06-15 14:23:11 UTC: PR #123 - opened
  Title: Add new feature
2025-06-20 09:45:22 UTC: PR #123 - closed
  Title: Add new feature
```

**Interpretation**:
- **No results** → Claim disproven (no PR activity found)
- **Results found** → Claim verified, proceed with detailed analysis

## Setup

### Prerequisites

1. **Google Cloud Project**:
   - Login to [Google Developer Console](https://console.cloud.google.com/)
   - Create a project and activate BigQuery API
   - Create a service account with `BigQuery User` role
   - Download JSON credentials file

2. **Install BigQuery Client**:
```bash
uv pip install google-cloud-bigquery google-auth
```

### Initialize Client

```python
from google.cloud import bigquery
from google.oauth2 import service_account

credentials = service_account.Credentials.from_service_account_file(
    'path/to/credentials.json',
    scopes=['https://www.googleapis.com/auth/bigquery']
)

client = bigquery.Client(
    credentials=credentials,
    project=credentials.project_id
)
```

**Free Tier**: Google provides 1 TB of data processed per month free.

## Deep Dive & References

To keep this skill lean, detailed documentation has been moved to reference files. Consult these only when necessary:

- **[Cost Management & Optimization](references/optimization.md)**: Essential techniques for reducing BigQuery scan costs, dry-run templates, and safe execution wrappers.
- **[Schema Reference](references/schema.md)**: Details on table organization (`githubarchive.day.YYYYMMDD`), payload structures, and event type JSON fields.
- **[Investigation Patterns](references/patterns.md)**: Advanced SQL queries for recovering deleted PRs, tracking force-pushes, and detecting direct API abuse vs workflow execution.

- **BigQuery Documentation**: https://cloud.google.com/bigquery/docs
- **BigQuery SQL Reference**: https://cloud.google.com/bigquery/docs/reference/standard-sql/query-syntax
- **Force Push Scanner Tool**: https://github.com/trufflesecurity/force-push-scanner
