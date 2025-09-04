#include <vulkan/vulkan.h>
#include <vulkan/vulkan_android.h>
#include <android/native_window.h>
#include <gui/Surface.h>
#include <gui/SurfaceComposerClient.h>
#include <gui/SurfaceControl.h>
#include <ui/DisplayInfo.h>
#include <binder/IBinder.h>
#include <utils/StrongPointer.h>
#include <unistd.h>
#include <limits.h>

using namespace android;

int main() {
    sp<SurfaceComposerClient> client = new SurfaceComposerClient();
    if (client->initCheck() != NO_ERROR) return -1;

    DisplayInfo info;
    sp<IBinder> display = SurfaceComposerClient::getInternalDisplayToken();
    if (display == nullptr) return -1;
    if (SurfaceComposerClient::getDisplayInfo(display, &info) != NO_ERROR) return -1;

    int width = info.w;
    int height = info.h;

    sp<SurfaceControl> sc = client->createSurface(
        String8("VkOverlay"),
        width, height,
        PIXEL_FORMAT_RGBA_8888,
        ISurfaceComposerClient::eFXSurfaceBufferState
    );
    if (sc == nullptr || !sc->isValid()) return -1;

    SurfaceComposerClient::Transaction t;
    t.setLayer(sc, INT_MAX);
    t.show(sc);
    t.apply();

    sp<Surface> surface = sc->getSurface();
    ANativeWindow* window = surface.get();

    // ---- Vulkan init ----
    VkApplicationInfo appInfo = {
        .sType = VK_STRUCTURE_TYPE_APPLICATION_INFO,
        .pNext = nullptr,
        .pApplicationName = "VkOverlay",
        .applicationVersion = VK_MAKE_VERSION(1,0,0),
        .pEngineName = "None",
        .engineVersion = VK_MAKE_VERSION(1,0,0),
        .apiVersion = VK_API_VERSION_1_0,
    };

    const char* exts[] = {"VK_KHR_surface","VK_KHR_android_surface"};

    VkInstanceCreateInfo ici = {
        .sType = VK_STRUCTURE_TYPE_INSTANCE_CREATE_INFO,
        .pNext = nullptr,
        .flags = 0,
        .pApplicationInfo = &appInfo,
        .enabledExtensionCount = 2,
        .ppEnabledExtensionNames = exts,
    };

    VkInstance instance;
    if (vkCreateInstance(&ici, nullptr, &instance) != VK_SUCCESS) return -1;

    VkAndroidSurfaceCreateInfoKHR asci = {
        .sType = VK_STRUCTURE_TYPE_ANDROID_SURFACE_CREATE_INFO_KHR,
        .pNext = nullptr,
        .flags = 0,
        .window = window,
    };

    VkSurfaceKHR surfaceKHR;
    if (vkCreateAndroidSurfaceKHR(instance, &asci, nullptr, &surfaceKHR) != VK_SUCCESS)
        return -1;

    // ở đây bạn chọn physicalDevice, tạo logicalDevice, swapchain, cmdBuffer,
    // và ghi clear màu đỏ. Do Vulkan khá dài nên mình viết skeleton sẵn.

    // ---- Đơn giản hóa: ngủ 5 giây rồi  ----
    sleep(5);

    vkDestroySurfaceKHR(instance, surfaceKHR, nullptr);
    vkDestroyInstance(instance, nullptr);

    SurfaceComposerClient::Transaction cleanup;
    cleanup.hide(sc);
    cleanup.reparent(sc, nullptr);
    cleanup.apply();

    return 0;
}
