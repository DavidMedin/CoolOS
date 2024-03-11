// https://wiki.osdev.org/Zig_Bare_Bones
const std = @import("std");

pub fn panic(msg: []const u8, error_return_trace: ?*std.builtin.StackTrace, something : ?usize) noreturn {
    _ = msg;
    _ = error_return_trace;
    _ = something;
    while(true) {
        @breakpoint();
    }
}

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
    input.* += ( (input.* - alignment) % alignment);
}

var base_address : u32 = 0; // bad.
var MBI_info = [_]u32{0} ** 3000; // Also bad.
var MBI_end : u32 = 0;

pub export fn kernel_main(mbi : *MBI) callconv(.C) void {
    var tag_head : *TagHeader = @ptrFromInt( @intFromPtr(mbi) + @sizeOf(MBI) );
    var tag_addr : u32 = @intFromPtr(tag_head);

    align_to(&tag_addr, 8);
    var fb_info : *FrameBufferInfo = undefined;

    while(tag_head.*.type != 0) {
        MBI_info[MBI_end] = tag_head.*.type;
        MBI_end += 1;

        switch(tag_head.*.type){
            8 => {
                fb_info = @ptrCast( tag_head );
            },
            else => {

            }
        }

        tag_addr += tag_head.*.size;
        align_to(&tag_addr, 8);
        tag_head = @ptrFromInt(tag_addr);
    }

    if(fb_info.*.fmbuff_type == 0 ){
        // color_info is defined by an indexed palette.
        //fb_info.*.fmbuff_addr = 1;
    }else if(fb_info.*.fmbuff_type == 1) {
        const to_usize : usize = @intCast( fb_info.*.fmbuff_addr );
        const bad_ptr : *u32 = @ptrFromInt( to_usize ) ;
        bad_ptr.* = std.math.maxInt(u32);
    }
    var thing : i32 = 3;
    thing = 2;
}

// test "simple test" {
//     var list = std.ArrayList(i32).init(std.testing.allocator);
//     defer list.deinit(); // try commenting this out and see if zig detects the memory leak!
//     try list.append(42);
//     try std.testing.expectEqual(@as(i32, 42), list.pop());
// }
