#include <stdio.h>
#include <unistd.h>
#include <fcntl.h>
#include <string.h>
#include <errno.h>
#include <linux/bpf.h>
#include <sys/syscall.h>

#define BPF_OBJ_FILE "/data/local/tmp/ebpf_prog_execve.o"

// Helper syscall
static int bpf_syscall(int cmd, union bpf_attr *attr, unsigned int size) {
    return syscall(__NR_bpf, cmd, attr, size);
}

int main() {
    // Mở file eBPF .o
    int fd = open(BPF_OBJ_FILE, O_RDONLY);
    if (fd < 0) {
        perror("open");
        return 1;
    }

    // Đọc file vào bộ nhớ
    char buf[65536];
    ssize_t n = read(fd, buf, sizeof(buf));
    if (n <= 0) {
        perror("read");
        close(fd);
        return 1;
    }
    close(fd);

    // Chuẩn bị bpf_attr (union)
    union bpf_attr attr;
    memset(&attr, 0, sizeof(attr));
    attr.prog_type = BPF_PROG_TYPE_TRACEPOINT;
    attr.insns = (uintptr_t)buf;  // demo, thực tế cần parse ELF
    attr.insn_cnt = n / sizeof(struct bpf_insn);
    attr.license = (uintptr_t)"GPL";

    int prog_fd = bpf_syscall(BPF_PROG_LOAD, &attr, sizeof(attr));
    if (prog_fd < 0) {
        perror("BPF_PROG_LOAD failed");
        return 1;
    }

    printf("✅ eBPF program loaded, fd=%d\n", prog_fd);

    // Giữ loader chạy để tracepoint ghi log
    while (1) sleep(5);

    return 0;
}
