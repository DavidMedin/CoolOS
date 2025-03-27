const std = @import("std");
const pretty = @import("pretty");
const render = @import("render.zig");

// Formatting and std.log logging.

var print_buffer = [_]u8{0} ** 0x10000;

// TODO: When needed, you can create a new TextBuffer 'window' that will render in a different part of the screen.
// By default there will be a 'fullscreen' one that everything dumps into.
// 'std.log.info' will print into that text buffer, storing it.
//   It will then cause a render of the text buffer onto the screen.
// This allows for non-destructive scrolling of text on the screen.

// This allocator uses the print_buffer too.
var GLOBAL_FBA : ?std.heap.FixedBufferAllocator = null;
pub var GLOBAL_ALLOCATOR: ?std.mem.Allocator = null;

/// A screen text buffer of a fixed (compile-time) height and width.
/// In the future, this should be runtime (not a parameter of the type).
/// Runtime known-height will require a memory allocation strategy.
pub fn TextBuffer(width : usize, height : usize) type {
    return struct {
        width : usize = width,
        height : usize = height,
        scroll : usize, // the index of the first line to be rendered.
        cursor : [2]usize,
        buffer : [width*height]u8, // Only 1 byte per character :( [likely only ascii]
        const Self = @This();
        pub fn new() Self{
            return .{
                .scroll = 0,
                .cursor = [2]u8{0,0},
            };
        }
        pub fn get_cursor(self : *Self) []u8 {
            // TODO: Debug assert that cursor is in-bounds.
            const y = self.*.cursor[1] * width;
            const x = self.*.cursor[0];
            const byte_offset = y + x;
            return self.*.buffer[byte_offset..];
        }
    };
}

// TODO: No more global prints!
pub const global_print_buffer = TextBuffer(1000,1000).new();

// Defines how std.log.error, std.log.debug, and friends function.
// In the Cool OS kernel code, it should only be referenced by std_options in main.zig.
pub fn kernel_log_fn(comptime level: std.log.Level, comptime scope: @TypeOf(.EnumLiteral), comptime format: []const u8, args: anytype) void {
    _ = scope;

    const prefix = "[" ++ comptime level.asText() ++ "] ";
    const buffer_cursor : []u8 = global_print_buffer.get_cursor();
    const fmt_string: []u8 = std.fmt.bufPrint(buffer_cursor, prefix ++ format, args) catch unreachable;
    // print_buffer[fmt_string.len] = 0;

    // render.render_scroll(fmt_string);
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
