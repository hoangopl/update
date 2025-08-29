#include <stdio.h>
#include <unistd.h>
#include <ui/DisplayInfo.h>
#include <gui/SurfaceComposerClient.h>
#include <gui/SurfaceControl.h>
#include <gui/Surface.h>
#include <utils/StrongPointer.h>
#include <utils/RefBase.h>
#include <android/native_window.h>
#include <android/native_window_jni.h>

using namespace android;

int main() {
    // Kết nối SurfaceFlinger
    sp<SurfaceComposerClient> client = new SurfaceComposerClient();
    if (client->initCheck() != NO_ERROR) {
        fprintf(stderr, "❌ Không kết nối được SurfaceFlinger\n");
        return -1;
    }

    // Lấy thông tin màn hình chính
    DisplayInfo info;
    sp<IBinder> display = SurfaceComposerClient::getInternalDisplayToken();
    if (display == nullptr) {
        fprintf(stderr, "❌ Không lấy được display token\n");
        return -1;
    }
    if (SurfaceComposerClient::getDisplayInfo(display, &info) != NO_ERROR) {
        fprintf(stderr, "❌ Không lấy được thông tin màn hình\n");
        return -1;
    }
    int width = info.w;
    int height = info.h;

    // Tạo SurfaceControl
    sp<SurfaceControl> sc = client->createSurface(
        String8("RedOverlay"),
        width, height,
        PIXEL_FORMAT_RGBA_8888,
        ISurfaceComposerClient::eFXSurfaceBufferState);

    if (sc == nullptr || !sc->isValid()) {
        fprintf(stderr, "❌ Tạo SurfaceControl thất bại\n");
        return -1;
    }

    // Hiện surface trên cùng
    SurfaceComposerClient::Transaction t;
    t.setLayer(sc, INT_MAX);
    t.show(sc);
    t.apply();

    // Lấy surface để vẽ
    sp<Surface> surface = sc->getSurface();
    ANativeWindow_Buffer buf;
    ARect rect = {0, 0, width, height};

    // Lock buffer
    if (ANativeWindow_lock(surface.get(), &buf, &rect) == 0) {
        uint32_t *pixels = (uint32_t *)buf.bits;
        for (int y = 0; y < height; y++) {
            for (int x = 0; x < width; x++) {
                pixels[y * buf.stride + x] = 0xFFFF0000; // ARGB: đỏ
            }
        }
        ANativeWindow_unlockAndPost(surface.get());
    } else {
        fprintf(stderr, "❌ Không lock được surface\n");
    }

    printf("✅ Overlay màu đỏ hiển thị trong 5 giây...\n");
    sleep(5);

    // Xoá overlay
    SurfaceComposerClient::Transaction cleanup;
    cleanup.remove(sc);
    cleanup.apply();

    return 0;
}