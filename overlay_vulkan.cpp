// overlay_vulkan.cpp
// Android 10 - Vulkan full-screen red overlay for ~5s

#include <unistd.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <errno.h>

#include <vulkan/vulkan.h>
#include <vulkan/vulkan_android.h>

#include <gui/SurfaceComposerClient.h>
#include <gui/SurfaceControl.h>
#include <gui/Surface.h>
#include <ui/DisplayInfo.h>
#include <utils/StrongPointer.h>

using namespace android;

static void fail(const char* msg) {
    fprintf(stderr, "%s\n", msg);
    exit(1);
}

int main(int argc, char** argv) {
    sp<SurfaceComposerClient> client = new SurfaceComposerClient();
    if (client->initCheck() != NO_ERROR) fail("SurfaceComposerClient init failed");

    DisplayInfo info;
    sp<IBinder> display = SurfaceComposerClient::getInternalDisplayToken();
    if (display == nullptr) fail("getInternalDisplayToken failed");
    if (SurfaceComposerClient::getDisplayInfo(display, &info) != NO_ERROR) fail("getDisplayInfo failed");

    int width = info.w;
    int height = info.h;

    sp<SurfaceControl> sc = client->createSurface(
        String8("VulkanRedOverlay"),
        width, height,
        PIXEL_FORMAT_RGBA_8888,
        ISurfaceComposerClient::eFXSurfaceBufferState
    );
    if (sc == nullptr || !sc->isValid()) fail("createSurface failed");

    SurfaceComposerClient::Transaction t;
    t.setLayer(sc, INT_MAX);
    t.show(sc);
    t.apply();

    sp<IGraphicBufferProducer> gbp = sc->getSurface();
    if (gbp == nullptr) fail("getSurface() failed");
    sp<Surface> surface = new Surface(gbp);
    if (surface == nullptr) fail("Surface wrapper failed");
    ANativeWindow* window = surface.get();
    if (window == nullptr) fail("ANativeWindow is null");

    VkResult vkres;

    const char* instExts[] = { VK_KHR_SURFACE_EXTENSION_NAME, VK_KHR_ANDROID_SURFACE_EXTENSION_NAME };

    VkApplicationInfo appInfo{};
    appInfo.sType = VK_STRUCTURE_TYPE_APPLICATION_INFO;
    appInfo.pNext = nullptr;
    appInfo.pApplicationName = "VulkanOverlay";
    appInfo.applicationVersion = VK_MAKE_VERSION(1,0,0);
    appInfo.pEngineName = "None";
    appInfo.engineVersion = VK_MAKE_VERSION(1,0,0);
    appInfo.apiVersion = VK_API_VERSION_1_0;

    VkInstanceCreateInfo icInfo{};
    icInfo.sType = VK_STRUCTURE_TYPE_INSTANCE_CREATE_INFO;
    icInfo.pNext = nullptr;
    icInfo.pApplicationInfo = &appInfo;
    icInfo.enabledExtensionCount = sizeof(instExts)/sizeof(instExts[0]);
    icInfo.ppEnabledExtensionNames = instExts;

    VkInstance instance;
    vkres = vkCreateInstance(&icInfo, NULL, &instance);
    if (vkres != VK_SUCCESS) fail("vkCreateInstance failed");

    VkAndroidSurfaceCreateInfoKHR surfInfo{};
    surfInfo.sType = VK_STRUCTURE_TYPE_ANDROID_SURFACE_CREATE_INFO_KHR;
    surfInfo.pNext = nullptr;
    surfInfo.window = window;

    VkSurfaceKHR surfaceKHR;
    vkres = vkCreateAndroidSurfaceKHR(instance, &surfInfo, NULL, &surfaceKHR);
    if (vkres != VK_SUCCESS) fail("vkCreateAndroidSurfaceKHR failed");

    uint32_t gpuCount = 0;
    vkEnumeratePhysicalDevices(instance, &gpuCount, NULL);
    if (gpuCount == 0) fail("No Vulkan physical devices");

    VkPhysicalDevice* gpus = (VkPhysicalDevice*)malloc(sizeof(VkPhysicalDevice) * gpuCount);
    vkEnumeratePhysicalDevices(instance, &gpuCount, gpus);

    VkPhysicalDevice phys = VK_NULL_HANDLE;
    uint32_t familyIndex = UINT32_MAX;

    for (uint32_t i = 0; i < gpuCount; ++i) {
        uint32_t qCount = 0;
        vkGetPhysicalDeviceQueueFamilyProperties(gpus[i], &qCount, NULL);
        VkQueueFamilyProperties* qProps = (VkQueueFamilyProperties*)malloc(sizeof(VkQueueFamilyProperties)*qCount);
        vkGetPhysicalDeviceQueueFamilyProperties(gpus[i], &qCount, qProps);

        for (uint32_t q = 0; q < qCount; ++q) {
            VkBool32 presentSupported = VK_FALSE;
            vkGetPhysicalDeviceSurfaceSupportKHR(gpus[i], q, surfaceKHR, &presentSupported);
            if ((qProps[q].queueFlags & VK_QUEUE_GRAPHICS_BIT) && presentSupported) {
                phys = gpus[i];
                familyIndex = q;
                break;
            }
        }
        free(qProps);
        if (phys != VK_NULL_HANDLE) break;
    }
    free(gpus);
    if (phys == VK_NULL_HANDLE) fail("No suitable physical device/queue family found");

    float qprio = 1.0f;
    VkDeviceQueueCreateInfo dqci{};
    dqci.sType = VK_STRUCTURE_TYPE_DEVICE_QUEUE_CREATE_INFO;
    dqci.pNext = nullptr;
    dqci.queueFamilyIndex = familyIndex;
    dqci.queueCount = 1;
    dqci.pQueuePriorities = &qprio;

    const char* devExts[] = { VK_KHR_SWAPCHAIN_EXTENSION_NAME };

    VkDeviceCreateInfo devInfo{};
    devInfo.sType = VK_STRUCTURE_TYPE_DEVICE_CREATE_INFO;
    devInfo.pNext = nullptr;
    devInfo.queueCreateInfoCount = 1;
    devInfo.pQueueCreateInfos = &dqci;
    devInfo.enabledExtensionCount = 1;
    devInfo.ppEnabledExtensionNames = devExts;

    VkDevice device;
    vkres = vkCreateDevice(phys, &devInfo, NULL, &device);
    if (vkres != VK_SUCCESS) fail("vkCreateDevice failed");

    VkQueue queue;
    vkGetDeviceQueue(device, familyIndex, 0, &queue);

    VkSurfaceCapabilitiesKHR caps;
    vkGetPhysicalDeviceSurfaceCapabilitiesKHR(phys, surfaceKHR, &caps);

    uint32_t fmtCount = 0;
    vkGetPhysicalDeviceSurfaceFormatsKHR(phys, surfaceKHR, &fmtCount, NULL);
    if (fmtCount == 0) fail("No surface formats");
    VkSurfaceFormatKHR* fmts = (VkSurfaceFormatKHR*)malloc(sizeof(VkSurfaceFormatKHR)*fmtCount);
    vkGetPhysicalDeviceSurfaceFormatsKHR(phys, surfaceKHR, &fmtCount, fmts);
    VkSurfaceFormatKHR surfFormat = fmts[0];
    free(fmts);

    VkExtent2D extent = caps.currentExtent.width != UINT32_MAX ? caps.currentExtent : VkExtent2D{(uint32_t)width,(uint32_t)height};

    VkSwapchainCreateInfoKHR scInfo{};
    scInfo.sType = VK_STRUCTURE_TYPE_SWAPCHAIN_CREATE_INFO_KHR;
    scInfo.pNext = nullptr;
    scInfo.surface = surfaceKHR;
    scInfo.minImageCount = (caps.minImageCount + 1 <= caps.maxImageCount || caps.maxImageCount == 0) ? caps.minImageCount + 1 : caps.minImageCount;
    scInfo.imageFormat = surfFormat.format;
    scInfo.imageColorSpace = surfFormat.colorSpace;
    scInfo.imageExtent = extent;
    scInfo.imageArrayLayers = 1;
    scInfo.imageUsage = VK_IMAGE_USAGE_COLOR_ATTACHMENT_BIT | VK_IMAGE_USAGE_TRANSFER_DST_BIT;
    scInfo.imageSharingMode = VK_SHARING_MODE_EXCLUSIVE;
    scInfo.preTransform = caps.currentTransform;
    scInfo.compositeAlpha = VK_COMPOSITE_ALPHA_OPAQUE_BIT_KHR;
    scInfo.presentMode = VK_PRESENT_MODE_FIFO_KHR;
    scInfo.clipped = VK_TRUE;

    VkSwapchainKHR swapchain;
    vkres = vkCreateSwapchainKHR(device, &scInfo, NULL, &swapchain);
    if (vkres != VK_SUCCESS) fail("vkCreateSwapchainKHR failed");

    uint32_t imgCount = 0;
    vkGetSwapchainImagesKHR(device, swapchain, &imgCount, NULL);
    VkImage* images = (VkImage*)malloc(sizeof(VkImage)*imgCount);
    vkGetSwapchainImagesKHR(device, swapchain, &imgCount, images);

    VkCommandPoolCreateInfo cpci{};
    cpci.sType = VK_STRUCTURE_TYPE_COMMAND_POOL_CREATE_INFO;
    cpci.pNext = nullptr;
    cpci.queueFamilyIndex = familyIndex;
    cpci.flags = VK_COMMAND_POOL_CREATE_RESET_COMMAND_BUFFER_BIT;

    VkCommandPool cmdPool;
    vkres = vkCreateCommandPool(device, &cpci, NULL, &cmdPool);
    if (vkres != VK_SUCCESS) fail("vkCreateCommandPool failed");

    VkCommandBufferAllocateInfo cbai{};
    cbai.sType = VK_STRUCTURE_TYPE_COMMAND_BUFFER_ALLOCATE_INFO;
    cbai.pNext = nullptr;
    cbai.commandPool = cmdPool;
    cbai.level = VK_COMMAND_BUFFER_LEVEL_PRIMARY;
    cbai.commandBufferCount = 1;

    VkCommandBuffer cmdBuf;
    vkres = vkAllocateCommandBuffers(device, &cbai, &cmdBuf);
    if (vkres != VK_SUCCESS) fail("vkAllocateCommandBuffers failed");

    VkFenceCreateInfo fci{};
    fci.sType = VK_STRUCTURE_TYPE_FENCE_CREATE_INFO;
    fci.pNext = nullptr;

    VkFence fence;
    vkCreateFence(device, &fci, NULL, &fence);

    VkSemaphoreCreateInfo sci{};
    sci.sType = VK_STRUCTURE_TYPE_SEMAPHORE_CREATE_INFO;
    sci.pNext = nullptr;

    VkSemaphore imageAvail, renderDone;
    vkCreateSemaphore(device, &sci, NULL, &imageAvail);
    vkCreateSemaphore(device, &sci, NULL, &renderDone);

    uint32_t imgIndex = 0;
    vkAcquireNextImageKHR(device, swapchain, UINT64_MAX, imageAvail, VK_NULL_HANDLE, &imgIndex);

    VkCommandBufferBeginInfo cbbi{};
    cbbi.sType = VK_STRUCTURE_TYPE_COMMAND_BUFFER_BEGIN_INFO;
    cbbi.pNext = nullptr;

    vkBeginCommandBuffer(cmdBuf, &cbbi);

    VkImageMemoryBarrier barrier{};
    barrier.sType = VK_STRUCTURE_TYPE_IMAGE_MEMORY_BARRIER;
    barrier.pNext = nullptr;
    barrier.oldLayout = VK_IMAGE_LAYOUT_UNDEFINED;
    barrier.newLayout = VK_IMAGE_LAYOUT_TRANSFER_DST_OPTIMAL;
    barrier.srcQueueFamilyIndex = VK_QUEUE_FAMILY_IGNORED;
    barrier.dstQueueFamilyIndex = VK_QUEUE_FAMILY_IGNORED;
    barrier.image = images[imgIndex];
    barrier.subresourceRange.aspectMask = VK_IMAGE_ASPECT_COLOR_BIT;
    barrier.subresourceRange.baseMipLevel = 0;
    barrier.subresourceRange.levelCount = 1;
    barrier.subresourceRange.baseArrayLayer = 0;
    barrier.subresourceRange.layerCount = 1;
    barrier.srcAccessMask = 0;
    barrier.dstAccessMask = VK_ACCESS_TRANSFER_WRITE_BIT;

    vkCmdPipelineBarrier(cmdBuf,
                         VK_PIPELINE_STAGE_TOP_OF_PIPE_BIT, VK_PIPELINE_STAGE_TRANSFER_BIT,
                         0, 0, NULL, 0, NULL, 1, &barrier);

    VkClearColorValue clearColor = {{1.0f, 0.0f, 0.0f, 1.0f}};
    VkImageSubresourceRange range = barrier.subresourceRange;
    vkCmdClearColorImage(cmdBuf, images[imgIndex], VK_IMAGE_LAYOUT_TRANSFER_DST_OPTIMAL, &clearColor, 1, &range);

    barrier.oldLayout = VK_IMAGE_LAYOUT_TRANSFER_DST_OPTIMAL;
    barrier.newLayout = VK_IMAGE_LAYOUT_PRESENT_SRC_KHR;
    barrier.srcAccessMask = VK_ACCESS_TRANSFER_WRITE_BIT;
    barrier.dstAccessMask = 0;

    vkCmdPipelineBarrier(cmdBuf,
                         VK_PIPELINE_STAGE_TRANSFER_BIT, VK_PIPELINE_STAGE_BOTTOM_OF_PIPE_BIT,
                         0, 0, NULL, 0, NULL, 1, &barrier);

    vkEndCommandBuffer(cmdBuf);

    VkPipelineStageFlags waitStages[] = { VK_PIPELINE_STAGE_TRANSFER_BIT };
    VkSubmitInfo submit{};
    submit.sType = VK_STRUCTURE_TYPE_SUBMIT_INFO;
    submit.pNext = nullptr;
    submit.waitSemaphoreCount = 1;
    submit.pWaitSemaphores = &imageAvail;
    submit.pWaitDstStageMask = waitStages;
    submit.commandBufferCount = 1;
    submit.pCommandBuffers = &cmdBuf;
    submit.signalSemaphoreCount = 1;
    submit.pSignalSemaphores = &renderDone;

    vkQueueSubmit(queue, 1, &submit, fence);
    vkWaitForFences(device, 1, &fence, VK_TRUE, UINT64_MAX);
    vkResetFences(device, 1, &fence);

    VkPresentInfoKHR pres{};
    pres.sType = VK_STRUCTURE_TYPE_PRESENT_INFO_KHR;
    pres.pNext = nullptr;
    pres.waitSemaphoreCount = 1;
    pres.pWaitSemaphores = &renderDone;
    pres.swapchainCount = 1;
    pres.pSwapchains = &swapchain;
    pres.pImageIndices = &imgIndex;

    vkQueuePresentKHR(queue, &pres);

    sleep(5);

    vkDeviceWaitIdle(device);
    vkDestroySemaphore(device, renderDone, NULL);
    vkDestroySemaphore(device, imageAvail, NULL);
    vkDestroyFence(device, fence, NULL);
    vkFreeCommandBuffers(device, cmdPool, 1, &cmdBuf);
    vkDestroyCommandPool(device, cmdPool, NULL);
    free(images);
    vkDestroySwapchainKHR(device, swapchain, NULL);
    vkDestroyDevice(device, NULL);
    vkDestroySurfaceKHR(instance, surfaceKHR, NULL);
    vkDestroyInstance(instance, NULL);

    SurfaceComposerClient::Transaction cleanup;
    cleanup.hide(sc);
    cleanup.reparent(sc, nullptr);
    cleanup.apply();

    return 0;
}
