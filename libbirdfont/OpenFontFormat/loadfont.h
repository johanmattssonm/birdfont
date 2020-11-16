#include <glib.h>
#include <ft2build.h>
#include FT_FREETYPE_H
#include FT_GLYPH_H
#include FT_OPENTYPE_VALIDATE_H
#include FT_TRUETYPE_TABLES_H
#include FT_SFNT_NAMES_H

#ifndef LOADFONT_H
#define LOADFONT_H 1

typedef struct FreeTypeFontFace {
	FT_Face face;
	FT_Library library;
} FreeTypeFontFace;

void close_ft_font (FreeTypeFontFace* font);

GString* load_glyph (FreeTypeFontFace* font, guint unicode);
GString* load_freetype_font (const gchar* file, int* err);

FreeTypeFontFace* open_font (const gchar* file);

gulong* get_all_unicode_points_in_font (const gchar* file);
gboolean freetype_has_glyph (FreeTypeFontFace* font, guint unicode);
gboolean get_freetype_font_is_regular (const char* file);
#endif