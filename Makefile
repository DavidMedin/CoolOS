
# CROSS=${HOME}/opt/cross/bin/
# CC=${CROSS}/i686-elf-gcc


coolos.img: coolos.bin
	cp coolos.bin isodir/boot
	grub-mkrescue -o coolos.img isodir

coolos.bin: kernel.o boot.o terminus_font.o cherry_font.o
	i686-elf-gcc -m32 -no-pie -ffreestanding -O0 -nostdlib -lgcc  boot.o kernel.o -T src/linker.ld -o coolos.bin

kernel.o: src/kernel.c
	i686-elf-gcc -g -m32 -std=gnu99  -ffreestanding -O0 -Wall -Wextra -c src/kernel.c -o kernel.o

boot.o: src/boot.asm
	nasm -g -f elf32 -o boot.o src/boot.asm


terminus_font.o: resources/terminusmod12b.pcf
	i686-elf-ld -r -b binary -o terminus_font.o resources/terminusmod12b.pcf
cherry_font.o: resources/cherry-11-r.bdf
	i686-elf-ld -r -b binary -o cherry_font.o resources/cherry-11-r.bdf

install:
