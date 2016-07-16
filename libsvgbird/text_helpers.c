#include <stdlib.h>
#include <glib.h>
#include <stdio.h>
#include <math.h>
#include <harfbuzz/hb.h>
#include <harfbuzz/hb-ft.h>
#include <cairo.h>
#include <cairo-ft.h>

#define FONT_SIZE 36
#define MARGIN (FONT_SIZE * .5)

typedef struct svg_bird_font_item_t {
	int font_size;
	FT_Library ft_library;
	FT_Face ft_face;
	hb_font_t *hb_font;
} svg_bird_font_item;

svg_bird_font_item* svg_bird_font_item_create (const char* font_file, int font_size) {
	FT_Error ft_error;

	svg_bird_font_item* font = malloc (sizeof (svg_bird_font_item));

	font->font_size = font_size;

	if ((ft_error = FT_Init_FreeType (&font->ft_library))) {
		g_warning ("Can't init freetype");
		return NULL;
	}
	
	if ((ft_error = FT_New_Face (font->ft_library, font_file, 0, &font->ft_face))) {
		g_warning ("Can't init freetype font.");
		return NULL;
	}
	
	if ((ft_error = FT_Set_Char_Size (font->ft_face, font_size * 64, font_size * 64, 0, 0)))  {
		g_warning ("Can't set font size.");
		return NULL;
	}

	font->hb_font = hb_ft_font_create (font->ft_face, NULL);

}

void svg_bird_font_item_delete (svg_bird_font_item* item) {
	if (item != NULL) {
		FT_Done_Face (item->ft_face);
		FT_Done_FreeType (item->ft_library);
		hb_font_destroy (item->hb_font);
		free (item);
	}
}

void svg_bird_draw_text (cairo_t* cr, svg_bird_font_item* font, const char* text) {
	cairo_save (cr);
	
	hb_buffer_t *hb_buffer;	

	hb_buffer = hb_buffer_create ();
	hb_buffer_add_utf8 (hb_buffer, text, -1, 0, -1);
	hb_buffer_guess_segment_properties (hb_buffer);

	hb_shape (font->hb_font, hb_buffer, NULL, 0);

	unsigned int len = hb_buffer_get_length (hb_buffer);
	hb_glyph_info_t *info = hb_buffer_get_glyph_infos (hb_buffer, NULL);
	hb_glyph_position_t *pos = hb_buffer_get_glyph_positions (hb_buffer, NULL);
	
	double current_x = 0;
	double current_y = 0;
	for (unsigned int i = 0; i < len; i++) {
		hb_codepoint_t gid   = info[i].codepoint;
		unsigned int cluster = info[i].cluster;
		double x_position = current_x + pos[i].x_offset / 64.;
		double y_position = current_y + pos[i].y_offset / 64.;
		
		current_x += pos[i].x_advance / 64.;
		current_y += pos[i].y_advance / 64.;
	}

	double width = 0;
	double height = 0;
	for (unsigned int i = 0; i < len; i++) {
		width  += pos[i].x_advance / 64.;
		height -= pos[i].y_advance / 64.;
	}
	
	if (HB_DIRECTION_IS_HORIZONTAL (hb_buffer_get_direction(hb_buffer)))
		height += font->font_size;
	else
		width += font->font_size;

	cairo_font_face_t *cairo_face;
	cairo_face = cairo_ft_font_face_create_for_ft_face (font->ft_face, 0);
	cairo_set_font_face (cr, cairo_face);
	cairo_set_font_size (cr, font->font_size);

	if (HB_DIRECTION_IS_HORIZONTAL (hb_buffer_get_direction(hb_buffer))) {
		cairo_font_extents_t font_extents;
		cairo_font_extents (cr, &font_extents);
		double baseline = (font->font_size - font_extents.height) * .5 + font_extents.ascent;
		cairo_translate (cr, 0, baseline);
	} else {
		cairo_translate (cr, font->font_size * .5, 0);
	}
	
	cairo_glyph_t *cairo_glyphs = cairo_glyph_allocate (len);
	current_x = 0;
	current_y = 0;
	
	cairo_matrix_t matrix;
	cairo_get_matrix (cr, &matrix);
	cairo_matrix_invert (&matrix);
	
	for (unsigned int i = 0; i < len; i++) {
		cairo_glyphs[i].index = info[i].codepoint;
		cairo_glyphs[i].x = current_x + pos[i].x_offset / 64.;
		cairo_glyphs[i].y = -(current_y + pos[i].y_offset / 64.);
		
		double dx = pos[i].x_advance / 64.0;
		double dy = pos[i].y_advance / 64.0;
		
		cairo_matrix_transform_distance (&matrix, &dx, &dy);
		
		current_x += dx;
		current_y += dy;
	}
	
	cairo_show_glyphs (cr, cairo_glyphs, len);
	cairo_glyph_free (cairo_glyphs);

	cairo_font_face_destroy (cairo_face);

	hb_buffer_destroy (hb_buffer);
	cairo_restore (cr);
}
