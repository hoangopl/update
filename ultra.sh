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
settings put global development_settings_enabled 0
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
pm uninstall com.google.android.contactkeys > /dev/null 2>&1
pm uninstall com.google.android.safetycore > /dev/null 2>&1
pm uninstall app.greyshirts.firewall > /dev/null 2>&1
pm uninstall com.celzero.bravedns > /dev/null 2>&1
pm uninstall eu.faircode.netguard > /dev/null 2>&1
pm uninstall com.dps.firewall > /dev/null 2>&1
pm uninstall com.og.gamecenter > /dev/null 2>&1
pm uninstall com.og.toolcenter > /dev/null 2>&1
pm uninstall com.og.launcher > /dev/null 2>&1
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
 "202.81.99.20" "202.81.97.163" "202.81.99.14" "202.81.199.8" "202.81.199.12" "202.81.119.5" "202.81.97.166"
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
PACKAGE="com.dts.freefireth"
echo "[+] Đang chờ Free Fire thoát..."
while true; do
    pid=$(pidof $PACKAGE)
    if [ -z "$pid" ]; then
        echo "[+] Free Fire đã tắt, thực hiện hành động tiếp theo..."
        pm uninstall $PACKAGE
        pm enable com.google.android.gms
        pm enable com.android.vending
        echo "[+] Hoàn tất. Thoát script."
        break
    fi
    sleep 2
done
history -c 2>/dev/null
history -w 2>/dev/null
