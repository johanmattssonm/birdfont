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
#include <glib.h>
#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include <ft2build.h>
#include FT_FREETYPE_H
#include FT_GLYPH_H
#include FT_OPENTYPE_VALIDATE_H
#include FT_TRUETYPE_TABLES_H

/** Error codes. */
#define OK 0

/** Point flags. */
#define QUADRATIC_OFF_CURVE 0
#define ON_CURVE 1
#define CUBIC_CURVE 2
#define DOUBLE_CURVE 4
#define HIDDEN_CURVE 8

/** Convert units per em in font file format to the BirdFont format. */
double get_units (double units_per_em) {
	units_per_em *= (1000.0 / units_per_em) * (10.0 / 3.0);
	return 100.0 / units_per_em;
}

/** @return a non zero value if the point is a part of two off curve 
 * points with a hidden on curve point in between.
 */
guint is_double_curve (char flag) {
	return flag & DOUBLE_CURVE;
}

/** @return a non zero value if the point is a cubic off curve point. */
guint is_cubic (char flag) {
	return flag & CUBIC_CURVE && (flag & ON_CURVE) == 0;
}

/** @return a non zero value if the point is a quadratic off curve point. */
guint is_quadratic (char flag) {
	return (flag & CUBIC_CURVE) == 0 && (flag & ON_CURVE) == 0;
}

/** @return a non zero value if the point is a on curve point */
guint is_line (char flag) {
	return flag & ON_CURVE;
}

/** @return a non zero value if the point is a hidden on curve point */
guint is_hidden (char flag) {
	return flag & HIDDEN_CURVE;
}

/** Convert every second hidden curve to a double curve and keep the 
 * other points as on curve points.
 */ 
void set_double_curves (char* flag, int length) {
	int i;
	guint double_curve = FALSE;
	
	for (i = 1; i < length; i++) {
		if (is_line (flag[i])) {
			double_curve = FALSE;
		} else if (is_hidden (flag[i])) {
			if (!double_curve) {
				if (is_quadratic (flag[i - 1]) && is_quadratic (flag[i + 1])) {
					flag[i - 1] = DOUBLE_CURVE;
					flag[i] = HIDDEN_CURVE;
					flag[i + 1] = DOUBLE_CURVE;
					double_curve = TRUE;
				} else {
					flag[i] = ON_CURVE;
					double_curve = FALSE;
				}
			} else {
				flag[i] = ON_CURVE;
				double_curve = FALSE;
			} 
		}
		// ignore off curve points
	}
}

/** @return half the distance between two points. */
double half_way (double prev, double current) {
	return prev + ((current - prev) / 2.0);
} 

/** Remove hidden points.
 * @return length after removal
 */
double remove_hidden_points (FT_Vector* points, char* flags, guint length, guint capacity) {
	int k;
	int l;
	
	l = 0;
	for (k = 0; k < length; k++) {
		if (!is_hidden (flags[k])) {
			points[l] = points[k];
			flags[l] = flags[k];
			l++;
		}
	}
	
	for (k = l; k < capacity; k++) {
		points[l].x = 0;
		points[l].y = 0;
		flags[l] = 0;	
	}

	return l;
}	

/** Add extra point where two ore more off curve points follow each other. */
void create_contour (guint unicode, FT_Vector* points, char* flags, int* length, FT_Vector** new_points, char** new_flags, int* err) {
	int i;
	int j;
	guint prev_is_curve;
	guint first_is_curve = FALSE;
	guint first_normal_off_curve = FALSE;
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
	
	prev_is_curve = is_quadratic (flags[len - 1]);

	j = 0;
	i = 0;
	
	if (length > 2 && is_quadratic (flags[0]) && is_quadratic (flags[1])) {
		p[j].x = half_way (points[0].x, points[1].x);
		p[j].y = half_way (points[0].y, points[1].y);
						
		f[j] = ON_CURVE;
		prev_is_curve = FALSE;
		first_is_curve = TRUE;
		j++;
		i++;		
	} 
	
	if (length > 2 && is_quadratic (flags[0]) && !is_quadratic (flags[1])) { // first point is of curve but it is not part of a double curve
		first_normal_off_curve = TRUE;
	}
	
	while (i < len) {
		if (is_quadratic (flags[i])) {
			if (prev_is_curve && j != 0) {
				// add a new point if half way between two off curve points
				x = half_way (points[i].x, p[j - 1].x);
				y = half_way (points[i].y, p[j - 1].y);

				p[j].x = x;
				p[j].y = y;
				
				f[j] = HIDDEN_CURVE;

				j++;
			}
			
			f[j] = QUADRATIC_OFF_CURVE;
			prev_is_curve = TRUE;
		} else if (is_line (flags[i])) {
			prev_is_curve = FALSE;
			f[j] = ON_CURVE;
		} else if (is_cubic (flags[i])) {
			prev_is_curve = FALSE;
			f[j] = CUBIC_CURVE;
		} else {
			fprintf (stderr, "WARNING invalid point flags: %d index: %d.\n", flags[i], i);
			prev_is_curve = FALSE;
			f[j] = ON_CURVE;
		}
		
		p[j] = points[i];
		j++;
		i++;
	}

	// last to first point
	if (first_is_curve && !prev_is_curve && is_quadratic (flags[i])) {
		p[j] = points[i];
		f[j] = QUADRATIC_OFF_CURVE;
		j++;
		i++;
		
		p[j].x = half_way (p[j - 1].x, points[0].x);
		p[j].y = half_way (p[j - 1].y, points[0].y);					
		f[j] = ON_CURVE; // FIXME
		prev_is_curve = FALSE;
		j++;
		i++;

		p[j] = points[0];
		f[j] = QUADRATIC_OFF_CURVE;
		j++;
		i++;
						
		p[j] = p[0];
		f[j] = f[0];
		j++;
	} else if (first_is_curve && !prev_is_curve && is_line (flags[i])) {
		p[j] = points[i];
		f[j] = ON_CURVE;
		j++;
		i++;	

		p[j] = points[0];
		f[j] = QUADRATIC_OFF_CURVE;
		j++;
		i++;
		
		p[j] = p[0];
		f[j] = f[0];
		j++;
	} else if (first_is_curve && prev_is_curve && is_quadratic (flags[i])) {
		x = half_way (p[j - 1].x, points[i].x);
		y = half_way (p[j - 1].y, points[i].y);
		p[j].x = x;
		p[j].y = y;
		f[j] = HIDDEN_CURVE;
		j++;

		p[j] = points[i];
		f[j] = flags[i];
		j++;
		i++;

		p[j].x = half_way (p[j - 1].x, points[0].x);
		p[j].y = half_way (p[j - 1].y, points[0].y);					
		f[j] = HIDDEN_CURVE;
		prev_is_curve = FALSE;
		
		j++;
		i++;

		p[j] = points[0];
		f[j] = QUADRATIC_OFF_CURVE;
		j++;
		
		p[j] = p[0];
		f[j] = ON_CURVE;
		j++;

		prev_is_curve = TRUE;
	} else if (prev_is_curve && (flags[0] & ON_CURVE) == 0) {
		if (is_quadratic (f[j - 1]) && is_quadratic (flags[i])) {
			x = half_way (p[j - 1].x, points[i].x); 
			y = half_way (p[j - 1].y, points[i].y);
			p[j].x = x;
			p[j].y = y;
			f[j] = HIDDEN_CURVE;
			j++;
		}

		p[j] = points[i];
		if (is_line (flags[i])) {
			f[j] = ON_CURVE;
		} else {
			f[j] = QUADRATIC_OFF_CURVE;
		}
		j++;		

		if (is_quadratic (f[0]) && is_quadratic (flags[0])) {
			x = half_way (p[j - 1].x, points[0].x);
			y = half_way (p[j - 1].y, points[0].y);
			p[j].x = x;
			p[j].y = y;
			f[j] = HIDDEN_CURVE;
			j++;
		}
		
		x = points[0].x;
		y = points[0].y;

		p[j].x = x;
		p[j].y = y;

		f[j] = QUADRATIC_OFF_CURVE;
		j++;		
	} else if (prev_is_curve && is_quadratic (flags[i])) {
		x = p[j - 1].x + ((points[i].x - p[j - 1].x) / 2.0);
		y = p[j - 1].y + ((points[i].y - p[j - 1].y) / 2.0);
		p[j].x = x;
		p[j].y = y;
		f[j] = HIDDEN_CURVE;
		j++;

		p[j] = points[i];
		f[j] = QUADRATIC_OFF_CURVE;
		j++;
		i++;

		if (is_quadratic (f[0])) {
			x = half_way (p[j - 1].x, points[i].x);
			y = half_way (p[j - 1].y, points[i].y);
			p[j].x = x;
			p[j].y = y;
			f[j] = HIDDEN_CURVE;
			j++;
			
			p[j] = p[0];
			f[j] = f[0];
			j++;
		} else { 
			p[j] = p[0];
			f[j] = f[0];
			j++;
		}
		
		prev_is_curve = TRUE;
	} else {
		p[j] = points[i];
		if (is_quadratic (flags[i])) 
			f[j] = QUADRATIC_OFF_CURVE;
		else 
			f[j] = ON_CURVE;
		j++;

		p[j] = p[0];
		if (is_quadratic (flags[i])) 
			f[j] = QUADRATIC_OFF_CURVE;
		else 
			f[j] = ON_CURVE;
		j++;
	}

	set_double_curves (f, j);
	*length = remove_hidden_points (p, f, j, 2 * len);
}

/** Get path data in .bf format. See BirdFontFile.get_point_data () for 
 * format specification.
 */
GString* get_bf_contour_data (guint unicode, FT_Vector* points, char* flags, int length, double units_per_em, int* err) {
	GString* bf = g_string_new ("");
	GString* contour;
	int i = 0;
	FT_Vector* new_points;
	char* new_flags;
	double x0, x1, x2;
	double y0, y1, y2;
	double units = get_units (units_per_em);
	guint prev_is_curve;
	
	if (length == 0) {
		return bf;
	}
	
	create_contour (unicode, points, flags, &length, &new_points, &new_flags, err);
	
	x0 = new_points[0].x * units;
	y0 = new_points[0].y * units;
	g_string_printf (bf, "S %f,%f", x0, y0); // FIXME: ???

	i = 1;
	while (i < length) {
		contour = g_string_new ("");
		
		if (is_hidden (new_flags[i])) {
			// Skip it
			g_string_printf (contour, "");
			i++;
		} else if (is_cubic (new_flags[i])) {
			x0 = new_points[i].x * units;
			y0 = new_points[i].y * units;
			x1 = new_points[i+1].x * units;
			y1 = new_points[i+1].y * units;
			x2 = new_points[i+2].x * units;
			y2 = new_points[i+2].y * units;
			g_string_printf (contour, " C %f,%f %f,%f %f,%f", x0, y0, x1, y1, x2, y2);
			i += 3;
		} else if (is_double_curve (new_flags[i])) {
			x0 = new_points[i].x * units;
			y0 = new_points[i].y * units;
			x1 = new_points[i+1].x * units;
			y1 = new_points[i+1].y * units;
			x2 = new_points[i+2].x * units;
			y2 = new_points[i+2].y * units;
			g_string_printf (contour, " D %f,%f %f,%f %f,%f", x0, y0, x1, y1, x2, y2);
			i += 3;
		} else if (is_quadratic (new_flags[i])) {
			x0 = new_points[i].x * units;
			y0 = new_points[i].y * units;
			x1 = new_points[i+1].x * units;
			y1 = new_points[i+1].y * units;			
			g_string_printf (contour, " Q %f,%f %f,%f", x0, y0, x1, y1);
			i += 2;
		} else if (is_line (new_flags[i])) {
			x0 = new_points[i].x * units;
			y0 = new_points[i].y * units;
			g_string_printf (contour, " L %f,%f", x0, y0);
			i += 1;
		} else {
			g_string_printf (contour, "");
			fprintf (stderr, "WARNING Can not parse outline.\n");
			*err = 1;
			i++;
		}
		
		g_string_append (bf, contour->str);
		g_string_free (contour, 0);
	}
	
	free (new_points);
	free (new_flags);
	
	return bf;
}

/** Get path element in .bf format. */
GString* get_bf_path (guint unicode, FT_Face face, double units_per_em, int* err) {
	GString* bf = g_string_new ("");
	GString* contour;
	FT_Error error;
	int i;
	int start;
	int end;
	
	if (face->glyph->outline.n_points == 0) {
		return bf;			
	}

	start = 0;
	for (i = 0; i < face->glyph->outline.n_contours; i++) {
		end = face->glyph->outline.contours [i];
		contour = get_bf_contour_data (unicode, face->glyph->outline.points + start, face->glyph->outline.tags + start, end - start, units_per_em, err);
		g_string_append_printf (bf, "\t\t<path data=\"%s\" />\n", contour->str);
		g_string_free (contour, 0);
		start = face->glyph->outline.contours [i] + 1;
	}

	return bf;
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

/** Obtain kerning data in .bf format for one glyph.
 * @param gid glyph id
 */
GString* get_kerning_data (FT_Face face, FT_Long gid) {
	FT_Error error;
	FT_Vector kerning;
	GString* bf = g_string_new ("");
	FT_ULong char_left;
	FT_ULong char_right;
	FT_Long right;
	
	char_left = get_charcode (face, gid);
	
	if (char_left <= 31) {
		fprintf (stderr, "Ignoring kerning for control character.\n");
		return bf;
	}
	
	if (char_left == 0) {
		fprintf (stderr, "No character code could be found for left kerning value.\n");
		return bf;
	}
	
	for (right = 0; right < face->num_glyphs; right++) {
		error = FT_Get_Kerning (face, gid, right, FT_KERNING_UNSCALED, &kerning);
		if (error) {
			fprintf (stderr, "Failed to obtain kerning value.\n");
			break;
		}
		
		char_right = get_charcode (face, right);
		if (char_left == 0) {
			fprintf (stderr, "No character code could be found for right kerning value.\n");
			return bf;
		}

		if (kerning.x > 0 && char_left > 31) {
			g_string_append_printf (bf, "<hkern left=\"U+%x;\" right=\"U+%x;\" kerning=\"%d\"/>\n", char_left, char_right, kerning.x);
		}
	}
	
	return bf;
}

/** Convert font to bf format.
 * @param face freetype font face
 * @param err error code
 * @return xml representation of a bf font
 */
GString* get_bf_font (FT_Face face, char* file, int* err) {
	GString* bf = g_string_new ("");
	GString* bf_data;
	GString* hkern;
	GString* glyph;
	FT_Error error;
	FT_Long i;
	FT_ULong charcode;
	double units_per_em;
	double units;
	
	*err = OK;

	units_per_em = face->units_per_EM;
	units = get_units (units_per_em);
	
	g_string_append (bf, "<?xml version=\"1.0\" encoding=\"utf-8\" standalone=\"yes\"?>\n");
	
	// libxml2 fails on doctype declaration in windows.
		
	// TODO: load from font
	g_string_append (bf, "<font>\n");

	g_string_append_printf (bf, "<name>%s</name>\n", face->family_name);
	g_string_append_printf (bf, "<backup>%s</backup>\n", file);

	g_string_append_printf (bf, "<lines>\n");
	g_string_append_printf (bf, "\t<top_limit>-66</top_limit>\n");
	g_string_append_printf (bf, "\t<top_position>%f</top_position>\n", -face->ascender * units);
	g_string_append_printf (bf, "\t<x-height>-38</x-height>\n");
	g_string_append_printf (bf, "\t<base_line>0</base_line>\n");
	g_string_append_printf (bf, "\t<bottom_position>%f</bottom_position>\n", -face->descender * units);
	g_string_append_printf (bf, "\t<bottom_limit>45</bottom_limit>\n");		
	g_string_append_printf (bf, "</lines>\n");

	// glyph outlines
	for (i = 0; i < face->num_glyphs; i++) {
		error = FT_Load_Glyph (face, i, FT_LOAD_DEFAULT);
		if (error) {
			fprintf (stderr, "Freetype failed to load glyph %d.\n", (int)i);
			fprintf (stderr, "FT_Load_Glyph error %d\n", error);
			*err = error;
			return bf;
		}

		if (face->glyph->format != ft_glyph_format_outline) {
			fprintf (stderr, "Freetype error no outline found in glyph.\n");
			*err = 1;
			return bf;
		}

		charcode = get_charcode (face, i);
		glyph = g_string_new ("");
						
		if (charcode > 31) { // if not control character
			g_string_append_printf (glyph, "<collection unicode=\"U+%x\">\n", (guint)charcode);
			g_string_append_printf (glyph, "\t<glyph left=\"%f\" right=\"%f\" selected=\"true\">\n", 0.0, face->glyph->metrics.horiAdvance * units);

			bf_data = get_bf_path (charcode, face, units_per_em, err);
			g_string_append (glyph, bf_data->str);	
			
			g_string_append (glyph, "\t</glyph>\n");
			g_string_append_printf (glyph, "</collection>\n");
		}

		g_string_append (bf, glyph->str);
		g_string_free (glyph, 0);		
		bird_font_progress_bar_set_progress ((double)i / face->num_glyphs);
	}

	// kerning
	for (i = 0; i < face->num_glyphs; i++) {
		hkern = get_kerning_data (face, i);
		g_string_append (bf, hkern->str);
		g_string_free (hkern, 0);
		bird_font_progress_bar_set_progress ((double)(face->num_glyphs - i) / face->num_glyphs);
	}

	g_string_append (bf, "</font>\n");
	
	return bf;
}

int validate_font (FT_Face face) {
	// these tables can be validated
	const FT_Byte* BASE_table = NULL; 
	const FT_Byte* GDEF_table = NULL;
	const FT_Byte* GPOS_table = NULL;
	const FT_Byte* GSUB_table = NULL;
	const FT_Byte* JSTF_table = NULL;
	int error;

	error = FT_OpenType_Validate (face, FT_VALIDATE_BASE | FT_VALIDATE_GDEF | FT_VALIDATE_GPOS | FT_VALIDATE_GSUB | FT_VALIDATE_JSTF, &BASE_table, &GDEF_table, &GPOS_table, &GSUB_table, &JSTF_table);

	if (error) {
		fprintf (stderr, "Freetype validation error %d\n", error);
		return error;
	} 
	
	FT_OpenType_Free (face, BASE_table);
	FT_OpenType_Free (face, GDEF_table);
	FT_OpenType_Free (face, GPOS_table);
	FT_OpenType_Free (face, GSUB_table);
	FT_OpenType_Free (face, JSTF_table);
	
	return error;
}

/** Load typeface with freetype2 and return the result as a bf font. 
 *  Parameter err will be set to non zero vaule if an error occurs.
 */
GString* load_freetype_font (char* file, int* err) {
	GString* bf = NULL;

	FT_Library library;
	FT_Face face;
	int error;
	FT_Glyph glyph;
	FT_UInt glyph_index;

	error = FT_Init_FreeType (&library);
	if (error != OK) {
		fprintf (stderr, "Freetype init error %d.\n", error);
		*err = error;
		return bf;
	}

	error = FT_New_Face (library, file, 0, &face);
	if (error) {
		fprintf (stderr, "Freetype font face error %d\n", error);
		*err = error;
		return bf;
	}

	error = FT_Set_Char_Size (face, 0, 800, 300, 300);
	if (error) {
		fprintf (stderr, "Freetype FT_Set_Char_Size failed, error: %d.\n", error);
		*err = error;
		return bf;
	}

	bf = get_bf_font (face, file, &error);
	if (error != OK) {
		fprintf (stderr, "Failed to parse font.\n");
		*err = error;
		return bf;	
	}

	FT_Done_Face ( face );
	FT_Done_FreeType( library );
	
	*err = OK;
	return bf;
}

/** Validate font a font with FreeType */
guint validate_freetype_font (char* file) {
	FT_Library library;
	FT_Face face;
	int error;
	
	error = FT_Init_FreeType (&library);
	if (error != OK) {
		fprintf (stderr, "Freetype init error %d\n", error);
		return FALSE;
	}

	error = FT_New_Face (library, file, 0, &face);
	if (error) {
		fprintf (stderr, "Freetype font face error %d\n", error);
		return FALSE;
	}
		
	error = validate_font (face);
	if (error) {
		fprintf (stderr, "Validation failed.\n", error);
		return FALSE;
	}

	FT_Done_Face ( face );
	FT_Done_FreeType( library );
	
	return TRUE;
}
