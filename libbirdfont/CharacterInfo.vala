/*
    Copyright (C) 2013 Johan Mattsson

    This library is free software; you can redistribute it and/or modify 
    it under the terms of the GNU Lesser General Public License as 
    published by the Free Software Foundation; either version 3 of the 
    License, or (at your option) any later version.

    This library is distributed in the hope that it will be useful, but 
    WITHOUT ANY WARRANTY; without even the implied warranty of 
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU 
    Lesser General Public License for more details.
*/

using Cairo;

namespace BirdFont {

/** Display functions for a unicode character database entry. */
public class CharacterInfo : GLib.Object {
	
	public unichar unicode;

	Text icon;
	double x = 0;
	double y = 0;
	bool ligature = false;
	string name = "";
	
	public CharacterInfo (unichar c, GlyphCollection? gc) {
		unicode = c;
		icon = new Text ("info_icon", 22);
		icon.load_font ("icons.bf");
		
		if (gc != null) {
			ligature = ((!) gc).is_unassigned ();
			name = ((!) gc).get_name ();
			icon.load_font ("icons.bf");
			icon.use_cache (true);
		}
	}
	
	public string get_name () {
		return name;
	}
	
	public bool is_ligature () {
		return ligature;
	}
	
	public string get_entry () {
		return CharDatabase.get_unicode_database_entry (unicode);
	}
	
	public void set_position (double x, double y) {
		this.x = x;
		this.y = y;
	}
	
	public bool is_over_icon (double px, double py) {
		return (x <= px <= x + 12) && (y <= py <= y + 24);
	}
	
	public void draw_icon (Context cr, bool selected, double px, double py) {	
		if (selected) {
			Theme.text_color (icon, "Overview Selected Foreground");
		} else {
			Theme.text_color (icon, "Overview Foreground");
		}
		
		icon.draw_at_top (cr, px, py);	
	}
}

}
