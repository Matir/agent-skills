# last30days: Research Manual

## Detailed Parsing: User Intent
Before executing, parse input for:
1. **TOPIC**: What to learn (e.g., "web app mockups").
2. **TARGET TOOL**: Where prompts will be used (e.g., "Midjourney").
3. **QUERY TYPE**:
   - **PROMPTING**: Learning techniques and copy-paste prompts.
   - **RECOMMENDATIONS**: Lists of specific items ("best X").
   - **NEWS**: Current events/updates.
   - **GENERAL**: Broad understanding.

## Research Execution
### Step 1: Run Script
```bash
python3 "../scripts/last30days.py" "$ARGUMENTS" --emit=compact 2>&1
```
### Step 2: Parallel WebSearch
Supplement script results with targeted queries:
- **RECOMMENDATIONS**: `best {TOPIC} recommendations`, `most popular {TOPIC}`.
- **NEWS**: `{TOPIC} news 2026`, `{TOPIC} announcement update`.
- **PROMPTING**: `{TOPIC} prompts examples 2026`, `{TOPIC} techniques tips`.

## Synthesis Guidelines (Judge Agent)
1. **Weighting**: Reddit/X (engagement signals) > WebSearch (no engagement data).
2. **Patterns**: Identify commonalities across all three sources.
3. **Product Precision**: Distinguish between similar names (e.g., "ClawdBot" vs "Claude Code").
4. **Actionable Insights**: Extract 3-5 key patterns or pitfalls mentioned by sources.

## Output Structure
### Summary Sequence
1. **What I Learned**: Summarize findings by QUERY_TYPE.
2. **Key Patterns**: 3-5 bullet points with citations (e.g., "per @handle").
3. **Stats Box**: Count threads, upvotes, posts, and likes.
4. **Invitation**: Offer follow-up questions or prompt creation based on specific findings.

## Prompt Writing Rules
- **Format Match**: Use the EXACT format (JSON, structured, etc.) recommended by research.
- **Tailoring**: Address the user's specific vision using discovered patterns.
- **Ready to Paste**: Ensure the prompt requires zero to minimal editing.

## Response Logic
- **Question/Deep Dive**: Answer using research findings (do not run new searches).
- **Creation/Prompt Request**: Write ONE perfect, highly-tailored prompt.
- **Alternatives**: Provide variations ONLY if requested.
