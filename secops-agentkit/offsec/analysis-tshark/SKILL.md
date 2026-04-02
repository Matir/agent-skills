---
name: analysis-tshark
description: 'Network protocol analyzer and packet capture tool for traffic analysis, security investigations, and forensic examination using Wireshark''s command-line interface. Use when: (1) Analyzing network traffic for security incidents and malware detection, (2) Capturing and filtering packets for forensic analysis, (3) Extracting credentials and sensitive data from network captures, (4) Investigating network anomalies and attack patterns, (5) Validating encryption and security controls, (6) Performing protocol analysis for vulnerability research.

  '
metadata:
  version: 0.1.0
  maintainer: sirappsec@gmail.com
  category: offsec
  tags:
  - packet-capture
  - network-analysis
  - forensics
  - tshark
  - wireshark
  - traffic-analysis
  frameworks:
  - MITRE-ATT&CK
  - NIST
  dependencies:
    packages:
    - tshark
    - wireshark
    tools:
    - tcpdump
    - python3
  references:
  - https://www.wireshark.org/docs/man-pages/tshark.html
  - https://wiki.wireshark.org/DisplayFilters
  - https://attack.mitre.org/techniques/T1040/
---
# TShark Network Protocol Analyzer

## Overview

TShark is the command-line network protocol analyzer from the Wireshark project. It provides powerful packet capture and analysis capabilities for security investigations, forensic analysis, and network troubleshooting. This skill covers authorized security operations including traffic analysis, credential extraction, malware detection, and forensic examination.

**IMPORTANT**: Network packet capture may expose sensitive information and must only be conducted with proper authorization. Ensure legal compliance and privacy considerations before capturing network traffic.

## Quick Start

Basic packet capture and analysis:

```bash
# Capture packets on interface
sudo tshark -i eth0

# Capture 100 packets and save to file
sudo tshark -i eth0 -c 100 -w capture.pcap

# Read and analyze capture file
tshark -r capture.pcap

# Apply display filter
tshark -r capture.pcap -Y "http.request.method == GET"

# Extract HTTP objects
tshark -r capture.pcap --export-objects http,extracted_files/
```

## Core Workflow

### Network Analysis Workflow

Progress:
[ ] 1. Verify authorization for packet capture
[ ] 2. Identify target interface and capture requirements
[ ] 3. Capture network traffic with appropriate filters
[ ] 4. Analyze captured packets for security indicators
[ ] 5. Extract artifacts (files, credentials, sessions)
[ ] 6. Document findings and security implications
[ ] 7. Securely handle and store capture files
[ ] 8. Clean up sensitive data per retention policy

Work through each step systematically. Check off completed items.

### 1. Authorization Verification

**CRITICAL**: Before any packet capture:
- Confirm written authorization for network monitoring
- Verify legal compliance (wiretapping laws, privacy regulations)
- Understand data handling and retention requirements
- Document scope of capture (interfaces, duration, filters)
- Ensure secure storage for captured data

### 2. Interface Discovery

Identify available network interfaces:

```bash
# List all interfaces
tshark -D

# List with interface details
sudo tshark -D

# Capture on specific interface
sudo tshark -i eth0
sudo tshark -i wlan0

# Capture on any interface
sudo tshark -i any

# Capture on multiple interfaces
sudo tshark -i eth0 -i wlan0
```

**Interface types**:
- **eth0/ens33**: Ethernet interface
- **wlan0**: Wireless interface
- **lo**: Loopback interface
- **any**: All interfaces (Linux only)
- **mon0**: Monitor mode interface (wireless)

### 3. Basic Packet Capture

Capture network traffic:

```bash
# Capture indefinitely (Ctrl+C to stop)
sudo tshark -i eth0

# Capture specific number of packets
sudo tshark -i eth0 -c 1000

# Capture for specific duration (seconds)
sudo tshark -i eth0 -a duration:60

# Capture to file
sudo tshark -i eth0 -w capture.pcap

# Capture with ring buffer (rotate files)
sudo tshark -i eth0 -w capture.pcap -b filesize:100000 -b files:5
```

**Capture options**:
- `-c <count>`: Capture packet count
- `-a duration:<sec>`: Auto-stop after duration
- `-w <file>`: Write to file
- `-b filesize:<KB>`: Rotate at file size
- `-b files:<num>`: Keep N ring buffer files

### 4. Capture Filters

Apply BPF (Berkeley Packet Filter) during capture for efficiency. See **[references/filters.md](references/filters.md)** for detailed capture filters for HTTP, specific hosts, subnets, and protocol flags.

```bash
# Example: Capture only HTTP traffic
sudo tshark -i eth0 -f "tcp port 80"
```

### 5. Display Filters

Analyze captured traffic with Wireshark display filters. See **[references/filters.md](references/filters.md)** for advanced display filters for HTTP POST, SMB file transfers, suspicious User-Agents, and beaconing detection.

```bash
# Example: HTTP requests only
tshark -r capture.pcap -Y "http.request"
```

### 6. Protocol Analysis

Perform deep dive analysis on specific protocols including HTTP/HTTPS, DNS, TLS/SSL, and SMB/CIFS. See **[references/protocols.md](references/protocols.md)** for field extraction and analysis techniques.

### 7. Credential Extraction

Extract credentials from network traffic (HTTP Basic Auth, FTP, NTLM/Kerberos, Email). See **[references/extraction.md](references/extraction.md)** for forensic extraction patterns.

### 8. File Extraction

Export files from packet captures (HTTP, SMB, DICOM, IMF). See **[references/extraction.md](references/extraction.md)** for export commands and manual file reconstruction.

### 9. Malware Detection

Identify malicious network activity:

```bash
# Detect common C2 beaconing patterns
tshark -r capture.pcap -Y "http" -T fields -e frame.time_relative -e ip.dst -e http.host | sort | uniq -c | sort -rn

# Suspicious DNS queries (DGA domains)
tshark -r capture.pcap -Y "dns.qry.name" -T fields -e dns.qry.name | awk -F'.' '{print $(NF-1)"."$NF}' | sort | uniq -c | sort -rn

# Detect port scanning
tshark -r capture.pcap -Y "tcp.flags.syn==1 and tcp.flags.ack==0" -T fields -e ip.src -e ip.dst -e tcp.dstport | sort | uniq -c | sort -rn

# Detect data exfiltration (large uploads)
tshark -r capture.pcap -Y "http.request.method == POST" -T fields -e ip.src -e http.content_length | awk '$2 > 1000000'

# Suspicious executable downloads
tshark -r capture.pcap -Y "http.response and (http.content_type contains \"application/exe\" or http.content_type contains \"application/x-dosexec\")"
```

### 10. Statistics and Reporting

Generate traffic statistics including protocol hierarchy, conversation stats, and endpoint analysis. See **[references/reporting.md](references/reporting.md)** for detailed statistics commands and reporting options.

```bash
# Example: Protocol hierarchy
tshark -r capture.pcap -q -z io,phs
```

## Security Considerations

### Authorization & Legal Compliance

- **Written Authorization**: Obtain explicit permission for network monitoring
- **Privacy Laws**: Comply with wiretapping and privacy regulations (GDPR, CCPA, ECPA)
- **Data Minimization**: Capture only necessary traffic for investigation
- **Credential Handling**: Treat extracted credentials as highly sensitive
- **Retention Policy**: Follow data retention and secure deletion requirements

### Operational Security

- **Encrypted Storage**: Encrypt capture files at rest
- **Access Control**: Restrict access to packet captures
- **Secure Transfer**: Use encrypted channels for capture file transfer
- **Anonymization**: Remove or redact PII when sharing captures
- **Chain of Custody**: Maintain forensic integrity for legal proceedings

### Audit Logging

Document all packet capture activities:
- Capture start and end timestamps
- Interface(s) captured
- Capture filters applied
- File names and storage locations
- Personnel who accessed captures
- Purpose of capture and investigation findings
- Secure deletion timestamps

### Compliance

- **MITRE ATT&CK**: T1040 (Network Sniffing)
- **NIST CSF**: DE.AE (Detection Processes - Anomalies and Events)
- **PCI-DSS**: Network security monitoring requirements
- **ISO 27001**: A.12.4 Logging and monitoring
- **GDPR**: Data protection and privacy requirements

## Common Patterns

TShark is used across various security scenarios including incident response, malware analysis, and network forensics. See **[references/patterns.md](references/patterns.md)** for detailed patterns including:
- **Incident Response**: Capture and analysis during active incidents.
- **Malware Traffic Analysis**: Extracting C2 indicators and payloads.
- **Credential Harvesting Detection**: Monitoring for unencrypted credential transmission.
- **Network Forensics**: Conversation reconstruction and timeline analysis.
- **Wireless Security**: Capturing and analyzing 802.11 traffic.

## Integration & Troubleshooting

For SIEM integration (JSON/CSV export), automation scripting, and troubleshooting common issues (permissions, huge files, TLS decryption), see the following resources:
- **[references/reporting.md](references/reporting.md)**: SIEM integration and automation scripting.
- **[references/troubleshooting.md](references/troubleshooting.md)**: Common issues and defensive considerations.

## Defensive Considerations

Organizations should protect against unauthorized packet capture:

- **Network Segmentation**: Reduce exposure to packet sniffing
- **Encryption**: Use TLS/SSL to protect sensitive data in transit
- **Switch Security**: Enable port security and DHCP snooping
- **Wireless Security**: Use WPA3, disable broadcast SSID
- **Intrusion Detection**: Monitor for promiscuous mode interfaces
- **Physical Security**: Protect network infrastructure from tap devices

Detect packet capture activity:
- Monitor for promiscuous mode network interfaces
- Detect ARP spoofing and MAC flooding attacks
- Audit administrative access to network devices
- Monitor for unusual outbound data transfers
- Deploy network access control (802.1X)

## Bundled Resources

### References (`references/`)

- **[filters.md](references/filters.md)** - Detailed capture and display filters for advanced traffic analysis.
- **[protocols.md](references/protocols.md)** - Deep dive protocol analysis for HTTP, DNS, TLS, and SMB.
- **[extraction.md](references/extraction.md)** - Forensic extraction techniques for credentials and files.
- **[reporting.md](references/reporting.md)** - Statistics, SIEM integration, and automation patterns.
- **[patterns.md](references/patterns.md)** - Common security investigation patterns (IR, malware, wireless).
- **[troubleshooting.md](references/troubleshooting.md)** - Solutions for common issues and defensive considerations.

## References

- [TShark Man Page](https://www.wireshark.org/docs/man-pages/tshark.html)
- [Wireshark Display Filters](https://wiki.wireshark.org/DisplayFilters)
- [MITRE ATT&CK: Network Sniffing](https://attack.mitre.org/techniques/T1040/)
- [NIST SP 800-92: Guide to Computer Security Log Management](https://csrc.nist.gov/publications/detail/sp/800-92/final)
- [Practical Packet Analysis Book](https://nostarch.com/packetanalysis3)
