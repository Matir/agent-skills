# Velociraptor Manual

## VQL Query Patterns

### Process Investigation
```sql
SELECT Pid, Ppid, Name, CommandLine, Username, Exe
FROM pslist()
WHERE Name =~ "(?i)(powershell|cmd|wscript)"
  AND CommandLine =~ "(?i)(invoke|download|iex)"
```

### Network Connection Analysis
```sql
SELECT Laddr.IP AS LocalIP, Raddr.IP AS RemoteIP, Status, Pid,
       process_tracker_get(id=Pid).Name AS ProcessName
FROM netstat()
WHERE Status = "ESTABLISHED"
  AND Raddr.IP =~ "^(?!10\\.)"
```

### File System Forensics
```sql
SELECT FullPath, Size, Mtime, Atime, Ctime
FROM glob(globs="C:/Users/*/AppData/**/*.exe")
WHERE Mtime > timestamp(epoch=now() - 86400)
```

## Common Investigation Patterns

### Ransomware Investigation
1. **Identify**: Patient zero endpoint.
2. **Timeline**: `Windows.Forensics.Timeline` for file modifications.
3. **Auth**: `Windows.EventLogs.Evtx` for logon patterns.
4. **Persistence**: Hunt for suspicious scheduled tasks or services.
5. **Malware**: Extract binary samples for analysis.

### Data Exfiltration Detection
1. **Network**: `Windows.Network.NetstatEnriched` for large outbound transfers.
2. **Process**: Correlate connections with process execution.
3. **Staging**: Hunt for compression tools or unusual staging directories.
4. **Exfiltration**: Review browser history and cloud sync activities.

## Custom Artifact Development
Create custom YAML artifacts for specific needs:
```yaml
name: Custom.Windows.SuspiciousProcess
sources:
  - query: |
      SELECT Pid, Name, CommandLine FROM pslist()
      WHERE Name =~ "(?i)(powershell|cmd)"
```

## Troubleshooting
- **High CPU**: Use `rate()` or `--ops_per_second` to limit resource impact.
- **Connectivity**: Check TCP 8000 and client logs.
- **No Results**: Test in local notebook; check filesystem path syntax.
