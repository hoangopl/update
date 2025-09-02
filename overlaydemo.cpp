#include <gui/SurfaceComposerClient.h>
#include <gui/SurfaceControl.h>
#include <gui/Surface.h>
#include <ui/DisplayInfo.h>
#include <android/native_window.h>
#include <utils/StrongPointer.h>
#include <unistd.h>
#include <string.h>
#include <fcntl.h>
#include <stdio.h>
#include <dirent.h>
#include <errno.h>

using namespace android;

// Hàm tìm pid của surfaceflinger
pid_t getSurfaceFlingerPid() {
    DIR *dir = opendir("/proc");
    if (!dir) return -1;

    struct dirent *entry;
    while ((entry = readdir(dir)) != nullptr) {
        if (entry->d_type == DT_DIR) {
            pid_t pid = atoi(entry->d_name);
            if (pid > 0) {
                char path[256];
                snprintf(path, sizeof(path), "/proc/%d/comm", pid);
                FILE *f = fopen(path, "r");
                if (f) {
                    char name[256];
                    if (fgets(name, sizeof(name), f)) {
                        name[strcspn(name, "\n")] = 0; // xoá newline
                        if (strcmp(name, "surfaceflinger") == 0) {
                            fclose(f);
                            closedir(dir);
                            return pid;
                        }
                    }
                    fclose(f);
                }
            }
        }
    }
    closedir(dir);
    return -1;
}

int main() {
    // 1. Tìm pid surfaceflinger
    pid_t pid = getSurfaceFlingerPid();
    if (pid <= 0) {
        fprintf(stderr, "Không tìm thấy surfaceflinger\n");
        return 1;
    }

    // 2. Mở /proc/<pid>/ns/ipc
    char nsPath[256];
    snprintf(nsPath, sizeof(nsPath), "/proc/%d/ns/ipc", pid);
    int fd = open(nsPath, O_RDONLY);
    if (fd < 0) {
        fprintf(stderr, "Không mở được %s: %s\n", nsPath, strerror(errno));
    } else {
        printf("Mở thành công %s\n", nsPath);
        close(fd);
    }

    // 3. Kết nối SurfaceComposer và phủ đỏ màn hình
    sp<SurfaceComposerClient> client = new SurfaceComposerClient();

    DisplayInfo info;
    SurfaceComposerClient::getDisplayInfo(0, &info);

    sp<SurfaceControl> control = client->createSurface(
        String8("RedOverlay"),
        info.w, info.h,
        PIXEL_FORMAT_RGBA_8888,
        ISurfaceComposerClient::eFXSurfaceDim | ISurfaceComposerClient::eSecure
    );

    SurfaceComposerClient::openGlobalTransaction();
    control->setLayer(INT_MAX);
    control->show();
    SurfaceComposerClient::closeGlobalTransaction();

    sp<Surface> surface = control->getSurface();
    ANativeWindow* window = static_cast<ANativeWindow*>(surface.get());

    for (int i = 0; i < 5; i++) {
        ANativeWindow_Buffer buffer;
        if (ANativeWindow_lock(window, &buffer, nullptr) == 0) {
            uint32_t* pixels = (uint32_t*)buffer.bits;
            int size = buffer.stride * buffer.height;
            for (int j = 0; j < size; j++) {
                pixels[j] = 0xFFFF0000; // đỏ ARGB
            }
            ANativeWindow_unlockAndPost(window);
        }
        sleep(1);
    }

    SurfaceComposerClient::openGlobalTransaction();
    control->hide();
    SurfaceComposerClient::closeGlobalTransaction();

    return 0;
}
