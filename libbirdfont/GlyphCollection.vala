/*
    Copyright (C) 2012, 2014 Johan Mattsson

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
	VersionList versions;
	unichar unicode_character;
	string name;

	public GlyphCollection (unichar unicode_character, string name) {
		this.unicode_character = unicode_character;
		this.name = name;
		versions = new VersionList (null, this);
	}

	public VersionList get_version_list () {
		return versions;
	}
	
	public Glyph get_current () {
		return versions.get_current ();
	}
	
	public void insert_glyph (Glyph g, bool selected) {
		versions.add_glyph (g, selected);		
		assert (versions.glyphs.size > 0);
	}
	
	public uint length () {
		return versions.glyphs.size;
	}
	
	public string get_unicode () {
		StringBuilder unicode = new StringBuilder ();
		unicode.append_unichar (unicode_character);
		return unicode.str;
	}
	
	public string get_name () {
		return name;
	}
	
	public int get_selected_id () {
		return versions.get_current ().version_id;	
	}
	
	public void set_selected_version (int version_id) {
		versions.set_selected_version (version_id);
	}
	
	/** Create a copy of this list. This method will copy the list data but 
	 * keep pointers to the original glyphs.
	 * @return a new list with copies of pointers to the glyphs
	 */
	public GlyphCollection copy () {
		GlyphCollection n = new GlyphCollection (unicode_character, name);
		
		foreach (Glyph g in versions.glyphs) {
			n.insert_glyph (g, false);
		}
		
		n.versions.set_selected_version (versions.current_version_id);
		
		return n;
	}
}
	
}
