/*
 * This is example code. Using this code in any project with any license is permitted.
 * Author: Johan Mattsson
 */
#ifndef FILE_FK_H
#define FILE_FK_H

#include <stdbool.h>
#include <stdint.h>
#include <stdlib.h>
#include <stdio.h>

typedef int32_t Fixed16_16;

#define FIXED_KERNING_HEADER_SIZE 8
#define FIXED_KERNING_ENTRY_SIZE (3 * sizeof (uint32_t))

/* Convert fixed 16.16 values to double. */
double fk_fixed_to_double (Fixed16_16 val);

Fixed16_16 fk_double_to_fixed (double v);

/*
 * All parser functions assumes that this function has been used to check if
 * the table is valid and we have kerning pairs in the subtable.
 */
bool fk_has_fixed_kerning (uint8_t* otf_table, size_t table_size);

uint32_t fk_get_num_kerning_pairs (uint8_t* otf_table, size_t table_size);

/*
 * A function that makes it possible iterate over all kerning pairs in the
 * table from 0 to fk_get_num_kerning_pairs.
 */
void fk_get_fixed_kerning_by_index (uint8_t* otf_table, size_t table_size, size_t index, uint32_t* first_glyph_index, uint32_t* second_glyph_index, Fixed16_16* kerning);

/* 
 * Get kerning for two gids, (glyph ID). The Fixed 16.16 value can be converted
 * to a floating point value with the with the function fixed_to_double.
 */
Fixed16_16 fk_get_fixed_kerning (uint8_t* otf_table, size_t table_size, uint32_t first_glyph_index, uint32_t second_glyph_index);

uint32_t fk_get_uint32 (uint8_t* otf_table, size_t table_size, size_t index);
uint16_t fk_get_uint16 (uint8_t* otf_table, size_t table_size, size_t index);

void fk_write_u8 (FILE* file, uint8_t val);
void fk_write_u16 (FILE* file, uint16_t val);
void fk_write_u32 (FILE* file, uint32_t val);

#endif
