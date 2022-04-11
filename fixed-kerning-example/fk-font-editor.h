/*
 * This is example code. Using this code in any project with any license is permitted.
 * Author: Johan Mattsson
 */
#ifndef FILE_FK_FONT_EDITOR
#define FILE_FK_FONT_EDITOR

#include <stdio.h>
#include "fk.h"

void fk_write_fixed_kerning_table_header (FILE* file, uint32_t num_kerning_pairs);
void fk_write_fixed_kerning_entry (FILE* file, uint32_t glyh_index_first, uint32_t glyh_index_second, double kerning);

#endif
