#include <stdio.h>
#include <bpf/libbpf.h>
#include <unistd.h>

int main() {
    struct bpf_object *obj;
    int prog_fd;

    // mở file prog.o (build từ prog.c)
    obj = bpf_object__open_file("/system/etc/bpf/prog.o", NULL);
    if (!obj) {
        perror("bpf_object__open_file");
        return 1;
    }

    if (bpf_object__load(obj)) {
        perror("bpf_object__load");
        return 1;
    }

    // lấy fd của program đầu tiên
    struct bpf_program *prog = bpf_object__next_program(obj, NULL);
    prog_fd = bpf_program__fd(prog);

    if (prog_fd < 0) {
        fprintf(stderr, "failed to get bpf program fd\n");
        return 1;
    }

    printf("eBPF program loaded, fd=%d\n", prog_fd);

    // giữ cho chương trình chạy để trace
    while (1) {
        sleep(5);
    }
    return 0;
}
