# TShark Manual

## Advanced Filters

### Capture Filters (BPF)
```bash
# Capture only HTTP
sudo tshark -i eth0 -f "tcp port 80"

# Specific host and port
sudo tshark -i eth0 -f "host 10.0.0.1 and port 443"
```

### Display Filters
```bash
# HTTP GET requests
tshark -r cap.pcap -Y "http.request.method == GET"

# Suspicious User-Agents
tshark -r cap.pcap -Y "http.user_agent contains \"nmap\""

# SMB file transfers
tshark -r cap.pcap -Y "smb2.filename"
```

## Forensic Extraction

### Credential Extraction
```bash
# HTTP Basic Auth
tshark -r cap.pcap -Y "http.authbasic" -T fields -e http.authbasic

# FTP User/Pass
tshark -r cap.pcap -Y "ftp.request.command == USER or ftp.request.command == PASS"
```

### File Extraction
```bash
# Export HTTP objects
tshark -r cap.pcap --export-objects http,extracted_files/

# Extract SMB files
tshark -r cap.pcap --export-objects smb,extracted_files/
```

## Malware Detection Patterns

### Beaconing Detection
```bash
tshark -r cap.pcap -Y "http" -T fields -e frame.time_relative -e ip.dst -e http.host | sort | uniq -c
```

### DNS Anomaly Detection (DGA)
```bash
tshark -r cap.pcap -Y "dns.qry.name" -T fields -e dns.qry.name | awk -F'.' '{print $(NF-1)"."$NF}' | sort | uniq -c
```

## Troubleshooting & Evasion
- **Large Files**: Use `-2` for two-pass analysis or `-Y` for initial filtering.
- **TLS Decryption**: Use `ssl.keylog_file:<path>` to decrypt traffic with a keylog file.
- **Missing Packets**: Increase buffer size with `-B <size_in_MB>`.
