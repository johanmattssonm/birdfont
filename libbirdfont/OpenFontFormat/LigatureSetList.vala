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

	public Gee.ArrayList<LigatureSet> ligature_sets;

	LigatureSet lig_set;
	LigatureSet last_set;

	public LigatureSetList.clig (GlyfTable glyf_table) {
		ligature_sets = new Gee.ArrayList<LigatureSet> ();	
		lig_set = new LigatureSet (glyf_table);
		last_set = new LigatureSet (glyf_table);
		
		add_clig_ligatures (glyf_table);
	}

	public LigatureSetList.contextual (GlyfTable glyf_table, ContextualLigatureSet ligatures) {
		ligature_sets = new Gee.ArrayList<LigatureSet> ();	
		lig_set = new LigatureSet (glyf_table);
		last_set = new LigatureSet (glyf_table);

		add_contextual_ligatures (glyf_table, ligatures);
	}

	void add_clig_ligatures (GlyfTable glyf_table) {
		Font font = BirdFont.get_current_font ();
		Ligatures ligatures = font.get_ligatures ();	
		
		ligatures.get_ligatures ((parts, ligature) => {
			add_ligatures (glyf_table, parts, ligature);
		});	
	}

	void add_contextual_ligatures (GlyfTable glyf_table, ContextualLigatureSet ligatures) {
		foreach (ContextualLigature c in ligatures.ligature_context) {
			foreach (string l in c.ligatures.strip ().split (" ")) {
				add_ligatures (glyf_table, "r", l); // FIXME: parts = ""
			}
		}
	}

	// multiple ligatures in non-contextual substitution
	// FIXME: what if parts equals "" ? Which set does ligatures becomes a part of?
	public void add_ligatures (GlyfTable glyf_table, string characters, string ligatures) 
		requires (!is_null (lig_set) && !is_null (last_set)) {
			
		Font font = BirdFont.get_current_font ();
		string[] parts = characters.split (" ");
		string l = ligatures;

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
			last_set.add (new Ligature (l, characters));
		} else {
			lig_set = new LigatureSet (glyf_table);
			lig_set.add (new Ligature (l, characters));
			ligature_sets.add (lig_set);
			last_set = lig_set;
		}		
	}
}

}
