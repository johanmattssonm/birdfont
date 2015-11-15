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

using Gee;

namespace BirdFont {

/** A sorted table of glyphs with search index. */
public class GlyphTable : GLib.Object {
	
	TreeMap<string, GlyphCollection> map;
	
	public GlyphTable () {
		map = new TreeMap<string, GlyphCollection> ();
	}

	public void remove_all () {
		map.clear ();
	}

	public void @for_each (Func<GlyphCollection> func) {
		if (unlikely (is_null (map))) {
			warning ("No data in table");
			return;
		}
		
		foreach (var entry in map.entries) {
			func (entry.value);
		}
	}

	public bool has_key (string n) {
		return map.has_key (n);
	}
		
	public void remove (string name) {
		map.unset (name);
	}

	public uint length () {
		return map.size;
	}

	public new GlyphCollection? @get (string name) {
		return map.get (name);
	}

	public new GlyphCollection? nth (uint index) {
		uint i = 0;

		foreach (var k in map.keys) {
			if (i == index) {
				return map.get (k);
			}
			i++;
		}

		return null;
	}

	public bool insert (string key, GlyphCollection g) {
		map.set (key, g);
		return true;
	}
}

}
