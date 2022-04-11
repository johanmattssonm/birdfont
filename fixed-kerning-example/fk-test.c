/*
 * This is example code. Using this code in any project with any license is permitted.
 * Author: Johan Mattsson
 */
#include <assert.h>
#include "fk.h"
#include "fk-font-editor.h"

uint8_t* read_content (const char* file_name, size_t* buffer_size) {
   FILE* file;
   file = fopen (file_name, "rb");
   assert(file);
   
   fseek (file, 0, SEEK_END);
   size_t size = ftell (file);
   *buffer_size = size;
   rewind (file);
   
   uint8_t* table_buffer = (uint8_t*) malloc(size);
   assert (table_buffer);
   
   fread (table_buffer, size, sizeof (uint8_t), file);
   fclose (file);

   return table_buffer;
}

int test_write () {
   FILE* file;
   uint32_t num_pairs = 10;
   
   file = fopen ("fixedkerningtable.test", "wb");

   fk_write_fixed_kerning_table_header (file, num_pairs);
   
   for (uint32_t i = 0; i < num_pairs; i++) {
      uint32_t gid1 = i;
      uint32_t gid2 = i;
      double kerning = -0.2;

      gid1 = 0x45678abc;
      gid2 = 0x6EEEEEE2 + i;

      // all entries needs to be sorted on gid1 and gid2.
      fk_write_fixed_kerning_entry (file, gid1, gid2, kerning);
   }

   fclose (file);
   return 0;
}

void test_datatypes () {
   FILE* file;
   file = fopen ("basic.test", "wb");

   fk_write_u16 (file, 0x1234);
   fk_write_u32 (file, 0x567abcde);

   fclose (file);

   uint8_t* table_buffer = NULL;
   size_t buffer_size;
   table_buffer = read_content ("basic.test", &buffer_size);

   assert (fk_get_uint16 (table_buffer, buffer_size, 0) == 0x1234);
   assert (fk_get_uint32 (table_buffer, buffer_size, 2) == 0x567abcde);

   free (table_buffer);
}

void test_fixed_conversion () {
   Fixed16_16 f;
   double d;

   int32_t x = 0xffffcccc;
   assert (x == 0xffffcccc);

   f = fk_double_to_fixed (-0.2);
   assert (f == 0xffffcccc);

   f = fk_double_to_fixed (-0.1);
   assert (f == 0xffffe666);

   d = fk_fixed_to_double (0xffffcccc);
   assert ((int) (d * 1000) == -200);

   d = fk_fixed_to_double (0xffffe666);
   assert ((int) (d * 1000) == -100);
}

void test_read_all () {
   FILE* file;
   uint8_t* table_buffer = NULL;
   size_t buffer_size;
   uint32_t num_pairs;
   
   table_buffer = read_content ("fixedkerningtable.test", &buffer_size);
   
   bool has_data = fk_has_fixed_kerning (table_buffer, buffer_size);
   assert (has_data);
   
   num_pairs = fk_get_num_kerning_pairs(table_buffer, buffer_size);
   assert (num_pairs > 0);
   
   printf ("Table size : %zu\n", buffer_size);
   printf ("List all kerning pairs in table. Number of pairs: %d\n", num_pairs);
   
   for (uint32_t i = 0; i < num_pairs; i++) {
      uint32_t gid1 = 0;
      uint32_t gid2 = 0;
      Fixed16_16 kern = 0;
      
      fk_get_fixed_kerning_by_index (table_buffer, buffer_size, i, &gid1, &gid2, &kern);
      
      Fixed16_16 fixed_kerning;
      fixed_kerning = fk_get_fixed_kerning (table_buffer, buffer_size, gid1, gid2);
      double kerning = fk_fixed_to_double (fixed_kerning);
      
      printf ("Kerning for gid1: %d and gid2: %d, kerning %4.4f, (raw fixed: %d)\n", gid1, gid2, kerning, fixed_kerning);
      assert (kern == fixed_kerning);
   }
   
   printf ("Total pairs %d\n\n", num_pairs);
   
   free (table_buffer);
}

void test_order () {  
   uint8_t* table_buffer = NULL;
   size_t buffer_size;
   uint32_t num_pairs;
   
   table_buffer = read_content ("fixedkerningtable.test", &buffer_size);
   
   bool has_data = fk_has_fixed_kerning (table_buffer, buffer_size);
   assert (has_data);
   
   num_pairs = fk_get_num_kerning_pairs(table_buffer, buffer_size);
   assert (num_pairs > 0);
   
   uint32_t read_index = FIXED_KERNING_HEADER_SIZE;
   
   uint32_t last_gid1 = 0;
   uint32_t last_gid2 = 0;
   
   for (uint32_t i = 0; i < num_pairs; i++) {
      uint32_t gid1 = fk_get_uint32 (table_buffer, buffer_size, read_index);
      read_index += sizeof (uint32_t);

      uint32_t gid2 = fk_get_uint32 (table_buffer, buffer_size, read_index);
      read_index += sizeof (uint32_t);

      Fixed16_16 kern = fk_get_uint32 (table_buffer, buffer_size, read_index);
      read_index += sizeof (uint32_t);

      double kerning = fk_fixed_to_double (kern);

      printf ("Row: %d gid1: %x, gid2 %x, kerning: %.4f (raw kerning %d)\n", i, gid1, gid2, kerning, kern);

      bool is_sorted = false;

      if (gid1 != last_gid1) {
         is_sorted = gid1 >= last_gid1;
         last_gid2 = 0;
      } else {
         is_sorted = gid2 >= last_gid2;
      }
       
      last_gid1 = gid1;
      last_gid2 = gid2;

      assert (is_sorted);
      assert (gid1 == 0x45678abc);
      assert (gid2 == 0x6EEEEEE2 + i);
   }
   
   printf ("Total pairs %d\n\n", num_pairs);

   free (table_buffer);
}

int main () {
   test_fixed_conversion ();
   test_datatypes ();
   test_write ();
   test_read_all ();
   test_order ();
   return 0;
}
