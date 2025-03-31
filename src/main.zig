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
const logging = @import("logging.zig");
const render = @import("render.zig");
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
    .logFn = logging.kernel_log_fn,
    .log_scope_levels = &[_]std.log.ScopeLevel{
        .{ .scope = .default, .level = .debug }, // Should be the zig provided scope.
        // .{ .scope = .pci, .level = .pci }, // as an example (prob not actually used.)
    }
};

export var base_address : u32 = 0; // bad.

// Called from boot.asm
pub export fn kernel_main(mbi : *multiboot.MBI) callconv(.C) void {

    // Parse the multiboot information.
    // Specifically, the framebuffer. Or die if it doesn't work.
    multiboot.parse_multiboot_info(mbi) catch unreachable;

    logging.init_printing();
    // const framebuffer_size = render.get_framebuffer_dims();
    // const glyph_size = render.get_glyph_dims();
    // std.log.info("Framebuffer size : {}x{}",.{framebuffer_size[0]/glyph_size[0], framebuffer_size[1]/glyph_size[1]});

    // Write to the screen!
    // std.log.debug("Hello!", .{});
    // std.log.err("Has something gone bad? Who knows?",.{});

    for (0..101) |i| {
        std.log.info("line : {} ({})", .{i, logging.global_print_buffer.scroll});
    }

    keyboard_input_task();


}

fn keyboard_input_task() noreturn {
    var keyboard : *ps2.PS2Controller = ps2.init();
    // TODO: PS2 interrupts.
    while(true) {

        const poll_res = keyboard.poll() catch {
            std.log.warn("wack",.{});
            continue;
        };

        if(poll_res) |keycode| {
            // There was something available this loop!
            switch(keycode) {
                .Unicode => |code| {
                        // const cursor = logging.render_char_from_string(@constCast(code));
                        // if(cursor != null) {
                        //     @panic("Cursor was not null. tried printing more than one character?");
                        // }
                        logging.global_print_buffer.add_log(@constCast(code));
                        logging.global_print_buffer.render_buffer();
                },
                .RawKey => |key| {
                    std.log.info("{} was pressed!", .{key});
                }
            }
        }
    }
}
