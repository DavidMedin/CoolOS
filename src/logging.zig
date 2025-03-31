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
        y_scroll_at : usize,
        cursor : [2]usize,
        buffer : [width*height]u8 = [_]u8{0} ** (width*height), // Only 1 byte per character :( [likely only ascii]
        const Self = @This();
        pub fn new(y_scroll_at : usize) Self{
            return .{
                .scroll = 0,
                .cursor = [2]usize{0,0},
                .y_scroll_at = y_scroll_at,
            };
        }
        pub inline fn get_cursor_token(self : *Self) usize {
            // TODO: Debug assert that cursor is in-bounds.
            return Self.get_token(self.cursor[0], self.cursor[1]);
        }
        pub inline fn get_token(x : usize, y : usize) usize {
            // TODO: Debug assert that [x,y] is in-bounds.
            const new_y = y * width;
            const new_x = x;
            const byte_offset = new_y + new_x;
            return byte_offset;
        }
        pub fn newline(self : *Self) void {
            self.cursor[0] = 0;
            self.cursor[1] += 1;
            if ( self.cursor[1]+self.scroll > self.y_scroll_at ){
                self.scroll += 1;
            }
        }
        pub fn add_log(self : *Self, log : []u8) void {
            var cursor : usize = self.get_cursor_token();

            for (log) |char| {
                if (char == 10) { // is a newline.
                    self.newline();
                    cursor = self.get_cursor_token();
                }else { // not a newline.
                    self.buffer[cursor] = char;
                    self.cursor[0] += 1;
                    cursor += 1; // this is what get_cursor_token() would effectivly yield.
                }
            }
        }
        pub fn render_buffer(self : *Self) void {
            render.reset_render_cursor();
            render.clear_screen();
            for (self.scroll..self.cursor[1]+1) |line_index| {
                if(self.cursor[0] == 0 and line_index == self.cursor[1]) continue; // Don't render the most recent line if there isn't anything to render :)
                const cursor = Self.get_token(0, line_index);
                const line : []u8 = self.buffer[cursor..cursor + self.width];

                var line_cursor : []u8 = line;

                while (render.render_char_from_string(line_cursor)) |new_cursor| {
                   line_cursor = new_cursor;
                }
                render.newline();

            }
        }
    };
}

// TODO: No more global prints!
// [67,57]
pub var global_print_buffer = TextBuffer(1000,1000).new(57);

// Defines how std.log.error, std.log.debug, and friends function.
// In the Cool OS kernel code, it should only be referenced by std_options in main.zig.
pub fn kernel_log_fn(comptime level: std.log.Level, comptime scope: @TypeOf(.EnumLiteral), comptime format: []const u8, args: anytype) void {
    _ = scope;

    const prefix = "[" ++ comptime level.asText() ++ "] ";
    // const buffer_cursor : []u8 = global_print_buffer.get_cursor();
    const fmt_string: []u8 = std.fmt.bufPrint(&print_buffer, prefix ++ format, args) catch unreachable;
    print_buffer[fmt_string.len] = '\n';
    print_buffer[fmt_string.len+1] = 0;
    const adjusted_fmt_string : []u8 = print_buffer[0..fmt_string.len+1];

    global_print_buffer.add_log(adjusted_fmt_string);

    global_print_buffer.render_buffer();
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
