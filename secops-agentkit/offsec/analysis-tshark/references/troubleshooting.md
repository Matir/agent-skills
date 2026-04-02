## Troubleshooting

### Issue: "Permission denied" when capturing

**Solutions**:
```bash
# Run with sudo
sudo tshark -i eth0

# Or add user to wireshark group (Linux)
sudo usermod -a -G wireshark $USER
sudo setcap cap_net_raw,cap_net_admin+eip /usr/bin/tshark

# Logout and login for group changes to take effect
```

### Issue: "No interfaces found"

**Solutions**:
```bash
# Verify tshark installation
tshark --version

# List interfaces with sudo
sudo tshark -D

# Check interface status
ip link show
ifconfig -a
```

### Issue: Capture file is huge

**Solutions**:
```bash
# Use capture filters to reduce size
sudo tshark -i eth0 -f "not port 22" -w capture.pcap

# Use ring buffer
sudo tshark -i eth0 -w capture.pcap -b filesize:100000 -b files:5

# Limit packet size (snaplen)
sudo tshark -i eth0 -s 128 -w capture.pcap
```

### Issue: Cannot decrypt TLS traffic

**Solutions**:
```bash
# Provide SSL key log file (requires SSLKEYLOGFILE environment variable)
tshark -r capture.pcap -o tls.keylog_file:sslkeys.log -Y "http"

# Use pre-master secret
tshark -r capture.pcap -o tls.keys_list:192.168.1.100,443,http,/path/to/server.key
```

