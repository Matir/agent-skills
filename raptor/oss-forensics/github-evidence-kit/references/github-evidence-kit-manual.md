# GH Evidence Kit Manual

## Detailed Collector Reference

### LocalGitCollector (Forensic Gold)
Essential for forensic analysis of cloned repositories, including force-pushed or deleted commits.

```python
from assets.src.collectors import LocalGitCollector
collector = LocalGitCollector("/path/to/cloned/repo")

# Find dangling commits (not reachable from any ref)
dangling = collector.collect_dangling_commits()
```

### GHArchiveCollector (BigQuery)
Recovers deleted content from GH Archive. Requires Google Cloud credentials.

```python
from assets.src.collectors import GHArchiveCollector
collector = GHArchiveCollector()

# Recover deleted content
deleted_pr = collector.recover_pr("aws/aws-toolkit-vscode", 7710, "2025-07-13T20:30:24Z")
```

### WaybackCollector
Collects archived snapshots from the Wayback Machine.

```python
from assets.src.collectors import WaybackCollector
collector = WaybackCollector()
snapshots = collector.collect_snapshots("https://github.com/owner/repo")
```

## Evidence Types

### Events (GH Archive)
Supports all 12 GitHub event types: `PushEvent`, `PullRequestEvent`, `IssueEvent`, `CreateEvent`, `DeleteEvent`, `ForkEvent`, etc.

### Observations
- `CommitObservation`: Metadata and file changes.
- `IssueObservation`: Issues or PRs.
- `SnapshotObservation`: Wayback snapshots.
- `IOC`: Indicators of Compromise (SHA, IP, Domain, etc.)

## Verification
Use `ConsistencyVerifier` to validate evidence against original sources.

```python
from assets.src.verifiers import ConsistencyVerifier
verifier = ConsistencyVerifier()
result = verifier.verify(commit)
```

## Testing
```bash
# Run unit tests
export PYTHONPATH=$PYTHONPATH:$(pwd)/assets
pytest assets/tests/ -v --ignore=assets/tests/test_integration.py
```

## Credentials Setup
Set `GOOGLE_APPLICATION_CREDENTIALS` for BigQuery access:
```bash
export GOOGLE_APPLICATION_CREDENTIALS=/path/to/credentials.json
```
Required role: `BigQuery User`.
