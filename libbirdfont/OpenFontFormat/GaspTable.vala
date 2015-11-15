/*
	Copyright (C) 2012 - 2014 Johan Mattsson

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

public class GaspTable : OtfTable {

	public const uint16 NONE = 0;
	public const uint16 GASP_GRIDFIT = 1;
	public const uint16 GASP_DOGRAY = 2;
	public const uint16 GASP_SYMMETRIC_GRIDFIT = 4;
	public const uint16 GASP_SYMMETRIC_SMOOTHING = 8;
	
	public GaspTable () {
		id = "gasp";
	}
	
	public override void parse (FontData dis) throws Error {
	}
	
	public void process () throws GLib.Error {
		FontData fd = new FontData ();

		fd.add_ushort (0); // version
		fd.add_ushort (1); // number of entries

		fd.add_ushort (0xFFFF); // range upper limit
		fd.add_ushort (GASP_DOGRAY); // hinting flags

		fd.pad ();
	
		this.font_data = fd;
	}

}

}
