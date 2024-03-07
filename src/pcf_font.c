// Totally based off of : https://fontforge.org/docs/techref/pcf-format.html
// Font selection : https://github.com/Tecate/bitmap-fonts
#include "defines.h"


; // [table_count]

typedef struct  {
    i8 header[4];                  /* always "\1fcp" (0x70636601)*/
    i32 table_count; // in file, Big Endian.
    
    struct toc_table {
        bei32 type;              /* See below, indicates which table */
        bei32 format;            /* See below, indicates how the data are formatted in the table */
        bei32 size;              /* In bytes */
        bei32 offset;            /* from start of file */
    };

    struct toc_table* table_entries; // of count table_count.
} PCFTable;

// Table Entry Types
#define PCF_PROPERTIES               (1<<0)
#define PCF_ACCELERATORS            (1<<1)
#define PCF_METRICS                 (1<<2)
#define PCF_BITMAPS                 (1<<3)
#define PCF_INK_METRICS             (1<<4)
#define PCF_BDF_ENCODINGS           (1<<5)
#define PCF_SWIDTHS                 (1<<6)
#define PCF_GLYPH_NAMES             (1<<7)
#define PCF_BDF_ACCELERATORS        (1<<8)
// ============

// Table Entry Format
#define PCF_DEFAULT_FORMAT       0x00000000
#define PCF_INKBOUNDS           0x00000200
#define PCF_ACCEL_W_INKBOUNDS   0x00000100
#define PCF_COMPRESSED_METRICS  0x00000100
// ===============


// Table Format Entry Modifiers
#define PCF_GLYPH_PAD_MASK       (3<<0)            /* See the bitmap table for explanation */
#define PCF_BYTE_MASK           (1<<2)            /* If set then Most Sig Byte First */
#define PCF_BIT_MASK            (1<<3)            /* If set then Most Sig Bit First */
#define PCF_SCAN_UNIT_MASK      (3<<4)            /* See the bitmap table for explanation */
// ===========

// ==================== Table Entry Items =======


// Properties Table
typedef struct {
    bei32 format;                 /* Always stored with least significant byte first! */
    i32 nprops;                   /* Stored in whatever byte order is specified in the format */
    struct props_t {
        i32 name_offset;          /* Offset into the following string table */
        i8 isStringProp;
        i32 value;                /* The value for integer props, the offset for string props */
    };
    struct props_t* props;

    // char padding[(nprops&3)==0?0:(4-(nprops&3))];   /* pad to next int32 boundary */
    i32 string_size;                /* total size of all strings (including their terminating NULs) */
    char* strings;
    // char padding2[];
} PCF_Properties;
// =====================

// === Metrics Data  ========
// Compressed
typedef struct {
    u8 left_sided_bearing;
    u8 right_side_bearing;
    u8 character_width;
    u8 character_ascent;
    u8 character_descent;
} PCF_Compressed_Metric;
// ==========

// Uncompressed
typedef struct {
    i16 left_sided_bearing;
    i16 right_side_bearing;
    i16 character_width;
    i16 character_ascent;
    i16 character_descent;
    u16 character_attributes;
} PCF_Uncompressed_Metric;
// ============

// ==========================


/// Accelrators Tables
typedef struct {
    bei32 format;                 /* Always stored with least significant byte first! */
    u8 noOverlap;                /* if for all i, max(metrics[i].rightSideBearing - metrics[i].characterWidth) */
                                    /*      <= minbounds.leftSideBearing */
    u8 constantMetrics;          /* Means the perchar field of the XFontStruct can be NULL */
    u8 terminalFont;             /* constantMetrics true and forall characters: */
                                    /*      the left side bearing==0 */
                                    /*      the right side bearing== the character's width */
                                    /*      the character's ascent==the font's ascent */
                                    /*      the character's descent==the font's descent */
    u8 constantWidth;            /* monospace font like courier */
    u8 inkInside;                /* Means that all inked bits are within the rectangle with x between [0,charwidth] */
                                    /*  and y between [-descent,ascent]. So no ink overlaps another char when drawing */
    u8 inkMetrics;               /* true if the ink metrics differ from the metrics somewhere */
    u8 drawDirection;            /* 0=>left to right, 1=>right to left */
    u8 padding;
    i32 fontAscent;               /* byte order as specified in format */
    i32 fontDescent;
    i32 maxOverlap;               /* ??? */
    PCF_Uncompressed_Metric minbounds;
    PCF_Uncompressed_Metric maxbounds;
    /* If format is PCF_ACCEL_W_INKBOUNDS then include the following fields */
        PCF_Uncompressed_Metric ink_minbounds;
        PCF_Uncompressed_Metric ink_maxbounds;
    /* Otherwise those fields are not in the file and should be filled by duplicating min/maxbounds above */
} PCF_AcceleratorTable;

/// ============================


typedef struct {
    PCFTable header;
    void* header_entries;
} PCF;

typedef struct {
    u8 is_error;
    union {
        PCF ok;
        char* error;
    } data;
} PCF_Result;

u32 size_of_pcf(PCF* pcf) {
    return 1; // NOT TRUE
}

PCF_Result load_font(void* font_bytes, u32 font_size) {
    PCF font;
    u32 file_cursor = (u32)font_bytes;

    // 01 66 63 70
    if(*(u32*)font_bytes != 0x70636601) { // Magic number.
        return (PCF_Result){true, {"The font pointed to by font_bytes is not a PCF!"}};
    }
    *(u32*)&font.header.header = *(u32*)font_bytes; // write to all 4 bytes at the same time (hopfully).
    file_cursor += 4; // jump over magic number.

    font.header.table_count = *(u32*)file_cursor;
    file_cursor += sizeof(u32);

    font.header.table_entries = (struct toc_table*)file_cursor;
    file_cursor += sizeof(struct toc_table)*font.header.table_count;
    align_to(&file_cursor, 4); // Align to 32 bit (4 byte) boundary.

    // Not actually needed.
    for(int i = 0; i < font.header.table_count ;i++) {
        bool glpyh_pad = PCF_GLYPH_PAD_MASK & (font.header.table_entries[i].format) != 0;
        bool byte_big_endian = PCF_BYTE_MASK & (font.header.table_entries[i].format) != 0;
        bool bit_big_endian = PCF_BIT_MASK & (font.header.table_entries[i].format) != 0;
        bool scan_unit = PCF_SCAN_UNIT_MASK & (font.header.table_entries[i].format) != 0;

        int do_something = 4;
        int nothing = do_something;
    }



    PCF_Result result;
    result.is_error = false;
    result.data.ok = font;

    return result;
}