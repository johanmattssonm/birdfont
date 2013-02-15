/*
    Copyright (C) 2013 Johan Mattsson

    This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program.  If not, see <http://www.gnu.org/licenses/>.
*/

#include <assert.h>
#include <stdio.h>
#include <string.h>
#include <stdlib.h>

#include <ft2build.h>
#include FT_FREETYPE_H
#include FT_GLYPH_H
#include FT_OPENTYPE_VALIDATE_H
#include FT_TRUETYPE_TABLES_H

#include <glib.h>

/** Error codes. */
#define OK 0

/** Point flags. */
#define ON_CURVE 1
#define CUBIC_CURVE 2
#define QUADRATIC_OFF_CURVE 0

uint is_cubic (char* flags, int index, int len) {
	return flags[index] & CUBIC_CURVE && (flags[index] & ON_CURVE) == 0;
}

uint is_quadratic (char* flags, int index, int len) {
	return (flags[index] & CUBIC_CURVE) == 0 && (flags[index] & ON_CURVE) == 0;
}

uint is_line (char* flags, int index, int len) {
	return flags[index] & ON_CURVE;
}

/** Add extra point where two ore more off curve points follow each other. */
void create_contour (FT_Vector* points, char* flags, int* length, FT_Vector** new_points, char** new_flags, int* err) {
	int i;
	int j;
	uint prev_is_curve;
	double x = 0;
	double y = 0;
	FT_Vector* p;
	char* f;
	int len = *length;
	
	*new_points = malloc (4 * len * sizeof (FT_Vector));
	*new_flags = malloc (4 * len * sizeof (char));
	
	p = *new_points;
	f = *new_flags;
	
	for (i = 0; i < 4 * len; i++) {
		p[i].x = 0;
		p[i].y = 0;
		f[i] = 0;
	}
	
	if (len == 0) {
		return;
	}
	
	prev_is_curve = is_quadratic (points, len - 1, len);
	
	if (is_quadratic (flags, 0, len)) {
		printf ("WARNING: path begins at off curve point.");
	} 

	// FIXME: What if first and last point is off curve?
	
	j = 0;
	for (i = 0; i < len; i++) {
		if (is_quadratic (flags, i, len)) {
			if (prev_is_curve && j != 0) { // i == 0?
				x = p[j - 1].x + ((points[i].x - p[j - 1].x) / 2.0);
				y = p[j - 1].y + ((points[i].y - p[j - 1].y) / 2.0);

				p[j].x = x;
				p[j].y = y;
				f[j] = ON_CURVE;
				j++;
			}
			
			prev_is_curve = TRUE;
		} else if (is_line (flags, i, len)) {
			prev_is_curve = FALSE;
		} else if (is_cubic (flags, i, len)) {
			prev_is_curve = TRUE;
		} else {
			printf ("WARNING invalid point flags: %d index: %d.\n", flags[i], i);
			prev_is_curve = TRUE;
		}
		
		p[j] = points[i];
		f[j] = flags[i];
		j++;
	}
	
	// last to first
	if (prev_is_curve) { // j == 0?
		x = p[j - 1].x + ((points[i].x - p[j - 1].x) / 2.0);
		y = p[j - 1].y + ((points[i].y - p[j - 1].y) / 2.0);
		p[j].x = x;
		p[j].y = y;
		f[j] = ON_CURVE;
		j++;

		p[j] = points[i];
		f[j] = QUADRATIC_OFF_CURVE;
		j++;
		i++;
				
		x = p[j - 1].x + ((p[0].x - p[j - 1].x) / 2.0);
		y = p[j - 1].y + ((p[0].y - p[j - 1].y) / 2.0);
		p[j].x = x;
		p[j].y = y;
		f[j] = ON_CURVE;
		j++;

		prev_is_curve = TRUE;
	} else {
		p[j] = points[i];
		f[j] = flags[i];
		j++;

		p[j] = p[0];
		f[j] = f[0];
	}

	*length = j;	
}

GString* get_svg_contour_data (FT_Vector* points, char* flags, int length, int* err) {
	GString* svg = g_string_new ("");
	GString* contour;
	int i = 0;
	FT_Vector* new_points;
	char* new_flags;
	 
	if (length == 0) {
		return svg;
	}
	
	create_contour (points, flags, &length, &new_points, &new_flags, err);
	
	g_string_printf (svg, "M %d,%d ", (int)new_points[length-1].x, (int)new_points[length-1].y); // FIXME: ????

	i = 0;
	while (i < length) {
		contour = g_string_new ("");
		
		if (is_cubic (new_flags, i, length)) {
			g_string_printf (contour, "C %d,%d  %d,%d  %d,%d ", (int)new_points[i].x, (int)new_points[i].y, (int)new_points[i+1].x, (int)new_points[i+1].y, (int)new_points[i+2].x, (int)new_points[i+2].y);
			i += 3;
		} else if (is_quadratic (new_flags, i, length)) {
			g_string_append_printf (contour, "Q %d,%d %d,%d ", (int)new_points[i].x, (int)new_points[i].y, (int)new_points[i+1].x, (int)new_points[i+1].y);	
			i += 2;
		} else if (is_line (new_flags, i, length)) {
			g_string_printf (contour, "L %d,%d ", (int)new_points[i].x, (int)new_points[i].y);
			i += 1;
		} else {
			printf ("WARNING Can not parse outline.\n");
			err = 1;
		}
		
		g_string_append (svg, contour->str);
		g_string_free (contour, 0);
	}
	
	g_string_append (svg, "z");
	
	free (new_points);
	free (new_flags);
	
	return svg;
}

GString* get_svg_glyph_data (FT_Face face, int* err) {
	GString* svg = g_string_new ("");
	GString* contour;
	FT_Error error;
	int i;
	int start;
	int end;
	
	if (face->glyph->outline.n_points == 0) {
		printf ("Freetype error no points for outline in glyph.\n"); // FIXME: DELETE
		return svg;			
	}

	start = 0;
	for (i = 0; i < face->glyph->outline.n_contours; i++) {
		end = face->glyph->outline.contours [i];
		contour = get_svg_contour_data (face->glyph->outline.points + start, face->glyph->outline.tags + start, end - start, err);
		g_string_append (svg, contour->str);
		g_string_free (contour, 0);
		start = face->glyph->outline.contours [i] + 1;
	}

	return svg;
}

/** Get char code for a glyph.
 * @gid glyph id
 * @return character code
 */
FT_ULong get_charcode (FT_Face face, FT_UInt gid) {
	FT_ULong charcode;
	FT_UInt gindex;
	
	// TODO: find the lookup function in freetype
	
	charcode = FT_Get_First_Char (face, &gindex);
	while (gindex != 0) {
		charcode = FT_Get_Next_Char (face, charcode, &gindex);
		if (gindex == gid) {
			return charcode;			
		}
	}
	
	return 0;
}

GString* get_svg_font (FT_Face face, int* err) {
	GString* svg = g_string_new ("");
	GString* svg_data;
	GString* font_element = g_string_new ("");
	GString* glyph_element;
	FT_Error error;
	FT_Long i;
	FT_ULong charcode;

	*err = OK;
	
	g_string_append (svg, "<?xml version=\"1.0\" standalone=\"no\"?>\n");
	g_string_append (svg, "<!DOCTYPE svg PUBLIC \"-//W3C//DTD SVG 1.1//EN\" \"http://www.w3.org/Graphics/SVG/1.1/DTD/svg11.dtd\" >\n");
	g_string_append (svg, "<svg xmlns=\"http://www.w3.org/2000/svg\">\n");
	g_string_append (svg, "<defs>\n");
	g_string_append_printf (svg, "<font id=\"%s\" horiz-adv-x=\"250\">\n", face->family_name);

	g_string_printf (font_element, "<font-face units-per-em=\"%d\" ascent=\"%d\" descent=\"%d\" />\n", (int) face->units_per_EM, (int) face->ascender, (int) face->descender);	
	g_string_append (svg, font_element->str);
	
	for (i = 0; i < face->num_glyphs; i++) {
		error = FT_Load_Glyph (face, i, FT_LOAD_DEFAULT);
		if (error) {
			printf ("Freetype failed to load glyph %d.\n", i);
			printf ("FT_Load_Glyph error %d\n", error);
			*err = error;
			return svg;
		}

		charcode = get_charcode (face, i);
		glyph_element = g_string_new ("<glyph ");
		
		if (charcode != 0) {
			g_string_append (glyph_element,"unicode=\"&#x");
			g_string_append_printf (glyph_element, "%x", (uint)charcode);
			g_string_append (glyph_element, ";\" ");
		}
		
		g_string_append_printf (glyph_element, "horiz-adv-x=\"%d\" ", (int)face->glyph->metrics.horiAdvance);
		g_string_append (svg, glyph_element->str);
		g_string_free (glyph_element, 0);
		
		g_string_append (svg, "d=\"");
				
		if (face->glyph->format != ft_glyph_format_outline) {
			printf ("Freetype error no outline found in glyph.\n");
			*err = 1;
			return svg;
		}

		svg_data = get_svg_glyph_data (face, err);
		g_string_append (svg, svg_data->str);
		
		g_string_append (svg, "\" />\n");
	}

	g_string_append (svg, "</font>\n");
	g_string_append (svg, "</defs>\n");
	g_string_append (svg, "</svg>");
	
	g_string_free (font_element, 0);
	
	return svg;
}

int validate_font (FT_Face face) {
	// these tables can be validated
	const FT_Byte* BASE_table = NULL; 
	const FT_Byte* GDEF_table = NULL;
	const FT_Byte* GPOS_table = NULL;
	const FT_Byte* GSUB_table = NULL;
	const FT_Byte* JSTF_table = NULL;
	int error = OK;

	error = FT_OpenType_Validate (face, FT_VALIDATE_BASE | FT_VALIDATE_GDEF | FT_VALIDATE_GPOS | FT_VALIDATE_GSUB | FT_VALIDATE_JSTF, &BASE_table, &GDEF_table, &GPOS_table, &GSUB_table, &JSTF_table);

	if (error) {
		printf ("Freetype validation error %d\n", error);
		return error;
	} 
	
	FT_OpenType_Free (face, BASE_table);
	FT_OpenType_Free (face, GDEF_table);
	FT_OpenType_Free (face, GPOS_table);
	FT_OpenType_Free (face, GSUB_table);
	FT_OpenType_Free (face, JSTF_table);
	
	return error;
}

/** Load typeface with freetype2 and return the result as a SVG font. 
 *  Parameter err will be set to non zero vaule if an error occurs.
 */
GString* load_svg_font (char* file, int* err) {
	GString* svg = NULL;

	FT_Library library;
	FT_Face face;
	int error;
	FT_Glyph glyph;
	FT_UInt glyph_index;

	error = FT_Init_FreeType (&library);
	if (error != OK) {
		printf ("Freetype init error %d\n", error);
		*err = error;
		return svg;
	}

	error = FT_New_Face (library, file, 0, &face);
	if (error) {
		printf ("Freetype font face error %d\n", error);
		*err = error;
		return svg;
	}

	error = validate_font (face);
	if (error) {
		*err = error;
		return svg;
	}

	error = FT_Set_Char_Size (face, 0, 800, 300, 300);
	if (error) {
		printf ("Freetype FT_Set_Char_Size failed, error: %d.\n", error);
		*err = error;
		return svg;
	}

	svg = get_svg_font (face, &error);
	if (error != OK) {
		printf ("Failed to parse font.\n");
		*err = error;
		return svg;	
	}

	FT_Done_Face ( face );
	FT_Done_FreeType( library );
	
	*err = OK;
	return svg;
}
