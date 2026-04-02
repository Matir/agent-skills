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

## Cost Management & Query Optimization

### Understanding GitHub Archive Costs

BigQuery charges **$6.25 per TiB** of data scanned (after the 1 TiB free tier). GitHub Archive tables are **large** - a single month table can be 50-100 GB, and yearly wildcards can scan multiple TiBs. **Unoptimized queries can cost $10-100+**, while optimized versions of the same query cost $0.10-1.00.

**Key Cost Principle**: BigQuery uses columnar storage - you pay for ALL data in the columns you SELECT, not just matching rows. A query with `SELECT *` on one day of data scans ~3 GB even with LIMIT 10.

### ALWAYS Estimate Costs Before Querying

**CRITICAL RULE**: Run a dry run to estimate costs before executing any query against GitHub Archive production tables.

```python
from google.cloud import bigquery

def estimate_gharchive_cost(query: str) -> dict:
    """Estimate cost before running GitHub Archive query."""
    client = bigquery.Client()

    # Dry run - validates query and returns bytes to scan
    dry_run_config = bigquery.QueryJobConfig(dry_run=True, use_query_cache=False)
    job = client.query(query, job_config=dry_run_config)

    bytes_processed = job.total_bytes_processed
    gb_processed = bytes_processed / (1024**3)
    tib_processed = bytes_processed / (1024**4)
    estimated_cost = tib_processed * 6.25

    return {
        'bytes': bytes_processed,
        'gigabytes': round(gb_processed, 2),
        'tib': round(tib_processed, 4),
        'estimated_cost_usd': round(estimated_cost, 4)
    }

# Example: Always check cost before running
estimate = estimate_gharchive_cost(your_query)
print(f"Cost estimate: {estimate['gigabytes']} GB → ${estimate['estimated_cost_usd']}")

if estimate['estimated_cost_usd'] > 1.0:
    print("⚠️ HIGH COST QUERY - Review optimization before proceeding")
```

**Command-line dry run**:
```bash
bq query --dry_run --use_legacy_sql=false 'YOUR_QUERY_HERE' 2>&1 | grep "bytes"
```

### When to Ask the User About Costs

**ASK USER BEFORE RUNNING** if any of these conditions apply:

1. **Estimated cost > $1.00** - Always confirm with user for queries over $1
2. **Wildcard spans > 3 months** - Queries like `githubarchive.day.2025*` scan entire year (~400 GB)
3. **No partition filter** - Queries without date/time filters scan entire table range
4. **SELECT * used** - Selecting all columns dramatically increases cost
5. **Cross-repository searches** - Queries without `repo.name` filter scan all GitHub activity

**Example user confirmation**:
```
Query estimate: 120 GB ($0.75)
Scanning: githubarchive.day.202506* (June 2025, 30 days)
Reason: Cross-repository search for actor 'suspected-user'

This exceeds typical query cost ($0.10-0.30). Proceed? [y/n]
```

**DON'T ASK if**:
- Estimated cost < $0.50 AND query is well-scoped (specific repo + date range)
- User explicitly requested broad analysis (e.g., "scan all of 2025")

### Cost Optimization Techniques for GitHub Archive

#### 1. Select Only Required Columns (50-90% cost reduction)

```sql
-- ❌ EXPENSIVE: Scans ALL columns (~3 GB per day)
SELECT * FROM `githubarchive.day.20250615`
WHERE actor.login = 'target-user'

-- ✅ OPTIMIZED: Scans only needed columns (~0.3 GB per day)
SELECT
    type,
    created_at,
    repo.name,
    actor.login,
    JSON_EXTRACT_SCALAR(payload, '$.action') as action
FROM `githubarchive.day.20250615`
WHERE actor.login = 'target-user'
```

**Never use `SELECT *` in production queries.** Always specify exact columns needed.

#### 2. Use Specific Date Ranges (10-100x cost reduction)

```sql
-- ❌ EXPENSIVE: Scans entire year (~400 GB)
SELECT ... FROM `githubarchive.day.2025*`
WHERE actor.login = 'target-user'

-- ✅ OPTIMIZED: Scans specific month (~40 GB)
SELECT ... FROM `githubarchive.day.202506*`
WHERE actor.login = 'target-user'

-- ✅ BEST: Scans single day (~3 GB)
SELECT ... FROM `githubarchive.day.20250615`
WHERE actor.login = 'target-user'
```

**Strategy**: Start with narrow date ranges (1-7 days), then expand if needed. Use monthly tables (`githubarchive.month.202506`) for multi-month queries instead of daily wildcards.

#### 3. Filter by Repository Name (5-50x cost reduction)

```sql
-- ❌ EXPENSIVE: Scans all GitHub activity
SELECT ... FROM `githubarchive.day.202506*`
WHERE actor.login = 'target-user'

-- ✅ OPTIMIZED: Filter by repo (BigQuery can prune data blocks)
SELECT ... FROM `githubarchive.day.202506*`
WHERE
    repo.name = 'target-org/target-repo'
    AND actor.login = 'target-user'
```

**Rule**: Always include `repo.name` filter when investigating a specific repository.

#### 4. Avoid SELECT * with Wildcards (Critical)

```sql
-- ❌ CATASTROPHIC: Can scan 1+ TiB ($6.25+)
SELECT * FROM `githubarchive.day.2025*`
WHERE type = 'PushEvent'

-- ✅ OPTIMIZED: Scans ~50 GB ($0.31)
SELECT
    created_at,
    actor.login,
    repo.name,
    JSON_EXTRACT_SCALAR(payload, '$.ref') as branch
FROM `githubarchive.day.2025*`
WHERE type = 'PushEvent'
```

#### 5. Use LIMIT Correctly (Does NOT reduce cost on GHArchive)

**IMPORTANT**: LIMIT does **not** reduce BigQuery costs on non-clustered tables like GitHub Archive. BigQuery must scan all matching data before applying LIMIT.

```sql
-- ❌ MISCONCEPTION: Still scans full dataset
SELECT * FROM `githubarchive.day.20250615`
LIMIT 100  -- Cost: ~3 GB scanned

-- ✅ CORRECT: Use WHERE filters and column selection
SELECT type, created_at, actor.login
FROM `githubarchive.day.20250615`
WHERE repo.name = 'target/repo'  -- Cost: ~0.2 GB scanned
LIMIT 100
```

### Safe Query Execution Template

Use this template for all GitHub Archive queries in production:

```python
def safe_gharchive_query(query: str, max_cost_usd: float = 1.0):
    """Execute GitHub Archive query with cost controls."""
    client = bigquery.Client()

    # Step 1: Dry run estimate
    dry_run_config = bigquery.QueryJobConfig(dry_run=True, use_query_cache=False)
    dry_job = client.query(query, job_config=dry_run_config)

    bytes_processed = dry_job.total_bytes_processed
    gb = bytes_processed / (1024**3)
    estimated_cost = (bytes_processed / (1024**4)) * 6.25

    print(f"📊 Estimate: {gb:.2f} GB → ${estimated_cost:.4f}")

    # Step 2: Check budget
    if estimated_cost > max_cost_usd:
        raise ValueError(
            f"Query exceeds ${max_cost_usd} budget (estimated ${estimated_cost:.2f}). "
            f"Optimize query or increase max_cost_usd parameter."
        )

    # Step 3: Execute with safety limit
    job_config = bigquery.QueryJobConfig(
        maximum_bytes_billed=int(bytes_processed * 1.2)  # 20% buffer
    )

    print(f"✅ Executing query (max ${estimated_cost:.2f})...")
    return client.query(query, job_config=job_config).result()

# Usage
results = safe_gharchive_query("""
    SELECT created_at, repo.name, actor.login
    FROM `githubarchive.day.20250615`
    WHERE repo.name = 'aws/aws-toolkit-vscode'
        AND type = 'PushEvent'
""", max_cost_usd=0.50)
```
