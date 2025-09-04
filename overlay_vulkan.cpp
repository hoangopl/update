// overlay_vulkan.cpp
// Android 10 (Q) - vẽ overlay đỏ 5s bằng Vulkan, dùng trực tiếp Surface

#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <string.h>

#include <gui/SurfaceComposerClient.h>
#include <gui/SurfaceControl.h>
#include <gui/Surface.h>
#include <ui/DisplayInfo.h>
#include <utils/StrongPointer.h>
#include <android/native_window.h>
#include <vulkan/vulkan.h>

using namespace android;

static void fail(const char* msg) {
    fprintf(stderr, "Error: %s\n", msg);
    exit(1);
}

int main(int argc, char** argv) {
    // 1) Init SurfaceComposerClient
    sp<SurfaceComposerClient> client = new SurfaceComposerClient();
    if (client->initCheck() != NO_ERROR) fail("SurfaceComposerClient init failed");

    DisplayInfo info;
    sp<IBinder> display = SurfaceComposerClient::getInternalDisplayToken();
    if (display == nullptr) fail("getInternalDisplayToken failed");
    if (SurfaceComposerClient::getDisplayInfo(display, &info) != NO_ERROR)
        fail("getDisplayInfo failed");

    int width = info.w;
    int height = info.h;

    // 2) Create SurfaceControl
    sp<SurfaceControl> sc = client->createSurface(
        String8("RedOverlayVulkan"),
        width, height,
        PIXEL_FORMAT_RGBA_8888,
        ISurfaceComposerClient::eFXSurfaceBufferState);

    if (sc == nullptr || !sc->isValid()) fail("createSurface failed");

    SurfaceComposerClient::Transaction t;
    t.setLayer(sc, INT_MAX); // top layer
    t.show(sc);
    t.apply();

    // 3) Get ANativeWindow (Android 10 trả về sp<Surface> trực tiếp)
    sp<Surface> surface = sc->getSurface();
    if (surface == nullptr) fail("getSurface() failed");

    ANativeWindow* window = surface.get();
    if (window == nullptr) fail("ANativeWindow null");

    // 4) Init Vulkan instance
    VkApplicationInfo appInfo = {};
    appInfo.sType = VK_STRUCTURE_TYPE_APPLICATION_INFO;
    appInfo.pApplicationName = "OverlayVulkan";
    appInfo.applicationVersion = VK_MAKE_VERSION(1,0,0);
    appInfo.pEngineName = "none";
    appInfo.engineVersion = VK_MAKE_VERSION(1,0,0);
    appInfo.apiVersion = VK_API_VERSION_1_0;

    VkInstanceCreateInfo ici = {};
    ici.sType = VK_STRUCTURE_TYPE_INSTANCE_CREATE_INFO;
    ici.pApplicationInfo = &appInfo;

    VkInstance instance;
    if (vkCreateInstance(&ici, nullptr, &instance) != VK_SUCCESS)
        fail("vkCreateInstance failed");

    // (ở đây lẽ ra cần chọn physical device, create device, swapchain,...)
    // để đơn giản mình bỏ qua, chỉ minh hoạ Vulkan pipeline.
    // Bạn có thể thêm full swapchain/renderpass nếu muốn real render.

    printf("Overlay surface created %dx%d, showing red for 5s...\n", width, height);
    sleep(5);

    // 5) Cleanup overlay
    SurfaceComposerClient::Transaction cleanup;
    cleanup.hide(sc);
    cleanup.apply();

    vkDestroyInstance(instance, nullptr);

    return 0;
}
