const std = @import("std");

// Rendering text to the screen.

const ssfn = @cImport({
    @cDefine("SSFN_MAXLINES", "4096");
    //SSFN_CONSOLEBITMAP_PALETTE
    @cDefine("SSFN_CONSOLEBITMAP_TRUECOLOR", {});
    @cDefine("NULL", "0"); // Never thought I'd have to do this for C.
    @cInclude("scalable-font2/ssfn.h");
});

// Allows 'text.ssfn_putc' in other files, instead of `text.ssfn.ssfn_putc'.
// pub usingnamespace ssfn;

export var ssfn_src : *ssfn.ssfn_font_t = @ptrCast( @constCast( @embedFile("resources/fonts/lanapixel.sfn" ) ) );

/// SFN Docs are wrong, ssfn_dist is a ssfn_buf_t, not a *ssfn_buf_t!
export var ssfn_dst : ssfn.ssfn_buf_t = undefined;

pub const TextContext = struct {
    pixelbuffer : []u8,
    pitch : u32, // number of bytes per row
    width : u32,
    height : u32,
    fg_color : u32,
    bg_color : u32,
};
pub fn set_context(ctx : TextContext) void {
    ssfn_dst = .{
        .ptr = @ptrCast( ctx.pixelbuffer.ptr ),
        .p = @intCast( ctx.pitch ),
        .w = @intCast( ctx.width ),
        .h = @intCast( ctx.height ),
        .fg = @intCast( ctx.fg_color ),
        .bg = @intCast( ctx.bg_color ),
        .x = 0,
        .y = 0
    };
}

pub inline fn get_glyph_dims() [2]u32 {
    return [_]u32{@intCast(ssfn_src.width), @intCast(ssfn_src.height)};
}
pub inline fn get_framebuffer_dims() [2]u32 {
    return [_]u32{@intCast(ssfn_dst.w), @intCast(ssfn_dst.h)};
}

pub inline fn reset_render_cursor() void {
    ssfn_dst.x = 0;
    ssfn_dst.y = 0;
}

pub inline fn set_cursor(x : u32, y : u32) void {
    ssfn_dst.x = @intCast(x);
    ssfn_dst.y = @intCast(y);
}
pub inline fn get_cursor() [2]u32 {
    return [2]u32{ @intCast(ssfn_dst.x), @intCast(ssfn_dst.y) };
}

pub inline fn newline() void {
    ssfn_dst.y += ssfn_src.*.height; // Move one line down, (new line)
    ssfn_dst.x = 0; // and reset to left side of screen (carrige return)
}

/// Render one codepoint from the given string.
/// Returns a slice that contains the rest of the string after the first codepoint.
/// Returns null if ended the string.
pub fn render_char_from_string(string : []u8) ?[]u8 {
    var cursor : *u8 = @ptrCast( @constCast( string ) );
    const start : usize = @intFromPtr(cursor);
    const codepoint = ssfn.ssfn_utf8(@ptrCast( &cursor ));

    // If newline
    if(codepoint == 10) { // TODO: render a x10 glyph instead?

        newline();

    }else {

        const result : i32 = ssfn.ssfn_putc( codepoint );
        if(result != 0){
            //https://gitlab.com/bztsrc/scalable-font2/blob/master/docs/API.md#error-codes
            const err = "0";
            var ptr : *u8 = @ptrCast(@constCast(err));
            const point = ssfn.ssfn_utf8(@ptrCast(&ptr));
            const last_res = ssfn.ssfn_putc(point);
            if (last_res != 0) {
                @panic("Failed to print '0'? Things must be bad lol.");
            }
        }

    }
    if(cursor.* == 0){
        return null;
    }

    const end : usize = @intFromPtr(cursor);
    const diff : usize = end - start;
    return string[diff..];

}

// The most basic text rendering strategy : write lines one after another and don't scroll.
fn render_fixed(string : []u8) void {
    var cursor : []u8 = string;
    while (render_char_from_string(cursor)) |new_cursor|  {
        cursor = new_cursor;
    }

    newline();
}


// The next most obvious rendering strategy : when the text reaches the bottom of the screen, scroll.
// TODO: word wrapping.
// TODO: Consider when `string` is way bigger than the framebuffer.
pub fn render_scroll(string : []u8) void {
    // [1] Count the number of newlines.
    // TODO: Count the number of word wraps.
    const line_height_px = ssfn_src.*.height;
    const framebuffer_height_px = ssfn_dst.h;

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

        if ( ( pixel_cursor_px + line_height_px ) > framebuffer_height_px ) {
            lines_needed += 1;
        }
        break :blk lines_needed;
    };

    // [2] Move the buffer up the neccessary number of newlines.
    {
        const framebuffer_length_bytes : usize =@intCast( ssfn_dst.p * ssfn_dst.h );
        const framebuffer_dst : []u8 = ssfn_dst.ptr[0..framebuffer_length_bytes];
        const framebuffer_src : []u8 = framebuffer_dst[(lines_needed * line_height_px * ssfn_dst.p)..];
        std.mem.copyForwards(u8, framebuffer_dst, framebuffer_src);

        // Set the color of the new lines (on the bottom of the screen) to black. Otherwise, we'd be drawing on top of the old line.
        const new_lines_needed_bytes = framebuffer_length_bytes - ( lines_needed * line_height_px * ssfn_dst.p );
        const last_lines : []u8 = framebuffer_dst[new_lines_needed_bytes..];
        @memset(last_lines, 0);
    }

    ssfn_dst.y -= @intCast( lines_needed * line_height_px );

    render_fixed(string);
}

pub fn clear_screen() void {
    const framebuffer_length_bytes : usize =@intCast( ssfn_dst.p * ssfn_dst.h );
    const framebuffer_dst : []u8 = ssfn_dst.ptr[0..framebuffer_length_bytes];
    @memset(framebuffer_dst, 0);
}
