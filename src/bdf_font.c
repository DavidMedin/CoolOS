// Parser for BDF, Glyph Bitmap Distribution Format, by Adobe
// Reference : https://adobe-type-tools.github.io/font-tech-notes/pdfs/5005.BDF_Spec.pdf
// Example Fonts : https://github.com/Tecate/bitmap-fonts
#include "defines.h"
#include "strings.c"

// Glyph - a drawn symbol for a character.

typedef struct {
    Slice font_source;
    Slice version;
    Slice name;
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

    // if ( ! wordcmp(file_cursor, "STARTFONT") ) {
    //     // This is bad.
    //     return (BDF_Result){true, {"The font pointed to by font_slc is not a BDF!"}};
    // }
    // file_cursor += 10; // len(STARTFONT) + 1

    // bool found_word = get_str_word(file_cursor, &font.version, &file_cursor);
    // if(found_word == false) {
    //     // very bad.
    //     return (BDF_Result){true, {"I am bad at parsing"}};
    // }

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
            if(get_slc_word(line, &font.version, &line) == false) {
                goto error_eof;
            }
        }else if(slccmp(directive, mkslc("FONT"))) {
            if(get_slc_word(line, &font.name, &line) == false) {
                goto error_eof;
            }
        }else if(slccmp(directive, mkslc("ENDPROPERTIES"))) {
            break;
        }

        
        // if(get_str_word(file_cursor, &directive, &file_cursor) == false) {
        //     // very bad.
        //     error_eof:
        //     return (BDF_Result){true, {"Found the end of the file while parsing the header."}};
        // }

        // if(strcmp(found_word, "FONT")) {
        //     if(get_str_word(file_cursor, &font.name, &file_cursor) == false) {
        //         goto error_eof;
        //     }
        // }else if(strcmp(found_word, "ENDPROPERTIES")){
        //     break; // DONE!
        // }
    }

    BDF_Result result;
    result.is_error = false;
    result.data.ok = font;

    return result;
}