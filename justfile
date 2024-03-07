default:
    just --list

@clean:
    rm *.o *.img *.bin isodir/boot/coolos.bin

# Use an actual build system (Nix [actually just make]) to build.
build:
    nix-build

debug:
    #!/usr/bin/env nix-shell
    #! nix-shell -i bash
    #! nix-shell -p qemu gdb
    qemu-system-i386 -blockdev driver=file,node-name=disk_file,read-only=true,filename=result/coolos.img  -device nvme,drive=disk_file,serial=deadbeef -s -S

# Run gdb and qemu
debug-gdb: build
    #!/usr/bin/env nix-shell
    #! nix-shell -i bash
    #! nix-shell -p qemu gdb
    set -euxo pipefail
    kitty --detach --directory=. gdb -ex 'target remote localhost:1234' --symbols=result/coolos.bin
    qemu-system-i386 -blockdev driver=file,node-name=disk_file,read-only=true,filename=result/coolos.img  -device nvme,drive=disk_file,serial=deadbeef  -s -S &

# https://stackoverflow.com/questions/71902815/qemu-system-i386-error-loading-uncompressed-kernel-without-pvh-elf-note
# make run & gdb -ex 'target remote localhost:1234'

# Run qemu
run: build
    #!/usr/bin/env nix-shell
    #! nix-shell -i bash
    #! nix-shell -p qemu
    set -euxo pipefail
    qemu-system-i386 -blockdev driver=file,node-name=disk_file,read-only=true,filename=result/coolos.img  -device nvme,drive=disk_file,serial=deadbeef
