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

class HeadTable : Table {

	public int16 xmin = int16.MIN;
	public int16 ymin = int16.MIN;
	public int16 xmax = int16.MAX;
	public int16 ymax = int16.MAX;
	
	uint32 adjusted_checksum = 0;

	uint16 mac_style;
	uint16 lowest_PPEM;
	int16 font_direction_hint;
		
	public int16 loca_offset_size = 1; // 0 for int16 1 for int32
	int16 glyph_data_format;

	Fixed version;
	Fixed font_revision;
	
	uint32 magic_number;
	
	uint16 flags;
	
	uint64 created;
	uint64 modified;
		
	// public static uint16 units_per_em = 4096; FIXME: windows testing
	public static uint16 units_per_em;
	public static double UNITS;
	
	const uint8 BASELINE_AT_ZERO = 1 << 0;
	const uint8 LSB_AT_ZERO = 1 << 1;
	
	GlyfTable glyf_table;
	
	public HeadTable (GlyfTable gt) {
		glyf_table = gt;
		id = "head";
		init ();
	}
	
	/** Set default value for unit. */
	public static void init () {
		units_per_em = 1000;
		UNITS = 10 * (units_per_em / 1000);
	}
	
	public uint32 get_adjusted_checksum () {
		return adjusted_checksum;
	}
	
	public double get_units_per_em () {
		return units_per_em * 10;
	}
	
	public override void parse (FontData dis) throws GLib.Error {
		return_if_fail (offset > 0 && length > 0);

		dis.seek (offset);
		
		font_data = new FontData ();		
	
		version = dis.read_fixed ();

		if (!version.equals (1, 0)) {
			warning (@"Expecting head version 1.0 got $(version.get_string ())\n");
		}
		
		font_revision = dis.read_fixed ();
		adjusted_checksum = dis.read_ulong ();
		magic_number = dis.read_ulong ();
		
		if (magic_number != 0x5F0F3CF5) {
			warning (@"Magic number is invalid. Got $(magic_number).");
			return;
		}
		
		flags = dis.read_ushort ();
		
		if ((flags & BASELINE_AT_ZERO) > 0) {
			printd ("Flag BASELINE_AT_ZERO has been set.\n");
		}

		if ((flags & LSB_AT_ZERO) > 0) {
			printd ("Flags LSB_AT_ZERO has been set.\n");
		}
		
		units_per_em = dis.read_ushort ();
		
		created = dis.read_udate ();
		modified = dis.read_udate ();
		
		xmin = dis.read_short ();
		ymin = dis.read_short ();
		
		xmax = dis.read_short ();
		ymax = dis.read_short ();

		printd (@"font boundries:\n");
		printd (@"xmin: $xmin\n");
		printd (@"ymin: $ymin\n");
		printd (@"xmax: $xmax\n");
		printd (@"ymax: $ymax\n");
				
		mac_style = dis.read_ushort ();
		lowest_PPEM = dis.read_ushort ();
		font_direction_hint = dis.read_short ();
		
		loca_offset_size = dis.read_short ();
		glyph_data_format = dis.read_short ();
		
		if (glyph_data_format != 0) {
			warning (@"Unknown glyph data format. Expecting 0 got $glyph_data_format.");
		}
		
		printd (@"Version: $(version.get_string ())\n");
		printd (@"flags: $flags\n");
		printd (@"font_revision: $(font_revision.get_string ())\n");
		printd (@"flags: $flags\n");
		printd (@"Units per em: $units_per_em\n");
		printd (@"lowest_PPEM: $lowest_PPEM\n");
		printd (@"font_direction_hint: $font_direction_hint\n");
		printd (@"loca_offset_size: $loca_offset_size\n");
		printd (@"glyph_data_format: $glyph_data_format\n");
		
		// Some deprecated values follow here ...
	}
	
	public uint32 get_font_checksum () {
		return adjusted_checksum;
	}
	
	public void set_check_sum_adjustment (uint32 csa) {
		this.adjusted_checksum = csa;
	}
	
	public uint32 get_checksum_position () {
		return 8;
	}
	
	public void process () throws GLib.Error {
		FontData font_data = new FontData ();
		Fixed version = 1 << 16;
		Fixed font_revision = 1 << 16;

		font_data.add_fixed (version);
		font_data.add_fixed (font_revision);
		
		// Zero on the first run and updated by directory tables checksum calculation
		// for the entire font.
		font_data.add_u32 (adjusted_checksum);
		
		font_data.add_u32 (0x5F0F3CF5); // magic number
		
		//font_data.add_u16 (BASELINE_AT_ZERO | LSB_AT_ZERO);
		font_data.add_u16 (0); // flags
		
		font_data.add_u16 (units_per_em); // units per em (should be a power of two for ttf fonts)
		
		font_data.add_64 (0); // creation time since 1904-01-01
		font_data.add_64 (0); // modified time since 1904-01-01

		xmin = glyf_table.xmin;
		ymin = glyf_table.ymin;
		xmax = glyf_table.xmax;
		ymax = glyf_table.ymax;

		printd (@"font boundries:\n");
		printd (@"xmin: $xmin\n");
		printd (@"ymin: $ymin\n");
		printd (@"xmax: $xmax\n");
		printd (@"ymax: $ymax\n");
		
		font_data.add_short (xmin);
		font_data.add_short (ymin);
		font_data.add_short (xmax);
		font_data.add_short (ymax);
	
		font_data.add_u16 (0); // mac style
		font_data.add_u16 (2); // smallest recommended size in pixels, ppem
		font_data.add_16 (2); // deprecated direction hint
		font_data.add_16 (loca_offset_size);  // long offset
		font_data.add_16 (0);  // Use current glyph data format
		
		font_data.pad ();
		
		this.font_data = font_data;
	}
}

}
