#include <stdio.h>
#include <unistd.h>
#include <fcntl.h>
#include <sched.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <errno.h>
#include <string.h>

#include <ui/DisplayInfo.h>
#include <gui/SurfaceComposerClient.h>
#include <gui/SurfaceControl.h>
#include <gui/Surface.h>
#include <utils/StrongPointer.h>
#include <utils/RefBase.h>
#include <android/native_window.h>

using namespace android;

int enterSurfaceFlingerNamespace() {
    FILE *fp = popen("pidof surfaceflinger", "r");
    if (!fp) {
        fprintf(stderr, "❌ Không chạy được pidof\n");
        return -1;
    }
    int pid = -1;
    fscanf(fp, "%d", &pid);
    pclose(fp);

    if (pid <= 0) {
        fprintf(stderr, "❌ Không tìm thấy PID surfaceflinger\n");
        return -1;
    }

    char ns_path[128];
    snprintf(ns_path, sizeof(ns_path), "/proc/%d/ns/ipc", pid);

    int fd = open(ns_path, O_RDONLY);
    if (fd < 0) {
        fprintf(stderr, "❌ Không mở được %s: %s\n", ns_path, strerror(errno));
        return -1;
    }

    if (setns(fd, 0) < 0) {
        fprintf(stderr, "❌ setns() thất bại: %s\n", strerror(errno));
        close(fd);
        return -1;
    }

    close(fd);
    printf("✅ Đã join IPC namespace của surfaceflinger (PID=%d)\n", pid);
    return 0;
}

int main() {
    if (enterSurfaceFlingerNamespace() < 0) {
        return -1;
    }

    // Kết nối SurfaceFlinger
    sp<SurfaceComposerClient> client = new SurfaceComposerClient();
    if (client->initCheck() != NO_ERROR) {
        fprintf(stderr, "❌ Không kết nối được SurfaceFlinger\n");
        return -1;
    }

    // Lấy thông tin màn hình
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

    SurfaceComposerClient::Transaction t;
    t.setLayer(sc, INT_MAX);
    t.show(sc);
    t.apply();

    // Vẽ đỏ
    sp<Surface> surface = sc->getSurface();
    ANativeWindow_Buffer buf;
    ARect rect = {0, 0, width, height};

    if (ANativeWindow_lock(surface.get(), &buf, &rect) == 0) {
        uint32_t *pixels = (uint32_t *)buf.bits;
        for (int y = 0; y < height; y++) {
            for (int x = 0; x < width; x++) {
                pixels[y * buf.stride + x] = 0xFFFF0000; // đỏ
            }
        }
        ANativeWindow_unlockAndPost(surface.get());
    } else {
        fprintf(stderr, "❌ Không lock được surface\n");
    }

    printf("✅ Overlay màu đỏ hiển thị trong 5 giây...\n");
    sleep(5);

    // Xóa overlay
    SurfaceComposerClient::Transaction cleanup;
    cleanup.hide(sc);
    cleanup.reparent(sc, nullptr);
    cleanup.apply();

    return 0;
}
