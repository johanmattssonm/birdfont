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
		Glyph? g;
		Glyph glyph;
		
		this.font = font;

		g = get_glyph_by_name ("a");
		if (g != null) {
			glyph = (!) g;
			base_line = glyph.baseline;
			top_limit = glyph.top_limit;
			bottom_limit = glyph.bottom_limit;
		} else {
			warning("No default chararacter found in font.");
		}
	}
	
	public Glyph? get_glyph_by_name (string name) {
		Glyph? g = null;
		Font f;
		Glyph glyph;
		
		if (font != null) {
			f = (!) font;
			g = f.get_glyph_by_name (name);
			
			if (g != null) {
				glyph = (!) g;
				glyph.top_limit = f.top_limit;
				glyph.baseline = f.base_line;
				glyph.bottom_limit = f.bottom_limit;
			}
		}
		
		if (g == null && name.char_count () == 1) {
			f = fallback_font.get_single_glyph_font (name.get_char (0));
			g = f.get_glyph_by_name (name);
			
			if (g == null) {
				return null;
			}
			
			glyph = (!) g;
			glyph.top_limit = f.top_limit;
			glyph.baseline = f.base_line;
			glyph.bottom_limit = f.bottom_limit;	
		}
		
		return g;
	}
}

}
