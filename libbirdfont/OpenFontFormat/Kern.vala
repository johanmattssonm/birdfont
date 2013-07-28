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

namespace BirdFont {

class Kern : GLib.Object {
	public uint16 left;
	public uint16 right;
	public int16 kerning;
	
	public Kern (uint16 l, uint16 r, int16 k) {
		left = l;
		right = r;
		kerning = k;
	}
}

class KernList : GLib.Object {
	public List<Kern> kernings;
	
	public KernList () {
		kernings = new List<Kern> ();
	}
}

class KernTable : Table {
	
	public static const uint16 HORIZONTAL = 1;
	public static const uint16 MINIMUM = 1 << 1;
	public static const uint16 CROSS_STREAM = 1 << 2;
	public static const uint16 OVERRIDE = 1 << 3;
	public static const uint16 FORMAT = 1 << 8;
	
	GlyfTable glyf_table;
	
	public List<Kern> kernings = new List<Kern> ();
	public int kerning_pairs = 0;
	
	public KernTable (GlyfTable gt) {
		glyf_table = gt;
		id = "kern";
	}
	
	public KernList get_all_pairs (int gid) {
		KernList kl = new KernList ();
		
		foreach (Kern k in kernings) {
			if (k.left == gid) {
				kl.kernings.append (k);
			}
		}
		
		return kl;
	}
	
	public override void parse (FontData dis) throws GLib.Error {
		uint16 version;
		uint16 sub_tables;
		
		uint16 subtable_version;
		uint16 subtable_length;
		uint16 subtable_flags;

		uint16 search_range;
		uint16 entry_selector;
		uint16 range_shift;
		
		uint16 n_pairs;
			
		dis.seek (offset);
		
		version = dis.read_ushort ();
		warn_if_fail (version == 0);
		sub_tables = dis.read_ushort ();
		
		for (uint16 i = 0; i < sub_tables; i++) {
			subtable_version = dis.read_ushort ();			
			subtable_length = dis.read_ushort ();			
			subtable_flags = dis.read_ushort ();

			n_pairs = dis.read_ushort ();
			search_range = dis.read_ushort ();
			entry_selector = dis.read_ushort ();
			range_shift = dis.read_ushort ();
						
			// TODO: check more flags
			if ((subtable_flags & HORIZONTAL) > 0 && (subtable_flags & CROSS_STREAM) == 0 && (subtable_flags & MINIMUM) == 0) {
				parse_pairs (dis, n_pairs);
			}
		}
	}
	
	public void parse_pairs (FontData dis, uint16 n_pairs) throws Error {
		uint16 left;
		uint16 right;
		int16 kerning;
		
		for (int i = 0; i < n_pairs; i++) {
			left = dis.read_ushort ();
			right = dis.read_ushort ();
			kerning = dis.read_short ();
						
			kernings.append (new Kern (left, right, kerning));
		}		
	}
	
	public void process () throws GLib.Error {
		FontData fd = new FontData ();
		uint16 n_pairs = 0;
		
		uint16 gid_left;
		int gid_right;
		
		uint16 range_shift = 0;
		uint16 entry_selector = 0;
		uint16 search_range = 0;
		
		Kern kern;
		int i;
		
		fd.add_ushort (0); // version 
		fd.add_ushort (1); // n subtables

		fd.add_ushort (0); // subtable version 

		foreach (Glyph g in glyf_table.glyphs) {
			foreach (Kerning k in g.kerning) {
				n_pairs++;
			}
		}
		
		if (n_pairs > (uint16.MAX - 14) / 6.0) {
			warning ("Too many kerning pairs!"); 
			n_pairs = (uint16) ((uint16.MAX - 14) / 6.0);
		}
		
		this.kerning_pairs = n_pairs;
		
		fd.add_ushort (6 * n_pairs + 14); // subtable length
		fd.add_ushort (HORIZONTAL); // subtable flags

		fd.add_ushort (n_pairs);
		
		search_range = 6 * largest_pow2 (n_pairs);
		entry_selector = largest_pow2_exponent (n_pairs);
		range_shift = 6 * n_pairs - search_range;
		
		fd.add_ushort (search_range);
		fd.add_ushort (entry_selector);
		fd.add_ushort (range_shift);

		gid_left = 0;
		
		i = 0;
		foreach (Glyph g in glyf_table.glyphs) {
			
			foreach (Kerning k in g.kerning) {
				// n_pairs is used to truncate this table to prevent buffer overflow
				if (n_pairs == i++) {
					break;
				}

				gid_right = glyf_table.get_gid (k.glyph_right);
				
				if (gid_right == -1) {
					warning ("right glyph not found in kerning table");
				}
				
				kern = new Kern (gid_left, (uint16)gid_right, (int16) (k.val * HeadTable.UNITS));
				
				fd.add_ushort (kern.left);
				fd.add_ushort (kern.right);
				fd.add_short (kern.kerning);
				
				kernings.append (kern);
			}
			
			gid_left++;
		}
		
		fd.pad ();
		this.font_data = fd;
	}

}


}

