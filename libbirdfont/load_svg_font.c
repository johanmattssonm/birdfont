#include <assert.h>
#include <stdio.h>
#include <string.h>
#include <stdlib.h>

#include <ft2build.h>
#include FT_FREETYPE_H
#include FT_GLYPH_H
#include FT_OPENTYPE_VALIDATE_H
#include FT_TRUETYPE_TABLES_H

#define OK 0

char* get_svg_font (FT_Face face, int* err) {
	char* svg = (char*) malloc (2 * sizeof (char));
	*err = 	OK;
	
	// TODO: parse the file.
	
	return svg;
}

int validate_font (FT_Face face) {
	// these tables can be validated
	const FT_Byte *BASE_table = NULL; 
	const FT_Byte *GDEF_table = NULL;
	const FT_Byte *GPOS_table = NULL;
	const FT_Byte *GSUB_table = NULL;
	const FT_Byte *JSTF_table = NULL;
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

/** Load typeface and return the result as a SVG font. 
 *  Parameter err will be set to non zero vaule if an error occurs.
 */
char* load_svg_font (char* file, int* err) {
	char* svg = NULL;

	FT_Library library;
	FT_Face face;
	FT_Error error;
	FT_Glyph glyph;
	FT_UInt glyph_index;

	error = FT_Init_FreeType (&library);
	if (error != OK) {
		printf ("Freetype init error %d\n", error);
		*err = error;
		return svg;
	}

	error = FT_New_Face (library, "FONT FILE", 0, &face);
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

	svg = get_svg_font (face, error);
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
