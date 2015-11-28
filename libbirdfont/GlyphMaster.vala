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

using Cairo;
using Math;

namespace BirdFont {

public class GlyphMaster : GLib.Object {
	public Gee.ArrayList<Glyph> glyphs = new Gee.ArrayList<Glyph> ();
	public int selected = 0;
	
	public string id = "Master 1";

	public GlyphMaster () {
	}
	
	public GlyphMaster.for_id (string id) {
		this.id = id;
	}
	
	public string get_id () {
		return id;
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

	public void add_glyph (Glyph g) {
		glyphs.add (g);
	}
	
	public Glyph? get_current () {
		if (likely (0 <= selected < glyphs.size)) {
			return glyphs.get (selected);
		}

		warning (@"No glyph $selected glyphs.size: $(glyphs.size)");

		return null;
	}
	
	public void insert_glyph (Glyph g, bool selected_glyph) {
		glyphs.add (g);
		
		if (selected_glyph) {
			selected = glyphs.size - 1;
		}
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
	
	public int get_last_id () {
		return_val_if_fail (glyphs.size > 0, 0);
		return glyphs.get (glyphs.size - 1).version_id;
	}
	
	public GlyphMaster copy_deep () {
		GlyphMaster n = new GlyphMaster ();
		
		foreach (Glyph g in glyphs) {
			n.glyphs.add (g.copy ());
		}
		
		n.selected = selected;
		n.id = id;
		
		return n;
	}

	public GlyphMaster copy () {
		GlyphMaster n = new GlyphMaster ();
		
		foreach (Glyph g in glyphs) {
			n.glyphs.add (g);
			n.glyphs.add (g);
		}
		
		n.selected = selected;
		n.id = id;
		
		return n;
	}
}

}

