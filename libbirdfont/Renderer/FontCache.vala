/*
    Copyright (C) 2014 Johan Mattsson

    This library is free software; you can redistribute it and/or modify 
    it under the terms of the GNU Lesser General Public License as 
    published by the Free Software Foundation; either version 3 of the 
    License, or (at your option) any later version.

    This library is distributed in the hope that it will be useful, but 
    WITHOUT ANY WARRANTY; without even the implied warranty of 
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU 
    Lesser General Public License for more details.
*/

using Gee;

namespace BirdFont {

/** Thread specific font cache. */	
public class FontCache {	
	public static FallbackFont fallback_font;
	
	static FontCache? default_cache = null;
	Gee.HashMap<string, CachedFont> fonts;
	CachedFont fallback;
	
	public FontCache () {
		if (is_null (fallback_font)) {
			fallback_font = new FallbackFont ();
		}
		
		fallback = new CachedFont (null);
		fonts = new Gee.HashMap<string, CachedFont> ();
		fonts.set ("", fallback);
	}
	
	public void reload_font (string file_name) {
		Font? f = get_font (file_name).font;
		
		if (f != null) {
			((!) f).load ();
		}
	}
	
	public CachedFont get_font (string file_name) {
		CachedFont c;
		Font f;
		bool ok;

		if (fonts.has_key (file_name)) {
			return fonts.get (file_name);
		}
		
		if (file_name == "") {
			return fallback;
		}
		
		f = new Font ();
		f.set_file (file_name);
		ok = f.load ();
		if (!ok) {
			stderr.printf ("Can't load %s\n", file_name);
			return new CachedFont (null);
		}
		
		c = new CachedFont (f);
		fonts.set (file_name, c);
		
		return c;
	}
	
	public static FontCache get_default_cache () {
		if (default_cache == null) {
			default_cache = new FontCache ();
		}
		
		return (!) default_cache;
	}
	
	public CachedFont get_fallback () {
		return fallback;
	}
	
	public class CachedFont : GLib.Object {
		public Font? font;

		// FIXME: move fallback glyphs in to fond boundaries
		public double top_limit = 84;
		public double base_line = 0;
		public double bottom_limit = -27;
		
		public static int cached = 0; 
		
		public CachedFont (Font? font) {
			this.font = font;
			cached++;
			
			warning (@"$cached cached fonts\n");
		}
		
		~CachedFont () {
			cached--;
			warning (@"$cached cached fonts\n");
		}
		
		public Glyph? get_glyph_by_name (string name) {
			Font f = new Font ();
			Glyph? g = null;
			
			if (font != null) {
				g = ((!) font).get_glyph_by_name (name);
			}
			
			if (g == null && name.char_count () == 1) {
				f = fallback_font.get_single_glyph_font (name.get_char (0));
				g = f.get_glyph_by_name (name);
				
				if (g == null) {
					return null;
				}
				
				top_limit = f.top_limit;
				base_line = f.base_line;
				bottom_limit = f.bottom_limit;	
			}
					
			return g;
		}
		
		public GlyphCollection get_not_def_character () {
			Font f;
			
			if (font != null) {
				return ((!) font).get_not_def_character ();
			}
			
			f = new Font ();
			
			return f.get_not_def_character ();
		}
	}
}

}
