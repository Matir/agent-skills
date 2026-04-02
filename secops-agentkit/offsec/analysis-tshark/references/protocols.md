### 6. Protocol Analysis

Analyze specific protocols:

**HTTP/HTTPS Analysis**:

```bash
# Extract HTTP requests
tshark -r capture.pcap -Y "http.request" -T fields -e ip.src -e http.host -e http.request.uri

# Extract HTTP User-Agents
tshark -r capture.pcap -Y "http.user_agent" -T fields -e ip.src -e http.user_agent

# HTTP status codes
tshark -r capture.pcap -Y "http.response" -T fields -e ip.src -e http.response.code

# Extract HTTP cookies
tshark -r capture.pcap -Y "http.cookie" -T fields -e ip.src -e http.cookie
```

**DNS Analysis**:

```bash
# DNS queries
tshark -r capture.pcap -Y "dns.flags.response == 0" -T fields -e ip.src -e dns.qry.name

# DNS responses
tshark -r capture.pcap -Y "dns.flags.response == 1" -T fields -e dns.qry.name -e dns.a

# DNS tunneling detection (long domain names)
tshark -r capture.pcap -Y "dns" -T fields -e dns.qry.name | awk 'length > 50'

# DNS query types
tshark -r capture.pcap -Y "dns" -T fields -e dns.qry.type -e dns.qry.name
```

**TLS/SSL Analysis**:

```bash
# TLS handshakes
tshark -r capture.pcap -Y "tls.handshake.type == 1" -T fields -e ip.src -e ip.dst -e tls.handshake.extensions_server_name

# TLS certificates
tshark -r capture.pcap -Y "tls.handshake.certificate" -T fields -e tls.handshake.certificate

# SSL/TLS versions
tshark -r capture.pcap -Y "tls" -T fields -e tls.record.version

# Weak cipher suites
tshark -r capture.pcap -Y "tls.handshake.ciphersuite" -T fields -e tls.handshake.ciphersuite
```

**SMB/CIFS Analysis**:

```bash
# SMB file access
tshark -r capture.pcap -Y "smb2" -T fields -e ip.src -e smb2.filename

# SMB authentication
tshark -r capture.pcap -Y "ntlmssp" -T fields -e ip.src -e ntlmssp.auth.username

# SMB commands
tshark -r capture.pcap -Y "smb2" -T fields -e smb2.cmd
```

