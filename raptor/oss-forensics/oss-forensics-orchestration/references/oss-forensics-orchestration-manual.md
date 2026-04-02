# OSS Forensics Orchestration Manual

## Detailed Investigation Phases

### Phase 0: Initialize Investigation
**CRITICAL:** Run the init script using Bash (this is a pre-approved Bash command):
```bash
source .venv/bin/activate && python .claude/skills/oss-forensics/github-evidence-kit/scripts/init_investigation.py
```
The script checks GOOGLE_APPLICATION_CREDENTIALS, creates `.out/oss-forensics-{timestamp}/`, and initializes `evidence.json`. Parse the JSON output for the workdir path.

### Phase 1: Parse Prompt & Form Research Question
Extract: Repository references, Actor usernames, Date ranges, and Vendor report URLs.
Goal: Produce timeline, attribution, intent, and impact analysis.

### Phase 2: Parallel Evidence Collection
Spawn investigators IN PARALLEL using a single message with multiple Task calls.
Agents include: `gh-archive-agent`, `github-agent`, `wayback-agent`, `local-git-agent`, and `ioc-extractor-agent` (optional).

### Phase 3: Hypothesis Formation Loop
Iterate up to `max_followups`. Spawn `oss-hypothesis-former-agent`. Handle `evidence-request-*.md` by spawning specific investigators.

### Phase 4: Evidence Verification
Spawn `oss-evidence-verifier-agent` to verify all evidence against original sources.

### Phase 5: Hypothesis Validation Loop
Iterate up to `max_retries`. Spawn `oss-hypothesis-checker-agent` to validate against verified evidence. Handle rebuttals by revising the hypothesis.

### Phase 6: Generate Report
Spawn `oss-report-generator-agent` to produce `forensic-report.md`.

### Phase 7: Complete
Inform user of report location and key outputs (evidence.json, verification-report, hypothesis files).

## Error Handling
- **BigQuery auth fails**: Stop, show credential setup instructions.
- **GitHub API rate limited**: Continue with other sources, note limitation.
- **Repo clone fails**: Note in evidence, continue investigation.
- **Max retries/followups exceeded**: Produce report with current state, note uncertainty.
- **Agent spawn fails**: Stop and report error with agent name.

## Example Execution
```
User: /oss-forensics "Investigate lkmanka58's activity on aws/aws-toolkit-vscode on July 13, 2025"

Phase 0: ✓ Run init script
Phase 1: ✓ Parse prompt
Phase 2: ✓ Spawn 4 investigators in parallel
Phase 3: ✓ Hypothesis former
Phase 4: ✓ Verifier
Phase 5: ✓ Checker
Phase 6: ✓ Report generator
Phase 7: ✓ Inform user
```
