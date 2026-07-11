# Nmap Cheat Sheet

Nmap ("Network Mapper") is a free and open-source utility for network discovery and security auditing. This cheat sheet summarizes the most commonly used flags, scan techniques, and options.

---

## 🎯 Target Specification
Ways to define hosts or networks to scan:
*   `nmap 192.168.1.1` — Scan a single IP address.
*   `nmap 192.168.1.1-100` — Scan a range of IPs (`.1` through `.100`).
*   `nmap 192.168.1.0/24` — Scan an entire subnet (CIDR notation).
*   `nmap scanme.nmap.org` — Scan a domain name.
*   `nmap -iL targets.txt` — Scan targets listed in a text file (one per line).
*   `nmap -iR 100` — Scan 100 random targets (excluding private networks by default).
*   `nmap --exclude 192.168.1.5` — Exclude specific hosts from the scan.

---

## 🔍 Host Discovery (Discovery Options)
Identify which hosts are active without performing full port scans:
*   `-sn` — Ping Scan (formerly `-sP`). Discovers live hosts but does not perform a port scan.
*   `-Pn` — Treat all hosts as online. Skips host discovery entirely (crucial if target blocks ICMP/ping requests).
*   `-PS[portlist]` — TCP SYN Ping. Sends SYN packets to specified ports to find live hosts.
*   `-PA[portlist]` — TCP ACK Ping. Sends ACK packets to bypass firewalls filtering SYN.
*   `-PU[portlist]` — UDP Ping. Sends UDP packets to find hosts that respond.
*   `-n` — Disable reverse DNS resolution. **Speeds up scans significantly.**
*   `-R` — Always resolve DNS. Forces reverse DNS lookup for all targets.

---

## 🚀 Scan Techniques
Choose how to scan ports (some require root/administrator privileges):
*   `-sS` — **TCP SYN Scan (Stealth / Half-open)**. Default and most popular scan. Fast and relatively stealthy.
*   `-sT` — **TCP Connect Scan**. Establishes a full TCP connection. Used when raw packet privileges are unavailable (e.g., non-root user).
*   `-sU` — **UDP Scan**. Identifies active UDP services (DNS, DHCP, SNMP, etc.). Typically slow.
*   `-sA` — **TCP ACK Scan**. Maps firewall rulesets and determines if ports are filtered or unfiltered.
*   `-sN` / `-sF` / `-sX` — **Null, FIN, and Xmas Scans**. Stealthy scans that can bypass certain non-stateful firewalls.

---

## 🔌 Port Specification
Define which ports to scan:
*   `-p 80` — Scan a specific port.
*   `-p 80,443,8080` — Scan multiple specific ports.
*   `-p 1-1024` — Scan a range of ports.
*   `-p-` — Scan all 65,535 ports (equivalent to `-p 1-65535`).
*   `-F` — Fast scan. Scan the 100 most common ports (default is 1,000).
*   `--top-ports 100` — Scan the top N most common ports.
*   `-p U:53,111,T:21-25,80` — Scan specific UDP ports and TCP ports in a single run.

---

## 🛡️ Service and OS Detection
Enumerate more information about the target services and operating system:
*   `-sV` — **Service version detection**. Probes open ports to determine service name, version, and details.
*   `--version-intensity [0-9]` — Set the intensity level of version detection. `7` is default; `9` is most thorough.
*   `-O` — **OS detection**. Attempts to identify the operating system based on TCP/IP stack fingerprinting.
*   `--osscan-limit` — Limit OS detection to promising targets (only targets with at least one open and one closed port).
*   `--osscan-guess` / `--fuzzy` — Guess OS detection results more aggressively if no exact match is found.

---

## ⚡ Timing and Performance
Tune scan speed and resources:
*   `-T0` (Paranoid) — Very slow, used to evade Intrusion Detection Systems (IDS).
*   `-T1` (Sneaky) — Slow, also used to evade IDS.
*   `-T2` (Polite) — Slows down to consume less bandwidth and avoid crashing the target.
*   `-T3` (Normal) — Default speed setting.
*   `-T4` (Aggressive) — Fast, assumes reliable and fast network. **Recommended for general use.**
*   `-T5` (Insane) — Extremely fast, may miss open ports on slower/congested networks.
*   `--min-rate [number]` — Send packets at a rate no slower than X per second.
*   `--max-rate [number]` — Send packets at a rate no faster than X per second.

---

## 🤖 Nmap Scripting Engine (NSE)
Automate vulnerability scanning, discovery, and exploit verification using Lua scripts:
*   `-sC` — Run default scripts. Equivalent to `--script=default`.
*   `--script=default,safe` — Run scripts that belong to the "default" or "safe" category.
*   `--script=http-title` — Run a specific script.
*   `--script="http-*"` — Run all scripts starting with "http-".
*   `--script-args=http.useragent="Mozilla"` — Pass arguments to NSE scripts.

---

## 🥷 Firewall/IDS Evasion and Spoofing
Techniques to bypass security controls and cover footprints:
*   `-f` — Fragment packets. Splits IP packets into smaller fragments to bypass simple packet filters.
*   `-mtu [value]` — Set custom Maximum Transmission Unit. Must be a multiple of 8.
*   `-D decoy1,decoy2,ME` — Send scans using decoys to mask your own IP.
*   `-S [IP_Address]` — Spoof source IP address.
*   `-e [interface]` — Use a specific network interface.
*   `--source-port [port]` / `-g [port]` — Spoof source port number (e.g., use 53 or 80 to bypass firewall rules).
*   `--data-length [size]` — Append random data to sent packets to change their signature.
*   `--proxies [url1,url2]` — Route connections through HTTP/SOCKS4 proxies.

---

## 💾 Output Formats
Save scan results to files:
*   `-oN filename.nmap` — Normal output. Saves human-readable output as seen on screen.
*   `-oX filename.xml` — XML output. Useful for parsing in other tools (Metasploit, etc.).
*   `-oG filename.gnmap` — Grepable output. Structured to easily search with `grep`, `awk`, etc.
*   `-oA basename` — Output in all three major formats (generates `basename.nmap`, `basename.xml`, and `basename.gnmap`).
*   `--stats-every [time]` — Print periodic status messages (e.g., `--stats-every 10s`).
*   `-v` / `-vv` — Increase verbosity levels.
*   `-d` / `-dd` — Increase debugging output.

---

## 🌟 Common Scan Recipes & Combos

### 1. Basic Quick Scan (Top 100 ports)
```bash
nmap -F 192.168.1.1
```

### 2. Standard Network Survey (No Ping, Fast Timing)
Useful when host blocks ICMP but is online.
```bash
nmap -Pn -T4 192.168.1.0/24
```

### 3. Comprehensive Recon Scan (Deep Info)
Enables OS detection, service version, default scripts, and traceroute.
```bash
nmap -A -T4 192.168.1.1
```
*Note: `-A` is equivalent to `-O -sV -sC --traceroute`.*

### 4. Stealth Port Scan (TCP SYN)
Requires root privileges.
```bash
sudo nmap -sS -Pn -T4 -p- 192.168.1.1
```

### 5. Vulnerability Scan
Runs vulnerability detection scripts against the target.
```bash
nmap -sV --script vuln 192.168.1.1
```
