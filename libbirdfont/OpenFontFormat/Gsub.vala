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
using Math;

namespace BirdFont {

public class GsubTable : Table {
	
	GlyfTable glyf_table;
	
	public GsubTable (GlyfTable glyf_table) {
		this.glyf_table = glyf_table;
		id = "GSUB";
	}
	
	public override void parse (FontData dis) throws Error {
	}

	public void process () throws GLib.Error {
		FontData fd = new FontData ();

		fd.add_ulong (0x00010000); // table version
		fd.add_ushort (10); // offset to script list
		fd.add_ushort (30); // offset to feature list
		fd.add_ushort (44); // offset to lookup list
		
		// script list
		fd.add_ushort (1);   // number of items in script list
		fd.add_tag ("DFLT"); // default script
		fd.add_ushort (8); // offset to script table from script list
		
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
		
		fd.add_tag ("clig"); // contextual ligatures, single substitution
		fd.add_ushort (8); // offset to feature
		
		fd.add_ushort (0); // feature prameters (null)
		fd.add_ushort (1); // number of lookups
		fd.add_ushort (0); // lookup indice
		
		// lookup table
		fd.add_ushort (1); // number of lookups
		fd.add_ushort (4); // offset to lookup 1
		
		// ligature substitution subtable
		fd.add_ushort (1); // lookup type, format identifier
		fd.add_ushort (20); // offset to coverage
		fd.add_ushort (1); // number of ligature set tables
		fd.add_ushort (10); // array of offsets to ligature sets
		
		// ligature sets
		fd.add_ushort (1); // number of offsets
		fd.add_ushort (4); // offset to ligature table
		
		// ligatures
		fd.add_ushort ((uint16) glyf_table.get_gid ("fi")); // gid of ligature
		fd.add_ushort (2); // number of components
		fd.add_ushort ((uint16) glyf_table.get_gid ("f")); // gid to component 
		fd.add_ushort ((uint16) glyf_table.get_gid ("i")); // gid to component 
		
		// coverage
		fd.add_ushort (1); // format
		fd.add_ushort (1); // num glyphs
		fd.add_ushort ((uint16) glyf_table.get_gid ("f")); // gid
		
		fd.pad ();	
		this.font_data = fd;
	}
}

}
