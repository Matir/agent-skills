### 10. Statistics and Reporting

Generate traffic statistics:

```bash
# Protocol hierarchy
tshark -r capture.pcap -q -z io,phs

# Conversation statistics
tshark -r capture.pcap -q -z conv,tcp
tshark -r capture.pcap -q -z conv,udp
tshark -r capture.pcap -q -z conv,ip

# HTTP statistics
tshark -r capture.pcap -q -z http,tree

# DNS statistics
tshark -r capture.pcap -q -z dns,tree

# Endpoints
tshark -r capture.pcap -q -z endpoints,tcp
tshark -r capture.pcap -q -z endpoints,udp

# Expert info (warnings/errors)
tshark -r capture.pcap -q -z expert
```

