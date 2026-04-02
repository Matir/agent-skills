# Skill Extractor Manual

## Finding Extraction Candidates
Ask:
- "What did I just learn that wasn't obvious before?"
- "If I faced this again, what would I wish I knew?"
- "What error message led me here, and what was the cause?"
- "Is this project-specific or a general pattern?"

## Detailed Extraction Process

### Step 0: Check Existing Skills
- `ls ~/.claude/skills/`
- `ls .claude/skills/`
- `grep -r "keyword" ~/.claude/skills/ .claude/skills/`

### Step 1: Identify the Learning
Analyze the conversation for non-obvious solutions and specific triggers.

### Step 2: Quality Assessment Criteria
- **Reusable**: Helps future tasks.
- **Non-trivial**: Required discovery, not just docs.
- **Verified**: Solution actually worked.
- **Specific triggers**: Exact symptoms/errors.
- **Explains WHY**: Trade-offs and judgment.

### Step 3: Gather Details (Name/Scope)
Suggest kebab-case name; decide user (`~/.claude/`) vs. project (`.claude/`) scope.

### Step 4: Optional Research
Search for best practices or official docs for external libraries.

### Step 5: Generate Skill
Follow the standard template and quality guides.

### Step 6: Validate & Save
Run the validation checklist and save to the appropriate path.

## Skill Lifecycle & Consolidation
- **Combine**: If new knowledge is a variation of an existing skill.
- **Separate**: If trigger conditions are fundamentally different.
- **Update**: For new edge cases, corrections, or better solutions.
- **Archive**: If tool or pattern becomes obsolete.

## Example Extraction: cyclic-ast-visitor-hardening
- **Trigger**: RecursionError during AST analysis.
- **Insight**: Visitor doesn't track cycles in serialized input.
- **Solution**: Add `visited: set` to track nodes and prevent infinite loops.
