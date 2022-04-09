/*
	Copyright (C) 2022 Johan Mattsson

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

public class FkTable : OtfTable {
	GlyfTable glyf_table;
	KernTable kern_table;

	public FkTable (GlyfTable glyf_table, KernTable kern_table) {
		this.glyf_table = glyf_table;
		this.kern_table = kern_table;
		id = "FK  ";
	}

	public static int32 to_fixed (double d) {
		int32 val = (int32) Math.floor (d);
		int32 mant = (int32) Math.floor (0x10000 * (d - val));
		val = (val << 16) | mant;
		return val;
	}

	public static double from_fixed (int32 val) {
		return val / 65536.0;
	}
	
	public override void parse (FontData dis) throws GLib.Error {
		uint16 version_upper;
		uint16 version_lower;

		uint32 n_pairs;
			
		dis.seek (offset);
		
		version_upper = dis.read_ushort ();
		version_lower = dis.read_ushort ();

		if (!(version_upper == 1 && version_lower == 0)) {
			warning (@"Expecting version 1.0. Found version: $version_upper.$version_lower");
			return;
		}
		
		n_pairs = dis.read_ulong ();
		
		printd (@"Pairs in fk table $n_pairs\n");

		uint32 gid1 = -1;
		uint32 gid2 = -1;
		int32 k = -1;
		double kerning = -1;
				
		for (uint32 i = 0; i < n_pairs; i++) {
			gid1 = dis.read_ulong ();
			gid2 = dis.read_ulong ();
			k = dis.read_int32 ();
			kerning = from_fixed (k);
			kern_table.fk_kerning.add (new FkKern ((int) gid1, (int) gid2, kerning));
		}
		
		if (dis.get_read_pos () != dis.length_with_padding ()) {
			warning (@"Data left in fk table. Read pos $(dis.get_read_pos ()), length: $(dis.length_with_padding ())");
		}
	}
	
	public void process () throws GLib.Error {
		FontData fd = new FontData ();
		KerningClasses classes = BirdFont.get_current_font ().get_kerning_classes ();
		
		fd.add_ushort (1); // version upper
		fd.add_ushort (0); // version lower

		write_kerning_pairs(fd);

		fd.pad ();
		this.font_data = fd;
	}

	public void write_kerning_pairs (FontData fd) throws GLib.Error { 
		KerningClasses classes = BirdFont.get_current_font ().get_kerning_classes ();
		Gee.ArrayList<FkKern> pairs = new Gee.ArrayList<FkKern> ();
		
		classes.each_pair ((g1, g2, kerning) => {
			int gid1 = glyf_table.get_gid (g1);
			int gid2 = glyf_table.get_gid (g2);
			
			if (gid1 == -1) {
				warning (@"Glyph id not found for $g1");
				return;
			}

			if (gid2 == -1) {
				warning (@"Glyph not found for $g2");
				return;
			}
						
			pairs.add (new FkKern ((int) gid1, (int) gid2, kerning));
		});

		pairs.sort ((a, b) => {
			FkKern first = (FkKern) a;
			FkKern next = (FkKern) b;
			
			if (first.left == next.left) {
				return first.right - next.right;
			}
			
			return first.left - next.left;
		});

		uint32 num_pairs = (uint32) pairs.size;
		fd.add_ulong (num_pairs);
						
		foreach (FkKern k in pairs) {
			write_pair (fd, k.left, k.right, k.kerning);
		}
	}
	
	public void write_pair (FontData fd, int gid1, int gid2, double kerning) throws GLib.Error {
		if (gid1 < 0) {
			warning (@"Negative gid1.");
			throw new FileError.FAILED (@"gid1 is $gid1");
		}

		if (gid2 < 0) {
			warning (@"Negative gid2.");
			throw new FileError.FAILED (@"gid2 is $gid2");
		}
	
		int32 fixed_kerning = to_fixed (kerning * HeadTable.UNITS);
	
		fd.add_ulong ((uint) gid1); // left gid
		fd.add_ulong ((uint) gid2); // right gid
		fd.add_long (fixed_kerning); // kerning
	}
}


}

