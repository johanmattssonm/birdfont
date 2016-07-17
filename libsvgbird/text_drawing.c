#include <stdlib.h>
#include <glib.h>
#include <stdio.h>
#include <math.h>
#include <harfbuzz/hb.h>
#include <harfbuzz/hb-ft.h>
#include <cairo.h>
#include <cairo-ft.h>
 
static GMutex font_config_lock;
FcConfig* font_config = NULL; 

typedef struct svg_bird_font_item_t {
	int font_size;
	FT_Library ft_library;
	FT_Face ft_face;
	hb_font_t *hb_font;
} svg_bird_font_item;

gchar* svg_bird_find_font_file (const gchar* font_name);
void svg_bird_font_item_delete (svg_bird_font_item* item);

void svg_bird_get_extent (svg_bird_font_item* font, const char* text, double* width, double* height) {
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
		double x_position = current_x + pos[i].x_offset / 64.;
		double y_position = current_y + pos[i].y_offset / 64.;
 		
		current_x += pos[i].x_advance / 64.;
		current_y += pos[i].y_advance / 64.;
	}

	*width = current_x;
	*height = current_y;

	if (HB_DIRECTION_IS_HORIZONTAL (hb_buffer_get_direction(hb_buffer))) {
		*height += font->font_size * 1.25;
	} else {
		*width += font->font_size * 1.25;
	}
}

gboolean svg_bird_has_font_config () {
	g_mutex_lock (&font_config_lock);
	gboolean exists = font_config != NULL;
	g_mutex_unlock (&font_config_lock);
	return exists;
}

void svg_bird_set_font_config (FcConfig* f) {
	g_mutex_lock (&font_config_lock);
	font_config = f;
	g_mutex_unlock (&font_config_lock);
}

svg_bird_font_item* svg_bird_font_item_create (const char* font_family, int font_size) {
	FT_Error ft_error;
	svg_bird_font_item* font = malloc (sizeof (svg_bird_font_item));
	memset (font, 0, sizeof (svg_bird_font_item));
 
	char* font_file = svg_bird_find_font_file (font_family);

	FT_Library ft_library = 0;
	FT_Face ft_face = 0;
	
	font->font_size = font_size;
	if ((ft_error = FT_Init_FreeType (&ft_library))) {
		g_warning ("Can't init freetype");
		svg_bird_font_item_delete (font);
		return NULL;
 	}
 	
 	font->ft_library = ft_library;
 	
	if ((ft_error = FT_New_Face (font->ft_library, font_file, 0, &ft_face))) {
		g_warning ("Can't find freetype font %s %s.", font_family, font_file);
		svg_bird_font_item_delete (font);
		return NULL;
 	}
 	
 	font->ft_face = ft_face;
 	
	if ((ft_error = FT_Set_Char_Size (font->ft_face, font_size * 64, font_size * 64, 0, 0)))  {
		g_warning ("Can't set font size.");
		svg_bird_font_item_delete (font);
		return NULL;
	}

	font->hb_font = hb_ft_font_create (font->ft_face, NULL);

	if (font->hb_font == NULL) {
		g_warning ("Can't create harfbuzz font for %s", font_file);
		svg_bird_font_item_delete (font);
		return NULL;
	}

	free (font_file);
	return font;
}

void svg_bird_font_item_delete (svg_bird_font_item* item) {
	if (item) {
		if (item->ft_face) {
			FT_Done_Face (item->ft_face);
		}

		if (item->hb_font) {
			hb_font_destroy (item->hb_font);
		}
		
		if (item->ft_library) {
			FT_Done_FreeType (item->ft_library);
		}
				
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
	
	cairo_font_face_t *cairo_face;
	cairo_face = cairo_ft_font_face_create_for_ft_face (font->ft_face, 0);
	cairo_set_font_face (cr, cairo_face);
	cairo_set_font_size (cr, font->font_size);

	cairo_font_extents_t font_extents;
	cairo_font_extents (cr, &font_extents);

	if (HB_DIRECTION_IS_HORIZONTAL (hb_buffer_get_direction(hb_buffer))) {
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

gchar* svg_bird_find_font_file (const gchar* font_name) {
	const FcChar8* name;
	FcPattern* search_pattern;
	FcPattern* font;
	FcChar8* file;
	gchar* path;
	FcObjectSet* font_properties;
	FcFontSet* fonts;
	int i;
	
	if (!svg_bird_has_font_config ()) {
		g_warning("Font config not loaded.");
		return NULL;
	}

	g_mutex_lock (&font_config_lock);

	if (font_config == NULL) {
		g_warning("Font config not loaded.");
		return NULL;
	}
	
	path = NULL;
	name = font_name;

	// match any font as fallback
	search_pattern = FcPatternCreate ();
	font_properties = FcObjectSetBuild (FC_FILE, NULL);

	fonts = FcFontList (font_config, search_pattern, font_properties);
	
	if (fonts->nfont > 0) {
		for (i = 0; i < fonts->nfont; i++) {
			font = fonts->fonts[i];
			
			if (FcPatternGetString(font, FC_FILE, 0, &file) == FcResultMatch) {
				path = g_strdup ((gchar*) file);
				break;
			}
			
			FcPatternDestroy (font);
		}
	}
	
	FcPatternDestroy (search_pattern);
	
	// search for a family name
	search_pattern = FcPatternCreate ();
	FcPatternAddString (search_pattern, FC_FAMILY, name);
	fonts = FcFontList (font_config, search_pattern, font_properties);
	
	if (fonts->nfont > 0) {
		for (i = 0; i < fonts->nfont; i++) {
			font = fonts->fonts[i];
			
			if (FcPatternGetString(font, FC_FILE, 0, &file) == FcResultMatch) {
				g_free (path);
				path = g_strdup ((gchar*) file);
				break;
			}
			
			FcPatternDestroy (font);
		}
	}

	FcPatternDestroy (search_pattern);
	
	g_mutex_unlock (&font_config_lock);
	return path;
}
