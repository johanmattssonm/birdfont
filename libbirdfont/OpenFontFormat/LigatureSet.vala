/*
    Copyright (C) 2014 Johan Mattsson

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

public class LigatureSet : GLib.Object {
	public Gee.ArrayList<Ligature> ligatures = new Gee.ArrayList<Ligature> ();
	GlyfTable glyf_table;
	
	public LigatureSet (GlyfTable gt) {
		glyf_table = gt;
	}
	
	public  void add (Ligature lig) {
		ligatures.add (lig);
	}
	
	public bool starts_with (string s) {
		if (ligatures.size == 0) {
			return false;
		}
		
		return ligatures.get (0).substitution.has_prefix (s);
	}
	
	public string get_coverage_char () {
		if (ligatures.size == 0) {
			warning ("No ligatures in set.");
			return "";
		}
		
		return (!) ligatures.get (0).substitution.get (0).to_string ();
	}
	
	public FontData get_set_data () {
		FontData fd, ligature_data;
		uint16 o, pos;
		
		fd = new FontData ();

		// number of ligatures in this set
		fd.add_ushort ((uint16) ligatures.size); 
		
		ligature_data = new FontData ();
		foreach (Ligature l in ligatures) {
			// offset to ligatures
			o = 2 + 2 * ligatures.size;
			
			pos = (uint16) (o + ligature_data.length_with_padding ());
			
			fd.add_ushort (pos);
			add_ligature (ligature_data, l);
		}
		
		fd.append (ligature_data);
		
		return fd;
	}
	
	void add_ligature (FontData fd, Ligature ligature) throws GLib.Error {
		string[] parts = ligature.substitution.split (" ");
		bool first = true;
		int gid = glyf_table.get_gid (ligature.ligature);
		
		if (gid == -1) {
			warning (@"No glyph ID for ligature $(ligature.ligature).");
			gid = 0;
		}
		
		fd.add_ushort ((uint16) gid);
		
		// number of components including the coverage glyph
		fd.add_ushort ((uint16) parts.length); 

		foreach (string p in parts) {
			if (!first) {
				fd.add_ushort ((uint16) glyf_table.get_gid (p));
			}
			
			first = false;
		}
	}
}

}
