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

public class AlternateFeature : GLib.Object {
	GlyfTable glyf_table;
	Gee.ArrayList<Alternate> alternates;
	string tag;
	
	public AlternateFeature (GlyfTable glyf_table, string tag) {
		Font font = OpenFontFormatWriter.get_current_font ();
		
		this.tag = tag;
		this.glyf_table = glyf_table;
		alternates = font.alternates.get_alt (tag);

		alternates.sort ((a, b) => {
			Alternate alt1 = (Alternate) a;
			Alternate alt2 = (Alternate) b;
			return strcmp (alt1.glyph_name, alt2.glyph_name);
		});
	}
	
	public bool has_alternates () {
		return alternates.size > 0;
	}
	
	public Lookups get_lookups () throws GLib.Error {
		Lookups lookups = new Lookups ();
		Lookup lookup = new Lookup (3, 0, tag);
		FontData fd = new FontData ();

		fd.add_ushort (1); // format identifier
		
		// offset to coverage
		int coverage_offset = 6;
		coverage_offset += 2 * alternates.size;
		
		foreach (Alternate a in alternates) {
			coverage_offset += 2;
			coverage_offset += 2 * a.alternates.size;
		}
		
		fd.add_ushort ((uint16) coverage_offset);
		
		// number of alternate sets
		fd.add_ushort ((uint16) alternates.size); 
		
		int offset = 6 + 2 * alternates.size;
		for (int i = 0; i < alternates.size; i++) {
			// offset to each alternate set
			fd.add_ushort ((uint16) offset);
			offset += 2;
			offset += 2 * alternates.get (i).alternates.size;
		}
		
		// alternates
		foreach (Alternate alternate in alternates) {
			fd.add_ushort ((uint16) alternate.alternates.size);
			
			alternate.alternates.sort ((a, b) => {
				string alt1 = (string) a;
				string alt2 = (string) b;
				return strcmp (alt1, alt2);
			});
			
			foreach (string alt in alternate.alternates) {
				fd.add_ushort ((uint16) glyf_table.get_gid (alt));
			}
		}		

		if (fd.length_with_padding () != coverage_offset) {
			warning (@"Bad coverage offset. $(fd.length_with_padding ()) != $coverage_offset");
		}

		// coverage  
		fd.add_ushort (1); // format
		fd.add_ushort ((uint16) alternates.size); // coverage array length
		foreach (Alternate alternate in alternates) {
			string glyph_name = alternate.glyph_name;
			fd.add_ushort ((uint16) glyf_table.get_gid (glyph_name));
		}
		
		lookup.add_subtable (fd);
		lookups.add_lookup (lookup);
		
		return lookups;
	}
}

}
