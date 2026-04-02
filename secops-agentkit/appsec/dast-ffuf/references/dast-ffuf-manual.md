# ffuf - Fast Web Fuzzer Manual

## Core Workflows

### 1. Directory and File Enumeration
```bash
# Basic directory discovery
ffuf -u https://target.com/FUZZ -w common.txt

# Recursive enumeration with file extensions
ffuf -u https://target.com/FUZZ -w wordlist.txt -recursion -recursion-depth 2 -e .php,.html
```

### 2. Parameter Fuzzing
```bash
# GET parameter names
ffuf -u https://target.com/api?FUZZ=test -w parameter-names.txt -fs 0

# POST data fuzzing (JSON)
ffuf -u https://target.com/api/login -X POST -d '{"user":"admin","pass":"FUZZ"}' -w passwords.txt -H "Content-Type: application/json"
```

### 3. VHost and Subdomain Discovery
```bash
# Virtual host discovery
ffuf -u https://target.com -H "Host: FUZZ.target.com" -w subdomains.txt -fs 0
```

### 4. Authentication Testing
```bash
# Fuzz usernames first, then passwords for identified users
ffuf -u https://target.com/login -X POST -d "user=FUZZ&pass=test" -w users.txt -mr "Invalid password"
```

## Fuzzing Modes
- **Clusterbomb**: Cartesian product of all wordlists (every combination).
- **Pitchfork**: Parallel iteration (user1/pass1, user2/pass2).
- **Sniper**: Single wordlist at a single position.

## Filtering and Matching
- `-mc`: Match status codes (e.g., `-mc 200,403`).
- `-fc`: Filter status codes (exclude).
- `-fs`: Filter by response size (very useful for VHost discovery).
- `-ac`: Auto-calibration (automatically filters baseline noise).

## Common Patterns

### API Endpoint Discovery
Enumerate paths like `/api/v1/FUZZ` with specific API wordlists.

### Rate-Limited Fuzzing
Use `-t 5` for low threads and `-p 0.5-1.0` for random delays.

### Custom Headers
Fuzz values for headers like `X-Forwarded-For` or `User-Agent`.

## Troubleshooting
- **Too many results**: Use `-ac` or manually filter by size (`-fs`) or word count (`-fw`).
- **Getting blocked**: Lower threads (`-t`), add delays (`-p`), and use a realistic `User-Agent`.
- **Missing files**: Always try common extensions with `-e .php,.bak,.zip,.txt`.

## References
- [ffuf GitHub Repository](https://github.com/ffuf/ffuf)
- [SecLists](https://github.com/danielmiessler/SecLists)
- [OWASP WSTG](https://owasp.org/www-project-web-security-testing-guide/)
