#include <linux/bpf.h>
#include <sys/syscall.h>
#include <unistd.h>
#include <fcntl.h>
#include <stdio.h>
#include <string.h>
#include <errno.h>

#define BPF_OBJ_FILE "/data/local/tmp/ebpf_prog_execve.o"

int main() {
    int fd = open(BPF_OBJ_FILE, O_RDONLY);
    if (fd < 0) {
        perror("open");
        return 1;
    }

    char buf[4096];
    ssize_t n = read(fd, buf, sizeof(buf));
    if (n <= 0) {
        perror("read");
        return 1;
    }

    struct bpf_attr attr;
    memset(&attr, 0, sizeof(attr));
    attr.prog_type = BPF_PROG_TYPE_TRACEPOINT;
    attr.insns = (uintptr_t)buf; // chỉ ví dụ, thực tế cần load ELF và parse section
    attr.insn_cnt = n / sizeof(struct bpf_insn);
    attr.license = (uintptr_t)"GPL";

    int prog_fd = syscall(__NR_bpf, BPF_PROG_LOAD, &attr, sizeof(attr));
    if (prog_fd < 0) {
        perror("bpf prog load");
        return 1;
    }

    printf("eBPF program loaded, fd=%d\n", prog_fd);
    sleep(999999);
    return 0;
}
