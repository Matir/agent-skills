# WooYun Legacy Manual

## Detailed Vulnerability Patterns

### SQL Injection
**High-risk parameters**: `id`, `sort_id`, `username`, `search`, `page`, `cat_id`.
- **Detection**: Use string terminators (`'`, `"`, `)`) and DB fingerprinting (`@@version`).
- **Bypass**: Whitespace (`/**/`), Keywords (`sel%00ect`), Quotes (`0x` hex).

### Cross-Site Scripting (XSS)
**Output points**: User profiles, search reflections, file metadata, email bodies.
- **Bypass**: Tag mutation (`<ScRiPt>`), Event handlers (`onerror`), Protocol handlers (`javascript:`).

### Command Execution
**Entry points**: System wrappers (`ping`), file ops (`image processing`), code eval (`eval`).
- **Chaining**: `;`, `|`, `||`, `&&` (Linux); `&`, `|` (Windows).
- **Bypass**: Whitespace (`${IFS}`), Keywords (`ca\t`), Encoding (`$(printf "\x63")`).

### File Upload
**Bypass detection**:
- **Extension**: `.php5`, `.phtml`, `.php::$DATA`.
- **Content-Type**: `image/gif` + PHP body.
- **Parser Discrepancy**: IIS 6.0 (`/1.asp;.jpg`), Nginx (`/1.jpg/1.php`).

### Path Traversal
**High-risk parameters**: `file`, `path`, `url`, `template`, `download`.
- **Payloads**: `../../../etc/passwd`, `%2e%2e%2f`, `..%252f`.
- **Null byte**: `../../../etc/passwd%00.jpg`.

## Core Mental Model
```
1. Input Source (Where does data come from?)
2. Data Path (Where does data flow?)
3. Trust Boundaries (Where is data trusted?)
4. Processing Logic (How is data processed?)
5. Output Sink (Where does data end up?)
```

## Defense Quick Reference
| Vulnerability | Core Defense |
|---------------|--------------|
| SQL Injection | Parameterized queries |
| XSS | Context-aware encoding + CSP |
| Command Execution | Avoid shell; use allowlist |
| File Upload | Allowlist ext + rename + isolate |
| Path Traversal | Resolve canonical paths + allowlist |
| Logic Flaws | Server-side validation of all logic |
