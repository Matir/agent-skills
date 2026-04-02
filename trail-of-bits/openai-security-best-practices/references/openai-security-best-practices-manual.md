# Security Best Practices Manual

## Workflow Decision Tree
- If the language/framework is unclear, inspect the repo to determine it and list your evidence.
- If matching guidance exists in `references/`, load only the relevant files and follow their instructions.
- If no matching guidance exists, consider well-known best practices or search online for documentation.

## Overrides
- Respect project-specific documentation that may require bypassing certain best practices.
- Report overrides to the user without conflict.
- Suggest documenting the reason for the bypass within the project.

## Report Format
- **Location**: `security_best_practices_report.md` (unless otherwise specified).
- **Structure**:
  - Executive summary at the top.
  - Sections delineated by severity.
  - Numeric IDs for each finding.
  - One-sentence impact statement for critical findings.
  - Verifiable line numbers for all code references.

## Fixes Procedure
- Focus on one finding at a time.
- Include concise comments explaining the security rationale.
- Prioritize functional integrity and avoid regressions.
- Follow existing project commit and testing flows.
- Use clear commit messages (e.g., "Align with security best practices").

## General Security Advice

### Public Resource IDs
- Avoid auto-incrementing IDs for public-facing resources.
- Use random UUID4 or hex strings to prevent resource enumeration.

### TLS and Cookies
- Do not report lack of TLS in development environments.
- Only set "secure" cookies if the application is confirmed to be running over TLS.
- Avoid recommending HSTS unless the full impact (e.g., user lockout) is understood.
