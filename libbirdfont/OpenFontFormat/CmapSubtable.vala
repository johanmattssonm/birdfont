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

public abstract class CmapSubtable : GLib.Object {
	public abstract ushort get_platform ();
	public abstract ushort get_encoding ();
	
	public abstract void generate_cmap_data (GlyfTable glyf_table)
		throws GLib.Error;
		
	public abstract FontData get_cmap_data ();
}

}
