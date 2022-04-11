/*
 * This is example code. Using this code in any project with any license is permitted.
 * Author: Johan Mattsson
 */
#include <stdint.h>
#include <stdio.h>
#include <stdbool.h>
#include <math.h>
#include <assert.h>
#include <stdlib.h>

#include "fk.h"

void fk_write_fixed_kerning_table_header (FILE* file, uint32_t num_kerning_pairs) {
   uint16_t version_upper = 1;
   uint16_t version_lower = 0;
   uint16_t pairs = num_kerning_pairs;
   
   fk_write_u16 (file, version_upper);
   fk_write_u16 (file, version_lower);
   fk_write_u32 (file, pairs);
}

Fixed16_16 fk_double_to_fixed (double v) {
   int32_t val;
   int32_t mant;
   
   val = (int32_t) floor (v);
   mant = (int32_t) floor (0x10000 * (v - val));
   val = (val << 16) | mant;

   return val;
}

void fk_write_fixed_kerning_entry (FILE* file, uint32_t glyph_index_first, uint32_t glyph_index_second, double kerning) {
   int32_t fixed_kerning;
   
   if (kerning > INT16_MAX || kerning < INT16_MIN) {
      fprintf(stderr, "Kerning is out of bounds.\n");
      kerning = 0;
   }
   
   fixed_kerning = fk_double_to_fixed (kerning);

   fk_write_u32 (file, glyph_index_first);
   fk_write_u32 (file, glyph_index_second);
   fk_write_u32 (file, fixed_kerning);
}
