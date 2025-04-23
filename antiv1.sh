#!/bin/bash
USERNAME="hoangopl"
REPO="update"
BRANCH="main"
FILE_PATH="antiv1.sh"
SCRIPT_URL="https://raw.githubusercontent.com/$USERNAME/$REPO/$BRANCH/$FILE_PATH"
SCRIPT_PATH="$(realpath "$0")"
check_update() {
    echo "[*] Kiểm tra bản cập nhật từ GitHub..."
    curl -fsSL "$SCRIPT_URL" -o "$SCRIPT_PATH.tmp"
    if [ $? -ne 0 ]; then
        echo "[!] Không thể tải script từ GitHub. Kiểm tra lại kết nối hoặc URL."
        rm -f "$SCRIPT_PATH.tmp"
        return
    fi
    if ! cmp -s "$SCRIPT_PATH" "$SCRIPT_PATH.tmp"; then
        echo "[+] Có phiên bản mới, đang cập nhật..."
        mv "$SCRIPT_PATH.tmp" "$SCRIPT_PATH"
        chmod +x "$SCRIPT_PATH"
        echo "[+] Script đã được cập nhật. Vui lòng chạy lại:"
        echo "    $SCRIPT_PATH"
        exit 0
    else
        echo "[=] Bạn đang dùng phiên bản mới nhất."
        rm -f "$SCRIPT_PATH.tmp"
    fi
}
main() {
    echo ">> Đang chạy nội dung chính..."
    echo ">> Ngày hiện tại: $(date "+%Y-%m-%d")"
    echo ">> thời gian hiện tại: $(date "+%H:%M:%S")"
    echo ">> Thiết bị: $(getprop ro.product.manufacturer)"
    echo ">> model: $(getprop ro.product.model)"
}
check_update
main
pm disable-user --user 0 com.google.android.gms
pm disable-user --user 0 com.android.vending
cmd notification post -S bigtext -t 'CHẾ ĐỘ:BẬT' 'Tag' 'ANTIBAN FREE FIRE' > /dev/null 2>&1
iptables -F OUTPUT
iptables -F INPUT
ACCEPT_IPS=(
 "202.81.119.2" "202.81.97.157" "202.81.99.15" "103.108.103.28" "202.81.112.209" "202.81.97.165" "202.81.99.1"
 "202.81.119.12" "202.81.97.161" "202.81.97.164" "202.81.97.159" "202.81.119.1" "202.81.99.16"
 "202.81.119.11" "202.81.97.162" "202.81.119.3" "202.81.99.18" "202.81.99.5" "202.81.99.2" "202.81.99.3"
 "202.81.119.9" "202.81.119.7" "202.81.97.160" "202.81.99.19" "103.108.103.33" "202.81.119.4" "202.81.99.11"
 "103.108.103.31" "202.81.99.10"
)
ACCEPT_PORTS=(443 39698)
echo "Đang cho phép các IP: ${#ACCEPT_IPS[@]} trên các cổng: ${ACCEPT_PORTS[*]}"
for ip in "${ACCEPT_IPS[@]}"; do
  for port in "${ACCEPT_PORTS[@]}"; do
    iptables -A OUTPUT -p tcp -d "$ip" --dport "$port" -j ACCEPT
    iptables -A INPUT -p tcp -s "$ip" --sport "$port" -j ACCEPT
    iptables -A OUTPUT -p udp -d "$ip" --dport "$port" -j ACCEPT
    iptables -A INPUT -p udp -s "$ip" --sport "$port" -j ACCEPT
    echo "Đã cho phép $ip cổng $port (TCP & UDP)"
  done
done
IP_LIST=(
  "3.162.51.124" "3.162.51.181" "3.162.51.39" "3.162.51.77" "3.162.58.112"
  "3.162.58.119" "3.162.58.73" "3.162.58.80" "3.162.58.98" "3.165.92.124"
  "3.165.92.8" "3.169.117.175" "3.170.230.210" "3.170.230.85" "13.226.123.105"
  "13.226.123.144" "13.226.123.190" "13.226.123.212" "13.226.61.120" "13.226.65.187"
  "13.226.65.193" "13.226.65.230" "13.226.65.34" "13.32.32.145" "13.32.32.148"
  "13.32.32.34" "13.32.32.47" "13.33.100.155" "13.33.171.138" "13.33.171.165"
  "13.33.171.186" "13.33.183.43" "13.33.47.140" "13.35.186.126" "13.35.212.228"
  "13.35.212.86" "13.35.218.164" "13.35.218.38" "108.156.139.223" "108.156.139.56"
  "108.157.32.15" "108.157.32.23" "108.157.32.41" "108.157.32.55" "108.157.32.71"
  "108.157.32.77" "108.157.32.112" "108.157.32.129" "108.157.34.108" "108.157.34.159"
  "108.157.34.160" "108.157.34.64" "108.158.4.50" "125.212.198.39" "125.234.51.49"
  "125.234.51.57" "125.234.51.74" "125.234.51.96" "125.235.36.155" "125.235.36.160"
  "125.235.36.163" "125.235.36.177" "125.235.36.209" "125.235.36.216" "125.56.199.34"
  "142.250.196.234" "142.250.197.10" "142.250.197.138" "142.250.197.170" "142.250.197.195"
  "142.250.197.202" "142.250.197.234" "142.250.197.42" "142.250.197.74" "142.250.197.99"
  "142.250.198.106" "142.250.198.138" "142.250.198.142" "142.250.198.170" "142.250.198.195"
  "142.250.198.200" "142.250.198.202" "142.250.198.234" "142.250.198.42" "142.250.199.17"
  "142.250.199.202" "142.250.199.234" "142.250.199.67" "142.250.199.74" "142.250.199.78"
  "142.250.66.42" "142.250.71.138" "142.250.71.163" "142.250.71.170" "142.250.71.202"
  "142.250.71.227" "142.250.71.234" "142.250.76.10" "142.250.76.234" "142.251.12.95"
  "157.240.13.14" "157.240.15.1" "157.240.199.17" "163.70.158.7" "163.70.159.7"
  "172.217.194.95" "202.81.96.5" "202.81.96.7" "202.81.96.8" "202.81.118.38"
  "23.197.85.40" "23.197.85.79" "23.202.34.32" "23.202.34.96" "23.202.35.225"
  "23.209.46.11" "23.2.16.218" "23.33.126.149" "23.33.184.232" "23.33.184.233"
  "23.39.160.11" "23.39.160.15" "23.39.160.5" "23.39.160.6" "23.46.230.141"
  "23.46.230.142" "23.49.104.164" "23.5.165.24" "23.5.165.43" "23.5.165.48"
  "23.5.165.50" "23.54.155.164" "23.54.155.168" "23.54.155.169" "23.54.155.170"
  "23.54.155.177" "23.55.39.159" "23.55.51.145" "23.56.0.216" "3.170.230.210"
  "34.104.35.84" "34.104.38.7" "34.126.122.233" "34.126.175.87" "34.126.76.45"
  "34.126.81.200" "34.87.109.50" "34.87.170.230" "34.87.177.14" "34.87.24.78"
  "35.185.183.57" "35.185.188.243" "35.187.246.126" "35.198.211.155" "35.198.221.239"
  "42.99.140.40" "54.192.16.108" "54.192.16.11" "54.192.16.152" "54.192.16.9"
  "54.192.18.123" "54.192.18.51" "54.192.18.76" "54.192.18.92" "57.144.150.141"
  "57.144.186.141" "74.125.130.95" "74.125.200.95" "103.108.103.13" "103.108.103.14"
  "103.108.103.15" "103.108.103.16" "103.108.103.17" "103.108.103.2" "103.108.103.4"
  "103.108.103.7" "103.108.103.8" "103.108.103.9" "103.239.120.105" "103.239.120.116"
  "103.78.86.100" "103.78.86.101" "103.78.86.102" "103.78.86.119" "103.78.86.138"
  "103.78.86.55" "103.78.86.62" "143.92.120.197" "143.92.120.196" "143.92.120.189"
  "13.35.218.13" "13.226.120.84" "13.33.183.22" "13.35.218.191" "35.198.221.239"
  "157.240.211.1" "13.226.61.52" "13.33.88.99" "13.33.47.49" "13.35.202.103" "35.187.246.126"
  "3.165.75.73" "13.35.226.52" "3.165.84.83" "18.155.70.65" "18.155.68.22" "142.250.197.67"
  "202.81.123.106" "142.250.199.195" "34.87.109.50" "3.169.132.180" "148.222.67.160"
  "202.81.118.2" "202.81.117.207" "104.18.61.225" "125.234.51.97" "104.18.61.225"
  "202.81.117.206" "202.81.118.31" "202.81.99.7"
)
PORTS=(443 39800 80 10012 8012 8001 6674 6006 8006 16006 6674)
echo "Đang chặn các IP: ${#IP_LIST[@]} trên các cổng: ${PORTS[*]}"
for ip in "${IP_LIST[@]}"; do
  for port in "${PORTS[@]}"; do
    iptables -A OUTPUT -p tcp -d "$ip" --dport "$port" -j DROP
    iptables -A INPUT -p tcp -s "$ip" --sport "$port" -j DROP
    iptables -A OUTPUT -p udp -d "$ip" --dport "$port" -j DROP
    iptables -A INPUT -p udp -s "$ip" --sport "$port" -j DROP
    echo "Đã chặn $ip cổng $port (TCP & UDP)"
  done
done
DOMAINS=(
  "ff.dr.grtc.garenanow.com"
  "csoversea.stronghold.freefiremobile.com"
  "dl.castle.freefiremobile.com"
  "ff.sdk.grtc.garenanow.com"
  "gin.freefiremobile.com"
  "dl.listdl.com"
  "firebaseinstallations.googleapis.com"
  "firebase-settings.crashlytics.com"
  "vnevent.ggblueshark.com"
  "rslw0r-conversions.appsflyersdk.com"
  "firewalltest.na.freefiremobile.com"
)
PORTS=(80 8012 8011 5001 9006 9008 6006 6008 5005 8008 8006)
echo "Đang chặn domain (qua IP)..."
for domain in "${DOMAINS[@]}"; do
  ip=$(getent hosts "$domain" | awk '{ print $1 }')
  if [ -n "$ip" ]; then
    for port in "${PORTS[@]}"; do
      iptables -A OUTPUT -p tcp -d "$ip" --dport "$port" -j DROP
      iptables -A INPUT -p tcp -s "$ip" --sport "$port" -j DROP
      iptables -A OUTPUT -p udp -d "$ip" --dport "$port" -j DROP
      iptables -A INPUT -p udp -s "$ip" --sport "$port" -j DROP
    done
    echo "Đã chặn domain: $domain ($ip)"
  else
    echo "Không tìm được IP cho $domain"
  fi
done
ACCEPT_IPS=(
 "202.81.119.2" "202.81.97.157" "202.81.99.15" "202.81.112.209" "202.81.97.165" "202.81.99.1"
 "202.81.119.12" "202.81.97.161" "202.81.97.164" "202.81.97.159" "202.81.119.1" "202.81.99.16"
 "202.81.119.11" "202.81.97.162" "202.81.119.3" "202.81.99.18" "202.81.99.5" "202.81.99.2" "202.81.99.3"
 "202.81.119.9" "202.81.119.7" "202.81.97.160" "202.81.99.19" "202.81.119.4" "202.81.99.11"
 "202.81.99.10"
)
ACCEPT_PORTS=(443 39698)
echo -n "bật chế độ antiban trong trận đấu ? (yes/no): "
read confirm
if [[ "${confirm}" == "yes" ]]; then
  echo "Đang chặn lại các IP đã cho phép..."
  for ip in "${ACCEPT_IPS[@]}"; do
    for port in "${ACCEPT_PORTS[@]}"; do
      iptables -D OUTPUT -p tcp -d "$ip" --dport "$port" -j ACCEPT 2>/dev/null
      iptables -D INPUT -p tcp -s "$ip" --sport "$port" -j ACCEPT 2>/dev/null
      iptables -D OUTPUT -p udp -d "$ip" --dport "$port" -j ACCEPT 2>/dev/null
      iptables -D INPUT -p udp -s "$ip" --sport "$port" -j ACCEPT 2>/dev/null
      iptables -A OUTPUT -p tcp -d "$ip" --dport "$port" -j DROP
      iptables -A INPUT -p tcp -s "$ip" --sport "$port" -j DROP
      iptables -A OUTPUT -p udp -d "$ip" --dport "$port" -j DROP
      iptables -A INPUT -p udp -s "$ip" --sport "$port" -j DROP
      echo "Đã chặn lại $ip cổng $port"
    done
  done
  echo "Hoàn tất chặn lại IP đã cho phép."
else
  echo "Không chặn các IP đã cho phép."
fi
echo "Hoàn tất!"
