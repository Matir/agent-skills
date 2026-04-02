# Hashcat Password Recovery Manual

This document contains exhaustive reference material for Hashcat, including hash modes, attack types, performance tuning, and common auditing patterns.

## Common Hash Modes (-m)
- **0**: MD5
- **100**: SHA1
- **1000**: NTLM
- **1400**: SHA256
- **1800**: sha512crypt
- **3200**: bcrypt
- **5600**: NetNTLMv2
- **13100**: Kerberos 5 TGS-REP
- **22000**: WPA/WPA2 (PMKID/EAPOL)

## Attack Modes (-a)
- **0 (Straight)**: Basic dictionary attack (Wordlist).
- **1 (Combination)**: Combine words from two wordlists.
- **3 (Brute-force/Mask)**: Try all combinations in a defined character set.
- **6 (Hybrid Wordlist + Mask)**: Wordlist followed by a mask (e.g., `word123`).
- **7 (Hybrid Mask + Wordlist)**: Mask followed by a wordlist (e.g., `123word`).

## Mask Character Sets
- `?l`: lowercase (a-z)
- `?u`: uppercase (A-Z)
- `?d`: digits (0-9)
- `?s`: special characters
- `?a`: all characters (l+u+d+s)

## Performance & Workload (-w)
- **-w 1 (Low)**: Desktop remains usable.
- **-w 2 (Default)**: Balanced performance.
- **-w 3 (High)**: Optimized for dedicated cracking.
- **-w 4 (Nightmare)**: Maximum performance (may freeze OS).
- **-O**: Enable optimized kernels (improves speed but limits password length).

## Common Mutation Rules (-r)
- **best64.rule**: Good balance of speed and coverage.
- **dive.rule**: Comprehensive/deep mutations.
- **toggles1.rule**: Case toggling variations.
- **leetspeak.rule**: Character substitutions (e.g., 'a' -> '@').

## Session Management
- **Save**: `--session=name`
- **Restore**: `--session=name --restore`
- **Status**: `--status`

## Common Auditing Patterns

### Windows Domain Audit
1. Extract NTLM hashes (e.g., via `secretsdump.py`).
2. Crack: `hashcat -m 1000 -a 0 hashes.txt rockyou.txt -r rules/best64.rule`
3. Show results: `hashcat -m 1000 hashes.txt --show`

### Linux Shadow Audit
1. Extract SHA-512 hashes from `/etc/shadow`.
2. Crack: `hashcat -m 1800 -a 0 hashes.txt rockyou.txt`

### Wi-Fi (WPA2)
1. Convert pcap to `.hccapx` or `.hc22000`.
2. Crack: `hashcat -m 22000 -a 0 wpa.hc22000 rockyou.txt`

## Troubleshooting
- **Speed too slow?** Use `-w 3` and `-O`. Check GPU drivers (`nvidia-smi`).
- **Hash format error?** Ensure the mode (`-m`) matches the hash type. Remove usernames/colons unless using `--username`.
- **Out of memory?** Reduce wordlist size or split large hash files.
