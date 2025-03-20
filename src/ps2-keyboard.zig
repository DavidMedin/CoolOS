// Defined in boot.asm
extern fn in_fn(port : u16) u32;
extern fn out_fn(port : u16, data : u32) void;

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
fn raw_poll() ?u32 {
    // poll if there is data to grab.
    const recv : StatusRegister = @bitCast(in_fn(0x64));
    if (recv.output_buffer_full) {
        const data : u32 = in_fn(0x60);
        return data;
    }
    return null; // no data to return.
}

pub const PS2Controller = struct {
    keyboard_desc : keycodes.Keyboard,

    const Self = @This();
    pub fn poll(self : *Self) !?keycodes.DecodedKey {
        const byte : u8 = @as(u8, @truncate(
            raw_poll() orelse return null
        ));

       const key_event = try self.*.keyboard_desc.addByte(byte) orelse return null; // Parse the bytestream from the ps2 controller.
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
