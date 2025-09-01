#include <binder/ProcessState.h>
#include <gui/SurfaceComposerClient.h>
#include <android/native_window.h>
#include <sched.h>
#include <fcntl.h>
#include <unistd.h>
#include <stdio.h>
#include <stdlib.h>

using namespace android;

int join_ipc_ns(pid_t target_pid) {
    char path[128];
    snprintf(path, sizeof(path), "/proc/%d/ns/ipc", target_pid);
    int fd = open(path, O_RDONLY);
    if (fd == -1) {
        perror("open ns/ipc");
        return -1;
    }
    if (setns(fd, 0) == -1) {
        perror("setns");
        close(fd);
        return -1;
    }
    close(fd);
    return 0;
}

int main() {
    // join IPC namespace của system_server
    pid_t sys_pid = system("pidof system_server > /tmp/sys_pid.txt");
    FILE *fp = fopen("/tmp/sys_pid.txt", "r");
    if (!fp) {
        perror("pidof system_server");
        return 1;
    }
    int pid;
    fscanf(fp, "%d", &pid);
    fclose(fp);

    if (join_ipc_ns(pid) != 0) {
        fprintf(stderr, "❌ Failed to join IPC namespace\n");
        return 1;
    }
    printf("✅ Đã join IPC namespace của system_server (pid=%d)\n", pid);

    // bắt đầu binder thread pool (quan trọng cho SurfaceComposerClient)
    sp<ProcessState> proc(ProcessState::self());
    proc->startThreadPool();

    // tạo SurfaceComposerClient
    sp<SurfaceComposerClient> client = new SurfaceComposerClient();
    if (client->initCheck() != NO_ERROR) {
        fprintf(stderr, "❌ Failed to create SurfaceComposerClient\n");
        return 1;
    }

    printf("✅ SurfaceComposerClient created thành công!\n");

    return 0;
}
