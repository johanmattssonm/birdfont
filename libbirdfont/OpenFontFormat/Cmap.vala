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

public class CmapSubtable : Table {

	// Override these methods in subtables for each format.
	
	/** Obtain length of subtable in bytes. */
	public virtual uint get_length () {
		warning ("Invalid CmapSubtable");
		return 0;
	}
	
	/** Get char code for a glyph id. */
	public virtual unichar get_char (uint32 i) {
		warning ("Invalid CmapSubtable");
		return 0;
	}
	
	public void print_cmap () {
		StringBuilder s;
		unichar c;
		for (uint32 i = 0; i < get_length (); i++) {
			s = new StringBuilder ();
			c = get_char (i);
			s.append_unichar (c);
			printd (@"Char: $(s.str)  val ($((uint32)c))\tindice: $(i)\n");
		}
	}
}

/** Format 4 cmap subtable */
public class CmapSubtableWindowsUnicode : CmapSubtable {
	uint16 format = 0;
	HashTable <uint64?, unichar> table = new HashTable <uint64?, unichar> (int64_hash, int_equal);
	
	public CmapSubtableWindowsUnicode () {
	}
	
	~CmapSubtableWindowsUnicode () {

	}

	public override uint get_length () {
		return table.size ();
	}
	
	public override unichar get_char (uint32 indice) {
		int64? c = table.lookup (indice);
		
		if (c == 0 && indice == 0) {
			return 0;
		}
		
		if (c == 0) {
			while (table.lookup (--indice) == 0) {
				if (indice == 0) {
					return 0;
				}
			} 
			
			warning (@"There is no char for glyph number $indice in cmap table. table.size: $(table.size ()))");
			return 0;
		}
		
		return (unichar) c;
	}
	
	public override void parse (FontData dis) throws GLib.Error {
		dis.seek (offset);
		
		format = dis.read_ushort ();
		
		switch (format) {
			case 4:
				parse_format4 (dis);
				break;
			
			default:
				stderr.printf (@"CmapSubtable is in format $format, it is not supportet (yet).\n");
				break;
		}
	}
		
	public void parse_format4 (FontData dis) throws GLib.Error {
		uint16 lang;
		uint16 seg_count_x2;
		uint16 seg_count;
		uint16 search_range;
		uint16 entry_selector;
		uint16 range_shift;

		uint16* end_char = null;
		uint16* start_char = null;
		int16* id_delta = null;
		uint16* id_range_offset = null;
		uint16* glyph_id_array = null;
	
		uint32 gid_len;
		
		length = dis.read_ushort ();
		lang = dis.read_ushort ();
		seg_count_x2 = dis.read_ushort ();
		search_range = dis.read_ushort ();
		entry_selector = dis.read_ushort ();
		range_shift = dis.read_ushort ();
		
		return_if_fail (seg_count_x2 % 2 == 0);

		seg_count = seg_count_x2 / 2;

		end_char = new uint16[seg_count];
		for (int i = 0; i < seg_count; i++) {
			end_char[i] = dis.read_ushort ();
		}
		
		if (end_char[seg_count - 1] != 0xFFFF) {
			warning ("end_char is $(end_char[seg_count - 1]), expecting 0xFFFF.");
		}
		
		dis.read_ushort (); // Reserved
		
		start_char = new uint16[seg_count];
		for (int i = 0; i < seg_count; i++) {
			start_char[i] = dis.read_ushort ();
		}

		id_delta = new int16[seg_count];
		for (int i = 0; i < seg_count; i++) {
			id_delta[i] = dis.read_short ();
		}

		id_range_offset = new uint16[seg_count];
		for (int i = 0; i < seg_count; i++) {
			id_range_offset[i] = dis.read_ushort ();
		}

		if (length == 0) {
			warning ("cmap subtable version 4 has length 0.");
			return;
		}

		gid_len = (length - 16 - 8 * seg_count) / 2;
		glyph_id_array = new uint16[gid_len];
		for (int i = 0; i < gid_len; i++) {
			glyph_id_array[i] = dis.read_ushort ();
		}
		
		// map all values in a hashtable
		int indice = 0;
		unichar character = 0;
		uint32 id;
		for (uint16 i = 0; i < seg_count && start_char[i] != 0xFFFF; i++) {
			
			// print_range (start_char[i], end_char[i], id_delta[i], id_range_offset[i]);
			
			uint16 j = 0;
			do {
				character = start_char[i] + j;
				indice = start_char[i] + id_delta[i] + j;
				
				if (id_range_offset[i] == 0) {
					table.insert (indice, character);
				} else {
					// the indexing trick:
					id = id_range_offset[i] / 2 + j + i - seg_count;
					
					if (!(0 <= id < gid_len)) {
						warning (@"(0 <= id < gid_len) (0 <= $id < $gid_len)");
						break;
					}
					
					indice = glyph_id_array [id] + id_delta[i];
										
					StringBuilder s = new StringBuilder ();
					s.append_unichar (character);
										
					table.insert (indice, character);
				}
				
				j++;
			} while (character != end_char[i]);
	
		}
		
		if (end_char != null) delete end_char;
		if (start_char != null) delete start_char;
		if (id_delta != null) delete id_delta;
		if (id_range_offset != null) delete id_range_offset;
		if (glyph_id_array != null) delete glyph_id_array;
	}
	
	public void process (FontData fd, GlyfTable glyf_table) throws GLib.Error {
		GlyphRange glyph_range = new GlyphRange ();
		Gee.ArrayList<UniRange> ranges;

		uint16 seg_count_2;
		uint16 seg_count;
		uint16 search_range;
		uint16 entry_selector;
		uint16 range_shift;				
		
		uint16 gid_length = 0;
		
		uint32 indice;
		uint32 first_assigned = 1;
		
		foreach (Glyph g in glyf_table.glyphs) {
			if (!g.is_unassigned ()) {
				glyph_range.add_single (g.unichar_code);
			}
		}
		
		ranges = glyph_range.get_ranges ();
		seg_count = (uint16) ranges.size + 1;
		seg_count_2 =  seg_count * 2;
		search_range = 2 * largest_pow2 (seg_count);
		entry_selector = largest_pow2_exponent (seg_count);
		range_shift = seg_count_2 - search_range;
		
		// format
		fd.add_ushort (4);
		
		// length of subtable
		fd.add_ushort (16 + 8 * seg_count + gid_length);
		
		// language
		fd.add_ushort (0);
		
		fd.add_ushort (seg_count_2);
		fd.add_ushort (search_range);
		fd.add_ushort (entry_selector);
		fd.add_ushort (range_shift);										
		
		// end codes
		indice = first_assigned;
		foreach (UniRange u in ranges) {
			if (u.stop >= 0xFFFF) {
				warning ("Not implemented yet.");
			} else {
				fd.add_ushort ((uint16) u.stop);
				indice += u.length ();
			}
		}
		fd.add_ushort (0xFFFF);
		
		fd.add_ushort (0); // Reserved
		
		// start codes
		indice = first_assigned; // since first glyph are notdef, null and nonmarkingreturn
		foreach (UniRange u in ranges) {
			if (u.start >= 0xFFFF) {
				warning ("Not implemented yet.");
			} else {
				fd.add_ushort ((uint16) u.start);
				indice += u.length ();
			}
		}
		fd.add_ushort (0xFFFF);

		// delta
		indice = first_assigned;
		foreach (UniRange u in ranges) {
			if ((u.start - indice) > 0xFFFF && u.start > indice) {
				warning ("Need range offset.");
			} else {
				fd.add_ushort ((uint16) (indice - u.start));
				indice += u.length ();
			}
		}
		fd.add_ushort (1);
		
		// range offset
		foreach (UniRange u in ranges) {
			if (u.stop <= 0xFFFF) {
				fd.add_ushort (0);
			} else {
				warning ("Not implemented yet.");
			}
		}
		fd.add_ushort (0);
		
		// FIXME: implement the rest of type 4 (mind gid_length in length field)
	}
}

public class CmapTable : Table { 
	
	GlyfTable glyf_table;	
	List<CmapSubtable> subtables;

	public CmapTable(GlyfTable gt) {
		glyf_table = gt;
		subtables = new List<CmapSubtable> ();
		id = "cmap";
	}
	
	public unichar get_char (uint32 i) {
		return get_prefered_table ().get_char (i) ;
	}
	
	CmapSubtable get_prefered_table () {
		if (subtables.length () == 0) {
			warning ("No cmap table has been parsed.");
			return new CmapSubtable ();
		}
		
		return subtables.first ().data;
	}
	
	public override string get_id () {
		return "cmap";
	}
	
	public override void parse (FontData dis) throws GLib.Error {
		uint16 version;
		uint16 nsubtables;
		
		uint16 platform;
		uint16 encoding;
		uint32 sub_offset;
		
		CmapSubtable subtable;

		return_if_fail (offset > 0 && length > 0);
		
		dis.seek (offset);
		
		version = dis.read_ushort ();
		nsubtables = dis.read_ushort ();

		printd (@"cmap version: $version\n");
		printd (@"cmap subtables: $nsubtables\n");
				
		if (version != 0) {
			warning (@"Bad version for cmap table: $version expecting 0. Number of subtables: $nsubtables");
			return;
		}
		
		for (uint i = 0; i < nsubtables; i++) {
			platform = dis.read_ushort ();
			encoding = dis.read_ushort ();
			sub_offset = dis.read_ulong ();	
		
			if (platform == 3 && encoding == 1) {
				printd (@"Parsing Unicode BMP (UCS-2) Platform: $platform Encoding: $encoding\n");
				subtable = new CmapSubtableWindowsUnicode ();
				subtable.offset = offset + sub_offset;
				subtables.append (subtable);
			} else {
				stderr.printf (@"Unknown cmap format. Platform: $platform Encoding: $encoding.\n");
			}
			
			if (encoding == 3) {
				stderr.printf ("Font contains a cmap table with the obsolete encoding 3.\n");
			}
		}
		
		if (subtables.length () == 0) {
			warning ("No suitable cmap subtable found.");
		}
		
		foreach (CmapSubtable t in subtables) {
			t.parse (dis);
			t.print_cmap ();
		}

	}
	
	/** Character to glyph mapping */
	public void process (GlyfTable glyf_table) throws GLib.Error {
		FontData fd = new FontData ();
		CmapSubtableWindowsUnicode cmap = new CmapSubtableWindowsUnicode ();
		uint16 n_encoding_tables;
		uint32 subtable_offset = 0;
			
		n_encoding_tables = 1;
		
		fd.add_u16 (0); // table version
		fd.add_u16 (n_encoding_tables);
		
		fd.add_u16 (3); // platform 
		fd.add_u16 (1); // encoding (Format Unicode UCS-4)

		subtable_offset = fd.length () + 4;
		printd (@"subtable_offset: $(subtable_offset)\n");
		
		fd.add_ulong (subtable_offset);
		cmap.process (fd, glyf_table);

		// padding
		fd.pad ();

		this.font_data = fd;
	}
}

/** Largest power of two less than max. */
internal static uint16 largest_pow2 (uint16 max) {
	uint16 x = 1;
	uint16 l = 0;
	
	while (x <= max) {
		l = x;
		x = x << 1;
	}
	
	return l;
}

/** Largest exponent for a power of two less than max. */
internal static uint16 largest_pow2_exponent (uint16 max) {
	uint16 exp = 0;
	uint16 l = 0;
	uint16 x = 0;
	
	while (x <= max) {
		l = exp;
		exp++;
		x = 1 << exp;
	}	
	
	return l;
}

}
