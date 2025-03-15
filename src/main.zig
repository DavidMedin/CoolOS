// multiboot 2 : https://www.gnu.org/software/grub/manual/multiboot2/multiboot.html

// Zig things:
// https://wiki.osdev.org/Zig_Bare_Bones

// Screen things.
// fonts : https://wiki.osdev.org/Scalable_Screen_Font
// https://wiki.osdev.org/Scalable_Screen_Font
// https://gitlab.com/bztsrc/scalable-font2

// File format : https://gitlab.com/bztsrc/scalable-font2/blob/master/docs/sfn_format.md
// Renderer API : https://gitlab.com/bztsrc/scalable-font2/blob/master/docs/API.md

// OSDEV forum about this : https://forum.osdev.org/viewtopic.php?f=2&t=33719

// https://github.com/cfenollosa/os-tutorial
const std = @import("std");
const text = @import("text.zig");
const multiboot = @import("multiboot.zig");
const pci = @import("pci.zig");

// Defines what happens when Zig panics.
// Panics happen when @panic() is 'called' or when the 'unreachable' keyword is reached.
// It just set a breakpoint so a debugger can look at the stacktrace.
pub fn panic(msg: []const u8, error_return_trace: ?*std.builtin.StackTrace, something : ?usize) noreturn {
    _ = msg;
    _ = error_return_trace;
    _ = something;
    while(true) {
        @breakpoint();
    }
}


// Tells the Zig Standard Library that std.log.[debug, err, info,...] should use kernel_log_fn for printing.
// It has to be in main.zig :(
pub const std_options : std.Options = .{
    .logFn = text.kernel_log_fn
};

export var base_address : u32 = 0; // bad.

// Called from boot.asm
pub export fn kernel_main(mbi : *multiboot.MBI) callconv(.C) void {

    // Parse the multiboot information.
    // Specifically, the framebuffer. Or die if it doesn't work.
    multiboot.parse_multiboot_info(mbi) catch unreachable;

    text.init_printing();

    // Write to the screen!
    std.log.debug("Hello!", .{});
    std.log.err("Has something gone bad? Who knows?",.{});

    for ( @as(u4,0) ..std.math.maxInt(u4)) |device_off_usize| {
        const device_off : u4 = @truncate(device_off_usize);
        const pci_id = pci.PciId{.pci_bus = 0, .pci_device = device_off};

        if (pci_id.get_info()) |pci_dev| {

            if( text.format_object(pci_dev) ) |fmtd| {
                defer text.GLOBAL_ALLOCATOR.?.free(fmtd);
                std.log.debug("PCI Device 0x{x} : {s}", .{device_off, fmtd});
            } else |err| {
                std.log.err("PCI Device 0x{x} : Failed to format string: {}", .{device_off, err});
            }

        }else{
            std.log.warn("PCI Device 0x{x} is not a device.", .{device_off});
        }
    }

//     while(true) {
//         @breakpoint();
//     }
}
