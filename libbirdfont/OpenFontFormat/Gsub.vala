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
using Math;

namespace BirdFont {

class GsubTable : Table {
	
	public GsubTable () {
		id = "GPOS";
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
		fd.add_ushort (8);	 // offset to script table from script list
		
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
		
		fd.add_ushort (2); // lookup type // FIXME	
		fd.add_ushort (0); // lookup flags
		fd.add_ushort (1); // number of subtables
		fd.add_ushort (8); // array of offsets to subtables
		
		// MarkFilteringSet 

		//fd.append (get_clig_data ());
		
		fd.pad ();	
		this.font_data = fd;
	}
}

}
