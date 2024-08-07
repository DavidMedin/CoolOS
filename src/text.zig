const std = @import("std");
const pretty = @import("pretty");

// Rendering to the screen.

pub const ssfn = @cImport({
    @cDefine("SSFN_MAXLINES", "4096");
    //SSFN_CONSOLEBITMAP_PALETTE
    @cDefine("SSFN_CONSOLEBITMAP_TRUECOLOR", {});
    @cDefine("NULL", "0"); // Never thought I'd have to do this for C.
    @cInclude("scalable-font2/ssfn.h");
});

// Allows 'text.ssfn_putc' in other files, instead of `text.ssfn.ssfn_putc'.
pub usingnamespace ssfn;

export var ssfn_src : *ssfn.ssfn_font_t = @ptrCast( @constCast( @embedFile("resources/fonts/lanapixel.sfn" ) ) );

// SFN Docs are wrong, ssfn_dist is a ssfn_buf_t, not a *ssfn_buf_t!
export var ssfn_dst : ssfn.ssfn_buf_t = undefined;

// The most basic text rendering strategy : write lines one after another and don't scroll.
fn render_fixed(string : []u8) void {
    var cursor : *u8 = @ptrCast( @constCast( string ) );
    while( cursor.* != 0 ) {
        const codepoint = ssfn.ssfn_utf8(@ptrCast( &cursor ));

        // If newline
        if(codepoint == 10) {

            ssfn_dst.y += ssfn_src.*.height; // Move one line down, (new line)
            ssfn_dst.x = 0; // and reset to left side of screen (carrige return)

        }else {

            const result : i32 = ssfn.ssfn_putc( codepoint );
            if(result != 0){
                //https://gitlab.com/bztsrc/scalable-font2/blob/master/docs/API.md#error-codes
                @panic("fonts are bad. I am good at errors.");
            }

        }
    }
    ssfn_dst.y += ssfn.ssfn_src.*.height; // Move one line down, (new line)
    ssfn_dst.x = 0; // and reset to left side of screen (carrige return)
}


// The next most obvious rendering strategy : when the text reaches the bottom of the screen, scroll.
// TODO: word wrapping.
// TODO: Consider when `string` is way bigger than the framebuffer.
fn render_scroll(string : []u8) void {
    // [1] Count the number of newlines.
    // TODO: Count the number of word wraps.
    const line_height_px = ssfn_src.*.height;
    const framebuffer_height_px = ssfn_dst.h * line_height_px;

    const lines_needed : u32 = blk: {
        var lines_needed : u32 = 0;
        var pixel_cursor_px = ssfn_dst.y;

        var cursor : *u8 = @ptrCast( @constCast( string ) );
        while( cursor.* != 0 ) {
            const codepoint = ssfn.ssfn_utf8(@ptrCast( &cursor )); // iterates the cursor.
            if ( codepoint == 10 ) {
                pixel_cursor_px += line_height_px;
                if ( ( pixel_cursor_px + line_height_px ) > framebuffer_height_px ) {
                    lines_needed += 1;
                }
            }
        }

        break :blk lines_needed;
    };

    // [2] Move the buffer up the neccessary number of newlines.
    {
        const framebuffer_length_bytes : usize =@intCast( ssfn_dst.p * ssfn_dst.h );
        const framebuffer_dst : []u8 = ssfn_dst.ptr[0..framebuffer_length_bytes];
        const framebuffer_src : []u8 = framebuffer_dst[(lines_needed * ssfn_dst.p)..];
        std.mem.copyBackwards(u8, framebuffer_dst, framebuffer_src);
    }

    ssfn_dst.y -= @intCast( lines_needed );

    render_fixed(string);
}

// Formatting and std.log logging.

var print_buffer = [_]u8{0} ** 0x1000;

// This allocator uses the print_buffer too.
var GLOBAL_FBA : ?std.heap.FixedBufferAllocator = null;
pub var GLOBAL_ALLOCATOR: ?std.mem.Allocator = null;

// Defines how std.log.error, std.log.debug, and friends function.
// In the Cool OS kernel code, it should only be referenced by std_options in main.zig.
pub fn kernel_log_fn(comptime level: std.log.Level, comptime scope: @TypeOf(.EnumLiteral), comptime format: []const u8, args: anytype) void {
        _ = scope;

        const prefix = "[" ++ comptime level.asText() ++ "] ";
        const fmt_string: []u8 = std.fmt.bufPrint(&print_buffer, prefix ++ format, args) catch unreachable;
        print_buffer[fmt_string.len] = 0;

        // render_fixed(fmt_string);
        render_scroll(fmt_string);
    }


// Takes any object and returns it formatted as a string.
// Just a simpler call to pretty.dump.
pub inline fn format_object(val : anytype) ![]u8 {
    return pretty.dump(GLOBAL_ALLOCATOR.?, val, .{} );
}

pub fn init_printing() void {
    // setup printing for the 'pretty' package. It needs a allocator.
    GLOBAL_FBA = std.heap.FixedBufferAllocator.init(&print_buffer);
    GLOBAL_ALLOCATOR = GLOBAL_FBA.?.allocator();
}
