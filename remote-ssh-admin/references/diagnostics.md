# Remote Diagnostics Guide

This reference provides a collection of commands for diagnosing remote Linux and MacOS systems.

## 1. System Overview
| Task | Linux | MacOS |
|---|---|---|
| OS Version | `cat /etc/os-release` | `sw_vers` |
| Kernel/Hardware | `uname -a` | `uname -a` |
| Uptime | `uptime` | `uptime` |
| Boot Log | `journalctl -b` | `log show --boot` |

## 2. CPU & Performance
| Task | Linux | MacOS |
|---|---|---|
| CPU Load | `top -bn1 | head -n 10` | `top -l 1 | head -n 15` |
| Core Info | `lscpu` | `sysctl -n machdep.cpu.brand_string` |
| Load Average | `uptime` | `uptime` |

## 3. Memory Usage
| Task | Linux | MacOS |
|---|---|---|
| RAM Usage | `free -h` | `vm_stat` |
| Swap Usage | `swapon --show` | `sysctl -n vm.swapusage` |

## 4. Disk Space & I/O
| Task | Linux | MacOS |
|---|---|---|
| Disk Usage | `df -h` | `df -h` |
| Directory Size | `du -sh <path>` | `du -sh <path>` |
| I/O Stats | `iostat -xz 1 2` | `iostat -c 2` |

## 5. Networking
| Task | Linux | MacOS |
|---|---|---|
| IP Addr | `ip addr` | `ifconfig` |
| Routes | `ip route` | `netstat -rn` |
| Open Ports | `ss -tuln` | `lsof -PiTCP -sTCP:LISTEN` |
| DNS Check | `dig <host>` | `dig <host>` |

## 6. Logs & Events
- **Linux (systemd):** `journalctl -u <service> -n 50` or `tail -n 50 /var/log/syslog`
- **MacOS:** `log show --last 1h` or `tail -n 50 /var/log/system.log`

## 7. Process Management
| Task | Linux | MacOS |
|---|---|---|
| List Processes | `ps aux` | `ps aux` |
| Process by CPU | `ps -eo pcpu,pmem,args --sort=-pcpu | head -n 10` | `ps -Ao pcpu,pmem,comm -r | head -n 11` |
