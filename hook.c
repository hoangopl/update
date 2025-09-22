#include <linux/bpf.h>
#include <bpf/bpf_helpers.h>
#include <bpf/bpf_tracing.h>

// Định nghĩa struct cho arg Vector3 (giả sử float x,y,z)
struct vector3 {
    float x;
    float y;
    float z;
};

// Map để lưu data (optional, ví dụ hash map cho count calls)
struct {
    __uint(type, BPF_MAP_TYPE_HASH);
    __uint(max_entries, 1024);
    __type(key, u32);   // PID or something
    __type(value, u64); // Call count
} call_count SEC(".maps");

// Uprobe attach vào entry của function (WorldToScreenPoint)
SEC("uprobe/com.dts.freefireth:libil2cpp.so:0x77ea99ea30")
int BPF_KPROBE(world_to_screen_entry, struct vector3 *position) {
    u32 pid = bpf_get_current_pid_tgid() >> 32;
    u64 *count = bpf_map_lookup_elem(&call_count, &pid);
    if (count) {
        (*count)++;
    } else {
        u64 zero = 0;
        bpf_map_update_elem(&call_count, &pid, &zero, BPF_ANY);
    }

    // Log arg (position) - dùng bpf_printk hoặc perf_event_output cho output
    bpf_printk("Hook entry: PID %d, pos x=%f y=%f z=%f\n",
               pid, position->x, position->y, position->z);

    return 0;
}

// Uretprobe attach vào return của function
SEC("uretprobe/com.dts.freefireth:libil2cpp.so:0x77ea99ea30")
int BPF_KRETPROBE(world_to_screen_ret, struct vector3 *retval) {
    u32 pid = bpf_get_current_pid_tgid() >> 32;
    u64 *count = bpf_map_lookup_elem(&call_count, &pid);
    if (count) {
        (*count)++;
    }

    // Log retval (giả sử return Vector3)
    bpf_printk("Hook return: PID %d, ret x=%f y=%f z=%f\n",
               pid, retval->x, retval->y, retval->z);

    return 0;
}

char _license[] SEC("license") = "GPL";
