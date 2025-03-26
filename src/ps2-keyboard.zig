// Defined in boot.asm
extern fn in_fn(port : u16) u32;
extern fn out_fn(port : u16, data : u32) void;

const std = @import("std");

const keycodes = @import("third-party/ps2-keyboard/src/pc_keyboard.zig");
pub usingnamespace keycodes;

// PS/2 Controoler IO Ports
// IO Port | Acess Type | Purpose
// ------------------------------
// 0x60    | Read/Write | Data Port
// 0x64    | Read       | Status Register
// 0x64    | Write      | Command Register
//
// Keyboard Mapping : https://wiki.osdev.org/PS/2_Keyboard
// Electrical Desc and History : https://wiki.osdev.org/PS/2
// Controller Info (ports and such [actually useful]) : https://wiki.osdev.org/%228042%22_PS/2_Controller

// TODO:
// - Configure PS/2 controller to use Keycode set 2.
// - Manual initialization of PS/2 controller.
// - Implement all PS/2 commands and such.

const StatusRegister = packed struct(u32) {
    output_buffer_full : bool,
    input_buffer_full : bool,
    system_flag : bool,
    command_or_data : bool,
    maybe_keyboard_lock : bool,
    unknown : bool,
    unknown_2 : bool,
    time_out_error : bool,
    parity_error : bool,
    _padding_bits : u23
};

// Non-blocking poll.
fn raw_poll() ?[4]u8 {
    // poll if there is data to grab.
    const recv : StatusRegister = @bitCast(in_fn(0x64));
    if (recv.output_buffer_full) {
        const data : u32 = in_fn(0x60);
        return @bitCast( data );
    }
    return null; // no data to return.
}

pub const PS2Controller = struct {
    keyboard_desc : keycodes.Keyboard,

    const Self = @This();
    pub fn poll(self : *Self) !?keycodes.DecodedKey {
        const EXTEND_BYTE : u8 = 0xE0;

        // All 4 bytes read in from the PS2 device.
        // If 'a' was pressed, there is a one byte message, but all of the 4 bytes repeat the one byte.
        const full_msg : [4]u8 = raw_poll() orelse return null;

        // This is under the assumption that all multi-byte messages start with the 'extend byte' (0xe0),
        // and the next byte is the real message.

        //     return null if was the extend byte--vvvvvvv
        const key_event = try self.*.keyboard_desc.addByte(full_msg[0]) orelse extend: {
            if ( full_msg[0] == EXTEND_BYTE ) {
                break :extend try self.*.keyboard_desc.addByte(full_msg[1]) orelse return null; // Parse the bytestream from the ps2 controller.
            }
            unreachable; // Sanity check.
        };

       const decoded_key = self.*.keyboard_desc.processKeyevent(key_event) orelse return null; // Figure out if what key is pressed, and if ctrl and such are active.
       return decoded_key;
    }
};

// Is global since there is only one PS2 Controller. All must travel through here.
var ps2_ctrlr : PS2Controller = PS2Controller{
    .keyboard_desc = keycodes.Keyboard.init(.ScancodeSet1, .Us104Key, .MapLettersToUnicode),
};

pub fn init() *PS2Controller {
    return &ps2_ctrlr;
}
