### 4. Capture Filters

Apply BPF (Berkeley Packet Filter) during capture for efficiency:

```bash
# Capture only HTTP traffic
sudo tshark -i eth0 -f "tcp port 80"

# Capture specific host
sudo tshark -i eth0 -f "host 192.168.1.100"

# Capture subnet
sudo tshark -i eth0 -f "net 192.168.1.0/24"

# Capture multiple ports
sudo tshark -i eth0 -f "tcp port 80 or tcp port 443"

# Exclude specific traffic
sudo tshark -i eth0 -f "not port 22"

# Capture SYN packets only
sudo tshark -i eth0 -f "tcp[tcpflags] & tcp-syn != 0"
```

**Common capture filters**:
- `host <ip>`: Traffic to/from IP
- `net <cidr>`: Traffic to/from network
- `port <port>`: Specific port
- `tcp|udp|icmp`: Protocol type
- `src|dst`: Direction filter
- `and|or|not`: Logical operators

### 5. Display Filters

Analyze captured traffic with Wireshark display filters:

```bash
# HTTP requests only
tshark -r capture.pcap -Y "http.request"

# HTTP responses
tshark -r capture.pcap -Y "http.response"

# DNS queries
tshark -r capture.pcap -Y "dns.flags.response == 0"

# TLS handshakes
tshark -r capture.pcap -Y "tls.handshake.type == 1"

# Suspicious traffic patterns
tshark -r capture.pcap -Y "tcp.flags.syn==1 and tcp.flags.ack==0"

# Failed connections
tshark -r capture.pcap -Y "tcp.flags.reset==1"
```

**Advanced display filters**:

```bash
# HTTP POST requests with credentials
tshark -r capture.pcap -Y "http.request.method == POST and (http contains \"password\" or http contains \"username\")"

# SMB file transfers
tshark -r capture.pcap -Y "smb2.cmd == 8 or smb2.cmd == 9"

# Suspicious User-Agents
tshark -r capture.pcap -Y "http.user_agent contains \"python\" or http.user_agent contains \"curl\""

# Large data transfers
tshark -r capture.pcap -Y "tcp.len > 1400"

# Beaconing detection (periodic traffic)
tshark -r capture.pcap -Y "http" -T fields -e frame.time_relative -e ip.dst
```

