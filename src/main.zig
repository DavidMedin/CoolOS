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


const std = @import("std");
const ssfn = @cImport({
    @cDefine("SSFN_MAXLINES", "4096");
    //SSFN_CONSOLEBITMAP_PALETTE
    @cDefine("SSFN_CONSOLEBITMAP_TRUECOLOR", {});
    @cDefine("NULL", "0"); // Never thought I'd have to do this for C.
    @cInclude("scalable-font2/ssfn.h");
});

pub fn panic(msg: []const u8, error_return_trace: ?*std.builtin.StackTrace, something : ?usize) noreturn {
    _ = msg;
    _ = error_return_trace;
    _ = something;
    while(true) {
        @breakpoint();
    }
}

export var ssfn_src : *ssfn.ssfn_font_t = @ptrCast( @constCast( @embedFile("resources/fonts/lanapixel.sfn" ) ) );
// SFN Docs are wrong, ssfn_dist is a ssfn_buf_t, not a *ssfn_buf_t!
export var ssfn_dst : ssfn.ssfn_buf_t = undefined;

var print_buffer = [_]u8{0} ** 4096;
// Defines how std.log.error, std.log.debug, and friends function.
fn kernelLogFn(comptime level: std.log.Level, comptime scope: @TypeOf(.EnumLiteral), comptime format: []const u8, args: anytype) void {
        _ = scope;
        //const ED = comptime "\x1b[";
        //_ = ED;
        //const reset = "\x1b[0m";
        //_ = reset;


        const prefix = "[" ++ comptime level.asText() ++ "] ";
        const fmt_string: []u8 = std.fmt.bufPrint(&print_buffer, prefix ++ format, args) catch unreachable;
        //const render_string  = "hello";
        var cursor : *u8 = @ptrCast( @constCast( fmt_string ) );
        while( cursor.* != 0) {
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
        ssfn_dst.y += ssfn_src.*.height; // Move one line down, (new line)
        ssfn_dst.x = 0; // and reset to left side of screen (carrige return)
    }
pub const std_options : std.Options = .{
    .logFn = kernelLogFn
};

const MBI = struct {
    total_size : u32, // Total size of everything.
    reserved : u32 // Not for the kernel to touch.
} ;

const TagHeader = struct {
    type : u32,
    size : u32,
};

const BasicMemInfo = struct { // type=4, size=16
    header : TagHeader,
    mem_lower : u32,
    mem_upper : u32,
};

const BIOSBootDevice= struct {// type=5, size=20
     header : TagHeader,
     biosdev : u32,
     partition : u32,
     sub_partition : u32,
};

const BootCmdLine = struct { // type=1
    header : TagHeader,
    start_of_string : u8,
};

const Modules = struct { // type=3
    header : TagHeader,
    mod_start : u32,
    mod_end : u32,
    string_start : u8,
};

// TODO: Elf-Symbols
// TODO: Memory map

const BootLoaderName = struct { // type=2
     header : TagHeader,
     string_start : u8,
} ;

// TODO: APM

const FrameBufferInfo = struct {
    header : TagHeader,
    fmbuff_addr : u64,
    fmbuff_pitch : u32,
    fmbuff_width : u32,
    fmbuff_height : u32,
    fmbuff_bpp : u8,
    fmbuff_type : u8,
    reserved : u8,
    color_info_start : u8, // not actual data, use this address for palette maybe.
};

// =============== Either =======
const PaletteInfo = struct {
    fmbuff_palette_num_colors : u32,
    palette_start : u8,
};

const palette = struct {
    red : u8,
    gree : u8,
    blue : u8,
};

// ================ Or ==========
 var fmbuff_red_field_position : u8 = 0;
 var fmbuff_red_mask_size : u8 = 0;
 var fmbuff_green_field_position : u8 = 0;
 var fmbuff_green_mask_size : u8 = 0;
 var fmbuff_blue_field_position : u8 = 0;
 var fmbuff_blue_mask_size : u8 = 0;

// =============================

const ImageLoadBaseAddress = struct {
    header : TagHeader,
    base_address : u32,
};

fn align_to(input : *usize, alignment : u32) void {
    input.* += ( alignment - (input.* % alignment) ) % alignment;
}

export var base_address : u32 = 0; // bad.
export var MBI_info = [_]u32{0} ** 3000; // Also bad.
export var MBI_end : u32 = 0;



pub export fn kernel_main(mbi : *MBI) callconv(.C) void {
    var tag_head : *TagHeader = @ptrFromInt( @intFromPtr(mbi) + @sizeOf(MBI) );
    var tag_addr : u32 = @intFromPtr(tag_head);

    align_to(&tag_addr, 8);
    tag_head = @ptrFromInt(tag_addr);

    var fb_info_maybe : ?*FrameBufferInfo = null;

    while(tag_head.*.type != 0) {
        MBI_info[MBI_end] = tag_head.*.type;
        MBI_end += 1;

        switch(tag_head.*.type){
            8 => {
                fb_info_maybe = @ptrCast( tag_head );
            },
            else => {

            }
        }

        tag_addr += tag_head.*.size;
        align_to(&tag_addr, 8);
        tag_head = @ptrFromInt(tag_addr);
    }

    if(fb_info_maybe) |fb_info| {
        if(fb_info.*.fmbuff_type == 0 ){
            // color_info is defined by an indexed palette.
            //fb_info.*.fmbuff_addr = 1;
        }else if(fb_info.*.fmbuff_type == 1) {

            // Test pixel in top left
            const to_usize : usize = @intCast( fb_info.*.fmbuff_addr );
            const bad_ptr : *u32 = @ptrFromInt( to_usize ) ;
            _ = bad_ptr;
            // bad_ptr.* = std.math.maxInt(u32);
        }

        
        // Frame buffer to ssfn dest.
        const fmbuff_addr : usize = @intCast( fb_info.*.fmbuff_addr );
        //_ = fmbuff_addr;
        ssfn_dst = .{
            .ptr = @ptrFromInt( fmbuff_addr ),
            .p = @intCast( fb_info.*.fmbuff_pitch ),
            .w = @intCast( fb_info.*.fmbuff_width ),
            .h = @intCast( fb_info.*.fmbuff_height ),
            .fg = 0xeeeeeeee,
            .bg = 0x0,
            .x = @intCast( 0 ),
            .y = @intCast( 0 )
        };

        std.log.debug("hello!", .{});
        std.log.err("Has something gone bad? Who knows?\n",.{});
    }


    while(true) {
        @breakpoint();
    }
}

