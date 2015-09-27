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
	
	public AlternateFeature (GlyfTable glyf_table) {	
		this.glyf_table = glyf_table;
	}
	
	public bool has_alternates () {
		Font font = OpenFontFormatWriter.get_current_font ();
		return font.alternates.size > 0;
	}
	
	public Lookups get_lookups () throws GLib.Error {
		Lookups lookups = new Lookups ();
		Lookup lookup = new Lookup (3, 0, Lookups.ALTERNATES);
		FontData fd = new FontData ();
		Font font = OpenFontFormatWriter.get_current_font ();
		
		font.alternates.sort ((a, b) => {
			Alternate alt1 = (Alternate) a;
			Alternate alt2 = (Alternate) b;
			return strcmp ((!) alt1.character.to_string (), (!) alt2.character.to_string ());
		});
		
		fd.add_ushort (1); // format identifier
		
		// offset to coverage
		int coverage_offset = 6;
		coverage_offset += 2 * font.alternates.size;
		coverage_offset += 2 + 2 * get_number_of_alternates (); 
		fd.add_ushort ((uint16) coverage_offset);
		
		// number of alternate sets
		fd.add_ushort ((uint16) font.alternates.size); 
		
		int offset = 6 + 2 * font.alternates.size;
		for (int i = 0; i < font.alternates.size; i++) {
			// offset to each alternate set
			fd.add_ushort ((uint16) offset);
			offset += 2;
			offset += 2 * font.alternates.get (i).alternates.size;
		}
		
		// alternates
		foreach (Alternate alternate in font.alternates) {
			fd.add_ushort ((uint16) alternate.alternates.size);
			
			foreach (string alt in alternate.alternates) {
				fd.add_ushort ((uint16) glyf_table.get_gid (alt));
			}
		}		

		// coverage  
		fd.add_ushort (1); // format
		fd.add_ushort ((uint16) font.alternates.size); // coverage array length
		foreach (Alternate alternate in font.alternates) {
			string glyph_name = (!) alternate.character.to_string ();
			fd.add_ushort ((uint16) glyf_table.get_gid (glyph_name));
		}
		
		lookup.add_subtable (fd);
		lookups.add_lookup (lookup);
		
		return lookups;
	}
	
	int get_number_of_alternates () {
		int n = 0;
		Font font = OpenFontFormatWriter.get_current_font ();
		
		foreach (Alternate alternate in font.alternates) {
			n += alternate.alternates.size;
		}
		
		return n;
	}
}

}
