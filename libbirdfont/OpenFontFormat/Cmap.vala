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

public class CmapTable : Table { 
	
	GlyfTable glyf_table;	
	CmapSubtableFormat4 cmap_format4 = new CmapSubtableFormat4 ();

	public CmapTable(GlyfTable gt) {
		glyf_table = gt;
		id = "cmap";
	}
	
	public unichar get_char (uint32 i) {
		return get_prefered_table ().get_char (i) ;
	}
	
	CmapSubtableFormat4 get_prefered_table () {
		return cmap_format4;
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
				cmap_format4.offset = offset + sub_offset;
			} else {
				stderr.printf (@"Unknown cmap format. Platform: $platform Encoding: $encoding.\n");
			}
			
			if (encoding == 3) {
				stderr.printf ("Font contains a cmap table with the obsolete encoding 3.\n");
			}
		}
		
		if (cmap_format4.offset > 0) {
			cmap_format4.parse (dis);
		} else {
			warning ("No cmap subtable4 found.");
		}
	}
	
	/** Character to glyph mapping */
	public void process (GlyfTable glyf_table) throws GLib.Error {
		FontData fd = new FontData ();
		FontData cmap0_data;
		FontData cmap4_data;
		FontData cmap12_data;
		CmapSubtableFormat0 cmap0 = new CmapSubtableFormat0 ();
		CmapSubtableFormat4 cmap4 = new CmapSubtableFormat4 ();
		CmapSubtableFormat12 cmap12 = new CmapSubtableFormat12 ();
		uint16 n_encoding_tables;
			
		cmap0_data = cmap0.get_cmap_data (glyf_table);
		cmap4_data = cmap4.get_cmap_data (glyf_table);
		cmap12_data = cmap12.get_cmap_data (glyf_table);
		
		n_encoding_tables = 3;
		
		fd.add_u16 (0); // table version
		fd.add_u16 (n_encoding_tables);
		
		fd.add_u16 (3); // platform 
		fd.add_u16 (1); // encoding (Format Unicode UCS-4)
		fd.add_ulong (28); // subtable offseet

		fd.add_u16 (3); // platform 
		fd.add_u16 (10); // encoding
		fd.add_ulong (28 + cmap4_data.length ()); // subtable offseet

		fd.add_u16 (1); // platform 
		fd.add_u16 (0); // encoding
		fd.add_ulong (28 + cmap4_data.length () + cmap12_data.length ()); // subtable offseet
				
		fd.append (cmap4_data);
		fd.append (cmap12_data);
		fd.append (cmap0_data);

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
