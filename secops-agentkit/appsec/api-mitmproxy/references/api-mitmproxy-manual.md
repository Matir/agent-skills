# mitmproxy API Security Testing Manual

## Interfaces
- **mitmproxy**: Interactive console interface for keyboard navigation.
- **mitmweb**: Web-based GUI for visual traffic inspection.
- **mitmdump**: Command-line tool for automated traffic capture and scripting.

## Core Workflows

### 1. Interactive API Traffic Inspection
1. Start mitmproxy: `mitmproxy --listen-host 0.0.0.0 --listen-port 8080`
2. Configure target app to use the proxy (localhost:8080).
3. Install mitmproxy CA certificate on the client (visit http://mitm.it).
4. Intercept, modify, and replay requests to test for vulnerabilities like IDOR or SQLi.

### 2. Mobile App Security Testing
1. Install CA certificate on the mobile device.
2. Configure device WiFi proxy to mitmproxy's IP and port.
3. Use visual interfaces (mitmweb) to exercise app features.
4. Bypass SSL pinning if necessary using Frida or other tools.

### 3. Automated Recording & Replay
```bash
# Record traffic
mitmdump -w traffic.flow

# Replay traffic to server
mitmdump -nc -r traffic.flow

# Replay with modifications via script
mitmdump -s script.py -r traffic.flow
```

### 4. Python Scripting
```python
from mitmproxy import http

class APITester:
    def request(self, flow: http.HTTPFlow):
        if "api.example.com" in flow.request.pretty_url:
            flow.request.headers["X-User-ID"] = "1" # Test for IDOR

addons = [APITester()]
```
Run with: `mitmproxy -s api-test.py`

## Operating Modes
- **Regular Proxy**: Client explicitly configures proxy.
- **Transparent Proxy**: Traffic is redirected via iptables (invisible to client).
- **Reverse Proxy**: mitmproxy acts as the server endpoint.
- **Upstream Proxy**: Chains to another proxy.

## Common Patterns

### API Authentication Testing
Capture tokens and test unauthenticated access by popping the Authorization header in a script.

### Parameter Fuzzing
Clone and modify requests with payloads for SQLi, XSS, or Path Traversal.

### GraphQL Testing
Inspect queries and test for introspection vulnerabilities by injecting `__schema` queries.

### HAR Export
Export flows to HTTP Archive format for external analysis: `mitmdump --set hardump=./traffic.har`

## Troubleshooting
- **SSL Errors**: Ensure the CA certificate is trusted. Regenerate with `rm -rf ~/.mitmproxy/` if needed.
- **No Traffic**: Check firewall rules, listen address (0.0.0.0), and client proxy settings.
- **SSL Pinning**: Use Frida or similar tools to bypass pinning in mobile apps.

## References
- [mitmproxy Documentation](https://docs.mitmproxy.org/)
- [mitmproxy GitHub](https://github.com/mitmproxy/mitmproxy)
- [OWASP API Security Top 10](https://owasp.org/www-project-api-security/)
