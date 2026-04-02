# Nmap Network Reconnaissance Manual

This document contains exhaustive reference material for Nmap, including flags, techniques, and common patterns.

## Host Discovery Techniques
- **ICMP Echo (-PE)**: Standard ping, often blocked
- **TCP SYN (-PS)**: Half-open connection to specified ports
- **TCP ACK (-PA)**: Sends ACK packets, useful for stateful firewalls
- **UDP (-PU)**: Sends UDP packets to specified ports
- **ARP (-PR)**: Layer 2 discovery, only works on local network

## Port Scan Techniques
- **TCP SYN Scan (-sS)**: Default, stealthy half-open scan (requires root)
- **TCP Connect Scan (-sT)**: Full TCP connection (no root required)
- **UDP Scan (-sU)**: Scan UDP ports (slow but critical)
- **Version Detection (-sV)**: Probe services for version information
- **Aggressive Scan (-A)**: Enable OS detection, version detection, script scanning, traceroute

## Timing and Performance Templates
- **T0 (Paranoid)**: Extremely slow, IDS evasion
- **T1 (Sneaky)**: Very slow, IDS evasion
- **T2 (Polite)**: Slows down to use less bandwidth
- **T3 (Normal)**: Default timing
- **T4 (Aggressive)**: Faster, assumes reliable network
- **T5 (Insane)**: Very fast, may miss results

## NSE Script Categories
- **auth**: Authentication testing
- **broadcast**: Network broadcast/multicast discovery
- **brute**: Brute-force password auditing
- **default**: Default safe scripts (-sC)
- **discovery**: Network and service discovery
- **dos**: Denial of service testing (use with caution)
- **exploit**: Exploitation attempts (authorized only)
- **external**: External resource queries (WHOIS, etc.)
- **fuzzer**: Fuzzing attacks
- **intrusive**: Intrusive scanning (may crash services)
- **malware**: Malware detection
- **safe**: Safe scripts unlikely to crash services
- **version**: Version detection enhancement
- **vuln**: Vulnerability detection

## Common Patterns

### Pattern 1: External Perimeter Assessment
```bash
nmap -sn -PE -PS80,443 -PA3389 <external-network>/24 -oG - | awk '/Up$/{print $2}' > external_hosts.txt
nmap -Pn -sV -p 21,22,25,53,80,110,143,443,587,993,995,3389,8080,8443 -iL external_hosts.txt -oA external_scan
```

### Pattern 2: Internal Network Mapping
```bash
nmap -sn -PR <internal-network>/24 -oG - | awk '/Up$/{print $2}' > internal_hosts.txt
nmap -sV -p- -T4 -iL internal_hosts.txt -oA internal_full_scan
```

### Pattern 3: Web Application Discovery
```bash
nmap -p 80,443,8000,8080,8443 --open -oG - <target-network>/24 | grep 'open' | awk '{print $2}' > web_servers.txt
nmap -sV -p 80,443,8080,8443 --script=http-enum,http-headers,http-methods,http-title,http-server-header -iL web_servers.txt -oA web_enum
```

### Pattern 4: SMB/CIFS Security Audit
```bash
nmap -p 445 --script=smb-protocols,smb-security-mode,smb-os-discovery <target-ip>
```

### Pattern 5: Database Server Discovery
```bash
nmap -sV -p 1433,1521,3306,5432,5984,6379,9200,27017 <target-network>/24 -oA database_scan
```

## Firewall and IDS Evasion
- **Fragment packets**: `sudo nmap -f <target-ip>`
- **Use decoys**: `sudo nmap -D RND:10 <target-ip>`
- **Spoof source IP**: `sudo nmap -S <spoofed-ip> -e <interface> <target-ip>`
- **Randomize target order**: `nmap --randomize-hosts -iL targets.txt`

## Troubleshooting
- **No results?** ICMP may be blocked. Use `-Pn` or TCP/UDP discovery.
- **Too slow?** Use `-T4`, `--top-ports 1000`, or parallelize.
- **False positives?** Manually verify with specific tools or increase `--version-intensity`.
