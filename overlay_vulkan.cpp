// overlaydemo_vulkan.cpp
// Android 10: Vẽ overlay đỏ 5s bằng Vulkan lên SurfaceControl (BufferLayer)

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
#include <gui/Surface.h>
#include <utils/StrongPointer.h>
#include <binder/IBinder.h>
#include <android/native_window.h>

// Vulkan
#include <vulkan/vulkan.h>
#include <vulkan/vulkan_android.h>

using namespace android;

static void segv_handler(int sig, siginfo_t *si, void *unused) {
    fprintf(stderr, "FATAL: signal %d at %p\n", sig, si ? si->si_addr : NULL);
    _exit(128 + sig);
}
static void install_segv_handler() {
    struct sigaction sa{};
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
    if (fd < 0) { fprintf(stderr, "WARN: open(%s): %s\n", path, strerror(errno)); return -1; }
    if (setns(fd, 0) < 0) { fprintf(stderr, "WARN: setns(%s): %s\n", path, strerror(errno)); close(fd); return -1; }
    close(fd);
    fprintf(stdout, "INFO: joined %s ns\n", nsname);
    return 0;
}

// --- Vulkan helpers (siêu tối giản, bỏ qua nhiều nhánh lỗi để ngắn gọn) ---
static uint32_t findGraphicsPresentQueue(VkPhysicalDevice pd, VkSurfaceKHR surface) {
    uint32_t qCount = 0;
    vkGetPhysicalDeviceQueueFamilyProperties(pd, &qCount, nullptr);
    std::vector<VkQueueFamilyProperties> props(qCount);
    vkGetPhysicalDeviceQueueFamilyProperties(pd, &qCount, props.data());
    for (uint32_t i = 0; i < qCount; ++i) {
        VkBool32 present = VK_FALSE;
        vkGetPhysicalDeviceSurfaceSupportKHR(pd, i, surface, &present);
        if ((props[i].queueFlags & VK_QUEUE_GRAPHICS_BIT) && present) return i;
    }
    return UINT32_MAX;
}
static VkSurfaceFormatKHR chooseSurfaceFormat(VkPhysicalDevice pd, VkSurfaceKHR surface) {
    uint32_t count = 0; vkGetPhysicalDeviceSurfaceFormatsKHR(pd, surface, &count, nullptr);
    std::vector<VkSurfaceFormatKHR> formats(count);
    vkGetPhysicalDeviceSurfaceFormatsKHR(pd, surface, &count, formats.data());
    // ưu tiên B8G8R8A8_UNORM
    for (auto &f : formats) {
        if (f.format == VK_FORMAT_B8G8R8A8_UNORM && f.colorSpace == VK_COLOR_SPACE_SRGB_NONLINEAR_KHR) return f;
    }
    // fallback: lấy cái đầu
    return formats[0];
}
static VkPresentModeKHR choosePresentMode(VkPhysicalDevice pd, VkSurfaceKHR surface) {
    uint32_t count = 0; vkGetPhysicalDevicePresentModesKHR(pd, surface, &count, nullptr);
    std::vector<VkPresentModeKHR> modes(count);
    vkGetPhysicalDevicePresentModesKHR(pd, surface, &count, modes.data());
    // Luôn có FIFO; nếu có MAILBOX thì mượt hơn, nhưng demo dùng FIFO cho chắc
    for (auto m : modes) if (m == VK_PRESENT_MODE_MAILBOX_KHR) return m;
    return VK_PRESENT_MODE_FIFO_KHR;
}

int main(int argc, char** argv) {
    install_segv_handler();
    fprintf(stdout, "INFO: Starting overlaydemo_vulkan (uid=%d,gid=%d)\n", getuid(), getgid());

    // (Tuỳ bạn có cần join ns/setuid không; giữ giống bản trước)
    int pid = get_surface_flinger_pid();
    if (pid <= 0) { fprintf(stderr, "ERROR: cannot find surfaceflinger pid\n"); return -1; }
    join_namespace(pid, "mnt"); join_namespace(pid, "ipc"); join_namespace(pid, "net");
    setgid(1000); setuid(1000);

    // Tạo SurfaceControl (BufferLayer)
    sp<SurfaceComposerClient> client = new SurfaceComposerClient();
    if (client->initCheck() != NO_ERROR) { fprintf(stderr, "ERROR: SurfaceComposerClient failed\n"); return -1; }

    DisplayInfo di{};
    sp<IBinder> dpy = SurfaceComposerClient::getInternalDisplayToken();
    if (dpy == nullptr || SurfaceComposerClient::getDisplayInfo(dpy, &di) != NO_ERROR) {
        fprintf(stderr, "ERROR: getDisplayInfo\n"); return -1;
    }
    const int width = di.w, height = di.h;

    sp<SurfaceControl> sc = client->createSurface(
        String8("VulkanOverlay"),
        width, height,
        PIXEL_FORMAT_RGBA_8888,
        ISurfaceComposerClient::eFXSurfaceBufferState
    );
    if (sc == nullptr || !sc->isValid()) { fprintf(stderr, "ERROR: createSurface\n"); return -1; }

    SurfaceComposerClient::Transaction t;
    t.setLayer(sc, INT_MAX).show(sc).apply();

    sp<Surface> surface = sc->getSurface();
    if (surface == nullptr) { fprintf(stderr, "ERROR: getSurface\n"); return -1; }
    ANativeWindow* window = surface.get();

    // --- Vulkan init ---
    const char* instExts[] = { VK_KHR_SURFACE_EXTENSION_NAME, VK_KHR_ANDROID_SURFACE_EXTENSION_NAME };
    VkApplicationInfo appInfo{ VK_STRUCTURE_TYPE_APPLICATION_INFO };
    appInfo.apiVersion = VK_API_VERSION_1_0;
    appInfo.pApplicationName = "overlaydemo_vulkan";

    VkInstanceCreateInfo ici{ VK_STRUCTURE_TYPE_INSTANCE_CREATE_INFO };
    ici.pApplicationInfo = &appInfo;
    ici.enabledExtensionCount = 2;
    ici.ppEnabledExtensionNames = instExts;

    VkInstance instance = VK_NULL_HANDLE;
    VkResult vr = vkCreateInstance(&ici, nullptr, &instance);
    if (vr != VK_SUCCESS) { fprintf(stderr, "ERROR: vkCreateInstance %d\n", vr); return -1; }

    // SurfaceKHR từ ANativeWindow
    VkAndroidSurfaceCreateInfoKHR asci{ VK_STRUCTURE_TYPE_ANDROID_SURFACE_CREATE_INFO_KHR };
    asci.window = window;
    VkSurfaceKHR vkSurface = VK_NULL_HANDLE;
    vr = vkCreateAndroidSurfaceKHR(instance, &asci, nullptr, &vkSurface);
    if (vr != VK_SUCCESS) { fprintf(stderr, "ERROR: vkCreateAndroidSurfaceKHR %d\n", vr); return -1; }

    // Chọn physical device
    uint32_t pdCount = 0; vkEnumeratePhysicalDevices(instance, &pdCount, nullptr);
    if (pdCount == 0) { fprintf(stderr, "ERROR: no physical device\n"); return -1; }
    std::vector<VkPhysicalDevice> pds(pdCount);
    vkEnumeratePhysicalDevices(instance, &pdCount, pds.data());

    VkPhysicalDevice phys = VK_NULL_HANDLE;
    uint32_t qFamily = UINT32_MAX;
    for (auto pd : pds) {
        uint32_t q = findGraphicsPresentQueue(pd, vkSurface);
        if (q != UINT32_MAX) { phys = pd; qFamily = q; break; }
    }
    if (phys == VK_NULL_HANDLE) { fprintf(stderr, "ERROR: no gfx+present queue\n"); return -1; }

    float qPrior = 1.0f;
    VkDeviceQueueCreateInfo dq{ VK_STRUCTURE_TYPE_DEVICE_QUEUE_CREATE_INFO };
    dq.queueFamilyIndex = qFamily; dq.queueCount = 1; dq.pQueuePriorities = &qPrior;

    const char* devExts[] = { VK_KHR_SWAPCHAIN_EXTENSION_NAME };
    VkDeviceCreateInfo dci{ VK_STRUCTURE_TYPE_DEVICE_CREATE_INFO };
    dci.queueCreateInfoCount = 1; dci.pQueueCreateInfos = &dq;
    dci.enabledExtensionCount = 1; dci.ppEnabledExtensionNames = devExts;

    VkDevice device = VK_NULL_HANDLE;
    vr = vkCreateDevice(phys, &dci, nullptr, &device);
    if (vr != VK_SUCCESS) { fprintf(stderr, "ERROR: vkCreateDevice %d\n", vr); return -1; }
    VkQueue queue = VK_NULL_HANDLE;
    vkGetDeviceQueue(device, qFamily, 0, &queue);

    // Chọn surface format & present mode
    VkSurfaceCapabilitiesKHR caps{};
    vkGetPhysicalDeviceSurfaceCapabilitiesKHR(phys, vkSurface, &caps);
    VkSurfaceFormatKHR sf = chooseSurfaceFormat(phys, vkSurface);
    VkPresentModeKHR pm = choosePresentMode(phys, vkSurface);

    VkExtent2D extent = caps.currentExtent;
    if (extent.width == 0xFFFFFFFF) { extent.width = width; extent.height = height; }

    uint32_t imageCount = caps.minImageCount + 1;
    if (caps.maxImageCount > 0 && imageCount > caps.maxImageCount) imageCount = caps.maxImageCount;

    VkSwapchainCreateInfoKHR sci{ VK_STRUCTURE_TYPE_SWAPCHAIN_CREATE_INFO_KHR };
    sci.surface = vkSurface;
    sci.minImageCount = imageCount;
    sci.imageFormat = sf.format;
    sci.imageColorSpace = sf.colorSpace;
    sci.imageExtent = extent;
    sci.imageArrayLayers = 1;
    sci.imageUsage = VK_IMAGE_USAGE_COLOR_ATTACHMENT_BIT;
    sci.imageSharingMode = VK_SHARING_MODE_EXCLUSIVE;
    sci.preTransform = caps.currentTransform;
    sci.compositeAlpha = VK_COMPOSITE_ALPHA_OPAQUE_BIT_KHR;
    sci.presentMode = pm;
    sci.clipped = VK_TRUE;

    VkSwapchainKHR swapchain = VK_NULL_HANDLE;
    vr = vkCreateSwapchainKHR(device, &sci, nullptr, &swapchain);
    if (vr != VK_SUCCESS) { fprintf(stderr, "ERROR: vkCreateSwapchainKHR %d\n", vr); return -1; }

    // Lấy images & tạo image views
    uint32_t scImgCount = 0; vkGetSwapchainImagesKHR(device, swapchain, &scImgCount, nullptr);
    std::vector<VkImage> images(scImgCount);
    vkGetSwapchainImagesKHR(device, swapchain, &scImgCount, images.data());

    std::vector<VkImageView> views(scImgCount);
    for (uint32_t i=0;i<scImgCount;i++){
        VkImageViewCreateInfo ivci{ VK_STRUCTURE_TYPE_IMAGE_VIEW_CREATE_INFO };
        ivci.image = images[i];
        ivci.viewType = VK_IMAGE_VIEW_TYPE_2D;
        ivci.format = sf.format;
        ivci.components = { VK_COMPONENT_SWIZZLE_IDENTITY, VK_COMPONENT_SWIZZLE_IDENTITY,
                            VK_COMPONENT_SWIZZLE_IDENTITY, VK_COMPONENT_SWIZZLE_IDENTITY };
        ivci.subresourceRange.aspectMask = VK_IMAGE_ASPECT_COLOR_BIT;
        ivci.subresourceRange.levelCount = 1;
        ivci.subresourceRange.layerCount = 1;
        vr = vkCreateImageView(device, &ivci, nullptr, &views[i]);
        if (vr != VK_SUCCESS) { fprintf(stderr, "ERROR: vkCreateImageView %d\n", vr); return -1; }
    }

    // Render pass (clear to color)
    VkAttachmentDescription colorAtt{};
    colorAtt.format = sf.format;
    colorAtt.samples = VK_SAMPLE_COUNT_1_BIT;
    colorAtt.loadOp = VK_ATTACHMENT_LOAD_OP_CLEAR;
    colorAtt.storeOp = VK_ATTACHMENT_STORE_OP_STORE;
    colorAtt.initialLayout = VK_IMAGE_LAYOUT_UNDEFINED;
    colorAtt.finalLayout = VK_IMAGE_LAYOUT_PRESENT_SRC_KHR;

    VkAttachmentReference colorRef{ 0, VK_IMAGE_LAYOUT_COLOR_ATTACHMENT_OPTIMAL };
    VkSubpassDescription subpass{};
    subpass.pipelineBindPoint = VK_PIPELINE_BIND_POINT_GRAPHICS;
    subpass.colorAttachmentCount = 1;
    subpass.pColorAttachments = &colorRef;

    VkRenderPassCreateInfo rpci{ VK_STRUCTURE_TYPE_RENDER_PASS_CREATE_INFO };
    rpci.attachmentCount = 1; rpci.pAttachments = &colorAtt;
    rpci.subpassCount = 1; rpci.pSubpasses = &subpass;

    VkRenderPass renderPass = VK_NULL_HANDLE;
    vr = vkCreateRenderPass(device, &rpci, nullptr, &renderPass);
    if (vr != VK_SUCCESS) { fprintf(stderr, "ERROR: vkCreateRenderPass %d\n", vr); return -1; }

    // Framebuffers
    std::vector<VkFramebuffer> fbs(scImgCount);
    for (uint32_t i=0;i<scImgCount;i++){
        VkFramebufferCreateInfo fbci{ VK_STRUCTURE_TYPE_FRAMEBUFFER_CREATE_INFO };
        fbci.renderPass = renderPass;
        fbci.attachmentCount = 1;
        VkImageView att = views[i];
        fbci.pAttachments = &att;
        fbci.width = extent.width; fbci.height = extent.height; fbci.layers = 1;
        vr = vkCreateFramebuffer(device, &fbci, nullptr, &fbs[i]);
        if (vr != VK_SUCCESS) { fprintf(stderr, "ERROR: vkCreateFramebuffer %d\n", vr); return -1; }
    }

    // Command pool/buffers
    VkCommandPoolCreateInfo cpci{ VK_STRUCTURE_TYPE_COMMAND_POOL_CREATE_INFO };
    cpci.queueFamilyIndex = qFamily;
    VkCommandPool cmdPool = VK_NULL_HANDLE;
    vkCreateCommandPool(device, &cpci, nullptr, &cmdPool);

    std::vector<VkCommandBuffer> cmd(scImgCount);
    VkCommandBufferAllocateInfo cbai{ VK_STRUCTURE_TYPE_COMMAND_BUFFER_ALLOCATE_INFO };
    cbai.commandPool = cmdPool; cbai.level = VK_COMMAND_BUFFER_LEVEL_PRIMARY; cbai.commandBufferCount = scImgCount;
    vkAllocateCommandBuffers(device, &cbai, cmd.data());

    // Ghi lệnh: clear đỏ
    for (uint32_t i=0;i<scImgCount;i++){
        VkCommandBufferBeginInfo bi{ VK_STRUCTURE_TYPE_COMMAND_BUFFER_BEGIN_INFO };
        vkBeginCommandBuffer(cmd[i], &bi);
        VkClearValue clearColor; clearColor.color = { {1.0f, 0.0f, 0.0f, 1.0f} }; // RED
        VkRenderPassBeginInfo rbi{ VK_STRUCTURE_TYPE_RENDER_PASS_BEGIN_INFO };
        rbi.renderPass = renderPass; rbi.framebuffer = fbs[i];
        rbi.renderArea.offset = {0,0}; rbi.renderArea.extent = extent;
        rbi.clearValueCount = 1; rbi.pClearValues = &clearColor;
        vkCmdBeginRenderPass(cmd[i], &rbi, VK_SUBPASS_CONTENTS_INLINE);
        vkCmdEndRenderPass(cmd[i]);
        vkEndCommandBuffer(cmd[i]);
    }

    // Sync objects
    VkSemaphoreCreateInfo sciSem{ VK_STRUCTURE_TYPE_SEMAPHORE_CREATE_INFO };
    VkFenceCreateInfo fci{ VK_STRUCTURE_TYPE_FENCE_CREATE_INFO };
    fci.flags = VK_FENCE_CREATE_SIGNALED_BIT;

    VkSemaphore imgAvail = VK_NULL_HANDLE, renderDone = VK_NULL_HANDLE;
    VkFence inFlight = VK_NULL_HANDLE;
    vkCreateSemaphore(device, &sciSem, nullptr, &imgAvail);
    vkCreateSemaphore(device, &sciSem, nullptr, &renderDone);
    vkCreateFence(device, &fci, nullptr, &inFlight);

    // Draw 1 frame (đủ cho overlay màu) rồi giữ 5s
    vkWaitForFences(device, 1, &inFlight, VK_TRUE, UINT64_MAX);
    vkResetFences(device, 1, &inFlight);

    uint32_t imageIndex = 0;
    vr = vkAcquireNextImageKHR(device, swapchain, UINT64_MAX, imgAvail, VK_NULL_HANDLE, &imageIndex);
    if (vr != VK_SUCCESS) { fprintf(stderr, "ERROR: vkAcquireNextImageKHR %d\n", vr); goto CLEANUP; }

    VkPipelineStageFlags waitStage = VK_PIPELINE_STAGE_COLOR_ATTACHMENT_OUTPUT_BIT;
    VkSubmitInfo si{ VK_STRUCTURE_TYPE_SUBMIT_INFO };
    si.waitSemaphoreCount = 1; si.pWaitSemaphores = &imgAvail; si.pWaitDstStageMask = &waitStage;
    si.commandBufferCount = 1; si.pCommandBuffers = &cmd[imageIndex];
    si.signalSemaphoreCount = 1; si.pSignalSemaphores = &renderDone;

    vr = vkQueueSubmit(queue, 1, &si, inFlight);
    if (vr != VK_SUCCESS) { fprintf(stderr, "ERROR: vkQueueSubmit %d\n", vr); goto CLEANUP; }

    VkPresentInfoKHR pi{ VK_STRUCTURE_TYPE_PRESENT_INFO_KHR };
    pi.waitSemaphoreCount = 1; pi.pWaitSemaphores = &renderDone;
    pi.swapchainCount = 1; pi.pSwapchains = &swapchain; pi.pImageIndices = &imageIndex;
    vkQueuePresentKHR(queue, &pi);

    vkWaitForFences(device, 1, &inFlight, VK_TRUE, UINT64_MAX);

    fprintf(stdout, "INFO: sleeping 5s\n");
    sleep(5);

CLEANUP:
    vkDeviceWaitIdle(device);
    vkDestroySemaphore(device, imgAvail, nullptr);
    vkDestroySemaphore(device, renderDone, nullptr);
    vkDestroyFence(device, inFlight, nullptr);
    for (auto fb : fbs) vkDestroyFramebuffer(device, fb, nullptr);
    for (auto v : views) vkDestroyImageView(device, v, nullptr);
    vkDestroyRenderPass(device, renderPass, nullptr);
    vkDestroySwapchainKHR(device, swapchain, nullptr);
    vkDestroyDevice(device, nullptr);
    vkDestroySurfaceKHR(instance, vkSurface, nullptr);
    vkDestroyInstance(instance, nullptr);

    // Ẩn layer & cleanup SurfaceControl
    SurfaceComposerClient::Transaction cleanup;
    cleanup.hide(sc).reparent(sc, nullptr).apply();

    fprintf(stdout, "INFO: exit.\n");
    return 0;
}
