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

uint8_t* fk_get_subtable_entries(uint8_t* otf_table, size_t table_size, size_t* subtable_size);

double fk_fixed_to_double (Fixed16_16 val) {
   return val / 65536.0;
}

uint16_t fk_get_uint16 (uint8_t* otf_table, size_t table_size, size_t index) {
	if (index + 1 >= table_size) {
		fprintf(stderr, "Index out of bounds: %zu Buffer size: %zu.\n", index, table_size);
		return 0;
	}
	
	uint16_t val = otf_table[index + 1] << 8;
	val |= otf_table[index];
	return val;
}

uint32_t fk_get_uint32 (uint8_t* otf_table, size_t table_size, size_t index) {
	if (index + 3 >= table_size) {
		fprintf(stderr, "Index out of bounds: %zu Buffer size: %zu.\n", index, table_size);
		return 0;
	}

   uint32_t val = fk_get_uint16 (otf_table, table_size, index) << 16;
   val |= fk_get_uint16 (otf_table, table_size, index + 2);

	return val;
}

void fk_write_u8 (FILE* file, uint8_t val) {
   fwrite(&val, 1, sizeof(uint8_t), file);
}

void fk_write_u16 (FILE* file, uint16_t val) {
   fk_write_u8 (file, (uint8_t) ((val & 0x00FF) >> (8 * 0)));
   fk_write_u8 (file, (uint8_t) ((val & 0xFF00) >> (8 * 1)));
}

void fk_write_u32 (FILE* file, uint32_t val) {
	uint16_t s = (uint16_t) (val >> 16);
   
   fk_write_u16 (file, (val & 0xFFFF0000) >> 16);
   fk_write_u16 (file, val & 0x0000FFFF);
}

uint32_t fk_get_int32 (uint8_t* otf_table, size_t table_size, size_t index) {
	return (uint32_t) fk_get_uint32 (otf_table, table_size, index);
}

/*
* This function ensures that we have data for the fixed kerning table. 
* The get_fixed_kerning assumes that has_fixed_kerning has been used to
* check if we have a valid subtable with kerning entries.
*/
bool fk_has_fixed_kerning (uint8_t* otf_table, size_t table_size) {
   if (otf_table == NULL) {
      fprintf(stderr, "No table for fixed kerning.\n");
      return false;
   }
   
   if (table_size <= FIXED_KERNING_HEADER_SIZE) {
      // No data in table
      return false;
   }
   
   if (table_size % 4 != 0) {
      fprintf(stderr, "Bad padding in fixed kerning table, size: %zu.\n", table_size);
      return false;
   }
   
   uint16_t version_upper = fk_get_uint16(otf_table, table_size, 0);
   uint16_t version_lower = fk_get_uint16(otf_table, table_size, 2);
   
   if (version_upper != 1 || version_lower != 0) {
      fprintf(stderr,"Bad version of fixed kerning table. Expecting 1.0 got %d.%d\n", version_upper, version_lower);
      return false;
   }
   
   uint32_t entries = fk_get_num_kerning_pairs (otf_table, table_size);
   size_t subtable_size = table_size - FIXED_KERNING_HEADER_SIZE;
   size_t expected_subtable_size = entries * 3 * sizeof(uint32_t);
   
   if (subtable_size != expected_subtable_size) {
      fprintf(stderr,"Bad subtable size in fixed kerning table. Size %zu bytes expecting %zu bytes (added entries: %d).\n", subtable_size, expected_subtable_size, entries);
      return false;
   }
   
   return true;
}

Fixed16_16 fk_get_fixed_kerning (uint8_t* otf_table, size_t table_size, uint32_t first_glyph_index, uint32_t second_glyph_index) {
   uint32_t entries = fk_get_num_kerning_pairs(otf_table, table_size);
   size_t subtable_size = 0;
   uint8_t* subtable = fk_get_subtable_entries(otf_table, table_size, &subtable_size);

   int lower = 0;
   int upper = entries;
   const int second_gid_offset = sizeof(uint32_t); // offset from start of an kerning entry to the second glyph 
   const int kerning_offset = 2 * sizeof(uint32_t); // offset from start of an kerning entry to the kerning value
   
   uint64_t gid1 = first_glyph_index;
   uint64_t gid2 = second_glyph_index;
   uint64_t search_key =  (gid1 << 32) | gid2;
   
   while (lower <= upper) {
      size_t middle = lower + (upper - lower) / 2;
      size_t index = middle;
      
      size_t row_index = index * 3 * sizeof(uint32_t);
      uint64_t pair_key = fk_get_uint32 (subtable, subtable_size, row_index);
      pair_key <<= 32;
      pair_key |= fk_get_uint32 (subtable, subtable_size, row_index + second_gid_offset);
      
      if (pair_key == search_key) {
         return (Fixed16_16) fk_get_uint32 (subtable, subtable_size, row_index + kerning_offset);
      }
      
      if (pair_key < search_key) {
         lower = middle + 1;
      } else {
         upper = middle - 1;
      }   
   }
   
   return 0;
}

uint8_t* fk_get_subtable_entries(uint8_t* otf_table, size_t table_size, size_t* subtable_size) {
   if (table_size <= FIXED_KERNING_HEADER_SIZE) {
      *subtable_size = 0;
      return NULL;
   }
   
   *subtable_size = table_size - FIXED_KERNING_HEADER_SIZE;
   
   return otf_table + FIXED_KERNING_HEADER_SIZE;
}

uint32_t fk_get_num_kerning_pairs (uint8_t* otf_table, size_t table_size) {
   if (table_size < FIXED_KERNING_HEADER_SIZE) {
      printf("Kerning table is too short.");
      return 0;
   }
   
   return fk_get_uint32 (otf_table, table_size, 4);
}

void fk_get_fixed_kerning_by_index (uint8_t* otf_table, size_t table_size, size_t index, uint32_t* first_glyph_index, uint32_t* second_glyph_index, Fixed16_16* kerning) {
   uint32_t num_pairs = fk_get_num_kerning_pairs (otf_table, table_size);
   size_t subtable_size = 0;
   uint8_t* subtable = fk_get_subtable_entries (otf_table, table_size, &subtable_size);
   
   index *= FIXED_KERNING_ENTRY_SIZE;
      
   if (index + FIXED_KERNING_ENTRY_SIZE > subtable_size) {
      fprintf (stderr, "Index out of bounds in fixed kerning table, index: %zu subtable size: %zu, item size: %ld\n", index, subtable_size, FIXED_KERNING_ENTRY_SIZE);
      *first_glyph_index = 0;
      *second_glyph_index = 0;
      *kerning = 0;
      return;
   }
   
   *first_glyph_index = fk_get_uint32 (subtable, subtable_size, index);
   *second_glyph_index = fk_get_uint32 (subtable, subtable_size, index + sizeof(uint32_t));

   int32_t fixed_kerning = fk_get_int32 (subtable, subtable_size, index + 2 * sizeof(uint32_t));
   *kerning = fixed_kerning;
}
