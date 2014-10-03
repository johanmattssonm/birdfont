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

public class LocaTable : OtfTable {
	
	uint32* glyph_offsets = null;
	public uint32 size = 0;
	
	public LocaTable () {
		id = "loca";
	}	
	
	~LocaTable () {
		if (glyph_offsets != null) {
			delete glyph_offsets;
		}
	}
	
	public uint32 get_offset (uint32 i) {
		return_val_if_fail (glyph_offsets != null, 0);
		
		if (size == 0) {
			warning ("No glyphs in loca table");
		}
		
		if (!(0 <= i < size + 1)) {
			warning (@"No offset for glyph $i. Requires (0 <= $i < $(size + 1)");
		}
		
		return glyph_offsets [i];
	}
	
	/** Returns true if glyph at index i is empty and have no body to parse. */
	public bool is_empty (uint32 i) {
		return_val_if_fail (glyph_offsets != null, true);

		if (size == 0) {
			warning ("No glyphs in loca table");
		}
				
		if (!(0 <= i < size + 1)) {
			warning (@"No offset for glyph $i. Requires (0 <= $i < $(size + 1)");
		}
		
		return glyph_offsets[i] == glyph_offsets[i + 1];
	}
	
	public new void parse (FontData dis, HeadTable head_table, MaxpTable maxp_table) throws GLib.Error {
		size = maxp_table.num_glyphs;
		glyph_offsets = new uint32[size + 1];
		
		dis.seek (offset);
		
		printd (@"size: $size\n");
		printd (@"length: $length\n");
		printd (@"length/4-1: $(length / 4 - 1)\n");
		printd (@"length/2-1: $(length / 2 - 1)\n");
		printd (@"head_table.loca_offset_size: $(head_table.loca_offset_size)\n");
		
		switch (head_table.loca_offset_size) {
			case 0:
				for (long i = 0; i < size + 1; i++) {
					glyph_offsets[i] = 2 * dis.read_ushort ();	
					
					if (0 < i < size && glyph_offsets[i - 1] > glyph_offsets[i]) {
						warning (@"Invalid loca table, it must be sorted. ($(glyph_offsets[i - 1]) > $(glyph_offsets[i]))");
					}
				}
				break;
				
			case 1:
				for (long i = 0; i < size + 1; i++) {
					glyph_offsets[i] = 	dis.read_ulong ();
									
					if (0 < i < size && glyph_offsets[i - 1] > glyph_offsets[i]) {
						warning (@"Invalid loca table, it must be sorted. ($(glyph_offsets[i - 1]) > $(glyph_offsets[i]))");
					}		
				}

				break;
			
			default:
				warning ("unknown size for offset in loca table");
				break;
		}
	}

	public void process (GlyfTable glyf_table, HeadTable head_table) {
		FontData fd = new FontData ();
		uint32 last = 0;
		uint32 prev = 0;
		int i = 0;
		
		foreach (uint32 o in glyf_table.location_offsets) {
			if (i != 0 && (o - prev) % 4 != 0) {
				warning (@"glyph length is not a multiple of four in gid $i");
			}
			
			if (o % 4 != 0) {
				warning ("glyph is not on a four byte boundary");
				assert_not_reached ();
			}
			
			prev = o;
			i++;
		}
	
		if (head_table.loca_offset_size == 0) {
			foreach (uint32 o in glyf_table.location_offsets) {
				fd.add_u16 ((uint16) (o / 2));
				
				if (o < last) {
					warning (@"Loca table must be sorted. ($o < $last)");
				}
				
				last = o;
			}
		} else if (head_table.loca_offset_size == 1) {
			foreach (uint32 o in glyf_table.location_offsets) {
				fd.add_u32 (o);

				if (o < last) {
					warning (@"Loca table must be sorted. ($o < $last)");
				}
				
				last = o;
			}
		} else {
			warn_if_reached ();
		}

		if (!(glyf_table.location_offsets.size == glyf_table.glyphs.size + 1)) {
			warning ("Bad location offset.");
		}

		fd.pad ();		
		font_data = fd;		
	}
}

}
