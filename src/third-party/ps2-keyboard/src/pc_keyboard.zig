const std = @import("std");

pub const KeyboardError = error{
    BadStartBit,
    BadStopBit,
    ParityError,
    UnknownKeyCode,
};

pub const KeyboardLayout = enum {
    Uk105Key,
    Us104Key,
    Jis109Key,
    AzertyKey,
    Dvorak104Key,
};
const Uk105KeyImpl = @import("keycode/layouts/uk105.zig");
const Us104KeyImpl = @import("keycode/layouts/us104.zig");
const Jis109KeyImpl = @import("keycode/layouts/jis109.zig");
const AzertyKeyImpl = @import("keycode/layouts/azerty.zig");
const Dvorak104KeyImpl = @import("keycode/layouts/dvorak104.zig");

pub const ScancodeSet = enum {
    ScancodeSet1,
    ScancodeSet2,
};
const ScancodeSet1Impl = @import("keycode/scancodes/scancode_set1.zig");
const ScancodeSet2Impl = @import("keycode/scancodes/scancode_set2.zig");

pub const Keyboard = struct {
    register: u16 = 0,
    num_bits: u4 = 0,
    decode_state: DecodeState = .Start,
    handle_ctrl: HandleControl,
    modifiers: Modifiers = .{},
    scancode_set: ScancodeSet,
    keyboard_layout: KeyboardLayout,

    /// Make a new Keyboard object with the given layout.
    pub fn init(scancode_set: ScancodeSet, keyboard_layout: KeyboardLayout, handle_ctrl: HandleControl) Keyboard {
        return .{
            .handle_ctrl = handle_ctrl,
            .scancode_set = scancode_set,
            .keyboard_layout = keyboard_layout,
        };
    }

    /// Change the Ctrl key mapping.
    pub fn setCtrlHandling(self: *Keyboard, new_value: HandleControl) void {
        self.handle_ctrl = new_value;
    }

    /// Get the current Ctrl key mapping.
    pub fn getCtrlHandling(self: *Keyboard) HandleControl {
        return self.handle_ctrl;
    }

    /// Clears the bit register.
    ///
    /// Call this when there is a timeout reading data from the keyboard.
    pub fn clear(self: *Keyboard) void {
        self.register = 0;
        self.num_bits = 0;
        self.decode_state = .Start;
    }

    /// Processes a 16-bit word from the keyboard.
    ///
    /// * The start bit (0) must be in bit 0.
    /// * The data octet must be in bits 1..8, with the LSB in bit 1 and the
    ///   MSB in bit 8.
    /// * The parity bit must be in bit 9.
    /// * The stop bit (1) must be in bit 10.
    pub fn addWord(self: *Keyboard, word: u16) KeyboardError!?KeyEvent {
        return self.addByte(try checkWord(word));
    }

    /// Processes an 8-bit byte from the keyboard.
    ///
    /// We assume the start, stop and parity bits have been processed and verified.
    pub fn addByte(self: *Keyboard, byte: u8) KeyboardError!?KeyEvent {
        return switch (self.scancode_set) {
            .ScancodeSet1 => ScancodeSet1Impl.advanceState(&self.decode_state, byte),
            .ScancodeSet2 => ScancodeSet2Impl.advanceState(&self.decode_state, byte),
        };
    }

    /// Shift a bit into the register.
    ///
    /// Call this /or/ call `add_word` - don't call both.
    /// Until the last bit is added you get null returned.
    pub fn addBit(self: *Keyboard, bit: u1) KeyboardError!?KeyEvent {
        self.register |= @as(u16, bit) << self.num_bits;
        self.num_bits += 1;
        if (self.num_bits == KEYCODE_BITS) {
            const word = self.register;
            self.register = 0;
            self.num_bits = 0;
            return self.addWord(word);
        } else {
            return null;
        }
    }

    /// Processes a `KeyEvent` returned from `add_bit`, `add_byte` or `add_word`
    /// and produces a decoded key.
    ///
    /// For example, the KeyEvent for pressing the '5' key on your keyboard
    /// gives a DecodedKey of unicode character '5', unless the shift key is
    /// held in which case you get the unicode character '%'.
    pub fn processKeyevent(self: *Keyboard, ev: KeyEvent) ?DecodedKey {
        switch (ev.state) {
            .Up => {
                switch (ev.code) {
                    .ShiftLeft => self.modifiers.lshift = false,
                    .ShiftRight => self.modifiers.rshift = false,
                    .ControlLeft => self.modifiers.lctrl = false,
                    .ControlRight => self.modifiers.rctrl = false,
                    .AltRight => self.modifiers.alt_gr = false,
                    else => {},
                }
            },
            .Down => {
                switch (ev.code) {
                    .ShiftLeft => self.modifiers.lshift = true,
                    .ShiftRight => self.modifiers.rshift = true,
                    .ControlLeft => self.modifiers.lctrl = true,
                    .ControlRight => self.modifiers.rctrl = true,
                    .AltRight => self.modifiers.alt_gr = true,
                    .CapsLock => self.modifiers.capslock = !self.modifiers.capslock,
                    .NumpadLock => self.modifiers.numlock = !self.modifiers.numlock,
                    else => {
                        return switch (self.keyboard_layout) {
                            .Uk105Key => Uk105KeyImpl.mapKeycode(ev.code, self.modifiers, self.handle_ctrl),
                            .Us104Key => Us104KeyImpl.mapKeycode(ev.code, self.modifiers, self.handle_ctrl),
                            .Jis109Key => Jis109KeyImpl.mapKeycode(ev.code, self.modifiers, self.handle_ctrl),
                            .AzertyKey => AzertyKeyImpl.mapKeycode(ev.code, self.modifiers, self.handle_ctrl),
                            .Dvorak104Key => Dvorak104KeyImpl.mapKeycode(ev.code, self.modifiers, self.handle_ctrl),
                        };
                    },
                }
            },
        }

        return null;
    }

    fn getBit(word: u16, offset: u4) bool {
        return ((word >> offset) & 0x0001) != 0;
    }

    fn hasEvenNumberOfBits(data: u8) bool {
        return @as(u8,@popCount(data)) % 2 == 0;
    }

    /// Check 11-bit word has 1 start bit, 1 stop bit and an odd parity bit.
    fn checkWord(word: u16) !u8 {
        if (getBit(word, 0)) return error.BadStartBit;
        if (!getBit(word, 10)) return error.BadStopBit;

        const data :u8 = @truncate((word >> 1));

        // Needs odd parity
        if (hasEvenNumberOfBits(data) != getBit(word, 9)) {
            return error.ParityError;
        }

        return data;
    }

    comptime {
        std.testing.refAllDecls(@This());
    }
};

/// Keycodes that can be generated by a keyboard.
pub const KeyCode = enum {
    AltLeft,
    AltRight,
    ArrowDown,
    ArrowLeft,
    ArrowRight,
    ArrowUp,
    BackSlash,
    Backspace,
    BackTick,
    BracketSquareLeft,
    BracketSquareRight,
    CapsLock,
    Comma,
    ControlLeft,
    ControlRight,
    Delete,
    End,
    Enter,
    Escape,
    Equals,
    F1,
    F2,
    F3,
    F4,
    F5,
    F6,
    F7,
    F8,
    F9,
    F10,
    F11,
    F12,
    Fullstop,
    Home,
    Insert,
    Key1,
    Key2,
    Key3,
    Key4,
    Key5,
    Key6,
    Key7,
    Key8,
    Key9,
    Key0,
    Menus,
    Minus,
    Numpad0,
    Numpad1,
    Numpad2,
    Numpad3,
    Numpad4,
    Numpad5,
    Numpad6,
    Numpad7,
    Numpad8,
    Numpad9,
    NumpadEnter,
    NumpadLock,
    NumpadSlash,
    NumpadStar,
    NumpadMinus,
    NumpadPeriod,
    NumpadPlus,
    PageDown,
    PageUp,
    PauseBreak,
    PrintScreen,
    ScrollLock,
    SemiColon,
    ShiftLeft,
    ShiftRight,
    Slash,
    Spacebar,
    Tab,
    Quote,
    WindowsLeft,
    WindowsRight,
    A,
    B,
    C,
    D,
    E,
    F,
    G,
    H,
    I,
    J,
    K,
    L,
    M,
    N,
    O,
    P,
    Q,
    R,
    S,
    T,
    U,
    V,
    W,
    X,
    Y,
    Z,
    /// Not on US keyboards
    HashTilde,
    // Scan code set 1 unique codes
    PrevTrack,
    NextTrack,
    Mute,
    Calculator,
    Play,
    Stop,
    VolumeDown,
    VolumeUp,
    WWWHome,
    // Sent when the keyboard boots
    PowerOnTestOk,
};

pub const KeyState = enum {
    Up,
    Down,
};

/// Options for how we can handle what happens when the Ctrl key is held down and a letter is pressed.
pub const HandleControl = enum {
    /// If either Ctrl key is held down, convert the letters A through Z into
    /// Unicode chars U+0001 through U+001A. If the Ctrl keys are not held
    /// down, letters go through normally.
    MapLettersToUnicode,
    /// Don't do anything special - send through the Ctrl key up/down events,
    /// and leave the letters as letters.
    Ignore,
};

pub const KeyEvent = struct {
    code: KeyCode,
    state: KeyState,
};

pub const Modifiers = struct {
    lshift: bool = false,
    rshift: bool = false,
    lctrl: bool = false,
    rctrl: bool = false,
    numlock: bool = true,
    capslock: bool = false,
    alt_gr: bool = false,

    pub inline fn isShifted(modifiers: Modifiers) bool {
        return modifiers.lshift or modifiers.rshift;
    }

    pub inline fn isCtrl(modifiers: Modifiers) bool {
        return modifiers.lctrl or modifiers.rctrl;
    }

    pub inline fn isCaps(modifiers: Modifiers) bool {
        return modifiers.isShifted() != modifiers.capslock;
    }

    comptime {
        std.testing.refAllDecls(@This());
    }
};

pub const DecodedKeyType = enum {
    RawKey,
    Unicode,
};

pub const DecodedKey = union(DecodedKeyType) {
    RawKey: KeyCode,
    Unicode: []const u8,
};

pub const DecodeState = enum {
    Start,
    Extended,
    Release,
    ExtendedRelease,
};

const KEYCODE_BITS: u8 = 11;

comptime {
    std.testing.refAllDecls(@This());
}

test "f9" {
    var keyboard = Keyboard.init(.ScancodeSet2, .Us104Key, .MapLettersToUnicode);

    // start
    try std.testing.expect((try keyboard.addBit(0)) == null);
    // 8 data bits (LSB first)
    try std.testing.expect((try keyboard.addBit(1)) == null);
    try std.testing.expect((try keyboard.addBit(0)) == null);
    try std.testing.expect((try keyboard.addBit(0)) == null);
    try std.testing.expect((try keyboard.addBit(0)) == null);
    try std.testing.expect((try keyboard.addBit(0)) == null);
    try std.testing.expect((try keyboard.addBit(0)) == null);
    try std.testing.expect((try keyboard.addBit(0)) == null);
    try std.testing.expect((try keyboard.addBit(0)) == null);
    // parity
    try std.testing.expect((try keyboard.addBit(0)) == null);
    // stop
    const result = try keyboard.addBit(1);
    try std.testing.expect(result != null);
    try std.testing.expectEqual(KeyEvent{ .code = .F9, .state = .Down }, result.?);
}

test "f9 word" {
    var keyboard = Keyboard.init(.ScancodeSet2, .Us104Key, .MapLettersToUnicode);

    const result = try keyboard.addWord(0x0402);
    try std.testing.expect(result != null);
    try std.testing.expectEqual(KeyEvent{ .code = .F9, .state = .Down }, result.?);
}

test "f9 byte" {
    var keyboard = Keyboard.init(.ScancodeSet2, .Us104Key, .MapLettersToUnicode);

    const result = try keyboard.addByte(0x01);
    try std.testing.expect(result != null);
    try std.testing.expectEqual(KeyEvent{ .code = .F9, .state = .Down }, result.?);
}

test "keyup keydown" {
    var keyboard = Keyboard.init(.ScancodeSet2, .Us104Key, .MapLettersToUnicode);

    var kv = try keyboard.addByte(0x01);
    try std.testing.expect(kv != null);
    try std.testing.expectEqual(KeyEvent{ .code = .F9, .state = .Down }, kv.?);

    kv = try keyboard.addByte(0x01);
    try std.testing.expect(kv != null);
    try std.testing.expectEqual(KeyEvent{ .code = .F9, .state = .Down }, kv.?);

    kv = try keyboard.addByte(0xF0);
    try std.testing.expect(kv == null);

    kv = try keyboard.addByte(0x01);
    try std.testing.expect(kv != null);
    try std.testing.expectEqual(KeyEvent{ .code = .F9, .state = .Up }, kv.?);
}

test "shift" {
    var keyboard = Keyboard.init(.ScancodeSet2, .Us104Key, .MapLettersToUnicode);

    // A with shift held
    var dk = keyboard.processKeyevent(KeyEvent{ .code = .ShiftLeft, .state = .Down });
    try std.testing.expect(dk == null);
    dk = keyboard.processKeyevent(KeyEvent{ .code = .A, .state = .Down });
    try std.testing.expect(dk != null);
    try std.testing.expectEqualStrings("A", dk.?.Unicode);
    dk = keyboard.processKeyevent(KeyEvent{ .code = .A, .state = .Up });
    try std.testing.expect(dk == null);
    dk = keyboard.processKeyevent(KeyEvent{ .code = .ShiftLeft, .state = .Up });
    try std.testing.expect(dk == null);

    // A with no shift
    dk = keyboard.processKeyevent(KeyEvent{ .code = .A, .state = .Down });
    try std.testing.expect(dk != null);
    try std.testing.expectEqualStrings("a", dk.?.Unicode);
    dk = keyboard.processKeyevent(KeyEvent{ .code = .A, .state = .Up });
    try std.testing.expect(dk == null);

    // A with right shift held
    dk = keyboard.processKeyevent(KeyEvent{ .code = .ShiftRight, .state = .Down });
    try std.testing.expect(dk == null);
    dk = keyboard.processKeyevent(KeyEvent{ .code = .A, .state = .Down });
    try std.testing.expect(dk != null);
    try std.testing.expectEqualStrings("A", dk.?.Unicode);
    dk = keyboard.processKeyevent(KeyEvent{ .code = .A, .state = .Up });
    try std.testing.expect(dk == null);
    dk = keyboard.processKeyevent(KeyEvent{ .code = .ShiftRight, .state = .Up });
    try std.testing.expect(dk == null);

    // Caps lock on
    dk = keyboard.processKeyevent(KeyEvent{ .code = .CapsLock, .state = .Down });
    try std.testing.expect(dk == null);
    dk = keyboard.processKeyevent(KeyEvent{ .code = .CapsLock, .state = .Up });
    try std.testing.expect(dk == null);

    // Letters are now caps
    dk = keyboard.processKeyevent(KeyEvent{ .code = .A, .state = .Down });
    try std.testing.expect(dk != null);
    try std.testing.expectEqualStrings("A", dk.?.Unicode);
    dk = keyboard.processKeyevent(KeyEvent{ .code = .A, .state = .Up });
    try std.testing.expect(dk == null);

    // Unless you press shift
    dk = keyboard.processKeyevent(KeyEvent{ .code = .ShiftLeft, .state = .Down });
    try std.testing.expect(dk == null);
    dk = keyboard.processKeyevent(KeyEvent{ .code = .A, .state = .Down });
    try std.testing.expect(dk != null);
    try std.testing.expectEqualStrings("a", dk.?.Unicode);
    dk = keyboard.processKeyevent(KeyEvent{ .code = .A, .state = .Up });
    try std.testing.expect(dk == null);
}
