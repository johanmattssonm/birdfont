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

namespace BirdFont {

public class AlternateSets : GLib.Object {
	
	public Gee.ArrayList<Alternate> alternates;
	
	public AlternateSets () {
		alternates = new Gee.ArrayList<Alternate> ();
	}
	
	public Gee.ArrayList<string> get_all_tags () {
		Gee.ArrayList<string> tags;
		tags = new Gee.ArrayList<string> ();
		
		foreach (Alternate a in alternates) {
			if (tags.index_of (a.tag) == -1) {
				tags.add (a.tag);
			}
		}
		
		tags.sort ((a, b) => {
			return strcmp ((string) a, (string) b);
		});
		
		return tags;
	}

	public Gee.ArrayList<Alternate> get_alt (string tag) {	
		Gee.ArrayList<Alternate> alt;
		alt = new Gee.ArrayList<Alternate> ();
		
		foreach (Alternate a in alternates) {
			if (a.tag == tag && a.alternates.size > 0) {
				alt.add (a);
			}
		}
		
		return alt;
	}

	public Gee.ArrayList<Alternate> get_alt_with_glyph (string tag, Font font) {	
		Gee.ArrayList<Alternate> alt;
		alt = new Gee.ArrayList<Alternate> ();
		
		foreach (Alternate a in alternates) {
			Alternate available = new Alternate (a.glyph_name, a.tag);
			
			foreach (string substitution in a.alternates) {
				if (font.has_glyph (substitution)) {
					available.alternates.add (substitution);
				}
			}
			
			if (available.tag == tag && available.alternates.size > 0) {
				if (font.has_glyph (available.glyph_name)) {
					alt.add (available);
				}
			}
		}
		
		return alt;
	}
		
	public void remove_empty_sets () {
		int i = 0;
		foreach (Alternate a in alternates) {
			if (a.is_empty ()) {
				alternates.remove_at (i);
				remove_empty_sets ();
				return;
			}
			i++;
		}
	}
	
	public void add (Alternate alternate) {
		alternates.add (alternate);
	}
	
	public AlternateSets copy () {
		AlternateSets n = new AlternateSets ();
		foreach (Alternate a in alternates) {
			n.alternates.add (a.copy ());
		}
		return n;
	}
}

public class AlternateItem : GLib.Object {
	public Alternate alternate_list;
	public string alternate;
	
	public AlternateItem (Alternate alternate_list, string alternate) {
		this.alternate_list = alternate_list;
		this.alternate = alternate;
	}
	
	public void delete_item_from_list () {
		alternate_list.remove_alternate (alternate);
	}
}

}
