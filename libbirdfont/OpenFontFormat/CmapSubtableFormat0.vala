/*
	Copyright (C) 2014 2015 Johan Mattsson

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

/** Format 0 cmap subtable */
public class CmapSubtableFormat0 : CmapSubtable {
	FontData cmap_data = new FontData ();
	
	public CmapSubtableFormat0 () {
	}
	
	public override ushort get_platform () {
		return 1;
	}

	public override ushort get_encoding () {
		return 0;
	}

	public override FontData get_cmap_data () {
		return cmap_data;
	}
	
	public override void generate_cmap_data (GlyfTable glyf_table) 
			throws GLib.Error {
		FontData fd = new FontData ();
		
		fd.add_u16 (0); // Format
		fd.add_u16 (262); // Length
		fd.add_u16 (0); // Language
		
		for (uint i = 0; i < 256; i++) {
			fd.add (get_gid_for_unichar ((unichar) i, glyf_table));
		}

		cmap_data = fd;
	}
	
	uint8 get_gid_for_unichar (unichar c, GlyfTable glyf_table) {
		uint32 index = 0;
		foreach (GlyphCollection g in glyf_table.glyphs) {
			if (g.get_unicode_character () == c && !g.is_unassigned ()) {
				return (index <= uint8.MAX) ? (uint8) index : 0;
			}
			index++;
		}
		return 0;		
	}
}

}

