// https://wiki.osdev.org/Zig_Bare_Bones
const std = @import("std");

// const Multiboot2 = packed struct {
//     magic: u32 = 0xE85250D6,
//     architecture: u32 = 0,
//     header_length: u32,
//     checksum: u32
// };

// const MultibootTag align(8) = packed struct {
//     type:u16,
//     flags:u16,
//     size:u32
// };
// const MultibootFramebuffer = packed struct {
//     width:u32,
//     height:u32,
//     depth:u32
// };

// var multiboot_start : void align(4) linksection(".multiboot2") = {};
// const multiboot_size : u32 = @intFromPtr(&multiboot_end) - @intFromPtr(&multiboot_start);
// export const multiboot2 align(4) linksection(".multiboot2") = Multiboot2{
//     .header_length = multiboot_size,
//     .checksum = -(0xE85250D6 + 0 + multiboot_size)
// };

// var mb_info_head align(4) linksection(".multiboot2") = MultibootTag {
//     .type =  1,
//     .flags =  1,
//     .size = &mb_info_end - &mb_info_head
// };
// var mb_info_types: u16 align(4) linksection(".multiboot2") = 4;
// var mb_info_end: void align(4) linksection(".multiboot2") = {};


// var mb_frame_tag align(4) linksection(".multiboot2") = MultibootTag {
//     .type =  1,
//     .flags =  1,
//     .size = &mb_frame_end - &mb_frame_tag
// };
// var mb_frame_data align(4) linksection(".multiboot2") = MultibootFramebuffer{
//     .width = 800,
//     .height = 800,
//     .depth = 2
// };
// var mb_frame_end: void align(4) linksection(".multiboot2") = {};

// var mb_end_tag align(4) linksection(".multiboot2") = MultibootTag {
//     .type = 0,
//     .flags = 0,
//     .size = 8
// };

// const multiboot_end : void align(4) linksection(".multiboot2") = {};

// export var _start linksection(".text") = fn callconv("naked") 
// export fn _start () callconv(.Naked) noreturn {

// }

pub export fn kernel_main() void {
    // Prints to stderr (it's a shortcut based on `std.io.getStdErr()`)
    // std.debug.print("All your {s} are belong to us.\n", .{"codebase"});

    // // stdout is for the actual output of your application, for example if you
    // // are implementing gzip, then only the compressed bytes should be sent to
    // // stdout, not any debugging messages.
    // const stdout_file = std.io.getStdOut().writer();
    // var bw = std.io.bufferedWriter(stdout_file);
    // const stdout = bw.writer();

    // try stdout.print("Run `zig build test` to run the tests.\n", .{});

    // try bw.flush(); // don't forget to flush!

    var thing : i32 = 3;
    thing = 2;
}

// test "simple test" {
//     var list = std.ArrayList(i32).init(std.testing.allocator);
//     defer list.deinit(); // try commenting this out and see if zig detects the memory leak!
//     try list.append(42);
//     try std.testing.expectEqual(@as(i32, 42), list.pop());
// }
