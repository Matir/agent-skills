# Ghidra Headless Analysis

Perform automated reverse engineering using Ghidra's `analyzeHeadless` tool.
Import binaries, run analysis, decompile to C code, and extract useful
information.

## When to Use

- Decompiling a binary to C pseudocode for review
- Extracting function signatures, strings, or symbols from executables
- Analyzing call graphs to understand binary control flow
- Triaging unknown binaries or firmware images
- Batch-analyzing multiple binaries for comparison
- Security auditing compiled code without source access

## When NOT to Use

- Source code is available — read it directly instead
- Interactive debugging is needed — use GDB, LLDB, or Ghidra GUI
- The binary is a .NET assembly — use dnSpy or ILSpy
- The binary is Java bytecode — use jadx or cfr
- Dynamic analysis is required — use a debugger or sandbox

## Quick Reference

| Task | Command |
||-----|
| x86 32-bit | `x86:LE:32:default` |
| x86 64-bit | `x86:LE:64:default` |
| ARM 32-bit | `ARM:LE:32:v7` |
| ARM 64-bit | `AARCH64:LE:64:v8A` |
| MIPS 32-bit | `MIPS:BE:32:default` or `MIPS:LE:32:default` |
| PowerPC | `PowerPC:BE:32:default` |

## Troubleshooting

### Ghidra Not Found

```bash
../scripts/find-ghidra.sh
# Or set GHIDRA_HOME if in non-standard location
export GHIDRA_HOME=/path/to/ghidra_11.x_PUBLIC
```

### Analysis Takes Too Long

```bash
../scripts/ghidra-analyze.sh --timeout 300 -s ExportAll.java binary
# Or skip analysis for quick export
../scripts/ghidra-analyze.sh --no-analysis -s ExportSymbols.java binary
```

### Out of Memory

Set before running:
```bash
export MAXMEM=4G
```

### Wrong Architecture Detected

Explicitly specify the processor:
```bash
../scripts/ghidra-analyze.sh -p "ARM:LE:32:v7" -s ExportAll.java firmware.bin
```

## Tips

1. **Start with ExportAll.java** — gives everything; the summary helps orient
2. **Check interesting.txt** — highlights security-relevant functions automatically
3. **Use jq for JSON parsing** — JSON exports are designed to be machine-readable
4. **Decompilation isn't perfect** — use as a guide, cross-reference with disassembly
5. **Large binaries take time** — use `--timeout` and consider `--no-analysis` for quick scans