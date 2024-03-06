#include "defines.h"
#include "font.c"

// Use VGA text mode buffer located at 0xB8000 . DONT ACTUALLY! Use UEFI PIXEL BUFFERS!

// A driver that remembers the location of the next character in the VGA buffer and provides a way to add a new character.

typedef struct {
    u32 total_size; // Total size of everything.
    u32 reserved; // Not for the kernel to touch.
} MBI;

typedef struct {
    u32 type;
    u32 size;
} TagHeader;

typedef struct { // type=4, size=16
    TagHeader header;
    u32 mem_lower;
    u32 mem_upper;
}BasicMemInfo;

typedef struct {// type=5, size=20
    TagHeader header;
    u32 biosdev;
    u32 partition;
    u32 sub_partition;
} BIOSBootDevice;

typedef struct { // type=1
    TagHeader header;
    u8 start_of_string;
} BootCmdLine;

typedef struct { // type=3
    TagHeader header;
    u32 mod_start;
    u32 mod_end;
    u8 string_start;
} Modules;

// TODO: Elf-Symbols
// TODO: Memory map

typedef struct { // type=2
    TagHeader header;
    u8 string_start;
} BootLoaderName;

// TODO: APM

typedef struct {
    TagHeader header;
    u64 fmbuff_addr;
    u32 fmbuff_pitch;
    u32 fmbuff_width;
    u32 fmbuff_height;
    u8 fmbuff_bpp;
    u8 fmbuff_type;
    u8 reserved;
    u8 color_info_start; // not actual data, use this address for palette maybe.
} FrameBufferInfo;

// =============== Either =======
typedef struct {
    u32 fmbuff_palette_num_colors;
    u8 palette_start;
} PaletteInfo;

typedef struct {
    u8 red;
    u8 gree;
    u8 blue;
} palette;

// ================ Or ==========
u8 fmbuff_red_field_position;
u8 fmbuff_red_mask_size;

u8 fmbuff_green_field_position;
u8 fmbuff_green_mask_size;

u8 fmbuff_blue_field_position;
u8 fmbuff_blue_mask_size;

// =============================

typedef struct {
    TagHeader header;
    u32 base_address;
} ImageLoadBaseAddress;

void align_to(u32* input, u32 alignment) {
    *input += ( (alignment - *input)  % alignment );
}

u32 base_address = 0; // bad.
u32 MBI_info[3000]; // Also bad.
u32 MBI_end = 0;

extern u8* _binary_resources_terminusmod12b_pcf_start;
extern u8* _binary_resources_terminusmod12b_pcf_end;
extern u8* _binary_resources_terminusmod12b_pcf_size;

void kernel_main(MBI* mbi) {
    TagHeader* tag_head = ((char*)mbi+sizeof(MBI));
    u32 tag_addr = tag_head;
    // Correct the pointer to be 8-byte aligned.
    align_to((u32)&tag_addr, 8);
    tag_head = (TagHeader*)(tag_addr);

    FrameBufferInfo* fb_info = 0;


    while(tag_head->type != 0){
        // if(tag_head->type == 21) {
        //     // base address.
        //     ImageLoadBaseAddress* tag = tag_head;
        //     base_address = tag->base_address;
        // }
        MBI_info[MBI_end] = tag_head->type;
        MBI_end += 1;


        switch(tag_head->type) {

            // Framebuffer Info tag
            case 8: {
                fb_info = tag_head;
                break;
            }
        }


        // jump to the next tag.
        tag_addr += tag_head->size;
        align_to((u32)&tag_addr, 8);
        tag_head = (TagHeader*)(tag_addr);
    };

    if(fb_info->fmbuff_type == 0) {
        // color_info is defined by a indexed palette.

        *(i32*)(fb_info->fmbuff_addr) = 1;
    }else if(fb_info->fmbuff_type == 1) {
        // color_info is field position and mask size for each color, red green and blue.

        *(i32*)(fb_info->fmbuff_addr) = -1;
    }


    // font things.
    PCF_Result font_result = load_font(_binary_resources_terminusmod12b_pcf_start, _binary_resources_terminusmod12b_pcf_size);

    int debug_nothing = 2;
}