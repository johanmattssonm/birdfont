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

public class MaxpTable : Table {
	
	GlyfTable glyf_table;
	
	public uint16 num_glyphs = 0;
	
	public MaxpTable (GlyfTable g) {
		glyf_table = g;
		id = "maxp";
	}
	
	public override void parse (FontData dis) 
		requires (offset > 0 && length > 0) {
		Fixed format;
		
		dis.seek (offset);
		
		format = dis.read_fixed ();
		printd (@"Maxp version: $(format.get_string ())\n");
		
		num_glyphs = dis.read_ushort ();
		
		if (format == 0x00005000) {
			return;
		}
		
		// Format 1.0 continues here
	}
	
	public void process () {
		FontData fd = new FontData();

		// Version 0.5 for fonts with cff data and 1.0 for ttf
		fd.add_u32 (0x00010000);
		
		if (glyf_table.glyphs.size == 0) {
			warning ("Zero glyphs in maxp table.");
		}
		
		fd.add_u16 ((uint16) glyf_table.glyphs.size); // numGlyphs in the font

		fd.add_u16 (glyf_table.get_max_points ()); // max points
		fd.add_u16 (glyf_table.get_max_contours ()); // max contours
		fd.add_u16 (0); // max composite points
		fd.add_u16 (0); // max composite contours
		fd.add_u16 (1); // max zones
		fd.add_u16 (0); // twilight points
		fd.add_u16 (0); // max storage
		fd.add_u16 (0); // max function defs
		fd.add_u16 (0); // max instruction defs
		fd.add_u16 (0); // max stack elements
		fd.add_u16 (0); // max size of instructions
		fd.add_u16 (0); // max component elements
		fd.add_u16 (0); // component depth
		
		fd.pad ();
		
		this.font_data = fd;
	}
}

}
