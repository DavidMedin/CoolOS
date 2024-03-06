
# CROSS=${HOME}/opt/cross/bin/
# CC=${CROSS}/i686-elf-gcc


myos.img: myos.bin
	cp myos.bin isodir/boot
	grub-mkrescue -o myos.img isodir

myos.bin: kernel.o boot.o
	i686-elf-gcc -m32 -no-pie -ffreestanding -O0 -nostdlib -lgcc  boot.o kernel.o -T linker.ld -o myos.bin

kernel.o: kernel.c
	i686-elf-gcc -g -m32 -std=gnu99  -ffreestanding -O0 -Wall -Wextra -c kernel.c -o kernel.o

boot.o: boot.asm
	nasm -g -f elf32 -o boot.o boot.asm