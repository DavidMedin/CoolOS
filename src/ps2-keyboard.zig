// Defined in boot.asm
pub extern fn in_fn(port : u16) u32;
pub extern fn out_fn(port : u16, data : u32) void;

// PS/2 Controoler IO Ports
// IO Port | Acess Type | Purpose
// ------------------------------
// 0x60    | Read/Write | Data Port
// 0x64    | Read       | Status Register
// 0x64    | Write      | Command Register

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

pub fn ps2_poll() ?u32 {
    // poll if there is data to grab.
    const recv : StatusRegister = @bitCast(in_fn(0x64));
    if (recv.output_buffer_full) {
        const data : u32 = in_fn(0x60);
        return data;
    }
    return null; // no data to return.
}
