#include <linux/module.h>
#include <linux/kernel.h>

static int __init hello_init(void) {
    printk(KERN_INFO "Hello LKM!\n");
    return 0;
}

static void __exit hello_exit(void) {
    printk(KERN_INFO "Bye LKM!\n");
}

module_init(hello_init);
module_exit(hello_exit);

MODULE_LICENSE("GPL");
MODULE_AUTHOR("You");
MODULE_DESCRIPTION("Simple Hello LKM");
