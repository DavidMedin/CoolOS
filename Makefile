
# CROSS=${HOME}/opt/cross/bin/
# CC=${CROSS}/i686-elf-gcc


coolos.img: coolos.bin
	cp coolos.bin isodir/boot
	grub-mkrescue -o coolos.img isodir

coolos.bin: kernel.o boot.o
	i686-elf-gcc -m32 -no-pie -ffreestanding -O0 -nostdlib -lgcc  boot.o kernel.o -T linker.ld -o coolos.bin

kernel.o: kernel.c
	i686-elf-gcc -g -m32 -std=gnu99  -ffreestanding -O0 -Wall -Wextra -c kernel.c -o kernel.o

boot.o: boot.asm
	nasm -g -f elf32 -o boot.o boot.asm

install:
