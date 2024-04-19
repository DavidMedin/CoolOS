default:
    just --list

@clean:
    rm isodir/boot/coolos.bin || true
    rm -rf zig-out || true
    rm -rf zig-cache || true

# Use an actual build system (Zig) to build.
build: clean # the dep. clean is to force zig to recompile.
    ./zig-tools/zig-linux/zig build
debug:
    qemu-system-i386 -drive file=zig-out/bin/coolos.img,format=raw,index=0,media=disk -s -S -no-reboot -no-shutdown # -d int <- if you want too much info about an interrupt.

# Run gdb and qemu
debug-gdb: build
    kitty --detach --directory=. gdb -ex 'target remote localhost:1234' --symbols=zig-out/bin/coolos.bin
    qemu-system-i386 -drive file=zig-out/bin/coolos.img,format=raw,index=0,media=disk -s -S -no-reboot -no-shutdown &

# https://stackoverflow.com/questions/71902815/qemu-system-i386-error-loading-uncompressed-kernel-without-pvh-elf-note
# make run & gdb -ex 'target remote localhost:1234'

# Run qemu
run: build
    qemu-system-i386 -drive file=zig-out/bin/coolos.img,format=raw,index=0,media=disk