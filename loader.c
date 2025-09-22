#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <dirent.h>
#include <fcntl.h>
#include <bpf/libbpf.h>
#include <bpf/bpf.h>
#include <linux/bpf.h>
#include <errno.h>

// Hàm tìm PID của package com.dts.freefireth
static int find_pid_by_package(const char *package_name) {
    DIR *dir = opendir("/proc");
    if (!dir) {
        perror("opendir /proc");
        return -1;
    }

    struct dirent *entry;
    while ((entry = readdir(dir))) {
        if (entry->d_type != DT_DIR)
            continue;

        int pid = atoi(entry->d_name);
        if (pid <= 0)
            continue;

        char cmdline_path[256];
        snprintf(cmdline_path, sizeof(cmdline_path), "/proc/%d/cmdline", pid);
        FILE *cmdline = fopen(cmdline_path, "r");
        if (!cmdline)
            continue;

        char cmd[256];
        if (fgets(cmd, sizeof(cmd), cmdline) && strstr(cmd, package_name)) {
            fclose(cmdline);
            closedir(dir);
            return pid;
        }
        fclose(cmdline);
    }
    closedir(dir);
    return -1;
}

int main(int argc, char **argv) {
    const char *package_name = "com.dts.freefireth";
    const char *bpf_obj_path = "hook.o";
    const char *lib_path = "libil2cpp.so";
    const char *uprobe_name = "world_to_screen_entry";
    const char *uretprobe_name = "world_to_screen_ret";
    const unsigned long rva = 0x77ea99ea30; // RVA từ yêu cầu

    // Tìm PID của Free Fire
    int pid = find_pid_by_package(package_name);
    if (pid < 0) {
        fprintf(stderr, "Không tìm thấy process %s\n", package_name);
        return 1;
    }
    printf("Tìm thấy PID %d cho package %s\n", pid, package_name);

    // Khởi tạo libbpf
    struct bpf_object *obj;
    struct bpf_program *prog;
    struct bpf_link *link_uprobe = NULL, *link_uretprobe = NULL;
    int err;

    // Load BPF object file
    obj = bpf_object__open_file(bpf_obj_path, NULL);
    if (libbpf_get_error(obj)) {
        fprintf(stderr, "Lỗi khi mở BPF object %s: %s\n", bpf_obj_path, strerror(errno));
        return 1;
    }

    // Load BPF program vào kernel
    err = bpf_object__load(obj);
    if (err) {
        fprintf(stderr, "Lỗi khi load BPF object: %s\n", strerror(errno));
        bpf_object__close(obj);
        return 1;
    }

    // Tìm uprobe program
    prog = bpf_object__find_program_by_name(obj, uprobe_name);
    if (!prog) {
        fprintf(stderr, "Không tìm thấy uprobe program %s\n", uprobe_name);
        bpf_object__close(obj);
        return 1;
    }

    // Attach uprobe
    link_uprobe = bpf_program__attach_uprobe(prog, false, pid, lib_path, rva);
    if (libbpf_get_error(link_uprobe)) {
        fprintf(stderr, "Lỗi khi attach uprobe: %s\n", strerror(errno));
        bpf_object__close(obj);
        return 1;
    }
    printf("Attached uprobe thành công\n");

    // Tìm uretprobe program
    prog = bpf_object__find_program_by_name(obj, uretprobe_name);
    if (!prog) {
        fprintf(stderr, "Không tìm thấy uretprobe program %s\n", uretprobe_name);
        bpf_object__close(obj);
        return 1;
    }

    // Attach uretprobe
    link_uretprobe = bpf_program__attach_uprobe(prog, true, pid, lib_path, rva);
    if (libbpf_get_error(link_uretprobe)) {
        fprintf(stderr, "Lỗi khi attach uretprobe: %s\n", strerror(errno));
        bpf_link__destroy(link_uprobe);
        bpf_object__close(obj);
        return 1;
    }
    printf("Attached uretprobe thành công\n");

    // Vòng lặp để giữ loader chạy (log xem ở dmesg)
    printf("Đang hook WorldToScreenPoint... Ctrl+C để dừng\n");
    while (1) {
        sleep(1);
    }

    // Cleanup (không chạy tới đây nếu vòng lặp vô hạn)
    bpf_link__destroy(link_uprobe);
    bpf_link__destroy(link_uretprobe);
    bpf_object__close(obj);
    return 0;
}
