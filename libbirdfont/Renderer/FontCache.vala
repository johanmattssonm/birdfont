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
	}
	
	public CachedFont get_font (string file_name) {
		CachedFont c;
		Font f;
		bool ok;

		if (file_name == "") {
			return fallback;
		}
		
		if (fonts.has_key (file_name)) {
			c = fonts.get (file_name);
			return c;
		}
		
		f = new Font ();
		f.set_file (file_name);
		ok = f.load ();
		if (!ok) {
			stderr.printf ("Can't load %s\n", file_name);
			return new CachedFont (null);
		}
		
		c = new CachedFont (f);
		
		if (file_name == "") {
			warning ("No file.");
			return c;
		}
		
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

}

}
