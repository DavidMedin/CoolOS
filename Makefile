
CROSS=${HOME}/opt/cross/bin/
CC=${CROSS}/i686-elf-gcc
ASM=nasm

myos.img: myos.bin
	cp myos.bin isodir/boot
	grub-mkrescue -o myos.img isodir

myos.bin: kernel.o boot.o
	${CC} -m32 -no-pie -ffreestanding -O0 -nostdlib -lgcc  boot.o kernel.o -T linker.ld -o myos.bin

kernel.o: kernel.c
	${CC} -g -m32 -std=gnu99  -ffreestanding -O0 -Wall -Wextra -c kernel.c -o kernel.o

boot.o: boot.asm
	${ASM} -g -f elf32 -o boot.o boot.asm