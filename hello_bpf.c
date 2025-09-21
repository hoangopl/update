#include <bpf/libbpf.h>
#include <stdio.h>

int main() {
    printf("libbpf version: %s\n", libbpf_version_string());
    return 0;
}
