/*
    Copyright (C) 2012, 2013 Johan Mattsson

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

class PairFormat1 : GLib.Object {
	public uint16 left = -1;
	public List<Kern> pairs = new List<Kern> ();
}

class GposTable : Table {
	
	GlyfTable glyf_table;
	List<Kern> kerning_pairs = new List<Kern> ();
	List<PairFormat1> pairs = new List<PairFormat1> ();
	
	public GposTable () {
		id = "GPOS";
	}
	
	public override void parse (FontData dis) throws Error {
		// Not implemented, freetype2 is used for loading fonts
		return_if_fail (offset > 0 && length > 0);

		stdout.printf ("GPOS data:\n");
		dis.seek (offset);
		for (int i = 0; i < length; i++) {
			stdout.printf ("%x ", dis.read ());
		}
		stdout.printf ("\n");
	}

	public void process (GlyfTable glyf_table) throws GLib.Error {
		FontData fd = new FontData ();
		
		this.glyf_table = glyf_table;

		printd ("Process GPOS\n");

		fd.add_ulong (0x00010000); // table version
		fd.add_ushort (10); // offset to script list
		fd.add_ushort (30); // offset to feature list
		fd.add_ushort (44); // offset to lookup list
		
		// script list ?
		fd.add_ushort (1);   // number of items in script list
		fd.add_tag ("DFLT"); // default script
		fd.add_ushort (8);	 // offset to script table from script list
		
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
		
		fd.add_tag ("kern"); // feature tag
		fd.add_ushort (8); // offset to feature
		
		fd.add_ushort (0); // feature prameters (null)
		fd.add_ushort (1); // number of lookups
		fd.add_ushort (0); // lookup indice
		
		// lookup table
		fd.add_ushort (1); // number of lookups
		fd.add_ushort (4); // offset to lookup 1
		
		fd.add_ushort (2); // lookup type // FIXME	
		fd.add_ushort (0); // lookup flags
		fd.add_ushort (1); // number of subtables
		fd.add_ushort (8); // array of offsets to subtables
		
		// MarkFilteringSet 

		fd.append (get_pair_pos_format1 ());
		
		fd.pad ();	
		this.font_data = fd;
	}

	// PairPosFormat1 subtable
	FontData get_pair_pos_format1 () throws GLib.Error {
		FontData fd = new FontData ();
		uint16 pair_set_count;
		
		create_kerning_pairs ();
		
		// FIXME: add more then current maximum of pairs
		
		if (pairs.length () > uint16.MAX) {
			print_pairs ();
			warning ("Too many kerning pairs.");
		}
		
		pair_set_count = (uint16) pairs.length ();
			
		fd.add_ushort (1); // position format
		// offset to coverage table from beginning of kern pair table
		fd.add_ushort (10 + pairs_offset_length () + pairs_set_length ());  
		fd.add_ushort (0x0004); // ValueFormat1 (0x0004 is x advance)
		fd.add_ushort (0); // ValueFormat2 (0 is null)
		fd.add_ushort (pair_set_count); // n pairs
		
		// pair offsets orderd by coverage index
		int pair_set_offset = 10 + pairs_offset_length ();
		foreach (PairFormat1 k in pairs) {
			fd.add_ushort ((uint16) pair_set_offset);
			pair_set_offset += 2;
			
			foreach (Kern pk in k.pairs) {
				pair_set_offset += 4;
			}
		}
		
		// pair table 
		foreach (PairFormat1 p in pairs) {
			fd.add_ushort ((uint16) p.pairs.length ()); 
			foreach (Kern k in p.pairs) {
				// pair value record	
				fd.add_ushort (k.right); // gid to second glyph
				fd.add_short (k.kerning); // value of ValueFormat1, horizontal adjustment for advance			
				// value of ValueFormat2 is null
			}
		}
		
		ProgressBar.set_progress (0); // reset progress bar
		
		// coverage
		fd.add_ushort (1); // format
		fd.add_ushort ((uint16) pairs.length ());
		foreach (PairFormat1 p in pairs) {
			fd.add_ushort (p.left); // gid
		}
		
		return fd;
	}
	
	public void print_pairs () {
		foreach (PairFormat1 p in pairs) {
			print (@"\nGid: $(p.left)\n");
			foreach (Kern k in p.pairs) {
				print (@"\tKern $(k.right)\t$(k.kerning)\n");
			}
		}
	}
	
	public int pairs_set_length () {
		int len = 0;
		foreach (PairFormat1 p in pairs) {
			len += 2;
			foreach (Kern k in p.pairs) {
				len += 4;
			}
		}
		return len;
	}
	
	public int pairs_offset_length () {
		int len = 0;
		foreach (PairFormat1 k in pairs) {
			len += 2;
		}
		return len;
	}

	public int get_pair_index (int gid) {
		int i = 0;
		foreach (PairFormat1 p in pairs) {
			if (p.left == gid) {
				return i;
			}
			i++;
		}
		return -1;
	}
	
	/** Create kerning pairs from classes. */
	public void create_kerning_pairs () {
		while (kerning_pairs.length () > 0) {
			kerning_pairs.remove_link (kerning_pairs.first ());
		}
		
		KerningClasses.get_instance ().all_pairs ((left, right, kerning) => {
			uint16 gid1, gid2;
			PairFormat1 pair;
			int pair_index;
			
			gid1 = (uint16) glyf_table.get_gid (left);
			gid2 = (uint16) glyf_table.get_gid (right);
			
			if (gid1 == -1) {
				warning (@"gid is -1 for \"$left\"");
				return;
			}
			
			if (gid2 == -1) {
				warning (@"gid is -1 for \"$right\"");
				return;
			}
			
			print (@"kerning: $left $right $kerning\n");
			
			pair_index = get_pair_index (gid1);
			if (pair_index == -1) {
				pair = new PairFormat1 ();
				pair.left = gid1; 
				pairs.append (pair);
			} else {
				pair = pairs.nth (pair_index).data;
			}
			
			pair.pairs.append (new Kern (gid1, gid2, (int16)(kerning * HeadTable.UNITS)));
		});
	}
}

}
