#!/usr/bin/env python3
import os, sys, struct, subprocess

PKG = "com.dts.freefireth"
LIB = "libil2cpp.so"

# --- Check root ---
if os.geteuid() != 0:
    # Nếu không phải root → gọi lại script bằng su
    os.execvp("su", ["su", "-c", "python3 " + " ".join(sys.argv)])
    sys.exit(0)

print("[*] Đang chạy với quyền root")

# --- B1: Lấy PID game ---
try:
    PID = subprocess.check_output(["pidof", PKG]).decode().strip()
except subprocess.CalledProcessError:
    print(f"[!] Game {PKG} chưa chạy!")
    sys.exit(1)

print(f"[*] PID game {PKG} = {PID}")

# --- B2: Lấy base libil2cpp.so ---
with open(f"/proc/{PID}/maps", "r") as f:
    base_line = None
    for line in f:
        if LIB in line and "r-xp" in line:
            base_line = line
            break

if not base_line:
    print("[!] Không tìm thấy base libil2cpp.so")
    sys.exit(1)

base_str = base_line.split(" ")[0].split("-")[0]
BASE = int(base_str, 16)
print(f"[*] Base {LIB} = 0x{BASE:x}")

# --- B3: Tính VA ---
RVA = 0x4a29334
OFFSET = 0x14
ADDR = BASE + RVA + OFFSET
print(f"[*] VA m_WorldPos+0x14 = 0x{ADDR:x}")

# --- B4: Đọc 3 float (x,y,z) ---
with open(f"/proc/{PID}/mem", "rb", 0) as mem:
    mem.seek(ADDR)
    data = mem.read(12)  # 3 floats
    if len(data) < 12:
        print("[!] Không đọc được đủ dữ liệu")
        sys.exit(1)

    x, y, z = struct.unpack("fff", data)
    print(f"[+] Toạ độ: x={x:.3f}, y={y:.3f}, z={z:.3f}")
