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
using Math;

namespace BirdFont {

public class LigatureSetList : GLib.Object {

	public Gee.ArrayList<LigatureSet> liga_sets;

	public LigatureSetList.clig (GlyfTable glyf_table) {
		liga_sets = new Gee.ArrayList<LigatureSet> ();	
		add_clig_ligatures (glyf_table);
	}
	
	public LigatureSetList.context (GlyfTable glyf_table) {
		liga_sets = new Gee.ArrayList<LigatureSet> ();	
		add_contextual_ligatures (glyf_table);
	}
	
	void add_contextual_ligatures (GlyfTable glyf_table) {
		LigatureSet lig_set;
		
		lig_set = new LigatureSet (glyf_table);
		lig_set.add (new Ligature ("ralt", "r"));
		
		liga_sets.add (lig_set);
	}
	
	// create ligature list
	void add_clig_ligatures (GlyfTable glyf_table) {
		Font font;
		Ligatures ligatures;
		LigatureSet lig_set;
		LigatureSet last_set;
				
		font = BirdFont.get_current_font ();
		ligatures = font.get_ligatures ();	

		lig_set = new LigatureSet (glyf_table);
		last_set = new LigatureSet (glyf_table);
		ligatures.get_ligatures ((s, lig) => {
			string[] parts = s.split (" ");
			string l = lig;

			if (l.has_prefix ("U+") || l.has_prefix ("u+")) {
				l = (!) Font.to_unichar (l).to_string ();
			}
							
			if (!font.has_glyph (l)) {
				warning (@"Ligature $l does not correspond to a glyph in this font.");
				return;
			}
			
			foreach (string p in parts) {		
				if (p.has_prefix ("U+") || p.has_prefix ("u+")) {
					p = (!) Font.to_unichar (p).to_string ();
				}
				
				if (!font.has_glyph (p)) {
					warning (@"Ligature substitution of $p is not possible, the character does have a glyph.");
					return;
				}
			}
			
			if (parts.length == 0) {
				warning ("No parts.");
				return;
			}
			
			if (last_set.starts_with (parts[0])) {
				last_set.add (new Ligature (l, s));
			} else {
				lig_set = new LigatureSet (glyf_table);
				lig_set.add (new Ligature (l, s));
				liga_sets.add (lig_set);
				last_set = lig_set;
			}
		});	
	}
}

}
