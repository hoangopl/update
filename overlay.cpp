#include <gui/SurfaceComposerClient.h>
#include <ui/DisplayInfo.h>
#include <utils/StrongPointer.h>
#include <cutils/native_handle.h>
#include <EGL/egl.h>
#include <EGL/eglext.h>
#include <unistd.h>
#define _ANDROID_LOG_H 1
#include "/sdcard/compile/log/log.h"
using namespace android;

int main() {
    // Tạo client cho SurfaceControl
    sp<SurfaceComposerClient> client = new SurfaceComposerClient();

    // Lấy thông tin màn hình
    DisplayInfo info;
    SurfaceComposerClient::getDisplayInfo(0, &info);
    int width = info.w;
    int height = info.h;

    // Tạo surface (overlay)
    sp<SurfaceControl> surfaceControl = client->createSurface(
        String8("MyOverlay"),
        width, height,
        PIXEL_FORMAT_RGBA_8888,
        ISurfaceComposerClient::eFXSurfaceBufferState |
        ISurfaceComposerClient::eFXSurfaceDim);

    // Hiển thị surface
    SurfaceComposerClient::Transaction{}
        .setLayer(surfaceControl, INT_MAX)   // Đặt top-most layer
        .show(surfaceControl)
        .apply();

    // Lấy surface để vẽ
    sp<Surface> surface = surfaceControl->getSurface();

    // Vẽ màu đỏ vào toàn bộ màn hình
    ANativeWindow_Buffer buffer;
    surface->lock(&buffer, nullptr);

    uint32_t* pixels = (uint32_t*)buffer.bits;
    for (int y = 0; y < buffer.height; y++) {
        for (int x = 0; x < buffer.width; x++) {
            pixels[y * buffer.stride + x] = 0xFFFF0000; // RGBA (đỏ)
        }
    }

    surface->unlockAndPost();

    // Giữ overlay trong 5 giây
    sleep(5);

    // Ẩn surface
    SurfaceComposerClient::Transaction{}
        .hide(surfaceControl)
        .apply();

    return 0;
}
