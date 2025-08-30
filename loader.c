#include <bpf/libbpf.h>
#include <stdio.h>
#include <unistd.h>

int main() {
    struct bpf_object *obj;
    int err;

    // load object file
    obj = bpf_object__open_file("/system/etc/ebpf_prog_execve.o", NULL);
    if (!obj) {
        fprintf(stderr, "Failed to open eBPF object\n");
        return 1;
    }

    err = bpf_object__load(obj);
    if (err) {
        fprintf(stderr, "Failed to load eBPF object: %d\n", err);
        return 1;
    }

    printf("eBPF program loaded!\n");
    pause(); // giữ process sống
    return 0;
}
