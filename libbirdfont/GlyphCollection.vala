/*
	Copyright (C) 2012 2014 2015 Johan Mattsson

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
	bool unassigned;
	public Gee.ArrayList<GlyphMaster> glyph_masters;	
	int current_master = 0;
	
	public GlyphCollection (unichar unicode_character, string name) {
		this.unicode_character = unicode_character;
		this.name = name;
		glyph_masters = new Gee.ArrayList<GlyphMaster> ();
		unassigned = false;
	}

	public GlyphCollection.with_glyph (unichar unicode_character, string name) {
		Glyph g;
		GlyphMaster master;
		
		glyph_masters = new Gee.ArrayList<GlyphMaster> ();
		master = new GlyphMaster ();
		glyph_masters.add (master);
		
		unassigned = false;
		
		this.unicode_character = unicode_character;
		this.name = name;
		
		g = new Glyph (name, unicode_character);
		master.glyphs.add (g);
		master.set_selected (g);
	}

	public bool has_masters () {
		return glyph_masters.size > 0;
	}
	
	/** This method returns the current master, it has global state. */
	public GlyphMaster get_current_master () {
		int i = current_master;
		GlyphMaster m;
		
		if (unlikely (glyph_masters.size == 0)) {
			warning("No master is set for glyph.");
			m = new GlyphMaster ();
			add_master (m);
			return m;
		} else if (unlikely (i >= glyph_masters.size)) {
			warning(@"No master at index $i. ($(glyph_masters.size)) in $(name)");
			i = glyph_masters.size - 1;
		}
		
		return_val_if_fail (0 <= i < glyph_masters.size, new GlyphMaster ());
		
		return glyph_masters.get (i);
	}

	public bool has_master (string id) {
		foreach (GlyphMaster m in glyph_masters) {
			if (m.get_id () == id) {
				return true;
			}
		}
		
		return false;
	}
		
	public GlyphMaster get_master (string id) {
		foreach (GlyphMaster m in glyph_masters) {
			if (m.get_id () == id) {
				return m;
			}
		}
		
		warning ("Master not found for id $(id).");
		return new GlyphMaster ();
	}
		
	public bool is_multimaster() {
		return glyph_masters.size > 1;
	}
	
	public void remove (int index) {
		get_current_master ().remove (index);
	}
	
	public void set_selected (Glyph g) {
		get_current_master ().set_selected (g);
	}
	
	public void set_unassigned (bool a) {
		unassigned = a;
	}

	public bool is_unassigned () {
		return unassigned;
	}
	
	public void add_master (GlyphMaster master) {
		glyph_masters.add (master);
	}
	
	public void set_selected_master (GlyphMaster m) {
		current_master = glyph_masters.index_of (m);
		
		if (current_master == -1) {
			warning ("Master does not exits");
			current_master = 0;
		}
	}
	
	public Glyph get_current () {
		Glyph? g = get_current_master ().get_current ();
		
		if (likely (g != null)) {
			return (!) g;
		}
		
		warning (@"No glyph selected for $(name)");
		return new Glyph ("", '\0');
	}
	
	public Glyph get_interpolated (double weight) {
		if (weight == 0) { // FIXME: compare to master weight
			return get_current (); 
		}
		
		if (glyph_masters.size == 1) {
			return get_current ().self_interpolate (weight);
		} else {
			warning("Not implemented.");
		}
		
		return get_current ();
	}

	public Glyph get_interpolated_fast (double weight) {
		if (weight == 0) { // FIXME: compare to master weight
			return get_current (); 
		}
		
		if (glyph_masters.size == 1) {
			return get_current ().self_interpolate_fast (weight);
		} else {
			warning("Not implemented.");
		}
		
		return get_current ();
	}
		
	public void insert_glyph (Glyph g, bool selected_glyph) {
		get_current_master ().insert_glyph (g, selected_glyph);
	}
	
	public uint length () {
		if (!has_masters ()) {
			return 0;
		}
		
		return get_current_master ().glyphs.size;
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
		
	/** Create a copy of this list. This method will copy the list data but 
	 * keep pointers to the original glyphs.
	 * @return a new list with copies of pointers to the glyphs
	 */
	public GlyphCollection copy () {
		GlyphCollection n = new GlyphCollection (unicode_character, name);
		
		foreach (GlyphMaster g in glyph_masters) {
			n.glyph_masters.add (g.copy ());
		}
		
		n.unassigned = unassigned;
		
		return n;
	}

	public GlyphCollection copy_deep () {
		GlyphCollection n = new GlyphCollection (unicode_character, name);
		
		foreach (GlyphMaster g in glyph_masters) {
			n.glyph_masters.add (g.copy_deep ());
		}
		
		n.unassigned = unassigned;
		
		return n;
	}
		
	public int get_last_id () {
		return get_current_master ().get_last_id ();
	}

	/** @return all versions of all masters */
	public Gee.ArrayList<Glyph> get_all_glyph_masters () {
		Gee.ArrayList<Glyph> glyphs = new Gee.ArrayList<Glyph> ();
		
		foreach (GlyphMaster master in glyph_masters) {
			foreach (Glyph g in master.glyphs) {
				glyphs.add (g);
			}
		}
		
		return glyphs;
	}
}
	
}
