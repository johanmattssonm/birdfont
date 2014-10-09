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

public class GposTable : OtfTable {
	
	GlyfTable glyf_table;
	KernList pairs;
	
	public GposTable () {
		id = "GPOS";
	}
	
	public override void parse (FontData dis) throws Error {
		// Not implemented, freetype2 is used for loading fonts
	}

	public void process (GlyfTable glyf_table) throws GLib.Error {
		FontData fd = new FontData ();
		
		this.glyf_table = glyf_table;
		this.pairs = new KernList (glyf_table);

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

	uint16 get_max_pairs () {
		return (uint16) ((uint16.MAX - 10) / 3.0);
	}

	// PairPosFormat1 subtable
	FontData get_pair_pos_format1 () throws GLib.Error {
		FontData fd = new FontData ();
		uint coverage_offset;
		uint16 max_pairs_per_table = get_max_pairs ();
		uint16 num_pairs;
		int i;
		uint pair_set_offset;
		uint written;
		uint written_pairs;
		uint last_gid_left;
		uint last_gid_right;
		uint16 pair_set_count;
		
		if (pairs.get_length () == 0) {
			pairs.fetch_all_pairs ();
		}

		// FIXME: add another table instead of truncating it
		if (pairs.get_length () > max_pairs_per_table) {
			warning (@"Too many kerning pairs. $(pairs.get_length ())");
			num_pairs = max_pairs_per_table;
		}

		num_pairs = (pairs.get_length () < max_pairs_per_table) ? 
			 (uint16) pairs.get_length () : max_pairs_per_table;
		
		pair_set_count = (uint16) pairs.get_length_left (); // FIXME: boundaries
		
		coverage_offset = 10 + pairs_offset_length () + pairs_set_length ();
		
		if (coverage_offset > uint16.MAX) {
			warning (@"Invalid coverage offset. Number of pairs: $(pairs.get_length ())");
			num_pairs = 0;
			coverage_offset = 10;
		}
			
		fd.add_ushort (1); // position format
		// offset to coverage table from beginning of kern pair table
		fd.add_ushort ((uint16) coverage_offset);  
		fd.add_ushort (0x0004); // ValueFormat1 (0x0004 is x advance)
		fd.add_ushort (0x0000); // ValueFormat2 (null, no value)
		fd.add_ushort (pair_set_count); // n pairs
		
		// pair offsets orderd by coverage index
		pair_set_offset = 10 + pairs_offset_length ();
		
		written = 0;
		written_pairs = 0;
		pairs.all_pairs_format1 ((k) => {
			try {
				if (pair_set_offset > uint16.MAX) {
					warning ("Invalid offset.");
					return;
				}
				
				if (k.pairs.size == 0) {
					warning ("No pairs.");
				}
				
				fd.add_ushort ((uint16) pair_set_offset);
				pair_set_offset += 2;
				pair_set_offset += 4 * k.pairs.size;
				written += 2;
			} catch (Error e) {
				warning (e.message);
			}
		}, num_pairs);
		
		if (unlikely (written != pairs_offset_length ())) {
			warning (@"Bad pairs_offset_length () calculated: $(pairs_offset_length ()), real length $written");
		}
		
		// pair table 
		i = 0;
		written = 0;
		last_gid_left = 0;
		last_gid_right = 0;
		pairs.all_pairs_format1 ((pn) => {
			try {
				PairFormat1 p = pn;
				uint pairset_length = p.pairs.size;
				
				if (pairset_length > uint16.MAX) {
					warning ("Too many pairs");
					pairset_length = uint16.MAX;
				}
				
				if (unlikely (p.left < last_gid_left)) {
					warning (@"Kerning table is not sorted $(p.left) < $last_gid_left.");
				}

				last_gid_left = p.left;
				
				fd.add_ushort ((uint16) pairset_length); 
				written += 2;
				last_gid_right = 0;
				written_pairs = 0;
				foreach (Kern k in p.pairs) {
					
					if (k.right == 0) {
						warning (@"GID $(p.left) is kerned zero units to $(k.right).");
					}
					
					// pair value record	
					fd.add_ushort (k.right);     // gid of the second glyph
					fd.add_short (k.kerning);    // value of ValueFormat1, horizontal adjustment for advance of the first glyph
					                             // value of ValueFormat2 (null)
					
					if (unlikely (k.right < last_gid_right)) {
						warning (@"Kerning table is not sorted $(k.right) < $last_gid_right).");
					}
				
					last_gid_right = k.right;

					written += 4;
					written_pairs++;
				}		
				
				if (unlikely (written_pairs != p.pairs.size)) {
					warning (@"written_pairs != p.pairs.length () $(written_pairs) != $(pairs.get_length ())   pairset_length: $pairset_length");
				}
				
				i++;
			} catch (Error e) {
				warning (e.message);
			}
		}, num_pairs);
		
		if (unlikely (pairs_set_length () != written)) {
			warning (@"Bad pair set length: $(pairs_set_length ()), real length: $written");
		}
		
		if (unlikely (fd.length () != coverage_offset)) {
			warning (@"Bad coverage offset, coverage_offset: $coverage_offset, real length: $(fd.length ())");
			warning (@"pairs_offset_length: $(pairs_offset_length ()) pairs_set_length: $(pairs_set_length ())");
		}
		
		// coverage
		fd.add_ushort (1); // format
		fd.add_ushort (pair_set_count);
		
		written = 0;
		pairs.all_pairs_format1 ((p) => {
			try {
				fd.add_ushort (p.left); // gid
				written += 2;
			} catch (Error e) {
				warning (e.message);
			}
		}, num_pairs);
		
		if (unlikely (written != 2 * pair_set_count)) {
			warning ("written != 2 * pair_set_count");
		}
		
		return fd;
	}
	
	public uint pairs_set_length () {
		uint len = 0;
		
		pairs.all_pairs_format1 ((p) => {
			len += 2 + 4 * p.pairs.size;
		});
		
		return len;
	}
	
	public uint pairs_offset_length () {
		return 2 * pairs.pairs.size;
	}
}

}
