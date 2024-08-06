// Defined in boot.asm
pub extern fn in_fn(port : u16) u32;
pub extern fn out_fn(port : u16, data : u32) void;

// register_offset is in words (2 bytes).
pub fn pci_config_read(bus : u8, device : u4, func : u3, register_offset : u8) u16 {
    const reserved_and_enable : u32 = 0x80000000;
    //                                         v------ 2 least significant bits of register offset are 0.
    const address : u32 = (register_offset & 0xFC) | (@as(u32,func) << 8) | (@as(u32,device) << 11) | (@as(u32,bus) << 16) | reserved_and_enable;

    out_fn(0xCF8, address);

    const recv : u32 = in_fn(0xCFC);
    return @truncate( (recv >> (@as(u5, @truncate( register_offset & 2)) * 8)) & 0xFFFF );
}

pub const PciId = struct {
    pci_bus : u8,
    pci_device : u4,

    const Self = @This();
    inline fn config_read(self:Self, func:u3, register_offset : u8) u16{
        return pci_config_read(self.pci_bus, self.pci_device, func, register_offset);
    }
    pub inline fn get_info(self:Self) ?PciDevice {
        const vendor_id = self.config_read(0,0);
        if (vendor_id == 0xFFFF) {
            return null;
        }
        return .{
            .pci_id = self,
            .vendor_id = vendor_id,
            .device_id = self.config_read(0,2),
            .command = self.config_read(0,4),
            .status = self.config_read(0,6),
            .rev_id = @truncate( self.config_read(0,8) ),
            .prog_if = @truncate( self.config_read(0,8) >> 8 ),
            .subclass = @truncate( self.config_read(0,10) ),
            .class_code = @truncate( self.config_read(0,10) >> 8 ),
            .cache_line_size = @truncate( self.config_read(0,12) ),
            .latency_timer = @truncate( self.config_read(0,12) >> 8 ),
            .header_type = @truncate( self.config_read(0,14) ),
            .bist = @truncate( self.config_read(0,14) >> 8 ),
        };
    }
};

pub const PciDevice = struct {
    pci_id : PciId,
    vendor_id : u16,
    device_id : u16,
    command : u16,
    status : u16,
    rev_id : u8,
    prog_if : u8,
    subclass : u8,
    class_code : u8,
    cache_line_size : u8,
    latency_timer : u8,
    header_type : u8,
    bist : u8
};

