#pragma once // bite me

#define u32 unsigned int
#define i32 int
#define u16 short unsigned int
#define i16 short int
#define u64 unsigned long long int
#define i64 long long int
#define u8 char 
#define i8 char // don't use this

#define bei32 int // big endian (LSB)

#define false 0
#define true 1


// Converts Big Endian to Little Endian
u32 be_to_le(u32 input){
    u32 b0,b1,b2,b3;

    b0 = (input & 0x000000ff) << 24u;
    b1 = (input & 0x0000ff00) << 8u;
    b2 = (input & 0x00ff0000) >> 8u;
    b3 = (input & 0xff000000) >> 24u;

    return b0 | b1 | b2 | b3;
}