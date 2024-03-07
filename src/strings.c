#pragma once
#include "defines.h"

typedef struct {
    char* string;
    u32 len;
} Slice;

// Header ================
static inline bool is_whitespace(char character);
bool strcmp(char* string_1, char* string_2);
bool strcmp_len(char* string_1, char* string_2, u32 length); // strcmp, but only searches up to 'length' characters.
u32 strlen(char* str);
bool slccmp(Slice slice_1, Slice slice_2);
bool wordcmp(char* string_1, char* string_2); // Returns if the characters before the first whitespace are equal.
                                            // currently only supports spaces (' ') and newlines ('\n').

// Get the next word that occurs (could be after some whitespace) and the length of that word (excluding whitespace).
// cursor is optional (set to 0 when unused). It will be incremented by the size of the word. It will not be read.
bool get_str_word(char* src, Slice* word, u32* cursor);

bool get_slc_word(Slice src, Slice* word, Slice* cursor);
bool get_slc_line(Slice src, Slice* output, Slice* cursor);

Slice mkslc(char* str);
// ================= Source

static inline bool is_whitespace(char character){
    return character == ' ' || character == '\n' || character == '\t';
}

bool strcmp(char* string_1, char* string_2){
    for(int i = 0; string_1[i] != 0 && string_2[i] != 0; i++){
        if(string_1[i] != string_2[i]) {
            return false;
        }
    }
    return true;
}

bool strcmp_len(char* string_1, char* string_2, u32 length){
    for(int i = 0; (string_1[i] != 0 && string_2[i] != 0) && i < length; i++){
        if(string_1[i] != string_2[i]) {
            return false;
        }
    }
    return true;
}

u32 strlen(char* str){
    int i;
    for(i = 0;str[i] != 0;i++);
    return i;
}

bool slccmp(Slice slice_1, Slice slice_2){
    if(slice_1.len != slice_2.len){
        return false;
    }
    for(int i = 0; (slice_1.string[i] != 0 && slice_2.string[i] != 0); i++){
        if(slice_1.string[i] != slice_2.string[i]) {
            return false;
        }
    }
    return true;
}

bool wordcmp(char* string_1, char* string_2){
    for(int i = 0; (string_1[i] != 0 && string_2[i] != 0) && (is_whitespace(string_1[i]) && is_whitespace); i++){
        if(string_1[i] != string_2[i]) {
            return false;
        }
    }
    return true;
}

bool get_str_word(char* src, Slice* word, u32* cursor){
    bool in_word = false;
    char* word_start = 0;
    int i; // Tom Halverson is finally rubbing off on me (whhaaa?)
    for(i = 0; src[i] != 0;i++){
        if(in_word == false && !is_whitespace(src[i])) {
            in_word = true;
            word_start = &src[i];
        }else if(in_word == true && is_whitespace(src[i])) {
            *word = (Slice){word_start, i};
            if(cursor != 0){
                *cursor += i;
            }
            return true;
        }

    }
    if(word_start == 0){
        return false;
    }
    *word = (Slice){word_start, i};
    if(cursor != 0){
        *cursor += i;
    }
    return true;
}

bool get_slc_word(Slice src, Slice* word, Slice* cursor){
    bool in_word = false;
    char* word_start = 0;
    int i; // Tom Halverson is finally rubbing off on me (whhaaa?)
    for(i = 0; i < src.len;i++){
        if(in_word == false && !is_whitespace(src.string[i])) {
            in_word = true;
            word_start = &src.string[i];
        }else if(in_word == true && is_whitespace(src.string[i])) {
            *word = (Slice){word_start, i};
            if(cursor != 0){
                // *cursor += i;
                *cursor = (Slice){cursor->string + i, cursor->len - i};
            }
            return true;
        }

    }
    if(word_start == 0){
        return false;
    }
    *word = (Slice){word_start, i};
    if(cursor != 0){
        *cursor = (Slice){cursor->string + i, cursor->len - i};
    }
    return true;
}

bool get_slc_line(Slice src, Slice* output, Slice* cursor){
    for(int i = 0;i < src.len;i++ ){
        if(src.string[i] == '\n') {
            *output = (Slice){src.string, i};
            if(cursor != 0){
               *cursor = (Slice){cursor->string + i, cursor->len - i};
            }
            return true;
        }
    }
    return false;
}

Slice mkslc(char* str){
    return (Slice){str, strlen(str)};
}