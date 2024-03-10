default:
    just --list

@clean:
    rm *.o *.img *.bin isodir/boot/coolos.bin

# Use an actual build system (Nix [actually just make]) to build.
build:
    ./zig-tools/zig-linux/zig build

debug:
    qemu-system-i386 -blockdev driver=file,node-name=disk_file,read-only=true,filename=zig-out/bin/coolos.img  -device nvme,drive=disk_file,serial=deadbeef -s -S

# Run gdb and qemu
debug-gdb: build
    set -euxo pipefail
    kitty --detach --directory=. gdb -ex 'target remote localhost:1234' --symbols=zig-out/bin/coolos.bin
    qemu-system-i386 -blockdev driver=file,node-name=disk_file,read-only=true,filename=zig-out/bin/coolos.img  -device nvme,drive=disk_file,serial=deadbeef  -s -S &

# https://stackoverflow.com/questions/71902815/qemu-system-i386-error-loading-uncompressed-kernel-without-pvh-elf-note
# make run & gdb -ex 'target remote localhost:1234'

# Run qemu
run: build
    set -euxo pipefail
    qemu-system-i386 -blockdev driver=file,node-name=disk_file,read-only=true,filename=zig-out/bin/coolos.img  -device nvme,drive=disk_file,serial=deadbeef
