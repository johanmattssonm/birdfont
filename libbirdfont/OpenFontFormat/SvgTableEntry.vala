/*
	Copyright (C) 2015 Johan Mattsson

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

public class SvgTableEntry : GLib.Object {
	public FontData data;
	public uint16 glyph_id;
	
	public SvgTableEntry (uint16 gid, string svg) {
		glyph_id = gid;
		data = new FontData ();
		data.add_str (svg);
	}
}

}
