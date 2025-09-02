// overlaydemo.cpp
// Yêu cầu: build trong AOSP (link libgui, libui, libutils, libbinder, libandroid, libcutils)
// Chức năng: join mnt+ipc (và net nếu có) của surfaceflinger, tạo overlay đỏ full-screen 5s

#include <stdio.h>
#include <stdlib.h>
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
#include <binder/IBinder.h>
#include <android/native_window.h>

using namespace android;

static void log_err(const char* fmt, ...) __attribute__((format(printf,1,2)));
static void log_err(const char* fmt, ...) {
    va_list ap;
    va_start(ap, fmt);
    fprintf(stderr, "ERROR: ");
    vfprintf(stderr, fmt, ap);
    fprintf(stderr, "\n");
    va_end(ap);
}
static void log_info(const char* fmt, ...) __attribute__((format(printf,1,2)));
static void log_info(const char* fmt, ...) {
    va_list ap;
    va_start(ap, fmt);
    fprintf(stdout, "INFO: ");
    vfprintf(stdout, fmt, ap);
    fprintf(stdout, "\n");
    va_end(ap);
}

static int get_surface_flinger_pid() {
    FILE *fp = popen("pidof surfaceflinger", "r");
    if (!fp) {
        log_err("popen(pidof) failed: %s", strerror(errno));
        return -1;
    }
    char buf[256];
    if (!fgets(buf, sizeof(buf), fp)) {
        pclose(fp);
        log_err("pidof returned nothing");
        return -1;
    }
    pclose(fp);

    // Trim newline
    size_t len = strlen(buf);
    if (len && buf[len-1] == '\n') buf[len-1] = '\0';

    // pidof can return multiple PIDs separated by space; pick the first token that's a number
    char *tok = strtok(buf, " \t");
    while (tok) {
        char *endptr = nullptr;
        long pid = strtol(tok, &endptr, 10);
        if (endptr != tok && pid > 0) {
            return (int)pid;
        }
        tok = strtok(NULL, " \t");
    }
    log_err("Could not parse pidof output: '%s'", buf);
    return -1;
}

static int join_namespace(int pid, const char* nsname) {
    char path[128];
    snprintf(path, sizeof(path), "/proc/%d/ns/%s", pid, nsname);
    int fd = open(path, O_RDONLY | O_CLOEXEC);
    if (fd < 0) {
        // Not fatal for optional namespaces (like net may not exist), but print message
        log_err("open(%s) failed: %s", path, strerror(errno));
        return -1;
    }
    if (setns(fd, 0) < 0) {
        log_err("setns(%s) failed: %s", path, strerror(errno));
        close(fd);
        return -1;
    }
    close(fd);
    log_info("Joined %s namespace of PID=%d", nsname, pid);
    return 0;
}

int main(int argc, char** argv) {
    // Warn if not running as system (helps debugging)
    uid_t uid = getuid();
    gid_t gid = getgid();
    log_info("Starting redoverlay (uid=%d,gid=%d)", uid, gid);
    if (uid != 1000) { // UID 1000 is typically 'system' on AOSP
        log_err("Warning: process not running as UID 1000 (system). You should run via init.rc with 'user system'. Continue anyway.");
    }

    int pid = get_surface_flinger_pid();
    if (pid <= 0) {
        log_err("Cannot find surfaceflinger PID");
        return -1;
    }
    log_info("Found surfaceflinger PID=%d", pid);

    // Join mount namespace first (important so binder files /dev/... and libraries resolve same)
    if (join_namespace(pid, "mnt") < 0) {
        log_err("Failed to join mnt namespace. Try running with nsenter --target %d --mount ... to test", pid);
        // continue and still try ipc, because sometimes mnt not required on some devices
    }

    // Join ipc namespace (important for binder ipc)
    if (join_namespace(pid, "ipc") < 0) {
        log_err("Failed to join ipc namespace.");
        // continue to try others
    }

    // Optionally join net namespace if exists
    join_namespace(pid, "net"); // ignore result

    // After setns, proceed to connect to SurfaceFlinger
    sp<SurfaceComposerClient> client = new SurfaceComposerClient();
    status_t st = client->initCheck();
    if (st != NO_ERROR) {
        log_err("SurfaceComposerClient initCheck failed: %d", st);
        return -1;
    }
    log_info("Connected to SurfaceFlinger");

    // Get display info
    DisplayInfo info;
    sp<IBinder> display = SurfaceComposerClient::getInternalDisplayToken();
    if (display == nullptr) {
        log_err("getInternalDisplayToken returned null");
        return -1;
    }
    if (SurfaceComposerClient::getDisplayInfo(display, &info) != NO_ERROR) {
        log_err("getDisplayInfo failed");
        return -1;
    }
    int width = info.w;
    int height = info.h;
    log_info("Display size: %d x %d (density=%f)", width, height, info.density);

    // Create surface
    sp<SurfaceControl> sc = client->createSurface(
        String8("RedOverlay"),
        width, height,
        PIXEL_FORMAT_RGBA_8888,
        ISurfaceComposerClient::eFXSurfaceBufferState);

    if (sc == nullptr || !sc->isValid()) {
        log_err("createSurface failed or surface invalid");
        return -1;
    }

    // Place it on top
    SurfaceComposerClient::Transaction t;
    // use a very high layer value; INT_MAX may be clamped, but it's fine in many builds
    t.setLayer(sc, INT_MAX);
    t.show(sc);
    t.apply();

    // Draw red
    sp<Surface> surface = sc->getSurface();
    if (surface == nullptr) {
        log_err("getSurface returned null");
    } else {
        ANativeWindow_Buffer buf;
        ARect rect = {0, 0, width, height};
        // ANativeWindow_lock expects ANativeWindow*, Surface inherits that on many builds so .get() works
        if (ANativeWindow_lock(surface.get(), &buf, &rect) == 0) {
            // Note: buf.stride may be >= width
            uint32_t *pixels = (uint32_t*)buf.bits;
            for (int y = 0; y < height; y++) {
                uint32_t *row = pixels + (y * buf.stride);
                for (int x = 0; x < width; x++) {
                    row[x] = 0xFFFF0000; // ARGB: solid red
                }
            }
            ANativeWindow_unlockAndPost(surface.get());
            log_info("Posted red buffer");
        } else {
            log_err("ANativeWindow_lock failed");
        }
    }

    log_info("Overlay shown for 5 seconds...");
    sleep(5);

    // Cleanup: hide + reparent to null
    SurfaceComposerClient::Transaction cleanup;
    cleanup.hide(sc);
    cleanup.reparent(sc, nullptr);
    cleanup.apply();
    log_info("Overlay removed, exiting.");

    return 0;
}
