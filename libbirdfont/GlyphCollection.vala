/*
	Copyright (C) 2012, 2014 2015 Johan Mattsson

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
using Math;

namespace BirdFont {

public class GlyphCollection : GLib.Object {
	unichar unicode_character;
	string name;
	bool unassigned = false;
	public Gee.ArrayList<Glyph> glyphs = new Gee.ArrayList<Glyph> ();
	public int selected;

	public GlyphCollection (unichar unicode_character, string name) {
		this.unicode_character = unicode_character;
		this.name = name;
	}

	public GlyphCollection.with_glyph (unichar unicode_character, string name) {
		Glyph g;
		
		this.unicode_character = unicode_character;
		this.name = name;
		
		g = new Glyph (name, unicode_character);
		glyphs.add (g);
		set_selected (g);
	}
	
	public void remove (int index) {
		return_if_fail (0 <= index < glyphs.size);
		
		if (selected >= index) {
			selected--;
		}
		
		glyphs.remove_at (index);
	}
	
	public void set_selected (Glyph g) {
		int i = 0;
		
		foreach (Glyph gl in glyphs) {
			if (gl == g) {
				selected = i;
				return;
			}
			i++;
		}
		
		selected = 0;
		warning ("Glyph is not a part of the collection.");
	}
	
	public void set_unassigned (bool a) {
		unassigned = a;
	}

	public bool is_unassigned () {
		return unassigned;
	}
	
	public void add_glyph (Glyph g) {
		glyphs.add (g);
	}
	
	public Glyph get_current () {
		if (likely (0 <= selected < glyphs.size)) {
			return glyphs.get (selected);
		}
		
		warning (@"No glyph selected for $(name): $selected glyphs.size: $(glyphs.size)");
		
		return new Glyph ("", '\0');
	}
	
	public void insert_glyph (Glyph g, bool selected_glyph) {
		glyphs.add (g);
		
		if (selected_glyph) {
			selected = glyphs.size - 1;
		}
	}
	
	public uint length () {
		return glyphs.size;
	}
	
	public string get_unicode () {
		StringBuilder unicode = new StringBuilder ();
		unicode.append_unichar (unicode_character);
		return unicode.str;
	}

	public void set_unicode_character (unichar c) {
		unicode_character = c;
	}

	public unichar get_unicode_character () {
		return unicode_character;
	}
		
	public string get_name () {
		return name;
	}
	
	public void set_name (string n) {
		name = n;
	}
	
	public void set_selected_version (int version_id) {
		int i = 0;
		foreach (Glyph g in glyphs) {
			if (g.version_id == version_id) {
				selected = i;
				break;
			}
			i++;
		}
	}
	
	/** Create a copy of this list. This method will copy the list data but 
	 * keep pointers to the original glyphs.
	 * @return a new list with copies of pointers to the glyphs
	 */
	public GlyphCollection copy () {
		GlyphCollection n = new GlyphCollection (unicode_character, name);
		
		foreach (Glyph g in glyphs) {
			n.insert_glyph (g, false);
		}
		
		n.selected = selected;
		n.unassigned = unassigned;
		
		return n;
	}

	public GlyphCollection copy_deep () {
		GlyphCollection n = new GlyphCollection (unicode_character, name);
		
		foreach (Glyph g in glyphs) {
			n.insert_glyph (g.copy (), false);
		}
		
		n.selected = selected;
		n.unassigned = unassigned;
		
		return n;
	}
		
	public int get_last_id () {
		return_val_if_fail (glyphs.size > 0, 0);
		return glyphs.get (glyphs.size - 1).version_id;
	}
}
	
}
