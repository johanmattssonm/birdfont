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
	Gee.HashMap<string, Font> fonts;
	
	public FontCache () {
		fonts = new Gee.HashMap<string, Font> ();
		
		if (is_null (fallback_font)) {
			fallback_font = new FallbackFont ();
		}
	}
	
	public void reload_font (string file_name) {
		Font? f = get_font (file_name).font;
		
		if (f != null) {
			((!) f).load ();
		}
	}
	
	public CachedFont get_font (string file_name) {
		Font f;
		bool ok;
		
		if (file_name == "") {
			stderr.printf ("No file name.\n");
			return new CachedFont (null);
		}
		
		if (fonts.has_key (file_name)) {
			return new CachedFont (fonts.get (file_name));
		}
		
		f = new Font ();
		f.set_file (file_name);
		ok = f.load ();
		if (!ok) {
			stderr.printf ("Can't load %s\n", file_name);
			return new CachedFont (null);
		}
		
		fonts.set (file_name, f);
		
		return new CachedFont (f);
	}
	
	public static FontCache get_default_cache () {
		if (default_cache == null) {
			default_cache = new FontCache ();
		}
		
		return (!) default_cache;
	}
	
	public CachedFont get_fallback () {
		return new CachedFont (null);
	}
	
	public class CachedFont : GLib.Object {
		public Font? font;

		// FIXME: move fallback glyphs in to fond boundaries
		public double top_limit = 84;
		public double base_line = 0;
		public double bottom_limit = -27;
			
		public CachedFont (Font? font) {
			this.font = font;
		}
		
		public Glyph? get_glyph_by_name (string name) {
			Glyph? g = null;
			
			if (font != null) {
				g = ((!) font).get_glyph_by_name (name);
			}
			
			if (g == null && name.char_count () == 1) {
				g = fallback_font.get_glyph (name.get_char (0));
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
