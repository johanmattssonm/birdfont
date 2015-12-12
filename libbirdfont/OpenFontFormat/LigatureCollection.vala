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

namespace BirdFont {

public class LigatureCollection : GLib.Object {

	public Gee.ArrayList<LigatureSet> ligature_sets;

	LigatureSet lig_set;
	LigatureSet last_set;

	public LigatureCollection.clig (GlyfTable glyf_table) {
		ligature_sets = new Gee.ArrayList<LigatureSet> ();	
		lig_set = new LigatureSet (glyf_table);
		last_set = new LigatureSet (glyf_table);
		
		add_clig_ligatures (glyf_table);
	}

	public LigatureCollection.contextual (GlyfTable glyf_table, ContextualLigature ligature) {
		ligature_sets = new Gee.ArrayList<LigatureSet> ();	
		lig_set = new LigatureSet (glyf_table);
		last_set = new LigatureSet (glyf_table);

		add_contextual_ligatures (glyf_table, ligature);
	}

	void add_clig_ligatures (GlyfTable glyf_table) {
		Font font = BirdFont.get_current_font ();
		Ligatures ligatures = font.get_ligatures ();	
		
		ligatures.get_ligatures ((parts, ligature) => {
			add_ligatures (glyf_table, parts, ligature);
		});	
	}

	void add_contextual_ligatures (GlyfTable glyf_table, ContextualLigature cl) {
		foreach (string l in cl.ligatures.strip ().split (" ")) {
			add_ligatures (glyf_table, cl.input, l);
		}
	}

	// multiple ligatures in non-contextual substitution
	public void add_ligatures (GlyfTable glyf_table, string characters, string ligatures) 
		requires (!is_null (lig_set) && !is_null (last_set)) {
			
		Font font = BirdFont.get_current_font ();
		string[] parts = characters.strip ().split (" ");
		string l = ligatures;
		bool has_set = false;

		if (l.has_prefix ("U+") || l.has_prefix ("u+")) {
			l = (!) Font.to_unichar (l).to_string ();
		}
		
		if (l == "space") {
			l = " ";
		}
		
		if (!font.has_glyph (l)) {
			warning (@"Ligature $l does not correspond to a glyph in this font.");
			return;
		}
		
		foreach (string p in parts) {		
			if (p.has_prefix ("U+") || p.has_prefix ("u+")) {
				p = (!) Font.to_unichar (p).to_string ();
			}

			if (p == "space") {
				p = " ";
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
		
		foreach (LigatureSet s in ligature_sets) {
			if (s.starts_with (parts[0])) {
				has_set = true;
				last_set = s;
			}
		}
		
		if (has_set) {
			last_set.add (new Ligature (l, characters));
		} else {
			lig_set = new LigatureSet (glyf_table);
			lig_set.add (new Ligature (l, characters));
			ligature_sets.add (lig_set);
		}
		
		// make sure coverage table is sorted otherwise will substitution not work
		ligature_sets.sort ((a, b) => {
			LigatureSet la = (LigatureSet) a;
			LigatureSet lb = (LigatureSet) b;
			string ca, cb;
			
			if (la.get_coverage_char () == "space") {
				ca = " ";
			} else {
				ca = la.get_coverage_char ();
			}

			if (lb.get_coverage_char () == "space") {
				cb = " ";
			} else {
				cb = lb.get_coverage_char ();
			}

			return strcmp (ca, cb);
		});
	}

	public FontData get_font_data (GlyfTable glyf_table) throws GLib.Error {
		FontData set_data;
		uint16 ligature_pos;
		uint16 table_start;
		int coverage_offset;
		FontData fd;
		
		fd = new FontData ();

		// ligature substitution subtable
		table_start = (uint16) fd.length_with_padding ();

		fd.add_ushort (1); // format identifier
		
		coverage_offset = 6 + 2 * ligature_sets.size;
		fd.add_ushort ((uint16) coverage_offset); // offset to coverage
		fd.add_ushort ((uint16) ligature_sets.size); // number of ligature set tables

		// array of offsets to ligature sets
		uint16 size = 0;
		foreach (LigatureSet l in ligature_sets) {
			ligature_pos = 10 + (uint16) ligature_sets.size * 4 + size;
			fd.add_ushort (ligature_pos);
			size += (uint16) l.get_set_data ().length_with_padding ();
		}

		// coverage
		fd.add_ushort (1); // format
		fd.add_ushort ((uint16) ligature_sets.size);

		// coverage gid:
		foreach (LigatureSet l in ligature_sets) {
			fd.add_ushort ((uint16) glyf_table.get_gid (l.get_coverage_char ()));
		}
		
		foreach (LigatureSet l in ligature_sets) {
			set_data = l.get_set_data ();
			fd.append (set_data);
		}
		
		return fd;
	}
}

}
