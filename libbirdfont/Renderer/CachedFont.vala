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

	public double top_limit {
		get { return _top_limit; }
		set { _top_limit = value; }
	}

	public double bottom_limit {
		get { return _bottom_limit; }
		set { _bottom_limit = value; }
	}
	
	public double base_line = 0;
	double _top_limit = 92.77; // FIXME: load before first glyph
	double _bottom_limit = -24.4;
	
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
		Glyph? g = null;
		
		if (font != null) {
			g = ((!) font).get_glyph_by_name (name);
		}
		
		if (g == null && name.char_count () == 1) {
			Font f = fallback_font.get_single_glyph_font (name.get_char (0));
			g = f.get_glyph_by_name (name);
			
			if (g == null) {
				return null;
			}
			
			top_limit = f.top_limit;
			base_line = f.base_line;
			bottom_limit = f.bottom_limit;	
			
			font = f;
		}
				
		return g;
	}
}

}
