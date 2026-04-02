# Smart Contract Vulnerability Auditor Manual

## Detailed Audit Workflow

### Phase 1: Load the Cheatsheet
Read `../references/CHEATSHEET.md` in full before scanning code. Internalize grep-able keywords and vulnerability patterns.

### Phase 2: Codebase Sweep
- **Pass A (Syntactic Grep)**: Use `grep` or `ripgrep` for cheatsheet keywords (e.g., `.call(`, `unchecked`, `selfdestruct`).
- **Pass B (Structural Analysis)**: Read for logic that matches cheatsheet semantic patterns.
- **Merge**: Create a deduplicated candidate list with File, Line, and Suspected vulnerability.

### Phase 3: Selective Deep Validation
For each candidate:
1. **Read full reference** for the suspected type (e.g., `reentrancy.md`).
2. **Detection Heuristic**: Trace variable values and call chains.
3. **False Positive Conditions**: Check every condition to discard noise.
4. **Cross-reference**: A single location may have multiple vulnerabilities.

### Phase 4: Report
Generate `scv-scan.md` with:
- Vulnerability name, location, and severity (Critical, High, Medium, Low, Info).
- Description and vulnerable code snippet.
- Recommendation based on reference remediation section.
- Summary table.

## Severity Guidelines
- **Critical**: Loss/freezing of funds, unauthorized extraction.
- **High**: Access control bypass, conditional loss.
- **Medium**: Griefing, non-critical DoS, value leak under edges.
- **Low**: Best practice violation, gas inefficiency.

## Key Principles
- **Semantic > Syntactic**: The hardest bugs (e.g., cross-function reentrancy) require logic reasoning.
- **Trace across boundaries**: Follow state through calls and inheritance.
- **Version matters**: `pragma solidity` determines default overflow/underflow checking.
- **False positives**: Discard findings if any False Positive condition matches.

## Detailed Reference Structure
Reference files in `references/` contain:
- **Preconditions**: Why it exists.
- **Vulnerable Pattern**: Annotated anti-pattern.
- **Detection Heuristic**: Step-by-step reasoning.
- **False Positives**: When the pattern is safe.
- **Remediation**: How to fix.
