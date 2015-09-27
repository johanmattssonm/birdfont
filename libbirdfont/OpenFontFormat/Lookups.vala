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
using Math;

namespace BirdFont {

// Contextual substitutions uses this table for chained substitutions, 
// the order is not arbitrary.

public class Lookups : GLib.Object {
	public Gee.ArrayList<Lookup> tables = new Gee.ArrayList<Lookup> ();
	
	public Lookups () {	
	}
	
	/** Subtables added in the proirity order for the substitution or
	 * spacing transformation. The first table will have highest 
	 * priority.
	 */
	public void add_lookup (Lookup lookup) {
		tables.add (lookup);
	}

	/** Find the lookup index for a particular lookup. */
	public uint16 find (string token) {
		uint16 index = 0;
		foreach (Lookup lookup in tables) {
			if (lookup.token == token) {
				return index;
			}
			
			index++;
		}
		
		warning (@"No lookup has been created with token $(token)");
		return 0;
	}

	public void append (Lookups lookups) {
		foreach (Lookup lookup in lookups.tables) {
			tables.add (lookup);
		}
	}
	
	public FontData generate_lookup_list () throws GLib.Error {
		FontData fd = new FontData ();
		uint lookup_offset;
		uint tables_size;
		uint entry_size;
		uint total_entries_size;
		FontData entry; 
		
		fd.add_ushort ((uint16) tables.size); // number of lookups
		lookup_offset = 2 + 2 * tables.size;
		total_entries_size = 0;
		
		foreach (Lookup lookup in tables) {
			fd.add_ushort ((uint16) lookup_offset);
			entry_size = lookup.get_lookup_entry_size ();
			return_val_if_fail (lookup.subtables.size != 0, fd);
			return_val_if_fail (entry_size == 6 + 2 * lookup.subtables.size, fd);
			lookup_offset += entry_size;
			total_entries_size += entry_size;
		}
		
		tables_size = 0;
		uint offset = total_entries_size;

		foreach (Lookup lookup in tables) {
			entry = lookup.get_lookup_entry (offset);
			offset -= lookup.get_lookup_entry_size ();
			offset += lookup.get_subtable_size ();
			fd.append (entry);
		}
		
		return fd;
	}
}

}
