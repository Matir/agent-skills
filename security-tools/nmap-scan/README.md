# Nmap (`Network Mapper`) Cheat Sheet

A comprehensive, quick-reference guide for the **Nmap** network exploration and security auditing tool.

---

## 🎯 Target Specification

How to specify hosts, IP addresses, subnets, and target files.

| Command / Option | Description | Example |
| :--- | :--- | :--- |
| `nmap <target>` | Scan a single IP or hostname | `nmap 192.168.1.1` or `nmap scanme.nmap.org` |
| `nmap <target1> <target2>` | Scan multiple specific targets | `nmap 192.168.1.1 10.0.0.1` |
| `nmap <range>` | Scan an IP range | `nmap 192.168.1.1-100` |
| `nmap <CIDR>` | Scan an entire subnet (CIDR notation) | `nmap 192.168.1.0/24` |
| `nmap -iL <file>` | Scan targets listed in a file | `nmap -iL targets.txt` |
| `nmap -iR <num>` | Scan `<num>` random hosts | `nmap -iR 100` |
| `nmap --exclude <targets>` | Exclude specific hosts or networks | `nmap 192.168.1.0/24 --exclude 192.168.1.254` |
| `nmap --excludefile <file>` | Exclude targets listed in a file | `nmap 192.168.1.0/24 --excludefile skip.txt` |

---

## 🔍 Host Discovery (Ping Scanning)

Determine which hosts are up and alive before performing detailed port scans.

| Command / Option | Description |
| :--- | :--- |
| `-sL` | **List Scan:** List targets to scan without sending traffic to them. |
| `-sn` | **Ping Scan:** Disable port scanning; only determine if hosts are up. |
| `-Pn` | **No Ping:** Treat all specified hosts as online (skip host discovery). |
| `-PS/PA/PU/PY[portlist]` | **TCP SYN/ACK, UDP, or SCTP discovery:** Ping target ports (default: 80). |
| `-PE/PP/PM` | **ICMP Echo, Timestamp, and Netmask request:** Discovery probes. |
| `-PR` | **ARP Ping:** Local network discovery (fast and reliable on local subnet). |
| `-n` | **No DNS Resolution:** Never do reverse DNS lookup (speeds up scanning). |
| `-R` | **DNS Resolution:** Always resolve hostnames for all target IPs. |

---

## 📡 Port Scan Techniques

Methods used to probe ports and determine their state (`open`, `closed`, `filtered`).

| Command / Option | Description | Notes |
| :--- | :--- | :--- |
| `-sS` | **TCP SYN Scan (Half-open)** | Default scan when run as root/administrator. Fast, relatively stealthy. |
| `-sT` | **TCP Connect Scan** | Default scan for non-root users. Completes the full 3-way handshake. |
| `-sU` | **UDP Scan** | Scans UDP ports (e.g., DNS 53, SNMP 161). Slower than TCP scans. |
| `-sY` | **SCTP INIT Scan** | SCTP equivalent of TCP SYN scan. |
| `-sN / -sF / -sX` | **Null, FIN, and Xmas Scans** | Exploit TCP RFC subtleties to bypass certain stateless firewalls. |
| `-sA` | **TCP ACK Scan** | Used to map firewall rulesets and determine if ports are filtered. |
| `-sW` | **TCP Window Scan** | Exploits an implementation quirk in some systems to detect open ports. |
| `-sM` | **TCP Maimon Scan** | Sends FIN/ACK probes; named after Uriel Maimon. |

---

## 🔢 Port Specification & Order

Control which ports are scanned and in what order.

| Command / Option | Description | Example |
| :--- | :--- | :--- |
| `-p <port range>` | Scan specific ports | `-p 22,80,443` or `-p 1-1024` |
| `-p-` | Scan all 65,535 ports | `nmap -p- 192.168.1.1` |
| `-p U:53,T:21-25,80` | Scan specific UDP and TCP ports | `-sU -sS -p U:53,161,T:22,80` |
| `-F` | **Fast mode:** Scan top 100 most common ports | `nmap -F 192.168.1.1` |
| `--top-ports <num>` | Scan the `<num>` highest-ratio ports | `nmap --top-ports 1000 192.168.1.1` |
| `-r` | **Sequential scan:** Do not randomize port scan order | `nmap -r -p 1-100 192.168.1.1` |

---

## 🛠️ Service Version & OS Detection

Identify operating systems, running services, and specific software versions.

| Command / Option | Description |
| :--- | :--- |
| `-sV` | **Version Detection:** Probe open ports to determine service/version info. |
| `--version-intensity <level>`| Set version scanning intensity from `0` (light) to `9` (all probes). |
| `-O` | **OS Detection:** Enable OS detection via TCP/IP stack fingerprinting. |
| `--osscan-guess` | Aggressive OS guessing if exact match is not found. |
| `-A` | **Aggressive Scan:** Enables OS detection (`-O`), version detection (`-sV`), script scanning (`-sC`), and traceroute (`--traceroute`). |

---

## ⏱️ Timing & Performance

Optimize scan speed, timeouts, and resource utilization.

| Option | Name | Description |
| :--- | :--- | :--- |
| `-T0` | **Paranoid** | Extremely slow; used for IDS evasion (one probe every 5 minutes). |
| `-T1` | **Sneaky** | Very slow; used for IDS evasion (one probe every 15 seconds). |
| `-T2` | **Polite** | Slows down to consume less bandwidth and server resources. |
| `-T3` | **Normal** | **Default speed** when no `-T` flag is specified. |
| `-T4` | **Aggressive** | Fast scan; assumes a fast and reliable network (recommended for modern LANs). |
| `-T5` | **Insane** | Extraordinarily fast; likely to drop packets or sacrifice accuracy. |

### Fine-Tuning Performance

```bash
--min-hostgroup <size> / --max-hostgroup <size>     # Parallel host scan group sizes
--min-parallelism <num> / --max-parallelism <num>   # Probe parallelization limits
--min-rtt-timeout <ms> / --max-rtt-timeout <ms>     # Probe round-trip time timeouts
--max-retries <tries>                               # Cap number of port scan probe retransmissions
--host-timeout <time>                               # Give up on target after specified time (e.g., 30m)
--scan-delay <time> / --max-scan-delay <time>       # Adjust delay between probes
--min-rate <rate> / --max-rate <rate>               # Send packets no slower/faster than <rate> per second
```

---

## 📜 Nmap Scripting Engine (NSE)

Automate vulnerability checks, brute-forcing, and advanced discovery using Lua scripts.

| Command / Option | Description | Example |
| :--- | :--- | :--- |
| `-sC` | Run default set of scripts (equivalent to `--script=default`) | `nmap -sC 192.168.1.1` |
| `--script <script/category>` | Run specific script(s) or script category | `nmap --script=http-title 192.168.1.1` |
| `--script-args <args>` | Pass arguments to scripts | `--script-args=http.useragent="Custom"` |
| `--script-updatedb` | Update the script database | `nmap --script-updatedb` |

### Popular Script Categories
* `default` - Safe, useful scripts run by `-sC`.
* `vuln` - Check for specific known vulnerabilities (e.g., EternalBlue, Heartbleed).
* `auth` - Test authentication controls and credentials.
* `brute` - Brute-force credentials for services (SSH, FTP, HTTP, etc.).
* `discovery` - Gather information about target services and architecture.
* `safe` - Non-intrusive scripts unlikely to crash target services.

---

## 🛡️ Firewall / IDS Evasion & Spoofing

Techniques to mask scan origins, evade intrusion detection systems, or bypass firewall restrictions.

| Command / Option | Description |
| :--- | :--- |
| `-f` / `-mtu <val>` | Fragment packets (or specify custom MTU) to make packet inspection harder. |
| `-D <decoy1,decoy2,ME>`| **Decoy scan:** Mask your IP among decoy IP addresses. |
| `-S <IP_Address>` | **Spoof source IP:** Specify a fake source IP address. |
| `-e <iface>` | Specify the network interface to send packets through. |
| `-g <port>` / `--source-port <port>`| Use a specific source port number (e.g., DNS 53 or HTTP 80 to bypass poorly configured firewalls). |
| `--data-length <num>` | Append random data to sent packets so they don't look like standard Nmap probes. |
| `--spoof-mac <mac>` | Spoof your MAC address (can be a vendor name like `Apple` or a specific hex MAC). |
| `--badsum` | Send packets with invalid TCP/UDP/SCTP checksums to detect IDS/firewalls. |

---

## 💾 Output Formats

Save scan results for analysis or parsing.

| Command / Option | Description | Example |
| :--- | :--- | :--- |
| `-oN <file>` | **Normal output:** Standard human-readable Nmap format | `-oN scan.txt` |
| `-oX <file>` | **XML output:** Machine-readable XML format (ideal for parsing or importing into tools) | `-oX scan.xml` |
| `-oG <file>` | **Greppable output:** One-line per host format for grep/awk/sed | `-oG scan.gnmap` |
| `-oA <basename>` | **All formats:** Output Normal (`.nmap`), XML (`.xml`), and Greppable (`.gnmap`) files simultaneously | `-oA my_scan` |
| `-v` / `-vv` | Increase verbosity level (print results as they are found) | `-vv` |
| `-d` / `-dd` | Increase debugging output level | `-dd` |
| `--packet-trace` | Trace all packets sent and received | `--packet-trace` |

---

## 💡 Practical Recipes & Common Workflows

### 1. Quick Local Subnet Discovery (Ping Only)
```bash
nmap -sn 192.168.1.0/24
```

### 2. Standard Comprehensive Scan (Aggressive + All Ports)
```bash
nmap -A -p- -T4 -oA full_audit 192.168.1.50
```

### 3. Fast Vulnerability Sweep
```bash
nmap -sV --script=vuln -T4 target.example.com
```

### 4. Stealthy SYN Scan on Top 1000 Ports
```bash
nmap -sS -n -Pn -T2 --top-ports 1000 10.10.10.10
```

### 5. UDP Service Audit
```bash
nmap -sU -p 53,67,68,123,161,500 -sV 192.168.1.1
```

### 6. Firewall Evasion via Source Port 53 (DNS)
```bash
nmap -sS --source-port 53 -Pn -f 192.168.1.100
```
