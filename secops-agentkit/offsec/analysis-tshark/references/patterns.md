### Pattern 1: Incident Response Investigation

```bash
# Capture traffic during incident
sudo tshark -i eth0 -w incident_$(date +%Y%m%d_%H%M%S).pcap -a duration:300

# Analyze for lateral movement
tshark -r incident.pcap -Y "smb2 or rdp or ssh" -T fields -e ip.src -e ip.dst

# Identify C2 communication
tshark -r incident.pcap -Y "http or dns" -T fields -e ip.dst -e http.host -e dns.qry.name

# Extract IOCs
tshark -r incident.pcap -Y "ip.dst" -T fields -e ip.dst | sort -u > ioc_ips.txt
tshark -r incident.pcap -Y "dns.qry.name" -T fields -e dns.qry.name | sort -u > ioc_domains.txt
```

### Pattern 2: Malware Traffic Analysis

```bash
# Capture malware sandbox traffic
sudo tshark -i eth0 -w malware_traffic.pcap

# Extract C2 indicators
tshark -r malware_traffic.pcap -Y "http.host" -T fields -e ip.src -e http.host -e http.user_agent

# Identify DNS tunneling
tshark -r malware_traffic.pcap -Y "dns" -T fields -e dns.qry.name | awk 'length > 50'

# Extract downloaded payloads
tshark -r malware_traffic.pcap --export-objects http,malware_artifacts/

# Analyze encryption/encoding
tshark -r malware_traffic.pcap -Y "http.request.method == POST" -T fields -e data.data
```

### Pattern 3: Credential Harvesting Detection

```bash
# Monitor for credential transmission
sudo tshark -i eth0 -Y "(http.authorization or ftp or pop or imap) and not tls" -T fields -e ip.src -e ip.dst

# Extract all HTTP POST data
tshark -r capture.pcap -Y "http.request.method == POST" -T fields -e http.file_data > post_data.txt

# Search for password keywords
tshark -r capture.pcap -Y "http contains \"password\" or http contains \"passwd\"" -T fields -e ip.src -e http.request.uri

# NTLM hash extraction
tshark -r capture.pcap -Y "ntlmssp.auth.ntlmv2response" -T fields -e ntlmssp.auth.username -e ntlmssp.auth.domain -e ntlmssp.auth.ntlmv2response > ntlm_hashes.txt
```

### Pattern 4: Network Forensics

```bash
# Reconstruct HTTP conversation
tshark -r capture.pcap -q -z follow,http,ascii,0

# Timeline analysis
tshark -r capture.pcap -T fields -e frame.time -e ip.src -e ip.dst -e tcp.dstport

# Identify file transfers
tshark -r capture.pcap -Y "http.content_type contains \"application/\" or ftp-data" -T fields -e frame.number -e http.content_type

# Geolocation of connections (requires GeoIP)
tshark -r capture.pcap -T fields -e ip.src -e ip.dst -e ip.geoip.src_country -e ip.geoip.dst_country
```

### Pattern 5: Wireless Security Assessment

```bash
# Capture wireless traffic (monitor mode required)
sudo tshark -i mon0 -w wireless_capture.pcap

# Identify wireless networks
tshark -r wireless_capture.pcap -Y "wlan.fc.type_subtype == 0x08" -T fields -e wlan.ssid -e wlan.bssid

# Detect deauth attacks
tshark -r wireless_capture.pcap -Y "wlan.fc.type_subtype == 0x0c"

# WPA handshake capture
tshark -r wireless_capture.pcap -Y "eapol"

# Client probing activity
tshark -r wireless_capture.pcap -Y "wlan.fc.type_subtype == 0x04" -T fields -e wlan.sa -e wlan.ssid
```

