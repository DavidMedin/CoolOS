# CoolOS, A Cool Operating System.
## What is this?
This is a homemade operating system for `i386` (aka AI-32 [aka 'Intel Architecture 32-bit'] ) systems.\
In other words, a 32-bit operating system for x86 machines, not ARM.

# Zig Info:
current Zig version : https://ziglang.org/builds/zig-linux-x86_64-0.12.0-dev.3192+e2cbbd0c2.tar.xz\
current Zls version : commit ac60c30661cb4c371106c330d4a851fbd61c4d9e [tree](https://github.com/zigtools/zls/tree/ac60c30661cb4c371106c330d4a851fbd61c4d9e)\
The `zig` tools should be installed in a file system like this:
- `zig-tools`
    - `zig-linux` - just a renamed zig prebuilt, like extracted from the `zig-linux...tar.xz` above.
    - `zls` - a cloned, checkout out, and built `zls` repo.

These file will not be included in git.

## Third Party Code:
- SSFN ( Scalable Screen FoNt )
    - [gitlab source](https://gitlab.com/bztsrc/scalable-font2)
    - commit 8607671c463d7a8dbf48074fb0cbeda22707def8

## Third Party Packages (at least):
- nasm (`apt` package)
- xorriso (`apt` package)
- qemu-system-i386 (`apt` package)
- grub-pc-bin (`apt` package) (Without this, you may not be able to build the image [because you have a UEFI only computer].)

# TODO:
[x] Reimplement in Zig.\
[x] Use [Scalable Screen Font](https://wiki.osdev.org/Scalable_Screen_Font).
[ ] Enable floating point numbers.
[ ] Use SSFN2 Normal Renderer
    [ ] Make dynamic allocator with Zig std.mem
[ ] Color Text
[ ] Prevent SIGTRAP at start of LLDB
[ ] Better panics - text
[ ] Simple File System


# Sources
- Intel Documentation - https://www.intel.com/content/www/us/en/developer/articles/technical/intel-sdm.html
- A lot of other things...