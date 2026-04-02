# Code Understanding Manual

## Modes and Command Flags

| Mode | Command flag | Purpose | Reference |
|------|-------------|---------|-----------|
| **Map** | `--map` | Build high-level context: entry points, trust model, data paths | [map.md](map.md) |
| **Trace** | `--trace <entry>` | Follow one flow source → sink with full call chain | [trace.md](trace.md) |
| **Hunt** | `--hunt <pattern>` | Find all variants of a pattern across the codebase | [hunt.md](hunt.md) |
| **Teach** | `--teach` | Explain unfamiliar code, frameworks, or patterns in depth | [teach.md](teach.md) |

Modes can be combined. Map → Trace → Hunt is the natural attack progression.

## Configuration

```yaml
output_dir: .out/code-understanding-<timestamp>/
confidence_levels:
  high: "Direct code evidence — quote the line"
  medium: "Inferred from context — state the assumption"
  low: "Speculative — flag explicitly, verify before acting on"
flow_format: source → transform(s) → sink
```

## Execution Rules (Expanded)

1. **Evidence-First**: Read actual code before making any claim. Do not rely on naming conventions or assumptions.
2. **Quoting**: Quote the exact line (file path + line number) as proof for every assertion.
3. **Completeness**: When tracing a flow, follow it until it terminates — don't stop at the first interesting function.
4. **Full Search**: When hunting variants, search the full codebase. Do not stop at the first match.
5. **Mechanisms**: When teaching, explain the mechanism, not just the name. Show the code that implements it.
6. **Structured Output**: Produce context-map.json, flow-trace.json, variants.json for integration.

## MUST-GATEs

**GATE-U1 [READ-FIRST]:** Never describe how code works without reading it. If you haven't read a file, say so and read it before continuing.

**GATE-U2 [ATTACKER-LENS]:** When reading any code path, ask: where does trust transfer? Where are checks missing? Where does user input influence execution?

**GATE-U3 [FULL-FLOW]:** When tracing a data flow, follow every branch: happy path, error paths, middleware, async handlers.

**GATE-U4 [VARIANT-COMPLETE]:** A variant hunt is not complete until the full codebase has been searched.

**GATE-U5 [EVIDENCE-ONLY]:** Confidence levels must match evidence. High confidence requires a quoted line.

## Output Formatting

- **File references**: `path/to/file.py:42` format throughout.
- **Flow format**: `source (file:line) → transform (file:line) → sink (file:line)`.
- **Confidence inline**: `(confidence: high — file:line)` or `(confidence: medium — assumed from X)`.
- **No status indicators**: No red/green status indicators (perspective-dependent).
- **Workdir**: JSON outputs go to `$WORKDIR/` for pipeline integration.

## Pipeline Integration

**Shared inventory**: MAP-0 runs `build_inventory.py` to produce `checklist.json` with SHA-256 checksums per file. Coverage tracking (`checked_by` per function) is cumulative across skills.

Output schemas are aligned with the validation pipeline's formats (`attack-surface.json`, `attack-paths.json`, `findings.json`).

## Stages and Gates

| Stage | Mode | Gate(s) | Output |
|-------|------|---------|--------|
| **Map** | `--map` | U1, U2 | `context-map.json` |
| **Trace** | `--trace` | U1, U2, U3, U5 | `flow-trace-<id>.json` |
| **Hunt** | `--hunt` | U1, U4, U5 | `variants.json` |
| **Teach** | `--teach` | U1, U5 | none --- inline output |

## Original References
- [Map Mode](map.md)
- [Trace Mode](trace.md)
- [Hunt Mode](hunt.md)
- [Teach Mode](teach.md)
