const text = @import("text.zig");

pub const MBI = struct {
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

export var MBI_info = [_]u32{0} ** 3000; // Also bad.
export var MBI_end : u32 = 0;

pub const MBErr = error {
    NoFramebuffer
};

pub fn parse_multiboot_info(mbi : *MBI) MBErr!void {

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
                // Found the framebuffer!
                fb_info_maybe = @ptrCast( tag_head );
            },
            else => {

            }
        }

        tag_addr += tag_head.*.size;
        align_to(&tag_addr, 8);
        tag_head = @ptrFromInt(tag_addr);
    }
    // Done looking for tags, now so stuff with these tags.

    if(fb_info_maybe) |fb_info| {

        // Frame buffer to ssfn dest.
        text.ssfn_dst = .{
            .ptr = @ptrFromInt( @as(usize, @intCast( fb_info.*.fmbuff_addr ) ) ),
            .p = @intCast( fb_info.*.fmbuff_pitch ),
            .w = @intCast( fb_info.*.fmbuff_width ),
            .h = @intCast( fb_info.*.fmbuff_height ),
            .fg = 0xeeeeeeee,
            .bg = 0x0,
            .x = @intCast( 0 ),
            .y = @intCast( 0 )
        };


    }else {
        return MBErr.NoFramebuffer;
    }
}