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

pub fn poll() ?u32 {
    // poll if there is data to grab.
    const recv : StatusRegister = @bitCast(in_fn(0x64));
    if (recv.output_buffer_full) {
        const data : u32 = in_fn(0x60);
        return data;
    }
    return null; // no data to return.
}
