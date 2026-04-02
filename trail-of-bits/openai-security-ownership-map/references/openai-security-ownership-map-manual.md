# Security Ownership Map Manual

## Requirements
- Python 3
- `networkx` (required for community detection)
- Install: `uv pip install networkx`

## Sensitivity Rules
By default, common auth/crypto/secret paths are flagged. Override by providing a CSV file:
```csv
# pattern,tag,weight
**/auth/**,auth,1.0
**/crypto/**,crypto,1.0
**/*.pem,secrets,1.0
```
Use with `--sensitive-config path/to/sensitive.csv`.

## Output Artifacts
The output directory contains:
- `people.csv` / `files.csv`: Nodes for people and files.
- `edges.csv`: Touches between people and files.
- `cochange_edges.csv`: File-to-file co-change edges (Jaccard weight).
- `summary.json`: High-level security ownership findings.
- `communities.json`: Clusters of files with designated maintainers.
- `cochange.graph.json`: NetworkX node-link JSON.

## Query Helper (`scripts/query_ownership.py`)
Use this helper to extract JSON-bounded slices of the graph:
```bash
# Get top 10 people
python scripts/query_ownership.py --data-dir out people --limit 10

# Find files with low bus factor for a specific tag
python scripts/query_ownership.py --data-dir out files --tag auth --bus-factor-max 1

# Identify orphaned sensitive code
python scripts/query_ownership.py --data-dir out summary --section orphaned_sensitive_code
```

## Security Queries
- **Orphaned Sensitive Code**: Stale files with low bus factor.
- **Hidden Owners**: Individuals controlling a large percentage of sensitive code.
- **Bus Factor Hotspots**: Sensitive files at risk due to few maintainers.
- **Co-change Neighbors**: Cluster hints for identifying ownership drift.

## Advanced Configuration
- **Touch Mode**: Use `--touch-mode file` to count per-file touches instead of per-authored commit.
- **Smoothing Churn**: Use `--window-days` or recency weighting (`--weight recency`).
- **Filtering Bots**: Use `--ignore-author-regex` to exclude automated accounts.
- **Attribution**: Switch between author and committer using `--identity`.

## Graph Persistence
See `references/neo4j-import.md` for instructions on loading CSVs into Neo4j for advanced visualization and Cypher querying.
