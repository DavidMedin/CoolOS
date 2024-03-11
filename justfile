default:
    just --list

@clean:
    rm *.o *.img *.bin isodir/boot/coolos.bin

# Use an actual build system (Nix [actually just make]) to build.
build:
    ./zig-tools/zig-linux/zig build

debug:
    qemu-system-i386 -hda zig-out/bin/coolos.img -s -S

# Run gdb and qemu
debug-gdb: build
    kitty --detach --directory=. gdb -ex 'target remote localhost:1234' --symbols=zig-out/bin/coolos.bin
    qemu-system-i386 -hda zig-out/bin/coolos.img -s -S &

# https://stackoverflow.com/questions/71902815/qemu-system-i386-error-loading-uncompressed-kernel-without-pvh-elf-note
# make run & gdb -ex 'target remote localhost:1234'

# Run qemu
run: build
    qemu-system-i386 -hda zig-out/bin/coolos.img