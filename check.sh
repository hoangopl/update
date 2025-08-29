#!/bin/bash
# open_scclient.sh
# Script mở frameworks/native/include/gui/SurfaceComposerClient.h

FILE="aosp10/frameworks/native/include/gui/SurfaceComposerClient.h"

if [ -f "$FILE" ]; then
    echo "📂 Found: $FILE"
    echo "----------------------------------"
    # In 30 dòng quanh Transaction class để kiểm tra remove()
    grep -n "class Transaction" -A 30 "$FILE"
    echo "----------------------------------"
    echo "👉 Mở toàn bộ file bằng less..."
    sleep 1
    less "$FILE"
else
    echo "❌ Không tìm thấy $FILE (có chắc bạn đang ở root AOSP không?)"
fi
