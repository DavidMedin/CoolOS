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


pub fn panic(msg: []const u8, error_return_trace: ?*std.builtin.StackTrace, something : ?usize) noreturn {
    _ = msg;
    _ = error_return_trace;
    _ = something;
    while(true) {
        @breakpoint();
    }
}

var print_buffer = [_]u8{0} ** 4096;
// Defines how std.log.error, std.log.debug, and friends function.
fn kernelLogFn(comptime level: std.log.Level, comptime scope: @TypeOf(.EnumLiteral), comptime format: []const u8, args: anytype) void {
        _ = scope;

        const prefix = "[" ++ comptime level.asText() ++ "] ";
        const fmt_string: []u8 = std.fmt.bufPrint(&print_buffer, prefix ++ format, args) catch unreachable;
        //const render_string  = "hello";
        var cursor : *u8 = @ptrCast( @constCast( fmt_string ) );
        while( cursor.* != 0) {
            const codepoint = text.ssfn_utf8(@ptrCast( &cursor ));

            // If newline
            if(codepoint == 10) {

                text.ssfn_dst.y += text.ssfn_src.*.height; // Move one line down, (new line)
                text.ssfn_dst.x = 0; // and reset to left side of screen (carrige return)

            }else {

                const result : i32 = text.ssfn_putc( codepoint );
                if(result != 0){
                    //https://gitlab.com/bztsrc/scalable-font2/blob/master/docs/API.md#error-codes
                    @panic("fonts are bad. I am good at errors.");
                }

            }
        }
        text.ssfn_dst.y += text.ssfn_src.*.height; // Move one line down, (new line)
        text.ssfn_dst.x = 0; // and reset to left side of screen (carrige return)
    }
pub const std_options : std.Options = .{
    .logFn = kernelLogFn
};

export var base_address : u32 = 0; // bad.

pub extern fn in_fn(port : u16) u32;
pub extern fn out_fn(port : u16, data : u32) void;

pub fn pci_config_read(bus : u8, device : u4, func : u3, register_offset : u8) u16 {
    const reserved_and_enable : u32 = 0x80000000;
    //                                         v------ 2 least significant bits of register offset are 0.
    const address : u32 = (register_offset & 0xFC) | (func << 8) | (device << 11) | (bus << 16) | reserved_and_enable;

    out_fn(0xCF8, address);

    const recv : u32 = in_fn(0xCFC);
    return recv >> ((register_offset & 2) * 8) & 0xFFFF;
}

pub export fn kernel_main(mbi : *multiboot.MBI) callconv(.C) void {
    
    // Parse the multiboot information.
    // Specifically, the framebuffer. Or die if it doesn't work.
    multiboot.parse_multiboot_info(mbi) catch unreachable;
    
    // Write to the screen!
    std.log.debug("hello!", .{});
    std.log.err("Has something gone bad? Who knows?\n",.{});
    
//     while(true) {
//         @breakpoint();
//     }
}
