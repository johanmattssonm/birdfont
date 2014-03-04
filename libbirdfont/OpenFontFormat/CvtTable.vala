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

public class CvtTable : Table {
	
	public CvtTable () {
		id = "cvt ";
	}
	
	public override void parse (FontData dis) throws Error {
	}
	
	public void process () throws GLib.Error {
		FontData fd = new FontData ();
		
		fd.add_ushort (0);
		fd.pad ();
	
		this.font_data = fd;
	}

}

}
