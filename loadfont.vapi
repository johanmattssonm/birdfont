namespace LoadFont {
	
[CCode (cname = "FreeTypeFontFace", cheader_filename="loadfont.h")]
public extern class FreeTypeFontFace {
}

[CCode (cname = "load_freetype_font", cheader_filename="loadfont.h")]
public extern static GLib.StringBuilder? load_freetype_font (string file, out int error);

[CCode (cname = "validate_freetype_font", cheader_filename="loadfont.h")]
public extern static bool validate_freetype_font (string file);

[CCode (cname = "load_glyph", cheader_filename="loadfont.h")]
public extern static GLib.StringBuilder? load_glyph (FreeTypeFontFace font, uint unicode);

[CCode (cname = "open_font", cheader_filename="loadfont.h")]
public extern static FreeTypeFontFace* open_font (string font_file);

[CCode (cname = "freetype_has_glyph", cheader_filename="loadfont.h")]
public extern static bool freetype_has_glyph (FreeTypeFontFace font, uint unicode);

[CCode (cname = "close_ft_font", cheader_filename="loadfont.h")]
public extern static void close_font (FreeTypeFontFace* font);

[CCode (cname = "get_all_unicode_points_in_font", cheader_filename="loadfont.h")]
public extern static ulong* get_all_unicode_points_in_font (string file);

[CCode (cname = "get_freetype_font_is_regular", cheader_filename="loadfont.h")]
public extern static bool get_freetype_font_is_regular (string file);

}
