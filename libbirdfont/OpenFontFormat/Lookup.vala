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
	
/** Representation of one lookup in gsub and gpos tables. */
public class Lookup : GLib.Object {
	public uint16 type;
	public uint16 flags;
	public Gee.ArrayList<FontData> subtables;
	public string token;
	
	// the token is used for obtaining index in lookup list, an empty
	// string ensures that the subtable can't be directly used by
	// a table, chaining context use that feature.
	//
	// Lookups.find is used to obtain index in the lookup list for
	// a token.
	public Lookup (uint16 type, uint16 flags, string token = "") {
		this.type = type;
		this.flags = flags;
		subtables = new Gee.ArrayList<FontData> ();
		this.token = token;
	}
	
	public void add_subtable (FontData subtable) {
		subtables.add (subtable);
	}
	
	public uint get_lookup_entry_size () throws GLib.Error {
		if (subtables.size == 0) {
			warning ("No subtables.");
		}
		
		return 6 + 2 * subtables.size;
	}
	
	public uint get_subtable_size () throws GLib.Error {
		uint size = 0;
		uint s;
		
		foreach (FontData subtable in subtables) {
			s = subtable.length_with_padding ();
			
			if (s == 0) {
				warning ("Zero size in subtable.");
			}
			
			size += s;
		}
		
		warn_if_fail (size != 0);
		
		return size;
	}
	
	public FontData get_lookup_entry (uint lookup_offset) 
	throws GLib.Error {
		FontData fd = new FontData ();
		
		return_val_if_fail (subtables.size > 0, fd);
		
		fd.add_ushort (type); // lookup type 
		fd.add_ushort (flags); // lookup flags
		fd.add_ushort ((uint16) subtables.size); // number of subtables
		
		// array of offsets to subtable 
		uint s;
		foreach (FontData subtable in subtables) {
			uint offset = lookup_offset;
			fd.add_ushort ((uint16) offset); 
			subtable.offset = offset;
			s = subtable.length_with_padding ();
			
			if (s == 0) {
				warning ("Zero size in subtable.");
			}
			
			lookup_offset += s;
		}

		return fd;
	}
}

}
