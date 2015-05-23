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

#include <stdio.h>
#include <glib.h>
#include <fontconfig/fontconfig.h>

/** Find a fallback font for a set of characters.
 * @return A path to the font file.
 */
gchar* find_font (FcConfig* fontconfig, const gchar* characters) {
	FcPattern* pattern;
	FcCharSet* character_set;
	FcObjectSet* font_properties;
	FcFontSet* fonts;
	FcPattern* font;
	FcChar8* path;
	gchar* result;
	gchar* remaining_characters;
	gunichar character;
	
	result = NULL;
	pattern = FcPatternCreate ();
	
	character_set = FcCharSetCreate ();
	
	remaining_characters = characters;
	while (TRUE) {
		character = g_utf8_get_char (remaining_characters);
		
		if (character == '\0') {
			break;
		}
		
		FcCharSetAddChar(character_set, character);
				
		remaining_characters = g_utf8_next_char (remaining_characters);
	}

	FcPatternAddCharSet (pattern, FC_CHARSET, character_set);
	FcCharSetDestroy (character_set);
	
	FcPatternAddBool(pattern, FC_SCALABLE, FcTrue);
	font_properties = FcObjectSetBuild (FC_FILE, NULL);	
	fonts = FcFontList (fontconfig, pattern, font_properties);

	if (fonts->nfont > 0) {
		font = fonts->fonts[0];
		if (FcPatternGetString(font, FC_FILE, 0, &path) == FcResultMatch) {
			result = g_strdup ((gchar*) path);
		}
	}

	if (fonts) {
		FcFontSetDestroy(fonts);
	}

	return result;
}
