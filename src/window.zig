const std = @import("std");
const pretty = @import("pretty");
const render = @import("render.zig");

pub const FrameBuffer = struct {
    buffer : []u8,
    pitch : u32,
    width : u32,
    height : u32
};

pub const WindowConfig = struct {
    border_width : u8 = 1
};

pub fn Window(width : u32, height : u32) type { // TODO: make this dynamically size (not a fn{struct} )
    return struct {
        const BUFF_SIZE : usize = width*height*3;

        title : []const u8,
        pos_px : [2]u32,
        size_px : [2]u32 = [_]u32{width,height},
        config : WindowConfig,
        pixel_buff : [BUFF_SIZE]u8 = [_]u8{0} ** BUFF_SIZE,

        const Self = @This();

        pub fn new(pos_px : [2]u32, title : []const u8, config : WindowConfig) Self {
            return Self {
                .title = title,
                .pos_px = pos_px,
                .config = config
            };
        }

    };
}
