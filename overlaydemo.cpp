#include <binder/ProcessState.h>
#include <gui/SurfaceComposerClient.h>
#include <gui/SurfaceControl.h>
#include <ui/Rect.h>
#include <unistd.h>
#include <fcntl.h>
#include <iostream>

using namespace android;

int main() {
    // Mở file /proc/self/ns/ipc (chỉ để demo requirement của bạn)
    int fd = open("/proc/self/ns/ipc", O_RDONLY);
    if (fd < 0) {
        perror("open /proc/self/ns/ipc");
    } else {
        std::cout << "Opened /proc/self/ns/ipc successfully\n";
        close(fd);
    }

    // Chuẩn bị SurfaceComposerClient
    sp<SurfaceComposerClient> client = new SurfaceComposerClient();
    if (client->initCheck() != NO_ERROR) {
        std::cerr << "SurfaceComposerClient init failed\n";
        return -1;
    }

    // Lấy kích thước màn hình
    sp<IBinder> dtoken(SurfaceComposerClient::getInternalDisplayToken());
    DisplayInfo dinfo;
    SurfaceComposerClient::getDisplayInfo(dtoken, &dinfo);

    int sw = dinfo.w;
    int sh = dinfo.h;

    // Tạo SurfaceControl
    sp<SurfaceControl> control = client->createSurface(
        String8("RedOverlay"),
        sw, sh, PIXEL_FORMAT_RGBA_8888,
        ISurfaceComposerClient::eFXSurfaceDim);

    if (control == nullptr || !control->isValid()) {
        std::cerr << "Failed to create SurfaceControl\n";
        return -1;
    }

    // Transaction để hiển thị màu đỏ
    SurfaceComposerClient::Transaction t;
    t.setLayer(control, INT_MAX)           // Lớp cao nhất
     .setAlpha(control, 1.0f)              // Độ trong suốt
     .setColor(control, {1.0f, 0.0f, 0.0f})// Màu đỏ (RGB normalized)
     .show(control)
     .apply();

    // Giữ overlay trong 5 giây
    sleep(5);

    // Ẩn overlay
    SurfaceComposerClient::Transaction t2;
    t2.hide(control).apply();

    return 0;
}
