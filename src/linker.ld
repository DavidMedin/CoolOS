
ENTRY(_start)

SECTIONS {
    . = 2M; /* Start offset of 2 MB */

    .text : ALIGN(4K)
    {
        *(.multiboot2)
        *(.text)
    }

    /* Read only things */
    .rodata : ALIGN(4K)
    {
        /*
        _terminus_font_start = .;
        terminus_font.o
        _terminus_font_end = .;
        _cherry_font_start = .;
        cherry_font.o
        _cherry_font_end = .;
        */
        *(.rodata)
    }

    /* Read-write data (initialized) */
    .data : ALIGN(4K)
    {
        *(.data)
    }

    /* read-write data (uninitialized) and the stack */
    .bss : ALIGN(4K)
    {
        *(COMMON)
        *(.bss)
    }
}