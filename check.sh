#!/bin/bash
# check_remove_scclient.sh
# Script kiểm tra hàm remove() trong SurfaceComposerClient.h

FILE="frameworks/native/include/gui/SurfaceComposerClient.h"

if [ -f "$FILE" ]; then
    echo "📂 Found: $FILE"
    echo "----------------------------------"
    grep -n "remove" "$FILE" || echo "❌ Không tìm thấy hàm remove()"
    echo "----------------------------------"
else
    echo "❌ Không tìm thấy $FILE (có chắc bạn đang ở root AOSP không?)"
fi
