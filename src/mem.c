#include "defines.h"
// A very bad dynamic allocator.
// Depends on a section in the linker.

extern u8 heap_top;
extern u8 heap_bottom;

// void* serial_alloc()