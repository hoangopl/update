#include <binder/IServiceManager.h>
#include <gui/SurfaceComposerClient.h>
#include <gui/SurfaceControl.h>
#include <unistd.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <sys/syscall.h>
#include <sys/mount.h>
#include <sched.h>
#include <fcntl.h>
#include <cstdlib>
#include <iostream>

using namespace android;

int main() {
    // Lấy pid surfaceflinger
    FILE* fp = popen("pidof surfaceflinger", "r");
    if (!fp) return -1;

    char buf[32] = {0};
    if (!fgets(buf, sizeof(buf), fp)) {
        pclose(fp);
        return -1;
    }
    pclose(fp);

    pid_t sf_pid = atoi(buf);
    if (sf_pid <= 0) return -1;

    // Join IPC namespace của surfaceflinger
    char ns_path[64];
    snprintf(ns_path, sizeof(ns_path), "/proc/%d/ns/ipc", sf_pid);
    int ns_fd = open(ns_path, O_RDONLY);
    if (ns_fd >= 0) {
        setns(ns_fd, 0);
        close(ns_fd);
    }

    // Kết nối SurfaceFlinger
    sp<SurfaceComposerClient> client = new SurfaceComposerClient();
    if (client->initCheck() != NO_ERROR) {
        ALOGE("Failed to init SurfaceComposerClient\n");
        return -1;
    }

    sp<SurfaceControl> control = client->createSurface(
        String8("RedOverlay"),
        1080, 1920, PIXEL_FORMAT_RGBA_8888,
        ISurfaceComposerClient::eOpaque);

    if (control == nullptr) {
        ALOGE("Failed to create surface\n");
        return -1;
    }

    SurfaceComposerClient::Transaction t;
    t.setLayer(control, INT_MAX)       // top layer
     .show(control)
     .setAlpha(control, 1.0f)
     .apply();

    sp<ANativeWindow> window = control->getSurface();
    ANativeWindow_Buffer outBuffer;

    if (window.get() != nullptr) {
        for (int i = 0; i < 5; i++) {
            if (ANativeWindow_lock(window.get(), &outBuffer, nullptr) == 0) {
                uint32_t* pixels = (uint32_t*)outBuffer.bits;
                for (int y = 0; y < outBuffer.height; y++) {
                    for (int x = 0; x < outBuffer.width; x++) {
                        pixels[y * (outBuffer.stride) + x] = 0xFFFF0000; // ARGB Red
                    }
                }
                ANativeWindow_unlockAndPost(window.get());
            }
            sleep(1);
        }
    }

    // Ẩn overlay sau 5 giây
    SurfaceComposerClient::Transaction t2;
    t2.hide(control).apply();

    return 0;
}
