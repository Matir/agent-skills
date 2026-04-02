        print(f"  Title: {event.pr_title}")
        print(f"  Repo: {event.repo_name}")
```

**Evidence Validation**:
- **Claim TRUE**: Archive shows `PullRequestEvent` with `action='opened'`
- **Claim FALSE**: No events found → claim disproven
- **Investigation Outcome**: Definitively verify or refute timeline claims

**Real Example**: Amazon Q investigation verified no PR from attacker's account in late June 2025, disproving media's claim of malicious code committed via deleted PR.

### Deleted Repository Forensics

**Scenario**: Threat actor creates staging repository, pushes malicious code, then deletes repo to cover tracks.

**Step 1: Find Repository Activity**
```python
query = """
SELECT
    type,
    created_at,
    JSON_EXTRACT_SCALAR(payload, '$.ref') as ref,
    JSON_EXTRACT_SCALAR(payload, '$.repository.name') as repo_name,
    payload
FROM `githubarchive.day.2025*`
WHERE
    actor.login = 'threat-actor'
    AND type IN ('CreateEvent', 'PushEvent')
    AND (
        JSON_EXTRACT_SCALAR(payload, '$.repository.name') = 'staging-repo'
        OR repo.name LIKE 'threat-actor/staging-repo'
    )
ORDER BY created_at
"""

results = client.query(query)
```

**Step 2: Extract Commit SHAs**
```python
import json

commits = []
for row in results:
    if row.type == 'PushEvent':
        payload_data = json.loads(row.payload)
        for commit in payload_data.get('commits', []):
            commits.append({
                'sha': commit['sha'],
                'message': commit['message'],
                'timestamp': row.created_at
            })

for c in commits:
    print(f"{c['timestamp']}: {c['sha'][:8]} - {c['message']}")
```

**Evidence Recovery**:
- `CreateEvent` reveals repository creation timestamp
- `PushEvent` records contain commit SHAs and metadata
- Commit SHAs can be used to recover code content via other archives or forks
- **Investigation Outcome**: Complete reconstruction of attacker's staging infrastructure

**Real Example**: `lkmanka58/code_whisperer` repository deleted after attack, but GitHub Archive revealed June 13 creation with 3 commits containing AWS IAM role assumption attempts.

### Deleted Tag Analysis

**Scenario**: Malicious tag used for payload delivery, then deleted to hide evidence.

**Step 1: Search for Tag Events**
```sql
SELECT
    type,
    created_at,
    actor.login,
    JSON_EXTRACT_SCALAR(payload, '$.ref') as tag_name,
    JSON_EXTRACT_SCALAR(payload, '$.ref_type') as ref_type
FROM `githubarchive.day.20250713`
WHERE
    repo.name = 'target/repository'
    AND type IN ('CreateEvent', 'DeleteEvent')
    AND JSON_EXTRACT_SCALAR(payload, '$.ref_type') = 'tag'
ORDER BY created_at
```

**Timeline Reconstruction**:
```
2025-07-13 19:41:44 UTC | CreateEvent | aws-toolkit-automation | tag 'stability'
2025-07-13 20:30:24 UTC | PushEvent   | aws-toolkit-automation | commit references tag
2025-07-14 08:15:33 UTC | DeleteEvent | aws-toolkit-automation | tag 'stability' deleted
```

**Analysis**: 48-hour window between tag creation and deletion reveals staging period for attack infrastructure.

**Real Example**: Amazon Q attack used 'stability' tag for malicious payload delivery. Tag was deleted, but `CreateEvent` in GitHub Archive preserved creation timestamp and actor, proving 48-hour staging window.

### Deleted Branch Reconstruction

**Scenario**: Attacker creates development branch with malicious code, pushes commits, then deletes branch after merging or to cover tracks.

**Step 1: Find Branch Lifecycle**
```sql
SELECT
    type,
    created_at,
    actor.login,
    JSON_EXTRACT_SCALAR(payload, '$.ref') as branch_name,
    JSON_EXTRACT_SCALAR(payload, '$.ref_type') as ref_type
FROM `githubarchive.day.2025*`
WHERE
    repo.name = 'target/repository'
    AND type IN ('CreateEvent', 'DeleteEvent')
    AND JSON_EXTRACT_SCALAR(payload, '$.ref_type') = 'branch'
ORDER BY created_at
```

**Step 2: Extract All Commit SHAs from Deleted Branch**
```sql
SELECT
    created_at,
    actor.login as pusher,
    JSON_EXTRACT_SCALAR(payload, '$.ref') as branch_ref,
    JSON_EXTRACT_SCALAR(commit, '$.sha') as commit_sha,
    JSON_EXTRACT_SCALAR(commit, '$.message') as commit_message,
    JSON_EXTRACT_SCALAR(commit, '$.author.name') as author_name,
    JSON_EXTRACT_SCALAR(commit, '$.author.email') as author_email
FROM `githubarchive.day.2025*`,
UNNEST(JSON_EXTRACT_ARRAY(payload, '$.commits')) as commit
WHERE
    repo.name = 'target/repository'
    AND type = 'PushEvent'
    AND JSON_EXTRACT_SCALAR(payload, '$.ref') = 'refs/heads/deleted-branch-name'
ORDER BY created_at
```

**Evidence Recovery**:
- **Commit SHAs**: All commit identifiers permanently recorded in `PushEvent` payload
- **Commit Messages**: Full commit messages preserved in commits array
- **Author Metadata**: Name and email from commit author field
- **Pusher Identity**: Actor who executed the push operation
- **Temporal Sequence**: Exact timestamps for each push operation
- **Branch Lifecycle**: Complete creation-to-deletion timeline

**Forensic Value**: Even after branch deletion, commit SHAs can be used to:
- Search for commits in forked repositories
- Check if commits were merged into other branches
- Search external code archives (Software Heritage, etc.)
- Reconstruct complete attack development timeline

### Automation vs Direct API Attribution

**Scenario**: Suspicious commits appear under automation account name. Determine if they came from legitimate GitHub Actions workflow execution or direct API abuse with compromised token.

**Step 1: Search for Workflow Events During Suspicious Window**
```python
query = """
SELECT
    type,
    created_at,
    actor.login,
    JSON_EXTRACT_SCALAR(payload, '$.workflow_run.name') as workflow_name,
    JSON_EXTRACT_SCALAR(payload, '$.workflow_run.head_sha') as commit_sha,
    JSON_EXTRACT_SCALAR(payload, '$.workflow_run.conclusion') as conclusion
FROM `githubarchive.day.20250713`
WHERE
    repo.name = 'org/repository'
    AND type IN ('WorkflowRunEvent', 'WorkflowJobEvent')
    AND created_at >= '2025-07-13T20:25:00Z'
    AND created_at <= '2025-07-13T20:35:00Z'
ORDER BY created_at
"""

workflow_events = list(client.query(query))
```

**Step 2: Establish Baseline Pattern**
```python
baseline_query = """
SELECT
    type,
    created_at,
    actor.login,
    JSON_EXTRACT_SCALAR(payload, '$.workflow_run.name') as workflow_name
FROM `githubarchive.day.20250713`
WHERE
    repo.name = 'org/repository'
    AND actor.login = 'automation-account'
    AND type = 'WorkflowRunEvent'
ORDER BY created_at
"""

baseline = list(client.query(baseline_query))
print(f"Total workflows for day: {len(baseline)}")
```

**Step 3: Analyze Results**
```python
if not workflow_events:
    print("🚨 DIRECT API ATTACK DETECTED")
    print("No WorkflowRunEvent during suspicious commit window")
    print("Commit was NOT from legitimate workflow execution")
else:
    print("✓ Legitimate workflow execution detected")
    for event in workflow_events:
        print(f"{event.created_at}: {event.workflow_name} - {event.conclusion}")
```

**Expected Results if Legitimate Workflow**:
```
2025-07-13 20:30:15 UTC | WorkflowRunEvent | deploy-automation | requested
2025-07-13 20:30:24 UTC | PushEvent        | aws-toolkit-automation | refs/heads/main
2025-07-13 20:31:08 UTC | WorkflowRunEvent | deploy-automation | completed
```

**Expected Results if Direct API Abuse**:
```
2025-07-13 20:30:24 UTC | PushEvent | aws-toolkit-automation | refs/heads/main
[NO WORKFLOW EVENTS IN ±10 MINUTE WINDOW]
```

**Investigation Outcome**: Absence of `WorkflowRunEvent` = Direct API attack with stolen token

**Real Example**: Amazon Q investigation needed to determine if malicious commit `678851bbe9776228f55e0460e66a6167ac2a1685` (pushed July 13, 2025 20:30:24 UTC by `aws-toolkit-automation`) came from compromised workflow or direct API abuse. GitHub Archive query showed ZERO `WorkflowRunEvent` or `WorkflowJobEvent` records during the 20:25-20:35 UTC window. Baseline analysis revealed the same automation account had 18 workflows that day, all clustered in 20:48-21:02 UTC. The temporal gap and complete workflow absence during the malicious commit proved direct API attack, not workflow compromise.

## Troubleshooting

**Permission denied errors**:
- Verify service account has `BigQuery User` role
- Check credentials file path is correct
- Ensure BigQuery API is enabled in Google Cloud project

**Query exceeds free tier (>1TB)**:
- Use daily tables instead of wildcard: `githubarchive.day.20250615`
- Add date filters: `WHERE created_at >= '2025-06-01' AND created_at < '2025-07-01'`
- Limit columns: Select only needed fields, not `SELECT *`
- Use monthly tables for broader searches: `githubarchive.month.202506`

**No results for known event**:
- Verify date range (archive starts Feb 12, 2011)
- Check timezone (GitHub Archive uses UTC)
- Confirm `actor.login` spelling (case-sensitive)
- Some events may take up to 1 hour to appear (hourly updates)

**Payload extraction returns NULL**:
- Verify JSON path exists with `JSON_EXTRACT()` before using `JSON_EXTRACT_SCALAR()`
- Check event type has that payload field (not all events have all fields)
- Inspect raw payload: `SELECT payload FROM ... LIMIT 1`

**Query timeout or slow performance**:
- Add `repo.name` filter when possible (significantly reduces data scanned)
- Use specific date ranges instead of wildcards
- Consider using monthly aggregated tables for long-term analysis
- Partition queries by date and run in parallel

### Force Push Recovery (Zero-Commit PushEvents)

**Scenario**: Developer accidentally commits secrets, then force pushes to "delete" the commit. The commit remains accessible on GitHub, but finding it requires knowing the SHA.

**Background**: When a developer runs `git reset --hard HEAD~1 && git push --force`, Git removes the reference to that commit from the branch. However:
- GitHub stores these "dangling" commits indefinitely
- GitHub Archive records the `before` SHA in PushEvent payloads
- Force pushes appear as PushEvents with zero commits (empty commits array)

**Step 1: Find All Zero-Commit PushEvents (Organization-Wide)**
```sql
SELECT
    created_at,
    actor.login,
    repo.name,
    JSON_EXTRACT_SCALAR(payload, '$.before') as deleted_commit_sha,
    JSON_EXTRACT_SCALAR(payload, '$.head') as current_head,
    JSON_EXTRACT_SCALAR(payload, '$.ref') as branch
FROM `githubarchive.day.2025*`
WHERE
    repo.name LIKE 'target-org/%'
    AND type = 'PushEvent'
    AND JSON_EXTRACT_SCALAR(payload, '$.size') = '0'
ORDER BY created_at DESC
```

**Step 2: Search for Specific Repository**
```sql
SELECT
    created_at,
    actor.login,
    JSON_EXTRACT_SCALAR(payload, '$.before') as deleted_commit_sha,
    JSON_EXTRACT_SCALAR(payload, '$.head') as after_sha,
    JSON_EXTRACT_SCALAR(payload, '$.ref') as branch
FROM `githubarchive.day.202506*`
WHERE
    repo.name = 'org/repository'
    AND type = 'PushEvent'
    AND JSON_EXTRACT_SCALAR(payload, '$.size') = '0'
ORDER BY created_at
```

**Step 3: Bulk Recovery Query**
```python
query = """
SELECT
    created_at,
    actor.login,
    repo.name,
    JSON_EXTRACT_SCALAR(payload, '$.before') as deleted_sha,
    JSON_EXTRACT_SCALAR(payload, '$.ref') as branch
FROM `githubarchive.year.2024`
WHERE
    type = 'PushEvent'
    AND JSON_EXTRACT_SCALAR(payload, '$.size') = '0'
    AND repo.name LIKE 'target-org/%'
"""

results = client.query(query)
deleted_commits = []
for row in results:
    deleted_commits.append({
        'timestamp': row.created_at,
        'actor': row.actor_login,
        'repo': row.repo_name,
        'deleted_sha': row.deleted_sha,
        'branch': row.branch
    })

print(f"Found {len(deleted_commits)} force-pushed commits to investigate")
```

**Evidence Recovery**:
- **`before` SHA**: The commit that was "deleted" by the force push
- **`head` SHA**: The commit the branch was reset to
- **`ref`**: Which branch was force pushed
- **`actor.login`**: Who performed the force push
- **Commit Access**: Use recovered SHA to access commit via GitHub API or web UI

**Forensic Applications**:
- **Secret Scanning**: Scan recovered commits for leaked credentials, API keys, tokens
- **Incident Timeline**: Identify when secrets were committed and when they were "hidden"
- **Attribution**: Determine who committed secrets and who attempted to cover them up
- **Compliance**: Prove data exposure window for breach notifications

**Real Example**: Security researcher Sharon Brizinov scanned all zero-commit PushEvents since 2020 across GitHub, recovering "deleted" commits and scanning them for secrets. This technique uncovered credentials worth $25k in bug bounties, including an admin-level GitHub PAT with access to all Istio repositories (36k stars, used by Google, IBM, Red Hat). The token could have enabled a massive supply-chain attack.

**Important Notes**:
- Force pushing does NOT delete commits from GitHub - they remain accessible via SHA
- GitHub Archive preserves the `before` SHA indefinitely
- Zero-commit PushEvents are the forensic fingerprint of history rewrites
- This technique provides 100% coverage of "deleted" commits (vs brute-forcing 4-char SHA prefixes)

## Learn More

- **GH Archive Documentation**: https://www.gharchive.org/
- **GitHub Event Types Schema**: https://docs.github.com/en/rest/using-the-rest-api/github-event-types
