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

public class GdefTable : OtfTable {
	
	public GdefTable () {
		id = "GDEF";
	}
	
	public override void parse (FontData dis) throws Error {
	}
	
	public void process () throws GLib.Error {
		FontData fd = new FontData ();

		fd.add_ulong (0x00010002);
		fd.add_ushort (0); // class def
		fd.add_ushort (0); // attach list
		fd.add_ushort (0); // ligature carret
		fd.add_ushort (0); // mark attach
		fd.add_ushort (0); // mark glyf
		fd.add_ushort (0); // mark glyf set def
		
		fd.pad ();
	
		this.font_data = fd;
	}

}

}
