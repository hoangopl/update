// overlaydemo_bufferlayer.cpp
// Android 10: dùng GraphicBuffer (constructor 4 tham số) để vẽ overlay đỏ 5s

#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <fcntl.h>
#include <sched.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <errno.h>
#include <string.h>
#include <signal.h>

#include <ui/DisplayInfo.h>
#include <gui/SurfaceComposerClient.h>
#include <gui/SurfaceControl.h>
#include <ui/GraphicBuffer.h>
#include <utils/StrongPointer.h>
#include <utils/RefBase.h>
#include <binder/IBinder.h>

using namespace android;

static void segv_handler(int sig, siginfo_t *si, void *unused) {
    fprintf(stderr, "FATAL: signal %d at address %p\n", sig, si ? si->si_addr : NULL);
    _exit(128 + sig);
}

static void install_segv_handler() {
    struct sigaction sa;
    sa.sa_flags = SA_SIGINFO | SA_RESTART;
    sa.sa_sigaction = segv_handler;
    sigemptyset(&sa.sa_mask);
    sigaction(SIGSEGV, &sa, NULL);
    sigaction(SIGABRT, &sa, NULL);
}

static int get_surface_flinger_pid() {
    FILE *fp = popen("pidof surfaceflinger", "r");
    if (!fp) return -1;
    char buf[256];
    if (!fgets(buf, sizeof(buf), fp)) { pclose(fp); return -1; }
    pclose(fp);
    size_t len = strlen(buf);
    if (len && buf[len-1]=='\n') buf[len-1]=0;
    char *tok = strtok(buf, " \t");
    while (tok) {
        char *endptr = NULL;
        long pid = strtol(tok, &endptr, 10);
        if (endptr != tok && pid > 0) return (int)pid;
        tok = strtok(NULL, " \t");
    }
    return -1;
}

static int join_namespace(int pid, const char* nsname) {
    char path[128];
    snprintf(path, sizeof(path), "/proc/%d/ns/%s", pid, nsname);
    int fd = open(path, O_RDONLY | O_CLOEXEC);
    if (fd < 0) {
        fprintf(stderr, "WARN: open(%s): %s\n", path, strerror(errno));
        return -1;
    }
    if (setns(fd, 0) < 0) {
        fprintf(stderr, "WARN: setns(%s): %s\n", path, strerror(errno));
        close(fd);
        return -1;
    }
    close(fd);
    fprintf(stdout, "INFO: joined %s ns\n", nsname);
    return 0;
}

int main(int argc, char** argv) {
    install_segv_handler();

    fprintf(stdout, "INFO: Starting overlaydemo_bufferlayer (uid=%d,gid=%d)\n", getuid(), getgid());

    int pid = get_surface_flinger_pid();
    if (pid <= 0) { fprintf(stderr, "ERROR: cannot find surfaceflinger pid\n"); return -1; }
    fprintf(stdout, "INFO: surfaceflinger pid=%d\n", pid);

    join_namespace(pid, "mnt");
    join_namespace(pid, "ipc");
    join_namespace(pid, "net");

    if (setgid(1000) != 0) {
        fprintf(stderr, "WARN: setgid(1000) failed: %s\n", strerror(errno));
    }
    if (setuid(1000) != 0) {
        fprintf(stderr, "WARN: setuid(1000) failed: %s\n", strerror(errno));
    }
    fprintf(stdout, "INFO: after setuid -> uid=%d,gid=%d\n", getuid(), getgid());

    sp<SurfaceComposerClient> client = new SurfaceComposerClient();
    status_t st = client->initCheck();
    if (st != NO_ERROR) {
        fprintf(stderr, "ERROR: SurfaceComposerClient initCheck failed: %d\n", st);
        return -1;
    }
    fprintf(stdout, "INFO: connected to SurfaceFlinger\n");

    DisplayInfo info;
    sp<IBinder> display = SurfaceComposerClient::getInternalDisplayToken();
    if (display == nullptr) { fprintf(stderr, "ERROR: null display token\n"); return -1; }
    if (SurfaceComposerClient::getDisplayInfo(display, &info) != NO_ERROR) {
        fprintf(stderr, "ERROR: getDisplayInfo failed\n"); return -1;
    }
    int width = info.w, height = info.h;
    fprintf(stdout, "INFO: display %d x %d density=%f\n", width, height, info.density);

    // Tạo SurfaceControl
    sp<SurfaceControl> sc = client->createSurface(
        String8("RedOverlayBuffer"),
        width, height,
        PIXEL_FORMAT_RGBA_8888,
        ISurfaceComposerClient::eFXSurfaceBufferState
    );
    if (sc == nullptr || !sc->isValid()) {
        fprintf(stderr, "ERROR: createSurface invalid\n");
        return -1;
    }

    SurfaceComposerClient::Transaction t;
    t.setLayer(sc, INT_MAX);
    t.show(sc);
    t.apply();

    // --- Tạo GraphicBuffer (Android 10 vẫn hỗ trợ constructor 4 tham số) ---
    sp<GraphicBuffer> gb = new GraphicBuffer(
        width,
        height,
        PIXEL_FORMAT_RGBA_8888,
        GraphicBuffer::USAGE_SW_WRITE_OFTEN | GraphicBuffer::USAGE_HW_COMPOSER
    );

    if (gb == nullptr || gb->initCheck() != NO_ERROR) {
        fprintf(stderr, "ERROR: cannot allocate GraphicBuffer\n");
        return -1;
    }

    void* vaddr = nullptr;
    status_t r = gb->lock(GraphicBuffer::USAGE_SW_WRITE_OFTEN, &vaddr);
    if (r == NO_ERROR && vaddr) {
        int32_t stride = gb->getStride();
        uint32_t* pixels = reinterpret_cast<uint32_t*>(vaddr);
        for (int y = 0; y < height; y++) {
            uint32_t* row = pixels + (size_t)y * (size_t)stride;
            for (int x = 0; x < width; x++) {
                row[x] = 0xFF0000FF; // alpha=255, blue=255
            }
        }
        gb->unlock();

        SurfaceComposerClient::Transaction bufT;
        bufT.setBuffer(sc, gb);
        bufT.apply();
        fprintf(stdout, "INFO: buffer set and posted\n");
    } else {
        fprintf(stderr, "ERROR: GraphicBuffer lock failed\n");
    }

    fprintf(stdout, "INFO: sleeping 5s\n");
    sleep(5);

    // cleanup
    SurfaceComposerClient::Transaction cleanup;
    cleanup.hide(sc);
    cleanup.reparent(sc, nullptr);
    cleanup.apply();

    fprintf(stdout, "INFO: exit.\n");
    return 0;
}
