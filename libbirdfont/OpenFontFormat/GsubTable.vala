/*
    Copyright (C) 2012, 2013, 2014 Johan Mattsson

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

public class GsubTable : OtfTable {
	
	GlyfTable glyf_table;
	
	public GsubTable (GlyfTable glyf_table) {
		this.glyf_table = glyf_table;
		id = "GSUB";
	}
	
	public override void parse (FontData dis) throws GLib.Error {
	}

	public void process () throws GLib.Error {
		FontData fd = new FontData ();
		FontData clig_subtable;
		FontData chained_context;
		FontData chained_ligatures;
		uint16 length;
		
		LigatureList clig;
		ContextList contextual;

		uint16 feature_lookups;
		
		fd = new FontData ();
		clig = new LigatureList.clig (glyf_table);
		contextual = new ContextList (glyf_table);

		fd.add_ulong (0x00010000); // table version
		fd.add_ushort (10); // offset to script list
		fd.add_ushort (30); // offset to feature list
		fd.add_ushort (contextual.has_ligatures () ? 46 : 44); // offset to lookup list
		
		// script list
		fd.add_ushort (1);   // number of items in script list
		fd.add_tag ("DFLT"); // default script
		fd.add_ushort (8); // offset to script table from script list
		
		// script table
		fd.add_ushort (4); // offset to default language system
		fd.add_ushort (0); // number of languages
		
		// LangSys table 
		fd.add_ushort (0); // reserved
		fd.add_ushort (0); // required features (0xFFFF is none)
		fd.add_ushort (1); // number of features
		fd.add_ushort (0); // feature index
		
		// feature table
		fd.add_ushort (1); // number of features
		
		fd.add_tag ("clig"); // feature tag
		fd.add_ushort (8); // offset to feature
		// FIXME: Should it be liga and clig?

		clig = new LigatureList.clig (glyf_table);
		contextual = new ContextList (glyf_table);

		feature_lookups = contextual.has_ligatures () ? 2 : 1;
		
		fd.add_ushort (0); // feature prameters (null)
		fd.add_ushort (feature_lookups); // number of lookups
		
		if (contextual.has_ligatures ()) {
			fd.add_ushort (2); // lookup chained_context (etc.) The chained context tables are listed here but the actual ligature table is only referenced in the context table
			fd.add_ushort (0); // lookup clig_subtable
		} else {
			fd.add_ushort (0); // lookup clig_subtable
		}
		
		clig_subtable = get_ligature_subtable (clig);
		chained_ligatures = get_ligature_subtable (contextual.ligatures);
		chained_context = get_chaining_contextual_substition_subtable (contextual);
		
		// lookup table
		uint16 lookups = contextual.has_ligatures () ? 3 : 1;
		fd.add_ushort (lookups); // number of lookups
		
		if (contextual.has_ligatures ()) {
			fd.add_ushort (8); // offset to lookup 1 
			fd.add_ushort (16); // offset to lookup 2
			fd.add_ushort (24); // offset to lookup 3
		} else {
			fd.add_ushort (4); // offset to lookup 1 
		}
		
		uint16 lookups_end;
		
		lookups_end = lookups * 8;
		if (contextual.has_ligatures ()) {
			lookups_end += 2 * ((uint16) contextual.ligature_context.size - 1);
		}
		
		length = 0;
		fd.add_ushort (4); // lookup type 
		fd.add_ushort (0); // lookup flags
		fd.add_ushort (1); // number of subtables
		fd.add_ushort (lookups_end + length); // array of offsets to subtable 
		length += (uint16) clig_subtable.length_with_padding ();
		lookups_end -= 8;
		
		if (contextual.has_ligatures ()) {			
			
			for (int i = 0; i < contextual.ligatures.size; i++) {
				fd.add_ushort (4); // lookup type 
				fd.add_ushort (0); // lookup flags
				fd.add_ushort (1); // number of subtables

				LigatureList ligature_set = contextual.ligatures.get (i);
				fd.add_ushort (lookups_end + length); // array of offsets to subtable
				length += (uint16) ligature_set.get_data (glyf_table).length_with_padding ();
				
				lookups_end -= 8;
			}

			fd.add_ushort (6); // lookup type 
			fd.add_ushort (0); // lookup flags
			fd.add_ushort ((uint16) contextual.ligature_context.size); // number of subtables FIXME: 1?
			
			foreach (ContextualLigature c in contextual.ligature_context) {
				fd.add_ushort (lookups_end + length); // array of offsets to subtable
				length += (uint16) c.get_data (glyf_table).length_with_padding ();
			}
			
			lookups_end -= 7 + 2 * contextual.ligature_context.size;
		}
		
		if (lookups_end == 0) {
			warning ("Wring offset to end of lookups.");
		}
		
		fd.append (clig_subtable);
		
		if (contextual.has_ligatures ()) {
			foreach (LigatureList s in contextual.ligatures) {
				fd.append (s.get_data (glyf_table));
			}

			foreach (FontData d in chain_data) {
				fd.append (d);
			}
		}
		
		fd.pad ();
		
		this.font_data = fd;
	}

	FontData get_ligature_subtable (LigatureCollection liga_list) throws GLib.Error {
		FontData set_data;
		Gee.ArrayList<LigatureSet> ligature_sets;
		uint16 ligature_pos;
		uint16 table_start;
		FontData fd;
		
		ligature_sets = liga_list.ligature_sets;
		fd = new FontData ();

		// ligature substitution subtable
		table_start = (uint16) fd.length_with_padding ();

		fd.add_ushort (1); // format identifier
		fd.add_ushort (6 + (uint16) 2 * ligature_sets.size); // offset to coverage
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

	// chaining contextual substitution format3
	Gee.ArrayList<FontData> get_chaining_contextual_substition_subtable (ContextList contexts) throws GLib.Error {
		Gee.ArrayList<FontData> fd = new Gee.ArrayList<FontData> ();
		uint16 ligature_lookup_index = 1;
		
		foreach (ContextualLigature context in contexts.ligature_context) {
			fd_all.append (context.get_data (glyf_table)); // FIXME: remove..
		}
		
		return fd_all;
	}
	
	void parse_ligatures (FontData fd, int table_start) {
		fd.seek (table_start);
		
		uint16 identifier = fd.read_ushort ();
		
		if (identifier != 1) {
			warning (@"Bad identifier expecting 1 found $identifier");
		}
		
		uint16 coverage_offset = fd.read_ushort (); // TODO: read coverage
		uint16 num_sets = fd.read_ushort ();
		
		Gee.ArrayList<int> liga_set_offsets = new Gee.ArrayList<int> ();
		for (int i = 0; i < num_sets; i++) {
			uint16 liga_set_offset = fd.read_ushort ();
			liga_set_offsets.add (table_start + liga_set_offset);
		}
		
		foreach (int liga_set_pos in liga_set_offsets) {
			fd.seek (liga_set_pos);
			parse_ligature_set (fd);
		}		
	}
	
	/** Parse ligature set at the current position. */
	void parse_ligature_set (FontData fd) {
		int liga_start = fd.get_read_pos ();
		uint nliga = fd.read_ushort ();
		Gee.ArrayList<int> offsets = new Gee.ArrayList<int> ();
		
		for (uint i = 0; i < nliga; i++) {
			int off = fd.read_ushort ();
			offsets.add (off);
		}

		foreach (int off in offsets) {
			fd.seek (liga_start);
			fd.seek_relative (off);
			uint16 lig = fd.read_ushort ();
			uint16 nlig_comp = fd.read_ushort ();
			
			for (int i = 1; i < nlig_comp; i++) {
				uint16 lig_comp = fd.read_ushort ();
			} 
		}
	}

	/** 
	 * @param glyphs Name of glyphs or unicode values separated by space.
	 * @return glyph names
	 */
	public static Gee.ArrayList<string> get_names (string glyphs) {
		Gee.ArrayList<string> names = new Gee.ArrayList<string> ();
		Font font = BirdFont.get_current_font ();
		string[] parts = glyphs.split (" ");
								
		foreach (string p in parts) {		
			if (p.has_prefix ("U+") || p.has_prefix ("u+")) {
				p = (!) Font.to_unichar (p).to_string ();
			}
			
			if (!font.has_glyph (p)) {
				warning (@"The character $p does have a glyph.");
				return new Gee.ArrayList<string> ();
			}
			
			names.add (p);
		}
		
		return names;
	}
}

}
