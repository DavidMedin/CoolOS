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