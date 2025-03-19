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
const ps2 = @import("ps2-keyboard.zig");

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
    std.log.info("ps2 data vvvv", .{});

    while(true) {
        if( ps2.ps2_poll() ) |data| {
            std.log.info("{}", .{data});
        }

    }


}
