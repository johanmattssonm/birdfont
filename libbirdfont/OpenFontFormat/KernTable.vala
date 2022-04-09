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

namespace BirdFont {

public class KernTable : OtfTable {
	
	public const uint16 HORIZONTAL = 1;
	public const uint16 MINIMUM = 1 << 1;
	public const uint16 CROSS_STREAM = 1 << 2;
	public const uint16 OVERRIDE = 1 << 3;
	public const uint16 FORMAT = 1 << 8;
	
	GlyfTable glyf_table;
	
	KernList pairs;
	
	// Only used for loading pairs
	public Gee.ArrayList<Kern> kerning = new Gee.ArrayList<Kern> ();
	public Gee.ArrayList<FkKern> fk_kerning = new Gee.ArrayList<FkKern> (); // Also only used for loading pairs
		
	public uint kerning_pairs = 0;
	
	public KernTable (GlyfTable gt) {
		glyf_table = gt;
		id = "kern";
		pairs = new KernList (gt);
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
		int16 k;
		
		for (int i = 0; i < n_pairs; i++) {
			left = dis.read_ushort ();
			right = dis.read_ushort ();
			k = dis.read_short ();
						
			kerning.add (new Kern (left, right, k));
		}		
	}
	
	public void process () throws GLib.Error {
		FontData fd = new FontData ();
		uint16 n_pairs = 0;
		
		uint16 gid_left;
		
		uint16 range_shift = 0;
		uint16 entry_selector = 0;
		uint16 search_range = 0;
		
		int i;
		
		uint last_gid_left;
		uint last_gid_right;
		
		if (pairs.get_length () == 0) {
			pairs.fetch_all_pairs ();
		}
		
		fd.add_ushort (0); // version 
		fd.add_ushort (1); // n subtables

		fd.add_ushort (0); // subtable version 
		
		if (pairs.get_length () > (uint16.MAX - 14) / 6.0) {
			warning ("Too many kerning pairs!"); 
			n_pairs = (uint16) ((uint16.MAX - 14) / 6.0);
		} else {
			n_pairs = (uint16) pairs.get_length ();
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
		last_gid_left  = 0;
		last_gid_right  = 0;

		pairs.all_kern ((kr) => {
			Kern k = kr;
			
			try {
				if (k.left != last_gid_left) {
					last_gid_right = 0;
				}
				
				if (unlikely (k.right < last_gid_right)) {
					warning (@"Kerning table is not sorted $(k.right) < $last_gid_right");
				}
				
				if (k.left < last_gid_left || k.right < last_gid_right) {
					warning (@"Kerning table is not sorted. $(k.left) < $last_gid_left");
				}
								
				last_gid_left = k.left;			
				last_gid_right = k.right;
				
				fd.add_ushort (k.left);
				fd.add_ushort (k.right);
				fd.add_short (k.kerning);
			} catch (GLib.Error e) {
				warning (e.message);
			}
		}, n_pairs);

		fd.pad ();
		this.font_data = fd;
	}
}


}

