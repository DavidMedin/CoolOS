#pragma once
#include "defines.h"

typedef struct {
    char* str;
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
    for(int i = 0; (slice_1.str[i] != 0 && slice_2.str[i] != 0); i++){
        if(slice_1.str[i] != slice_2.str[i]) {
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
    u32 word_start_idx = 0;
    u32 i; // Tom Halverson is finally rubbing off on me (whhaaa?)
    for(i = 0; i < src.len;i++){
        if(in_word == false && !is_whitespace(src.str[i])) {
            in_word = true;
            word_start_idx = i;
        }else if(in_word == true && is_whitespace(src.str[i])) {
            *word = (Slice){&src.str[word_start_idx], i-word_start_idx};
            if(cursor != 0){
                *cursor = (Slice){cursor->str + i, cursor->len - i};
            }
            return true;
        }

    }
    if(in_word == false){
        return false;
    }
    *word = (Slice){&src.str[word_start_idx], i-word_start_idx};
    if(cursor != 0){
        *cursor = (Slice){cursor->str + i, cursor->len - i};
    }
    return true;
}

bool get_slc_line(Slice src, Slice* output, Slice* cursor){
    for(int i = 0;i < src.len;i++ ){
        if(src.str[i] == '\n') {
            *output = (Slice){src.str, i};
            if(cursor != 0){
               *cursor = (Slice){cursor->str + i + 1, cursor->len - i + 1};
            }
            return true;
        }
    }
    return false;
}

Slice mkslc(char* str){
    return (Slice){str, strlen(str)};
}


//Yoink Source : https://stackoverflow.com/questions/7021725/how-to-convert-a-string-to-integer-in-c
u32 parse(char* str)
{
  u32 result;
  u32 puiss;

  result = 0;
  puiss = 1;
  while (('-' == (*str)) || ((*str) == '+'))
  {
      if (*str == '-')
        puiss = puiss * -1;
      str++;
  }
  while ((*str >= '0') && (*str <= '9'))
  {
      result = (result * 10) + ((*str) - '0');
      str++;
  }
  return (result * puiss);
}
