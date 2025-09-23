// hello.c - minimal safe test LKM
#include <linux/init.h>
#include <linux/module.h>
#include <linux/kernel.h>
#include <linux/utsname.h>

static int __init hello_init(void)
{
    struct new_utsname *u = utsname();
    pr_info("hello_lkm: loaded on kernel %s\n", u->release);
    pr_info("hello_lkm: build_user: %s\n", u->version);
    return 0;
}

static void __exit hello_exit(void)
{
    pr_info("hello_lkm: unloaded\n");
}

module_init(hello_init);
module_exit(hello_exit);

MODULE_LICENSE("GPL");
MODULE_AUTHOR("Hoang");
MODULE_DESCRIPTION("Simple Hello LKM for testing");
