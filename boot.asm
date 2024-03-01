; https://wiki.osdev.org/Bare_Bones

; OLD : https://www.gnu.org/software/grub/manual/multiboot/multiboot.html
; multiboot 2 : https://www.gnu.org/software/grub/manual/multiboot2/multiboot.html
section .multiboot2
    align 4 ; Align this code on the 32 bit (4 byte) boundary
    magic: dd 0xE85250D6 ; Multiboot magic number
    architechture : dd 0
    header_length_val: equ (tags.end - magic)
    header_length: dd header_length_val
    checksum_val: equ -(0xE85250D6 + 0 + header_length_val ) ; checksum of the above
    checksum: dd checksum_val
    tags:

    ; Defines (with .tag_tag_types) what information structs the kernel gets with the MBI.
    align 8 ; align 8 bytes
    tags.MBI: ; MultiBoot Information
    .tag_type: dw 1 
    .tag_flags: dw 1 ; means it must have these tags
    .tag_size_val: equ (tags.MBI.end - tags.MBI)
    .tag_size: dd .tag_size_val
    .tag_tag_types: dd 4 ; this is an array of Boot Information (section 3.6)
    tags.MBI.end:

    ; align 8
    ; tags.address:
    ; .tag_type: dw 2
    ; .tag_flags: dw 1
    ; .tag_size_val: equ (tags.address.end - tags.address)
    ; .tag_size: dd .tag_size_val
    ; .tag_header_addr: dd magic
    ; .tag_load_addr: dd _start
    ; .tag_load_end_addr: dd _start.end
    ; .tag_bss_end_addr: dd stack_top
    ; tags.address.end:
    
    ; align 8
    ; tags.entry_addr:
    ; .tag_type: dw 3
    ; .tag_flags: dw 1
    ; .tag_size_val: equ (tags.entry_addr.end - tags.entry_addr)
    ; .tag_size: dd .tag_size_val
    ; .tag_entry_addr: dd _start
    ; tags.entry_addr.end:


    ; align 8
    ; tags.entry_addr:
    ; .tag_type: dw 8 ; i386 entry address tag
    ; .tag_flags: dw 0
    ; .tag_size_val: equ (tags.entry_addr.end - tags.entry_addr)
    ; .tag_size: dd .tag_size_val
    ; .tag_entry_addr: dd _start
    ; tags.entry_addr.end:


    ; align 8
    ; tags.flags:
    ; .tag_type: dw 4 ; console tags (use text, not gui)
    ; .tag_flags: dw 1
    ; .tag_size: dd 12
    ; .console_flags: dd 0
    ; tags.flags.end:

    align 8
    tags.frame:
    .tag_type: dw 5
    .tag_flags: dw 1
    .tag_size_val: equ (tags.frame.end - tags.frame)
    .tag_size: dd .tag_size_val
    .tag_width: dd 800
    .tag_height: dd 800
    .tag_depth: dd 2
    tags.frame.end:

    align 8
    tags.tag_end:
    .tag_type: dw 0
    .tag_flags: dw 0
    .tag_size: dd 8
tags.end:
; This is our 'stack' section. It will be 16 KiB.
; BSS is 'Block Ended by Symbol'. Not sure what that means, but
; this stack has a symbol at the top and bottom.
section .bss
align 16
stack_bottom:
resq 16384 ; not sure how to just 'skip' bytes.
stack_top: ; with x86, the stack grows down.


; Section with out kernel starting point.
; Some linker script (idk where) likes the word '_start', so we use it.
section .text
global _start ; export this symbol to the linker.
extern kernel_main
_start:
    ; 32 bit protected mode on x86.
    mov esp, stack_top
    ; no need to write to ebp bc there is no returning from here.
    push ebx ; ebx contains the address to the Boot Information provided by multiboot2
    call kernel_main ; defined in C

    ; =========== Infinite Loop
    cli
    hlt
    jmp 1b
    ; =========================
_start.end: