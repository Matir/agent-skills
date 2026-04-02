# Nikto Web Server Scanner Manual

## Advanced Scanning Options

### Tuning Options
Customize scan behavior using `-Tuning <options>`:
- **0**: File Upload
- **1**: Interesting File/Seen in logs
- **2**: Misconfiguration/Default File
- **3**: Information Disclosure
- **4**: Injection (XSS/Script/HTML)
- **5**: Remote File Retrieval (Inside Web Root)
- **6**: Denial of Service
- **7**: Remote File Retrieval (Server Wide)
- **8**: Command Execution/Remote Shell
- **9**: SQL Injection
- **a**: Authentication Bypass
- **b**: Software Identification
- **c**: Remote Source Inclusion
- **d**: WebService
- **e**: Administrative Console
- **x**: Reverse Tuning (exclude specified)

### Evasion Techniques
Evade detection using `-evasion <options>`:
- **1**: Random URI encoding
- **2**: Directory self-reference (/./)
- **3**: Premature URL ending
- **4**: Prepend long random string
- **5**: Fake parameter
- **6**: TAB as request spacer
- **7**: Change case of URL
- **8**: Use Windows directory separator (\)

## Performance Tuning
Optimize scan performance:
```bash
# Increase timeout (default 10 seconds)
nikto -h http://example.com -timeout 20
# Limit maximum execution time
nikto -h http://example.com -maxtime 30m
# Disable 404 guessing
nikto -h http://example.com -no404
# Pause between tests
nikto -h http://example.com -Pause 2
```

## Common Patterns

### External Perimeter Assessment
```bash
# Scan common web ports
nikto -h example.com -p 80,443,8080,8443 -o external_scan.txt
```

### Authenticated Scanning
```bash
# Scan with authentication
nikto -h http://example.com -id admin:password -cookies "sessionid=abc123"
```

## Troubleshooting

### Issue: Scan Takes Too Long
- Limit duration: `-maxtime 15m`
- Reduce tuning: `-Tuning 123`
- Disable 404 checks: `-no404`

### Issue: WAF Blocking Scans
- Use evasion: `-evasion 1234567`
- Add delays: `-Pause 10`
- Custom User-Agent: `-useragent "legitimate-browser-string"`

## Defensive Considerations
Protect web servers against Nikto:
- **WAF Rules**: Block "Nikto" User-Agent; implement rate limiting.
- **Server Hardening**: Remove default files; disable directory listing; hide banners.
- **Monitoring**: Alert on rapid sequential 404 errors.
