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

using Gee;

namespace BirdFont {
	
public class CachedFont : GLib.Object {
	public Font? font;

	// FIXME: move fallback glyphs in to fond boundaries
	public double top_limit = 84;
	public double base_line = 0;
	public double bottom_limit = -27;
	
	FallbackFont fallback_font {
		get {
			if (_fallback_font == null) {
				_fallback_font = new FallbackFont ();
			}
			
			return (!) _fallback_font;
		}
	}
	static FallbackFont? _fallback_font = null;

	public CachedFont (Font? font) {
		this.font = font;
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
}

}
