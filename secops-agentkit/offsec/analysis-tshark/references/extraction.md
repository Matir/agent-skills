### 7. Credential Extraction

Extract credentials from network traffic (authorized forensics only):

**HTTP Basic Authentication**:

```bash
# Extract HTTP Basic Auth credentials
tshark -r capture.pcap -Y "http.authbasic" -T fields -e ip.src -e http.authbasic

# Decode Base64 credentials
tshark -r capture.pcap -Y "http.authorization" -T fields -e http.authorization | base64 -d
```

**FTP Credentials**:

```bash
# Extract FTP usernames
tshark -r capture.pcap -Y "ftp.request.command == USER" -T fields -e ip.src -e ftp.request.arg

# Extract FTP passwords
tshark -r capture.pcap -Y "ftp.request.command == PASS" -T fields -e ip.src -e ftp.request.arg
```

**NTLM/Kerberos**:

```bash
# Extract NTLM hashes
tshark -r capture.pcap -Y "ntlmssp.auth.ntlmv2response" -T fields -e ntlmssp.auth.username -e ntlmssp.auth.domain -e ntlmssp.auth.ntlmv2response

# Kerberos tickets
tshark -r capture.pcap -Y "kerberos.CNameString" -T fields -e kerberos.CNameString -e kerberos.realm
```

**Email Credentials**:

```bash
# SMTP authentication
tshark -r capture.pcap -Y "smtp.req.command == AUTH" -T fields -e ip.src

# POP3 credentials
tshark -r capture.pcap -Y "pop.request.command == USER or pop.request.command == PASS" -T fields -e pop.request.parameter

# IMAP credentials
tshark -r capture.pcap -Y "imap.request contains \"LOGIN\"" -T fields -e imap.request
```

### 8. File Extraction

Extract files from packet captures:

```bash
# Export HTTP objects
tshark -r capture.pcap --export-objects http,extracted_http/

# Export SMB objects
tshark -r capture.pcap --export-objects smb,extracted_smb/

# Export DICOM objects
tshark -r capture.pcap --export-objects dicom,extracted_dicom/

# Export IMF (email) objects
tshark -r capture.pcap --export-objects imf,extracted_email/
```

**Manual file reconstruction**:

```bash
# Extract file data from HTTP response
tshark -r capture.pcap -Y "http.response and http.content_type contains \"application/pdf\"" -T fields -e data.data | xxd -r -p > extracted_file.pdf

# Reassemble TCP stream
tshark -r capture.pcap -q -z follow,tcp,ascii,<stream-number>
```

