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
using Math;

namespace BirdFont {

public class CligFeature : GLib.Object {
	public LigatureCollection clig;
	public ContextualLigatureCollection contextual;
	Lookups lookups;
	GlyfTable glyf_table;
	
	public CligFeature (GlyfTable glyf_table) throws GLib.Error {	
		this.glyf_table = glyf_table;
		generate_feature ();
	}
	
	public Lookups get_lookups () {
		return lookups;
	}
	
	private void generate_feature () throws GLib.Error {
		Gee.ArrayList<FontData> chain_data;
		FontData clig_subtable;
		FontData fd;
		Lookup lookup;
		
		fd = new FontData ();
		clig = new LigatureCollection.clig (glyf_table);
		contextual = new ContextualLigatureCollection (glyf_table);

		clig_subtable = clig.get_font_data (glyf_table);
		clig_subtable.pad ();
		
		chain_data = get_chaining_contextual_substition_subtable (contextual);
		
		// lookup table
		lookups = new Lookups ();
		
		if (contextual.has_ligatures ()) {
			foreach (LigatureCollection s in contextual.ligatures) {
				lookup = new Lookup (4, 0);
				lookup.add_subtable (s.get_font_data (glyf_table));
				lookups.add_lookup(lookup);
			}

			lookup = new Lookup (6, 0);
			foreach (FontData d in chain_data) {
				lookup.add_subtable (d);
			}
			lookups.add_lookup(lookup);			
		}

		lookup = new Lookup (4, 0);
		lookup.add_subtable (clig_subtable);
		lookups.add_lookup(lookup);
	}
	
	// chaining contextual substitution format3
	Gee.ArrayList<FontData> get_chaining_contextual_substition_subtable (ContextualLigatureCollection contexts) throws GLib.Error {
		Gee.ArrayList<FontData> fd = new Gee.ArrayList<FontData> ();
		uint16 ligature_lookup_index = 0;
		
		foreach (ContextualLigature context in contexts.ligature_context) {
			fd.add (context.get_font_data (glyf_table, ligature_lookup_index)); 
			ligature_lookup_index++;
		}
		
		return fd;
	}
}

}

