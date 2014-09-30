/*
    Copyright (C) 2012 Johan Mattsson

    This library is free software; you can redistribute it and/or modify 
    it under the terms of the GNU Lesser General Public License as 
    published by the Free Software Foundation; either version 3 of the 
    License, or (at your option) any later version.

    This library is distributed in the hope that it will be useful, but 
    WITHOUT ANY WARRANTY; without even the implied warranty of 
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU 
    Lesser General Public License for more details.
*/

namespace BirdFont {

public class Tab : GLib.Object {

	bool always_open;
	double width; 
	string label;
	FontDisplay display;
	GlyphCollection glyph_collection;

	public Tab (FontDisplay glyph, double tab_width, bool always_open) {
		width = tab_width;
		display = glyph;
		this.always_open = always_open;
		label = display.get_label ();
		glyph_collection = new GlyphCollection.with_glyph ('\0', "");
	}

	public bool has_close_button () {
		return !always_open;
	}

	public GlyphCollection get_glyph_collection () {
		return glyph_collection;
	}

	public void set_glyph_collection (GlyphCollection gc) {
		glyph_collection = gc;
	}

	public void set_display (FontDisplay fd) {
		display = fd;
	}

	public FontDisplay get_display () {
		return display;
	}
	
	public double get_width () {
		return width;
	}
	
	public string get_label () {
		return label;
	}
}

}
