/*
	Copyright (C) 2015 Johan Mattsson

	This library is free software; you can redistribute it and/or modify 
	it under the terms of the GNU Lesser General Public License as 
	published by the Free Software Foundation; either version 3 of the 
	License, or (at your option) any later version.

	This library is distributed in the hope that it will be useful, but 
	WITHOUT ANY WARRANTY; without even the implied warranty of 
	MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU 
	Lesser General Public License for more details.
*/

#include <assert.h>
#include <glib.h>
#include <stdio.h>
#include <cairo.h>
#include <cairo-ft.h>
#include <stdlib.h>
#include <ft2build.h>
#include FT_FREETYPE_H
#include FT_GLYPH_H

FT_Library freetype_library = NULL;

gboolean draw_overview_glyph (cairo_t* context, const char* font_file, gdouble width, gdouble height, gunichar character) {
	FT_Face face;
	int error;
	gdouble units_per_em;
	gdouble units;
	gdouble advance;
	int gid;

	// private use area
	if (0xe000 <= character && character <= 0xf8ff) {
		return FALSE;
	}
	
	// control characters
	if (character <= 0x001f || (0x007f <= character && character <= 0x008d)) {
		return FALSE;
	}

	gchar text[7];
	int length = g_unichar_to_utf8 (character, text);
	text[length] = '\0';
	
	if (freetype_library == NULL) {
		error = FT_Init_FreeType (&freetype_library);
		if (error) {
			g_warning ("Freetype init error %d.\n", error);
			return FALSE;
		}
	}
	
	error = FT_New_Face (freetype_library, font_file, 0, &face);
	if (error) {
		g_warning ("Freetype font face error %d\n", error);
		return FALSE;
	}

	units_per_em = face->units_per_EM;
	units = (height * 0.5) / units_per_em;
	
	error = FT_Select_Charmap (face , FT_ENCODING_UNICODE);
	if (error) {
		g_warning ("Freetype can not use Unicode, error: %d\n", error);
		FT_Done_Face (face);
		return FALSE;
	}

	error = FT_Set_Char_Size (face, 0, 64, (int) height, (int) height);
	if (error) {
		g_warning ("FT_Set_Char_Size, error: %d.\n", error);
		FT_Done_Face (face);
		return FALSE;
	}
	
	error = FT_Set_Pixel_Sizes (face, 0, (int) (height * 0.5));
	if (error) {
		g_warning ("FT_Set_Pixel_Sizes, error: %d.\n", error);
		FT_Done_Face (face);
		return FALSE;
	}

	gid = FT_Get_Char_Index (face, character);
	advance = 0;
	if (gid != 0) {
		FT_Load_Glyph(face, gid, FT_LOAD_DEFAULT | FT_LOAD_NO_BITMAP | FT_LOAD_NO_SCALE);
		advance = face->glyph->metrics.horiAdvance;
		advance *= units;
	} else {
		FT_Done_Face (face);
		return FALSE;
	}

	static const cairo_user_data_key_t key;

	cairo_save (context);
	
	cairo_font_face_t* cairo_face = cairo_ft_font_face_create_for_ft_face (face, 0);
	
	if (cairo_face == NULL) {
		g_warning("cairo font face is null");
		FT_Done_Face (face);
		return FALSE;
	}
	
	int status = cairo_font_face_set_user_data (cairo_face, &key, face, (cairo_destroy_func_t) FT_Done_Face);
	
	if (status != CAIRO_STATUS_SUCCESS) {		
		cairo_font_face_destroy (cairo_face);
		FT_Done_Face (face);
		return FALSE;
	}

	cairo_set_font_face (context, cairo_face);
	cairo_set_font_size (context, height * 0.5);
	
	gdouble x = (width - advance) / 2;
	
	if (x < 0) {
		x = 0;
	}
	
	cairo_move_to (context, x, height - 30);
	cairo_show_text (context, text);
	
	cairo_font_face_destroy (cairo_face);
	cairo_restore (context);
	
	// cairo closes the font face and the library must be kept open
	
	return TRUE;
}
