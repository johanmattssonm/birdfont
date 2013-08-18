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
	FontData get_pair_pos_format1 () {
		int size_of_pair = 6;
		FontData fd = new FontData ();
		uint16 i;
		
		create_kerning_pairs ();
		// FIXME: add more then current maximum of pairs
		
		uint16 pair_set_count = (uint16) pairs.length ();
		
		fd.add_ushort (1); // position format
		// offset to coverage table from beginning of kern pair table
		fd.add_ushort (10 + pairs_offset_length () + pairs_set_length ());  
		fd.add_ushort (0x0004); // ValueFormat1 (0x0004 is x advance)
		fd.add_ushort (0); // ValueFormat2 (0 is null)
		fd.add_ushort (pair_set_count); // n pairs
		
		// pair offsets orderd by coverage index
		int pair_set_offset = 10 + pairs_offset_length ();
		foreach (PairFormat1 k in pairs) {
			//fd.add_ushort (10 + 2 * num_kerning_values + i * size_of_pair);
			
			print (@"Off: $pair_set_offset\n");
			
			fd.add_ushort ((uint16) pair_set_offset);
			pair_set_offset += 2;
			
			foreach (Kern pk in k.pairs) {
				pair_set_offset += 4;
			}
		}
		
		print_pairs ();
	
		// pair table 
		i = 0;
		
		int last = -1;
		int index = 0;

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
	
	public int count_pairs (int index) {
		unowned List<Kern> k = kerning_pairs.nth (index);
		int len = 0;
		
		for (int i = index; i < kerning_pairs.length (); i++) {
			if (kerning_pairs.nth (i).data.left == k.data.left) {
				len++;
			} else {
				break;
			}
		}
		
		return len;
	}
	
	/** Create kerning pairs from classes. */
	public void create_kerning_pairs () {
		while (kerning_pairs.length () > 0) {
			kerning_pairs.remove_link (kerning_pairs.first ());
		}
		
		KerningClasses.all_pairs ((left, right, kerning) => {
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

	// I tried several different ways to organize the code with 
	// kerning classes but I could not find a way to use the
	// PairPosFormat2 without defining a huge array of kerningpairs
	// for every glyph in the class. Storing the kerning pairs 
	// on a flat array seems like the better solution with less
	// redundant kerning pairs, but this code might be useful in
	// the future.
	/** PairPosFormat2 subtable. */
	FontData get_pair_pos_format_2 () {
		FontData fd, left_classes, right_classes, coverage;
		uint16 coverage_offset, num_kerning_values;
		uint16 left_class_offset, right_class_offset;
		uint16 pairpos2_offset;
		uint16 num_class_left, num_class_right;

		fd = new FontData ();
/*		
		pairpos2_offset = (uint16) fd.length ();
		left_classes = get_classes ();
		num_kerning_values = (uint16) KerningClasses.classes_left.length ();
		coverage_offset = 16 + 2 * num_kerning_values * num_kerning_values;
		coverage = get_coverage_format_2 ();
		left_class_offset = (uint16) (coverage_offset  + coverage.length ());
	
		num_class_left = num_kerning_values;
		num_class_right = num_kerning_values;
		
		printd (@"Adding $num_kerning_values pairs to subtable of type PairPosFormat2\n");
		
		fd.add_ushort (2); // position format
		
		// offset to coverage table from beginning of kern pair table
		fd.add_ushort (coverage_offset);  
		fd.add_ushort (0x0004); // ValueFormat1 (0x0004 is x advance)
		fd.add_ushort (0); // ValueFormat2 (0 is null)
		
		// Offset to classes for left kerning classes
		fd.add_ushort (left_class_offset); 
		
		printd (@"leftclass offset: $(coverage_offset) + $(coverage.length ())\n");
		right_class_offset = left_class_offset;
		
		// Offset to classes for right kerning classes
		fd.add_ushort (right_class_offset); 
		
		fd.add_ushort (num_class_left); // numberof class left kerning classes
		fd.add_ushort (num_class_right); // numberof class right kerning classes
		
		double k;
		for (int i = 0; i < num_class_left; i++) {
			for (int j = 0; j < num_class_right; j++) {
				k = KerningClasses.kerning[i][j];
				//fd.add_ushort ((uint16) rint (k * HeadTable.UNITS));
				fd.add_short (1000 - j);
			}
		}
		
		// coverage 
		fd.append (coverage);

		// left classes
		if (left_class_offset != fd.length () - pairpos2_offset) {
			warning (@"Bad class offset, $left_class_offset != $(fd.length () - pairpos2_offset)");
		}
		
		fd.append (left_classes);
		
		// right classes
		if (right_class_offset != fd.length () - pairpos2_offset) {
			//warning (@"Bad class offset, $right_class_offset != $(fd.length () - pairpos2_offset)");
		}
		
		//fd.append (right_classes);
		
		print ("left: ");
		left_classes.dump ();

		print ("right:");
		left_classes.dump ();

		print ("All:");		
		fd.dump ();
		*/
		return fd;	
	}

	FontData get_coverage_format_2 () throws GLib.Error {
		FontData fd = new FontData ();
/*		List<uint16> coverage_left = new List<uint16> ();
		uint16 last_gindex;
		GlyphRange r;
		int gid, length;
		
		if (KerningClasses.classes_first.length () == 0) {
			warning ("no kerning pairs");
			KerningClasses.print_all ();
		}
		
		for (int j = 0; j < KerningClasses.classes.length (); j++) {
			r = KerningClasses.classes.nth (j).data;
			for (int k = 0; k < (uint16)r.get_length (); k++) {
				gid = glyf_table.get_gid_from_unicode (r.get_char (k).get_char ()); // TODO: glyph names
				
				if (gid == -1) {
					warning ("glyph not found");
				} else {
					coverage_left.append ((uint16)gid);
				}
			}
		}

		if (coverage_left.length () == 0) {
			warning ("no gid for kerning pairs");
		}

		length = 0;
		last_gindex = 0;
		foreach (uint16 gindex in coverage_left) {
			if (last_gindex != gindex) {
				length++;
			}
		}
		
		printd (@"GPOS class coverage length: $(length)\n");

		fd.add_ushort (2); // format
		fd.add_ushort ((uint16) length);
		
		coverage_left.sort ((a, b) => {
			return a - b;
		});
		
		last_gindex = 0;
		int next_index = 0;
		foreach (uint16 gindex in coverage_left) {
			if (last_gindex != gindex) {
				fd.add_ushort (gindex);
				fd.add_ushort (gindex);
				fd.add_ushort ((uint16)next_index); // stop - start + 1 ?
				next_index++;
			}
			last_gindex = gindex;
		}
*/
		return fd;
	}
	
	FontData get_coverage_format_1 () throws GLib.Error {
		FontData fd = new FontData ();
/*		List<uint16> coverage_left = new List<uint16> ();
		uint16 last_gindex;
		GlyphRange r;
		int gid;
		int length;
		
		if (KerningClasses.classes.length () == 0) {
			warning ("no kerning pairs");
			KerningClasses.print_all ();
		}
		
		for (int j = 0; j < KerningClasses.classes.length (); j++) {
			r = KerningClasses.classes.nth (j).data;
			for (int k = 0; k < (uint16)r.get_length (); k++) {
				gid = glyf_table.get_gid_from_unicode (r.get_char (k).get_char ()); // TODO: glyph names
				
				if (gid == -1) {
					warning ("glyph not found");
				} else {
					coverage_left.append ((uint16)gid);
				}
			}
		}

		if (coverage_left.length () == 0) {
			warning ("no gid for kerning pairs");
		}
		
		length = 0;
		last_gindex = 0;
		foreach (uint16 gindex in coverage_left) {
			if (last_gindex != gindex) {
				length++;
			}
		}
		
		fd.add_ushort (1); // format
		fd.add_ushort ((uint16) length); // TODO: overflow
		
		coverage_left.sort ((a, b) => {
			return a - b;
		});
		
		last_gindex = 0;
		foreach (uint16 gindex in coverage_left) {
			if (last_gindex != gindex) {
				fd.add_ushort (gindex);
			}
			last_gindex = gindex;
		}
		*/
		return fd;
	}
	
	FontData get_classes () throws GLib.Error {
		List<uint16> classes;
		FontData fd = new FontData ();
/*		uint num_ranges;
		GlyphRange r;
		GlyphRange r_sorted;
		uint length = KerningClasses.classes.length ();

		classes = new List<uint16> (); // start and stop
		num_ranges = 0;
		for (int j = 0; j < length; j++) {		
			r = KerningClasses.classes.nth (j).data;
			
			r_sorted = new GlyphRange ();
			for (int m = 0; m < r.get_length (); m++) {
				r_sorted.add_single (r.get_char (m).get_char ());
				r_sorted.sort ();
			}
			
			print ("Sorted range:\n");
			r_sorted.print_all ();
			
			for (int k = 0; k < (uint16)r_sorted.get_length (); k++) {
				foreach (UniRange ur in r_sorted.get_ranges ()) {
					classes.append ((uint16) glyf_table.get_gid_from_unicode (ur.start));
					classes.append ((uint16) glyf_table.get_gid_from_unicode (ur.stop));
					classes.append (1);  // end of range
					num_ranges++;
				}
			}
		}

		fd.add_ushort (2); // class format
		fd.add_ushort ((uint16) num_ranges); // ranges		
		
		foreach (uint16 l in classes) {
			fd.add_ushort (l);
		}
*/
		return fd;
	}
}

}
