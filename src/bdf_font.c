// Parser for BDF, Glyph Bitmap Distribution Format, by Adobe
// Reference : https://adobe-type-tools.github.io/font-tech-notes/pdfs/5005.BDF_Spec.pdf
// Example Fonts : https://github.com/Tecate/bitmap-fonts
#include "defines.h"
#include "strings.c"

// Glyph - a drawn symbol for a character.

typedef struct {
    Slice font_source;
    Slice version; // from STARTFONT
    Slice name; // from FONT

    // from SIZE
    struct {
        u32 point_size;
        u32 x_res;
        u32 y_res;
    } size;

    struct {
        u32 bb_x; // bounding box x
        u32 bb_y;
        u32 x_off; // x offset
        u32 y_off;
    } font_bounding_box;

    // can be 0,1, or 2. Defualt to 0.
    // If set to 1, DWIDTH and SWIDTH are optional.
    u32 metric_set;

    u32 property_count;

} BDF;

typedef struct {
    u8 is_error;
    union {
        BDF ok;
        char* error;
    } data;
} BDF_Result;

u32 size_of_bdf(BDF* bdf) {
    return 1; // NOT TRUE
}

BDF_Result load_font(Slice font_slc) {
    BDF font = {0};
    font.font_source = font_slc;

    Slice file_cursor = font_slc;

    // 3.1 : Global Font Information
    Slice line;
    while(true){ // only breaks on error or 'ENDPROPERTIES'.

        if(get_slc_line(file_cursor, &line, &file_cursor) == false) {
            // very bad.
            error_eof:
            return (BDF_Result){true, {"Found the end of the file while parsing the header."}};
        }

        Slice directive;
        Slice cmd_cursor = line;
        if(get_slc_word(line, &directive, &line) == false) {
            goto error_eof;
        }

        if(slccmp(directive, mkslc("STARTFONT"))) {
            // args:
            //  integer version
            if(get_slc_word(line, &font.version, &line) == false) goto error_eof;
        }else if(slccmp(directive, mkslc("FONT"))) {
            // args:
            //  string name
            if(get_slc_word(line, &font.name, &line) == false) goto error_eof;
        }else if( slccmp(directive, mkslc("SIZE") ) ){
            // args:
            //  integer point_size
            //  integer x_res
            //  integer y_res
            Slice param;
            if( get_slc_word(line, &param, &line) == false ) goto error_eof;
            font.size.point_size = parse(param.str);
            
            if( get_slc_word(line, &param, &line) == false ) goto error_eof;
            font.size.x_res = parse(param.str);
            
            if( get_slc_word(line, &param, &line) == false ) goto error_eof;
            font.size.y_res = parse(param.str);
        }
        
        else if(slccmp(directive, mkslc("ENDPROPERTIES"))) {
            break;
        }

    }

    BDF_Result result;
    result.is_error = false;
    result.data.ok = font;

    return result;
}