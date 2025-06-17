#!/data/data/com.termux/files/usr/bin/bash  
export HISTFILE=/dev/null
unset HISTFILE
unset HISTSIZE
unset HISTFILESIZE
RED='\e[1;31m'
GREEN='\e[1;32m'
YELLOW='\e[1;33m'
BLUE='\e[1;34m'
ORANGE='\033[38;5;208m'
RESET='\e[0m'
if [ "$(id -u)" -ne 0 ]; then
  echo "Script này cần quyền root"
  exit 1
fi
mount -o remount,hidepid=2 /proc
mount -o remount,rw /proc
echo > /proc/kmsg 2>/dev/null
resetprop ro.debuggable 0
resetprop ro.secure 1
resetprop init.svc.magisk ""
resetprop persist.sys.root_access 0
BUILD_PROP="/system/build.prop"
mount -o remount,rw /system
sed -i '/ro.product.model/d' "$BUILD_PROP"
sed -i '/ro.hardware/d' "$BUILD_PROP"
sed -i '/ro.kernel.qemu/d' "$BUILD_PROP"
sed -i '/qemu.hw.mainkeys/d' "$BUILD_PROP"
export PATH=$(echo "$PATH" | sed 's:/system/xbin::g' | sed 's:/system/bin::g')
mount -o remount,rw /system
rm -rf /system/bin/busybox
rm -rf /system/xbin/busybox
mount -o remount,ro /system
export PATH=/data/data/com.termux/files/usr/bin:/system/bin:$PATH
ipset create blacklist hash:ip -exist
cmd notification post -S bigtext -t 'CHẾ ĐỘ:BẬT' 'Tag' 'ANTIBAN FREE FIRE' > /dev/null 2>&1
ANDROID_ID=$(settings get secure android_id)
MODEL=$(getprop ro.product.model)
DEVICE=$(getprop ro.product.device)
VERSION=$(getprop ro.build.version.release)
if [[ -z "$ANDROID_ID" ]]; then
    echo -e "${RED}[!] Lỗi: Không thể lấy Android ID!${RESET}"
    exit 1
fi
echo -e "${BLUE}======= THÔNG TIN THIẾT BỊ =======${RESET}"
echo -e "${ORANGE}Android ID   : $ANDROID_ID"
echo -e "Model        : $MODEL"
echo -e "Device       : $DEVICE"
echo -e "Version      : $VERSION${RESET}"
echo -e "${BLUE}==================================${RESET}"
echo -e -n "${YELLOW}Nhập key của bạn:${RESET} "
read USER_KEY
echo -e "${GREEN}Key đã được nhập.${RESET}"
KEY_FILE_URL="https://raw.githubusercontent.com/hoangopl/update/main/key.txt"
TMP_KEY_FILE="/data/data/com.termux/files/home/keys.txt"
echo -e "${BLUE}[+] Đang check key${RESET}"
if ! curl -fsSL -o "$TMP_KEY_FILE" "$KEY_FILE_URL"; then
    echo -e "${RED}[!] Lỗi: Không thể tải key từ server!${RESET}"
    exit 1
fi
echo -e "${GREEN}[+] Tải key thành công.${RESET}"
if [[ ! -s "$TMP_KEY_FILE" ]]; then
    echo -e "${RED}[!] Lỗi: Tệp keys.txt rỗng!${RESET}"
    rm -f "$TMP_KEY_FILE"
    exit 1
fi
FOUND="no"
while IFS='|' read -r key type devices; do
    [[ -z "$key" || -z "$type" || -z "$devices" ]] && continue
    if [[ "$USER_KEY" == "$key" ]]; then
        echo -e "${YELLOW}Đang kiểm tra key: $key${RESET}"
        if [[ "$type" == "share" ]]; then
            FOUND="yes"
            echo -e "${GREEN}[+] Key dùng chung hợp lệ!${RESET}"
            break
        elif [[ "$type" == "private" ]]; then
            if [[ "$devices" == *"$ANDROID_ID"* ]]; then
                FOUND="yes"
                echo -e "${GREEN}[+] Key riêng hợp lệ cho thiết bị này!${RESET}"
                break
            else
                echo -e "${YELLOW}[!] Key đúng nhưng thiết bị không được phép!${RESET}"
                rm -f "$TMP_KEY_FILE"
                exit 1
            fi
        fi
    fi
done < "$TMP_KEY_FILE"
rm -f "$TMP_KEY_FILE"
if [[ "$FOUND" != "yes" ]]; then
    echo -e "${RED}[X] Key không hợp lệ hoặc không tồn tại!${RESET}"
    exit 1
fi
echo -e "${BLUE}[*] Xác thực hoàn tất. Bạn có thể tiếp tục!${RESET}"
USERNAME="hoangopl"
REPO="update"
BRANCH="main"
FILE_PATH="bypass"
SCRIPT_URL="https://raw.githubusercontent.com/$USERNAME/$REPO/$BRANCH/$FILE_PATH"
SCRIPT_PATH="$(realpath "$0")"
check_update() {
    echo -e "${YELLOW}[*] Kiểm tra bản cập nhật từ server...${RESET}"
    curl -fsSL "$SCRIPT_URL" -o "$SCRIPT_PATH.tmp"
    if [ $? -ne 0 ]; then
        echo -e "${RED}[!] Không thể tải script từ Server. Kiểm tra lại kết nối hoặc URL.${RESET}"
        rm -f "$SCRIPT_PATH.tmp"
        return
    fi
    if ! cmp -s "$SCRIPT_PATH" "$SCRIPT_PATH.tmp"; then
        echo -e "${BLUE}[+] Có phiên bản mới, đang cập nhật...${RESET}"
        mv "$SCRIPT_PATH.tmp" "$SCRIPT_PATH"
        chmod +x "$SCRIPT_PATH"
        echo -e "${GREEN}[+] Script đã được cập nhật. Vui lòng chạy lại${RESET}"
        echo "    $SCRIPT_PATH"
        exit 0
    else
        echo -e "${GREEN}[=] Bạn đang dùng phiên bản mới nhất.${RESET}"
        rm -f "$SCRIPT_PATH.tmp"
    fi
}
main() {
    echo -e "${ORANGE}>> Ngày hiện tại: $(date "+%Y-%m-%d")"
    echo -e ">> thời gian hiện tại: $(date "+%H:%M:%S")${RESET}"
}
check_update
main
PACKAGE_NAME="com.dts.freefireth"
if ! pm list packages | grep -q "$PACKAGE_NAME"; then
    echo -e "${RED}[!] Free Fire chưa được cài đặt${RESET}"
    exit 1
else
    echo -e "${GREEN}[+] Free Fire đã được cài đặt${RESET}"
fi
pm disable-user --user 0 com.google.android.gms > /dev/null 2>&1
pm disable-user --user 0 com.android.vending > /dev/null 2>&1
pm uninstall -k --user 0 com.google.android.contactkeys > /dev/null 2>&1
pm uninstall -k --user 0 com.google.android.safetycore > /dev/null 2>&1
iptables -F OUTPUT > /dev/null 2>&1
iptables -F INPUT > /dev/null 2>&1
iptables -A INPUT -p icmp -j DROP > /dev/null 2>&1
iptables -A OUTPUT -p icmp -j DROP > /dev/null 2>&1
iptables -A INPUT -i lo -j DROP > /dev/null 2>&1
IPSET_NAME=blacklist
IP_LIST=(
  "3.162.51.124" "3.162.51.181" "3.162.51.39" "3.162.51.77" "3.162.58.112"
  "3.162.58.119" "3.162.58.73" "3.162.58.80" "3.162.58.98" "3.165.92.124"
  "3.165.92.8" "3.169.117.175" "3.170.230.85" "13.226.123.105"
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
  "157.240.13.14" "157.240.15.1" "163.70.158.7" "163.70.159.7"
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
  "202.81.117.206" "202.81.118.31" "18.65.99.53" "23.5.165.56" "104.90.7.35" "23.202.35.147"
  "23.54.118.106" "34.87.177.14" "104.84.150.172" "142.250.71.195" "34.126.76.45" "23.54.155.135"
  "3.162.58.77" "23.205.151.49" "23.202.35.26" "23.5.165.49" "23.46.63.161" "202.81.123.105"
  "23.62.21.98" "103.78.86.100" "202.81.118.37" "103.78.86.116" "103.78.86.56" "125.234.51.51"
  "125.235.36.211" "104.18.61.222" "104.18.57.37" "23.2.16.107" "45.119.242.114" "142.250.197.106"
  "13.33.171.32" "45.119.242.150" "163.70.159.7" "23.202.34.136" "23.202.34.154" "23.202.34.144"
  "163.70.158.7" "23.202.34.107" "13.35.212.96" "148.153.218.190" "23.2.16.115" "125.56.199.112"
  "202.81.99.45" "13.35.238.111" "3.165.102.42" "3.165.102.72" "202.81.123.2" "104.18.57.34"
  "23.200.24.56" "3.165.102.42" "18.155.70.18" "3.165.84.97" "18.155.70.122" "202.81.123.18"
  "13.33.100.88" "184.27.123.35" "74.125.130.94" "3.165.84.139" "3.170.230.30" "18.155.68.19"
  "142.250.4.95" "13.33.183.72" "13.35.238.40" "13.35.238.76" "23.75.23.248" "148.222.66.239"
  "103.78.86.118" "74.125.24.95" "13.35.202.12" "45.119.216.84" "13.35.212.22" "103.78.86.16"
  "34.104.32.54" "13.249.146.36" "23.34.81.19" "23.202.34.225" "142.251.175.95" "45.119.242.161"
  "103.78.86.209" "13.33.100.152" "172.253.118.95" "13.33.100.152" "23.75.23.66" "13.33.183.106"
  "104.93.25.193" "3.165.84.69" "13.35.226.89" "104.93.25.193" "108.158.4.35" "45.119.216.71"
  "13.33.100.97" "13.33.88.83" "13.33.88.45" "23.202.33.155" "3.170.230.227" "3.171.197.107"
  "13.33.88.129" "13.35.202.53" "23.202.33.136" "23.202.33.192" "18.155.70.30" "45.119.216.31"
  "23.59.80.234" "13.33.88.63" "3.165.91.57" "13.33.47.51" "125.56.199.98" "23.59.80.211"
  "108.157.254.42" "3.165.91.87" "108.156.139.57" "108.156.139.81" "23.202.33.194" "45.119.242.55"
  "3.165.91.123" "142.251.163.95" "163.70.159.7" "13.33.47.83" "13.35.226.59" "103.78.86.29"
  "148.153.218.166" "23.2.16.219" "103.78.86.117" "202.81.118.39" "148.222.67.12" "148.153.69.111"
  "148.222.67.11" "103.78.86.211" "13.35.226.88" "148.222.66.238" "23.2.16.97" "13.226.120.85"
  "13.35.186.109" "45.119.242.174" "148.222.66.233" "148.153.69.110" "23.2.16.113" "13.33.183.73"
  "142.250.197.3" "148.222.66.252" "23.33.126.188" "13.226.61.96" "142.251.179.95" "3.171.197.44"
  "54.230.71.73" "148.222.66.219" "54.230.71.96" "103.78.86.175" "202.81.118.33" "23.2.16.116"
  "103.78.86.168" "148.222.66.243" "148.153.69.104" "23.2.16.90" "202.81.118.40" "45.119.242.166"
  "142.251.16.95" "45.119.242.42" "184.26.91.32" "54.192.18.3" "103.78.86.205" "54.230.71.111"
  "23.219.172.56" "148.153.218.216" "3.171.197.188" "23.219.172.59" "13.32.54.4" "13.35.186.105"
  "103.78.86.181" "45.119.242.91" "23.49.104.180" "23.33.126.164" "45.119.216.18" "13.226.120.38"
  "45.119.242.61" "103.108.103.3" "148.153.218.252" "184.87.193.73" "148.153.218.252" "10.6.194.240"
  "13.33.88.89" "23.61.202.53" "108.158.4.144" "57.144.144.141" "103.78.86.118" "103.78.86.101"
  "103.78.86.28" "45.119.242.148" "23.33.184.229" "157.240.199.17" "13.33.183.97" "45.119.242.200"
  "103.78.86.163" "23.202.34.162" "18.65.99.189" "54.239.162.12" "54.239.162.145" "13.249.152.130"
  "47.74.253.77" "47.74.253.69" "45.119.242.152" "23.33.126.191" "3.163.200.114" "103.78.86.50"
  "35.187.244.36" "34.87.85.75" "202.81.118.34" "202.81.118.36" "202.81.118.35" "202.81.118.32"
  "148.222.67.171" "23.5.165.147" "23.5.165.81" "184.87.193.84" "23.45.207.201" "23.45.207.203"
  "184.87.193.93" "103.78.86.228" "148.222.67.169" "148.222.67.170" "148.222.66.93" "148.222.67.172"
  "172.253.115.95" "142.250.197.234" "142.250.71.163" "142.250.197.163" "142.250.199.234"
  "163.70.159.7" "45.119.216.27" "45.119.242.211" "23.33.184.230" "45.119.242.64" "3.165.91.2"
  "54.230.71.52" "54.192.18.65" "23.33.184.244" "23.75.23.169" "23.75.23.32" "23.220.203.16"
  "23.220.203.27" "104.84.150.191" "13.33.183.50" "31.13.82.1" "13.225.175.189" "99.84.138.198"
  "18.172.39.63" "18.65.216.52" "3.166.243.177" "103.78.86.218" "3.175.227.120" "23.220.70.75"
  "18.65.199.159" "13.249.166.42" "157.240.7.20" "103.78.86.201" "23.200.143.16" "23.49.104.207"
  "104.84.150.175" "23.209.46.80" "108.158.4.153" "148.153.218.247" "45.119.242.63" "57.144.152.141"
  "184.87.193.149" "184.87.193.158" "57.144.160.141" "142.250.4.95" "74.125.200.94" "23.75.23.160"
  "23.33.184.227" "142.250.198.110" "23.33.184.227" "54.230.71.76" "23.33.126.140" "172.253.122.95"
  "13.226.61.73" "23.33.126.180" "148.153.219.74" "13.33.88.29" "23.49.104.168" "23.33.126.136"
  "148.222.66.13" "23.205.151.68" "23.49.104.212" "13.226.120.78" "23.202.35.42" "23.200.143.5"
  "13.35.186.99" "23.202.34.176" "13.33.183.95" "23.33.126.170" "34.111.113.40" "34.107.172.168"
  "104.84.150.158" "23.33.126.156" "142.250.197.35" "13.33.183.72" "108.157.32.30" "142.250.66.35"
  "54.230.175.8" "13.33.183.27" "23.219.172.57" "23.219.172.49" "13.226.120.28" "23.33.126.137"
  "23.49.104.184" "13.249.166.213" "18.172.39.117" "18.65.214.29" "23.40.52.107" "3.175.227.126"
  "23.33.126.143" "23.33.126.148" "13.33.183.48" "13.35.185.77" "23.49.104.165" "13.35.185.17"
  "3.175.225.35" "18.65.171.187" "104.84.150.165" "18.65.116.78" "142.250.198.99" "23.33.126.173"
  "64.233.180.94" "54.192.18.90" "23.210.7.174" "3.175.227.34" "23.195.119.77" "3.165.16.50"
  "18.65.199.139" "99.84.50.91" "3.169.8.220" "54.230.175.121" "23.49.104.214" "23.202.34.139"
  "13.32.53.177" "18.172.50.147" "13.227.62.61" "23.52.128.95" "13.225.175.172" "99.84.138.8"
  "18.65.199.57" "3.168.243.163" "3.175.227.85" "23.46.63.97" "23.210.7.171" "23.54.155.75"
  "23.202.35.17" "13.226.120.6" "23.217.139.39" "18.67.79.184" "3.164.109.176" "18.154.230.50"
  "18.160.15.175" "18.238.217.87" "3.167.54.185" "18.165.80.167" "3.167.54.108" "23.33.126.141"
  "23.2.16.8" "13.225.163.95" "23.49.104.179" "18.165.98.11" "3.169.8.184" "18.165.94.203"
  "18.160.45.4" "18.154.230.11" "23.220.71.163" "52.85.150.231" "54.230.71.64" "54.239.153.160"
  "142.250.198.163" "54.192.18.8" "172.253.122.94" "142.251.111.95" "18.154.230.25" "3.162.115.224"
  "3.162.115.146" "3.171.89.166" "172.253.115.94" "172.253.63.95" "18.238.79.63" "125.56.201.98"
  "13.225.134.30" "142.250.71.142" "142.250.31.95" "18.65.185.17" "18.172.39.197" "64.233.180.95"
  "3.171.170.123" "3.161.178.65" "192.178.218.94" "172.253.62.95" "142.251.179.100" "18.160.75.97"
  "18.67.79.182" "192.178.218.95" "3.171.73.25" "3.171.89.208" "23.33.184.234" "142.251.167.95"
  "23.202.34.138" "192.178.155.95" "108.138.60.102" "3.165.16.219" "23.33.126.134" "13.35.185.64"
  "3.161.154.63" "3.161.178.140" "23.49.104.200" "142.250.196.238" "13.35.185.110" "13.35.185.88"
  "54.239.153.31" "3.162.104.30" "54.230.71.115" "142.250.76.227" "52.85.150.166" "13.35.185.42"
  "54.230.71.126" "18.160.37.226" "18.165.80.151" "142.251.179.139" "18.67.79.122" "18.238.217.27"
  "3.162.115.70" "142.250.197.131" "3.162.104.141" "18.67.79.10" "13.226.61.104" "23.33.126.161"
  "3.167.54.211" "23.74.15.202" "23.74.15.152" "23.204.80.232" "23.204.80.235" "23.206.203.233"
  "3.167.84.151" "142.250.197.238" "23.200.143.11" "142.250.198.227" "23.33.126.158" "23.200.143.15"
  "3.164.109.187" "13.32.53.224" "18.172.39.143" "18.65.214.91" "23.195.119.70" "3.175.225.103"
  "13.225.175.166" "3.166.225.106" "18.65.190.124" "23.205.214.32" "18.65.171.161" "54.230.71.86"
  "54.230.71.47" "23.32.39.74" "54.230.71.17" "23.202.34.147" "23.56.0.221" "3.167.84.192" "3.162.104.183"
  "23.54.155.134" "18.160.45.105" "184.28.218.65" "23.202.34.83" "23.210.7.178" "3.171.197.211"
  "18.160.45.105" "99.84.178.82" "23.204.80.240" "23.33.126.183" "3.171.102.210" "23.202.35.43"
  "3.167.42.79" "13.249.46.224" "23.202.35.49" "13.249.46.59" "3.171.89.51" "99.84.178.158"
  "13.35.185.119" "13.249.223.136" "142.250.199.227" "23.202.35.179" "23.39.160.4" "23.217.139.50"
  "23.200.143.6" "23.2.16.9" "13.225.175.125" "99.84.138.11" "13.35.185.46" "23.217.139.135"
  "23.217.139.144" "23.208.31.136" "23.208.31.138" "23.208.31.173" "23.55.44.76" "104.84.150.174"
  "23.210.7.167" "18.160.37.31" "3.167.54.207" "23.55.44.41" "23.55.44.82" "23.55.44.46" "23.56.97.65"
  "23.54.118.134" "23.56.97.27" "173.222.248.74" "173.222.248.136" "23.46.63.130" "23.46.63.90"
  "23.205.214.44" "23.217.136.186" "23.208.31.149" "23.208.31.187" "23.210.215.81" "23.216.153.158"
  "104.84.150.190" "23.202.35.192" "23.202.35.121" "23.202.35.202" "23.61.202.44" "23.61.202.37"
  "23.202.34.89" "23.202.35.120" "23.202.35.211" "23.202.35.210" "23.202.35.224" "23.202.35.115"
  "23.202.35.129" "23.202.35.234" "23.54.155.167" "23.195.119.10" "23.209.46.74" "23.202.34.66"
  "23.2.16.40" "23.202.34.217" "13.32.54.62" "13.32.54.41" "23.33.126.157" "23.33.126.182"
  "23.202.34.40" "23.33.126.189" "13.35.185.56" "23.202.35.8" "99.86.195.100" "23.49.104.203"
  "23.33.126.162" "54.230.71.39" "23.202.34.152" "13.32.54.118" "3.171.198.126" "18.239.196.190"
  "65.8.165.142" "3.169.182.89" "108.138.245.118" "13.227.21.16" "3.170.229.114" "18.65.116.226"
  "54.239.162.205" "18.239.196.9" "65.8.165.75" "13.227.21.49" "23.2.16.98" "13.35.37.2" "13.32.54.9"
  "23.202.34.168" "23.202.34.250" "23.33.126.187" "23.2.16.203" "184.26.91.88" "13.35.185.113"
  "142.251.167.94" "18.160.0.218" "23.33.126.152" "99.84.178.201" "23.33.126.186" "3.167.64.223"
  "3.167.116.80" "3.162.104.26" "3.167.42.35" "13.35.33.111" "172.253.62.94" "13.35.185.30" "54.239.153.223"
  "3.162.115.183" "23.33.126.185" "18.67.66.159" "23.49.104.204" "23.49.104.169"
)
spinner="/-\|"
i=0
iptables -t mangle -C OUTPUT -m set --match-set $IPSET_NAME dst -j MARK --set-mark 13 2>/dev/null || iptables -t mangle -A OUTPUT -m set --match-set $IPSET_NAME dst -j MARK --set-mark 13
iptables -t mangle -C INPUT -m set --match-set $IPSET_NAME src -j MARK --set-mark 13 2>/dev/null || iptables -t mangle -A INPUT -m set --match-set $IPSET_NAME src -j MARK --set-mark 13
ip rule add fwmark 13 table 100 2>/dev/null
ip route add blackhole default table 100 2>/dev/null
echo -n "Đang làm việc"
for ip in "${IP_LIST[@]}";do
  printf "\r\033[1;32mĐang làm việc...\033[0m ${spinner:i++%${#spinner}:1}"
  ipset add $IPSET_NAME $ip -exist
done
echo -e "\r\033[1;32mHoàn tất !        \033[0m"
GAME_PACKAGE="com.dts.freefireth"
is_game_running() {
    pid=$(pidof $GAME_PACKAGE)
    if [ -z "$pid" ]; then
        return 1
    else
        return 0
    fi
}
echo -e "${YELLOW}Đang chờ game khởi động: $GAME_PACKAGE...${RESET}"
while ! is_game_running; do
    sleep 2
done
echo -e "${BLUE}Game đã chạy, tiếp tục thực thi script...${RESET}"
echo -e "${GREEN}Đang thực hiện thao tác...${RESET}"
ACCEPT_IPS=(
 "202.81.119.2" "202.81.97.157" "202.81.99.15" "202.81.112.209" "202.81.97.165" "202.81.99.1"  
 "202.81.119.12" "202.81.97.161" "202.81.97.164" "202.81.97.159" "202.81.119.1" "202.81.99.16"  
 "202.81.119.11" "202.81.97.162" "202.81.119.3" "202.81.99.18" "202.81.99.5" "202.81.99.2" "202.81.99.3"  
 "202.81.119.9" "202.81.119.7" "202.81.97.160" "202.81.99.19" "202.81.119.4" "202.81.99.11" "202.81.99.13"
 "202.81.99.10" "202.81.99.7" "202.81.119.14" "202.81.97.158" "202.81.99.9" "202.81.119.13"
 "202.81.119.8" "202.81.99.8" "202.81.99.6" "202.81.99.17" "202.81.99.12" "202.81.99.15"
 "202.81.99.20"
)
spinner="/-\|"
i=0
echo -en "${GREEN}Bật chế độ antiban 1 (sảnh) ? (yes/no): ${RESET}"
read -r confirm
if [[ "$confirm" == "yes" ]]; then
  echo -en "${GREEN}Đang bắt đầu...${RESET}\r"
iptables -t mangle -C OUTPUT -m set --match-set $IPSET_NAME dst -j MARK --set-mark 13 2>/dev/null || iptables -t mangle -A OUTPUT -m set --match-set $IPSET_NAME dst -j MARK --set-mark 13
iptables -t mangle -C INPUT -m set --match-set $IPSET_NAME src -j MARK --set-mark 13 2>/dev/null || iptables -t mangle -A INPUT -m set --match-set $IPSET_NAME src -j MARK --set-mark 13
ip rule add fwmark 13 table 100 2>/dev/null
ip route add blackhole default table 100 2>/dev/null
  for ip in "${ACCEPT_IPS[@]}"; do
      printf "\r\033[1;32mĐang làm việc...\033[0m ${spinner:i++%${#spinner}:1}"
      sleep 0.1
      ipset add $IPSET_NAME $ip -exist
  done
  printf "\r${GREEN}Hoàn tất bật chế độ antiban!       ${RESET}\n"
else
  echo -e "${RED}Thất bại, antiban không được bật.${RESET}"
fi
  iptables -A OUTPUT -o lo -j DROP
  appops set com.dts.freefireth LEGACY_STORAGE deny
  appops set com.dts.freefireth READ_EXTERNAL_STORAGE deny
  appops set com.dts.freefireth WRITE_EXTERNAL_STORAGE deny
echo -ne "${GREEN}Bật chế độ antiban 2 (sảnh) (yes/no): ${RESET}"
read confirm
if [ "$confirm" == "yes" ]; then
    echo -e "${GREEN}Đang tiến hành...${RESET}"
  while true; do
stop logd > /dev/null 2>&1
logcat -b all -c > /dev/null 2>&1
dmesg -C > /dev/null 2>&1
dmesg -n 1 > /dev/null 2>&1
rm -rf /data/misc/logd/* >/dev/null 2>&1
rm -rf /cache/log/* >/dev/null 2>&1
rm -rf /data/system/dropbox/* >/dev/null 2>&1
rm -rf /data/anr/* >/dev/null 2>&1
rm -f -r /mnt/sdcard/.FFTemp/* > /dev/null 2>&1
rm -f -r /mnt/sdcard/Android/data/com.dts.freefireth/cache/* > /dev/null 2>&1
rm -f -r /mnt/sdcard/Android/data/com.dts.freefireth/files/*.log > /dev/null 2>&1
rm -f -r /mnt/sdcard/Android/data/com.dts.freefireth/files/*.txt > /dev/null 2>&1
rm -f -r /storage/emulated/0/Android/data/com.dts.freefireth/cache > /dev/null 2>&1
rm -f -r /data/user/0/com.dts.freefireth/cache > /dev/null 2>&1
rm -f -r /data/user/0/com.dts.freefireth/no_backup > /dev/null 2>&1
rm -f -r /data/user/0/com.dts.freefireth/code_cache > /dev/null 2>&1
rm -f -r /data/user/0/com.dts.freefireth/databases > /dev/null 2>&1
rm -f -r /data/user/0/com.dts.freefireth/oat > /dev/null 2>&1
rm -f -r /data/user/0/com.dts.freefireth/files/.com.google.firebase.crashlytics.files.v2:com.dts.freefireth > /dev/null 2>&1
rm -f -r /data/user/0/com.dts.freefireth/files/AFRequestCache > /dev/null 2>&1
rm -f -r /data/user/0/com.dts.freefireth/files/data > /dev/null 2>&1
rm -f -r /data/user/0/com.dts.freefireth/files/app > /dev/null 2>&1
rm -f -r /data/user/0/com.dts.freefireth/files/ano_tmp > /dev/null 2>&1
rm -f -r /data/user/0/com.dts.freefireth/files/ace_shell_di.dat > /dev/null 2>&1
rm -f -r /data/user/0/com.dts.freefireth/files/GGMEs.dump > /dev/null 2>&1
rm -f -r /data/user/0/com.dts.freefireth/files/Deps.dump > /dev/null 2>&1
rm -f -r /data/user/0/com.dts.freefireth/files/DSAs.dump > /dev/null 2>&1
rm -f -r /data/user/0/com.dts.freefireth/files/GGMEs.version > /dev/null 2>&1
rm -f -r /data/user/0/com.dts.freefireth/files/RMP.dump > /dev/null 2>&1
rm -f -r /data/user/0/com.dts.freefireth/files/InitDump.version > /dev/null 2>&1
rm -f -r /data/user/0/com.dts.freefireth/files/apk.pdcache > /dev/null 2>&1
rm -f -r /data/user/0/com.dts.freefireth/files/generatefid.lock > /dev/null 2>&1
rm -f -r /data/user/0/com.dts.freefireth/files/obb.pdcache > /dev/null 2>&1
rm -f -r /data/user/0/com.dts.freefireth/files/profilelnstalled > /dev/null 2>&1
rm -f -r /storage/emulated/0/Android/data/com.dts.freefireth/cache > /dev/null 2>&1
rm -f -r /storage/emulated/0/Android/data/com.dts.freefireth/files/ImageCache > /dev/null 2>&1
rm -f -r /storage/emulated/0/Android/data/com.dts.freefireth/files/MReplays > /dev/null 2>&1
rm -f -r /storage/emulated/0/Android/data/com.dts.freefireth/files/ShaderStripSettings > /dev/null 2>&1
rm -f -r /storage/emulated/0/Android/data/com.dts.freefireth/files/record > /dev/null 2>&1
rm -f -r /storage/emulated/0/Android/data/com.dts.freefireth/files/Workshop > /dev/null 2>&1
rm -f -r /storage/emulated/0/Android/data/com.dts.freefireth/files/reportnew.db > /dev/null 2>&1
rm -f -r /storage/emulated/0/Android/data/com.dts.freefireth/files/ymrtc_log.txt > /dev/null 2>&1
rm -f -r /storage/emulated/0/Android/data/com.dts.freefireth/files/ffrtc_log.txt > /dev/null 2>&1
rm -f -r /data/user/0/com.dts.freefireth/files/datastore > /dev/null 2>&1
rm -f -r /data/user/0/com.dts.freefireth/app_textures > /dev/null 2>&1
rm -f -r /data/user/0/com.dts.freefireth/app_webview > /dev/null 2>&1
rm -f -r /data/user/0/com.dts.freefireth/app_libs > /dev/null 2>&1
rm -f -r /data/user/0/com.dts.freefireth/files/*.dat > /dev/null 2>&1
rm -f -r /data/user/0/com.dts.freefireth/files/*.ltm > /dev/null 2>&1
rm -f -r /data/user/0/com.dts.freefireth/files/*.xml > /dev/null 2>&1
rm -f -r /data/user/0/com.dts.freefireth/shared_prefs/com.google.firebase.messaging.xml > /dev/null 2>&1
rm -f -r /data/user/0/com.dts.freefireth/shared_prefs/appsflyer-data.xml > /dev/null 2>&1
rm -f -r /data/user/0/com.dts.freefireth/shared_prefs/com.google.firebase.crashlytics.xml > /dev/null 2>&1
rm -f -r /data/user/0/com.dts.freefireth/app_webview_com.dts.freefireth:UnityWebViewActivity > /dev/null 2>&1
rm -f -r /data/user/0/com.dts.freefireth/files/*.json > /dev/null 2>&1
rm -f -r /data/user/0/com.dts.freefireth/shared_prefs/com.facebook.internal.preferences.APP_GATEKEEPERS.xml > /dev/null 2>&1
rm -f -r /data/user/0/com.dts.freefireth/shared_prefs/com.facebook.internal.preferences.APP_SETTINGS.xml > /dev/null 2>&1
rm -f -r /data/user/0/com.dts.freefireth/shared_prefs/com.google.android.gms.appid.xml > /dev/null 2>&1
rm -f -r /data/user/0/com.dts.freefireth/shared_prefs/FirebaseHeartBeatW0RFRkFVTFRd+MToxODU3NTM2MjQ1OTE6YW5kcm9pZDo3YzJhOGYzNjE2ZmRhODY2.xml > /dev/null 2>&1
rm -f -r /storage/emulated/0/Android/data/com.dts.freefireth/files/contentcache/Temp > /dev/null 2>&1
rm -f -r /data/user/0/com.dts.freefireth/shared_prefs/com.google.android.gms.measurement.prefs.xml > /dev/null 2>&1
rm -f -r /data/user/0/com.dts.freefireth/shared_prefs/FF_FCM_SVC.xml > /dev/null 2>&1
rm -f -r /data/user/0/com.dts.freefireth/shared_prefs/FreeFireSharedPreference.xml > /dev/null 2>&1
rm -f -r /data/user/0/com.dts.freefireth/files/FIREBASE_CLOUD_MESSAGING_LOCAL_STORAGE > /dev/null 2>&1
rm -f -r /data/user/0/com.dts.freefireth/shared_prefs/WebViewChromiumPrefs.xml > /dev/null 2>&1
rm -f -r /data/user/0/com.dts.freefireth/shared_prefs/* > /dev/null 2>&1
rm -f -r /data/user/0/com.dts.freefireth/shared_prefs/com.google.android.gms.signin.xml > /dev/null 2>&1
rm -f -r /storage/emulated/0/Android/data/com.dts.freefireth/files/il2cpp/etc/mono > /dev/null 2>&1
rm -f -r /storage/emulated/0/Android/data/com.dts.freefireth/files/il2cpp/Resources > /dev/null 2>&1
rm -f -r /data/data/com.dts.freefireth/files/anogs.log > /dev/null 2>&1
rm -f -r /data/data/com.dts.freefireth/files/anogs.cfg > /dev/null 2>&1
rm -f -r /data/data/com.dts.freefireth/app_crashlytics > /dev/null 2>&1
rm -f -r /data/data/com.dts.freefireth/files/.fabric > /dev/null 2>&1
rm -f -r /data/data/com.dts.freefireth/cache/* > /dev/null 2>&1
rm -f -r /data/user/0/com.dts.freefireth/files/il2cpp/etc > /dev/null 2>&1
rm -f -r /data/user/0/com.dts.freefireth/files/il2cpp/Resources > /dev/null 2>&1
    sleep 0.1
  done &
else
  echo -e "${RED}[!]thực hiện thất bại${RESET}"
fi
echo -e "${GREEN}Đã xong${RESET}"
echo -n -e "${GREEN}Bật chế độ antiban 1 (trận) ? (yes/no): ${RESET}"
read confirm
if [[ "$confirm" == "yes" ]]; then
  echo -e "${GREEN}Đang bật chế độ antiban...${RESET}"
  iptables -t mangle -A OUTPUT -p udp --dport 14112  -j MARK --set-mark 10 > /dev/null 2>&1
  iptables -t mangle -A OUTPUT -p udp --dport 8992   -j MARK --set-mark 10 > /dev/null 2>&1
  iptables -t mangle -A OUTPUT -p udp --dport 26400  -j MARK --set-mark 10 > /dev/null 2>&1
  iptables -t mangle -A OUTPUT -p udp --dport 9984   -j MARK --set-mark 10 > /dev/null 2>&1
  iptables -t mangle -A OUTPUT -p udp --dport 10019  -j MARK --set-mark 10 > /dev/null 2>&1
  iptables -t mangle -A OUTPUT -p udp --dport 26401  -j MARK --set-mark 10 > /dev/null 2>&1
  iptables -t mangle -A OUTPUT -p udp --dport 10033  -j MARK --set-mark 10 > /dev/null 2>&1
  iptables -t mangle -A OUTPUT -p udp --dport 10025  -j MARK --set-mark 10 > /dev/null 2>&1
  iptables -t mangle -A OUTPUT -p udp --dport 12065  -j MARK --set-mark 10 > /dev/null 2>&1
  iptables -t mangle -A OUTPUT -p udp --dport 9985   -j MARK --set-mark 10 > /dev/null 2>&1
  iptables -t mangle -A OUTPUT -p udp --dport 10021  -j MARK --set-mark 10 > /dev/null 2>&1
  iptables -t mangle -A OUTPUT -p udp --dport 8991   -j MARK --set-mark 10 > /dev/null 2>&1
  iptables -t mangle -A OUTPUT -p udp --dport 12063  -j MARK --set-mark 10 > /dev/null 2>&1
  iptables -t mangle -A OUTPUT -p udp --dport 1823   -j MARK --set-mark 10 > /dev/null 2>&1
  iptables -t mangle -A OUTPUT -p udp --dport 10081  -j MARK --set-mark 10 > /dev/null 2>&1
  iptables -t mangle -A OUTPUT -p udp --dport 9761   -j MARK --set-mark 10 > /dev/null 2>&1
  iptables -t mangle -A OUTPUT -p udp --dport 1825   -j MARK --set-mark 10 > /dev/null 2>&1
  iptables -t mangle -A OUTPUT -p udp --dport 14114  -j MARK --set-mark 10 > /dev/null 2>&1
  iptables -t mangle -A OUTPUT -p udp --dport 10034  -j MARK --set-mark 10 > /dev/null 2>&1
  iptables -t mangle -A OUTPUT -p udp --dport 10026  -j MARK --set-mark 10 > /dev/null 2>&1
  iptables -t mangle -A OUTPUT -p udp --dport 1824   -j MARK --set-mark 10 > /dev/null 2>&1
  iptables -t mangle -A OUTPUT -p udp --dport 42785  -j MARK --set-mark 10 > /dev/null 2>&1
  iptables -t mangle -A OUTPUT -p udp --dport 10080  -j MARK --set-mark 10 > /dev/null 2>&1
  iptables -t mangle -A OUTPUT -p udp --dport 12064  -j MARK --set-mark 10 > /dev/null 2>&1
  iptables -t mangle -A OUTPUT -p udp --dport 10020  -j MARK --set-mark 10 > /dev/null 2>&1
  iptables -t mangle -A OUTPUT -p udp --dport 10024  -j MARK --set-mark 10 > /dev/null 2>&1
  iptables -t mangle -A OUTPUT -p udp --dport 10146  -j MARK --set-mark 10 > /dev/null 2>&1
  iptables -t mangle -A OUTPUT -p udp --dport 10022  -j MARK --set-mark 10 > /dev/null 2>&1
  iptables -t mangle -A OUTPUT -p udp --dport 9762   -j MARK --set-mark 10 > /dev/null 2>&1
  iptables -t mangle -A OUTPUT -p udp --dport 9504   -j MARK --set-mark 10 > /dev/null 2>&1
  iptables -t mangle -A OUTPUT -p udp --dport 8993   -j MARK --set-mark 10 > /dev/null 2>&1
  iptables -t mangle -A OUTPUT -p udp --dport 10145   -j MARK --set-mark 10 > /dev/null 2>&1
  iptables -t mangle -A OUTPUT -p udp --dport 9505   -j MARK --set-mark 10 > /dev/null 2>&1
  iptables -t mangle -A OUTPUT -p udp --dport 10047   -j MARK --set-mark 10 > /dev/null 2>&1
  iptables -t mangle -A OUTPUT -p udp --dport 42783   -j MARK --set-mark 10 > /dev/null 2>&1
  iptables -t mangle -A OUTPUT -p udp --dport 26399   -j MARK --set-mark 10 > /dev/null 2>&1
  iptables -t mangle -A OUTPUT -p udp --dport 10143   -j MARK --set-mark 10 > /dev/null 2>&1
  iptables -t mangle -A OUTPUT -p udp --dport 10144   -j MARK --set-mark 10 > /dev/null 2>&1
  iptables -t mangle -A OUTPUT -p udp --dport 42784   -j MARK --set-mark 10 > /dev/null 2>&1
  iptables -t mangle -A OUTPUT -p udp --dport 10032   -j MARK --set-mark 10 > /dev/null 2>&1
  iptables -t mangle -A OUTPUT -d 202.81.0.0/16 -j MARK --set-mark 10 > /dev/null 2>&1
  iptables -t mangle -A OUTPUT -d 103.108.103.0/24 -j MARK --set-mark 10 > /dev/null 2>&1
IFACES=("wlan0" "rmnet_data0" "rmnet_data1" "tun0" "eth0")
for IFACE in "${IFACES[@]}"; do
  tc qdisc add dev "$IFACE" root handle 1: htb default 1 > /dev/null 2>&1
  tc class add dev "$IFACE" parent 1: classid 1:1 htb rate 100mbit > /dev/null 2>&1
  tc class add dev "$IFACE" parent 1: classid 1:10 htb rate 1kbit > /dev/null 2>&1
  tc qdisc add dev "$IFACE" parent 1:10 handle 10: netem \
    delay 99999ms 10000ms \
    loss 100% \
    duplicate 100% \
    corrupt 100% \
    reorder 100% 100% > /dev/null 2>&1
  tc filter add dev "$IFACE" parent 1: protocol ip prio 1 handle 10 fw flowid 1:10 > /dev/null 2>&1
done
  echo -e "${GREEN}Hoàn tất bật chế độ antiban!${RESET}"
else
  echo -e "${RED}Thất bại, antiban không được bật.${RESET}"
fi
echo -n -e "${GREEN}Bật chế độ antiban 2 (trận) ? (yes/no): ${RESET}"
read confirm
if [[ "$confirm" == "yes" ]]; then
  echo -e "${GREEN}Đang bật chế độ antiban...${RESET}"
  iptables -t mangle -A POSTROUTING -p udp --dport 10011 -j MARK --set-mark 11 > /dev/null 2>&1
  iptables -t mangle -A POSTROUTING -p udp --dport 10012 -j MARK --set-mark 11 > /dev/null 2>&1
  iptables -t mangle -A POSTROUTING -p udp --dport 10013 -j MARK --set-mark 11 > /dev/null 2>&1
  iptables -t mangle -A POSTROUTING -p udp --dport 10014 -j MARK --set-mark 11 > /dev/null 2>&1
  iptables -t mangle -A POSTROUTING -p udp --dport 10015 -j MARK --set-mark 11 > /dev/null 2>&1
  iptables -t mangle -A POSTROUTING -p udp --dport 10016 -j MARK --set-mark 11 > /dev/null 2>&1
  iptables -t mangle -A POSTROUTING -p udp --dport 10017 -j MARK --set-mark 11 > /dev/null 2>&1
  iptables -t mangle -A POSTROUTING -p udp --dport 10018 -j MARK --set-mark 11 > /dev/null 2>&1
IFACES=("wlan0" "rmnet_data0" "rmnet_data1" "tun0" "eth0")
for IFACE in "${IFACES[@]}"; do
  tc qdisc add dev "$IFACE" root handle 1: htb default 1 > /dev/null 2>&1
  tc class add dev "$IFACE" parent 1: classid 1:1 htb rate 10mbit > /dev/null 2>&1
  tc class add dev "$IFACE" parent 1: classid 1:11 htb rate 50kbit > /dev/null 2>&1
  tc qdisc add dev "$IFACE" parent 1:11 handle 11: netem \
    delay 1000ms 100ms \
    loss 10% \
    duplicate 2% \
    corrupt 5% \
    reorder 20% 50% > /dev/null 2>&1
  tc filter add dev "$IFACE" parent 1: protocol ip prio 1 handle 11 fw flowid 1:11 > /dev/null 2>&1
done
  echo -e "${GREEN}Hoàn tất bật chế độ antiban!${RESET}"
else
  echo -e "${RED}Thất bại, antiban không được bật.${RESET}"
fi
history -c 2>/dev/null
history -w 2>/dev/null