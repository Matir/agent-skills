# Planning with Files Manual

## File Purposes

| File | Purpose | When to Update |
|------|---------|----------------|
| `task_plan.md` | Phases, progress, decisions | After each phase completes |
| `findings.md` | Research, discoveries, decisions | After ANY discovery |
| `progress.md` | Session log, test results | Throughout the session |

All three files go in the **project root**, not the plugin directory.

## Critical Rules (Expanded)

### 1. Create Plan First
Never start a complex task without `task_plan.md`. This is non-negotiable. The plan is your persistent memory.

### 2. The 2-Action Rule
After every 2 search, browse, or read operations, immediately save key findings to `findings.md`. Multimodal content (images, browser results, PDF contents) does not persist in context -- capture it as text before it is lost.

### 3. Read Before Decide
Before any major decision, re-read `task_plan.md`. This pushes goals and context back into the recent attention window, counteracting the "lost in the middle" effect.

### 4. Update After Act
After completing any phase:
- Mark phase status: `in_progress` -> `complete`
- Log any errors encountered in the Errors table
- Note files created or modified in `progress.md`

### 5. Log ALL Errors
Every error goes in `task_plan.md`. Include the attempt number and resolution.

### 6. Never Repeat Failures
If an action failed, the next action must be different. Track what you tried and mutate the approach.

## 3-Strike Error Protocol

1. **ATTEMPT 1: Diagnose & Fix**: Read error carefully, identify root cause, apply targeted fix.
2. **ATTEMPT 2: Alternative Approach**: Try a different method, tool, or library. NEVER repeat the exact same failing action.
3. **ATTEMPT 3: Broader Rethink**: Question assumptions, search for solutions, consider updating the plan.
4. **AFTER 3 FAILURES: Escalate to User**: Explain what you tried (with attempt log), share the specific error, and ask for guidance.

## Read vs Write Decision Matrix

| Situation | Action | Reason |
|-----------|--------|--------|
| Just wrote a file | Don't read it | Content still in context |
| Viewed image/PDF | Write findings NOW | Multimodal content doesn't persist |
| Browser returned data | Write to file | Screenshots don't persist |
| Starting new phase | Read plan/findings | Re-orient if context is stale |
| Error occurred | Read relevant file | Need current state to fix |
| Resuming after gap | Read all planning files | Recover full state |

## 5-Question Reboot Test
If you can answer these from your planning files, context is solid:
- Where am I? (Current phase in `task_plan.md`)
- Where am I going? (Remaining phases)
- What's the goal? (Goal statement in plan)
- What have I learned? (`findings.md`)
- What have I done? (`progress.md`)

## Anti-Patterns
- State goals once and forget
- Hide errors and retry silently
- Stuff everything in context
- Start executing immediately
- Repeat failed actions
- Create files in plugin directory

## Original References
- [Templates](templates.md)
- [Principles](principles.md)
- [Examples](examples.md)
