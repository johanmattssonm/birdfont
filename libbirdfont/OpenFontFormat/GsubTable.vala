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
	
	public override void parse (FontData dis) throws Error {
	}

	public void process () throws GLib.Error {
		FontData fd = new FontData ();
		FontData clig_subtable;
		
		fd.add_ulong (0x00010000); // table version
		fd.add_ushort (10); // offset to script list
		fd.add_ushort (30); // offset to feature list
		fd.add_ushort (44); // offset to lookup list
		
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
		
		fd.add_ushort (0); // feature prameters (null)
		fd.add_ushort (1); // number of lookups
		fd.add_ushort (0); // lookup indice
		
		// lookup table
		fd.add_ushort (1); // number of lookups
		fd.add_ushort (4); // offset to lookup 1

		fd.add_ushort (4); // lookup type 
		fd.add_ushort (0); // lookup flags
		fd.add_ushort (1); // number of subtables
		fd.add_ushort (8); // array of offsets to subtable

		clig_subtable = get_ligature_subtable ();
		fd.append (clig_subtable);
		
		fd.pad ();
		
		this.font_data = fd;
	}

	FontData get_ligature_subtable () {
		Font font;
		Ligatures ligatures;
		LigatureSet lig_set;
		LigatureSet last_set;
		FontData set_data;
		Gee.ArrayList<LigatureSet> liga_sets;
		uint16 ligature_pos;
		uint16 table_start;
		FontData fd;
		
		font = BirdFont.get_current_font ();
		ligatures = font.get_ligatures ();		
		fd = new FontData ();
		
		// create ligature list
		liga_sets = new Gee.ArrayList<LigatureSet> ();
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
				
		// ligature substitution subtable
		table_start = (uint16) fd.length_with_padding ();

		fd.add_ushort (1); // format identifier
		fd.add_ushort (6 + (uint16) 2 * liga_sets.size); // offset to coverage
		fd.add_ushort ((uint16) liga_sets.size); // number of ligature set tables

		// array of offsets to ligature sets
		uint16 size = 0;
		foreach (LigatureSet l in liga_sets) {
			ligature_pos = 10 + (uint16) liga_sets.size * 4 + size;
			fd.add_ushort (ligature_pos);
			size += (uint16) l.get_set_data ().length_with_padding ();
		}

		// coverage
		fd.add_ushort (1); // format
		fd.add_ushort ((uint16) liga_sets.size);

		// coverage gid:
		foreach (LigatureSet l in liga_sets) {
			fd.add_ushort ((uint16) glyf_table.get_gid (l.get_coverage_char ()));
		}
		
		foreach (LigatureSet l in liga_sets) {
			set_data = l.get_set_data ();
			fd.append (set_data);
		}
	}

	// chaining context substitution format3
	FontData get_context_substition_subtable () {
		FontData fd = new FontData ();
		
		fd.add_ushort (3); // format identifier
		
		fd.add_ushort (1); // backtrack glyph count
		// array of offsets to coverage table
		fd.add_ushort (18);
		
		fd.add_ushort (1); // input glyph count (middle)
		// array of offsets to coverage table
		fd.add_ushort (18 + 6);
		
		fd.add_ushort (1); // lookahead glyph count
		// array of offsets to coverage table
		fd.add_ushort (18 + 2 * 6);

		fd.add_ushort (1); // substitute, (ligatures)
		// array of offsets to coverage table
		fd.add_ushort (18 + 3 * 6);

		// backtrack coverage table1
		fd.add_ushort (1); // format
		fd.add_ushort (1); // coverage array length
		
		// gid array
		fd.add_ushort ((uint16) glyf_table.get_gid ("a"));
		
		// input coverage table1
		fd.add_ushort (1); // format
		fd.add_ushort (1); // coverage array length
		
		// gid array
		fd.add_ushort ((uint16) glyf_table.get_gid ("r"));

		// lookahead coverage table1
		fd.add_ushort (1); // format
		fd.add_ushort (1); // coverage array length
		
		// gid array
		fd.add_ushort ((uint16) glyf_table.get_gid ("t"));

		// substitute coverage table1
		fd.add_ushort (1); // format
		fd.add_ushort (1); // coverage array length
		
		// gid array
		fd.add_ushort ((uint16) glyf_table.get_gid ("art"));
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
}

}
