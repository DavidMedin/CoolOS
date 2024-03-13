= CoolOS, A Cool Operating System.


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

# TODO:
[x] Reimplement in Zig.\
[] Use [Scalable Screen Font](https://wiki.osdev.org/Scalable_Screen_Font).