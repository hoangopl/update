#!/bin/bash
set -e

# ========================
# 1. Cài dependencies
# ========================
echo "[*] Installing dependencies..."
sudo apt update
sudo apt install -y openjdk-8-jdk git-core gnupg flex bison gperf build-essential \
  zip curl zlib1g-dev gcc-multilib g++-multilib libc6-dev-i386 \
  libncurses5-dev x11proto-core-dev libx11-dev libgl1-mesa-dev \
  libxml2-utils xsltproc unzip fontconfig python3 python-is-python3

# ========================
# 2. Thiết lập repo tool
# ========================
echo "[*] Setting up repo tool..."
mkdir -p ~/bin
curl https://storage.googleapis.com/git-repo-downloads/repo > ~/bin/repo
chmod a+x ~/bin/repo
export PATH=~/bin:$PATH

# ========================
# 3. Tải mã nguồn AOSP 10
# ========================
WORKDIR=~/aosp10
mkdir -p $WORKDIR
cd $WORKDIR

if [ ! -d ".repo" ]; then
  echo "[*] Initializing AOSP 10 repo..."
  repo init -u https://android.googlesource.com/platform/manifest -b android-10.0.0_r1
fi

echo "[*] Syncing sources (this may take a while)..."
repo sync -j$(nproc) --force-sync

# ========================
# 4. Thiết lập môi trường build
# ========================
echo "[*] Setting up build environment..."
source build/envsetup.sh

# ========================
# 5. Chọn target & build
# ========================
lunch aosp_arm64-eng

echo "[*] Start building..."
make -j$(nproc)

echo "[✔] Build completed!"
