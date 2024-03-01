default:
    just --list

@clean:
    rm *.o *.img *.bin isodir/boot/myos.bin

# Use an actual build system (make) to build.
build:
    make 

debug: build
    qemu-system-i386 -hda myos.img -s -S

# Run gdb and qemu
debug-gdb: build
    kitty --detach --directory=. gdb -ex 'target remote localhost:1234' --symbols=myos.bin
    qemu-system-i386 -hda myos.img -s -S &

# https://stackoverflow.com/questions/71902815/qemu-system-i386-error-loading-uncompressed-kernel-without-pvh-elf-note
# make run & gdb -ex 'target remote localhost:1234'

# Run qemu
run: build
	qemu-system-i386 -hda myos.img
