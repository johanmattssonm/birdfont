/*
    Copyright (C) 2012 2013 2014 2015 Johan Mattsson

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

public class GsubTable : OtfTable {
	
	GlyfTable glyf_table;
	
	public GsubTable (GlyfTable glyf_table) {
		this.glyf_table = glyf_table;
		id = "GSUB";
	}
	
	public override void parse (FontData dis) throws GLib.Error {
	}

	public void process () throws GLib.Error {
		FontData fd;
		
		fd = new FontData ();
		CligFeature clig_feature = new CligFeature (glyf_table);
		AlternateFeature alternate_feature = new AlternateFeature ();
		
		fd.add_ulong (0x00010000); // table version
		fd.add_ushort (10); // offset to script list
		fd.add_ushort (30); // offset to feature list
		fd.add_ushort (clig_feature.contextual.has_ligatures () ? 46 : 44); // offset to lookup list
		
		// script list
		fd.add_ushort (1); // number of items in script list
		fd.add_tag ("DFLT"); // default script
		fd.add_ushort (8); // offset to script table from script list
		
		// script table
		fd.add_ushort (4); // offset to default language system
		fd.add_ushort (0); // number of languages
		
		// LangSys table 
		fd.add_ushort (0); // reserved
		fd.add_ushort (0); // required features (0xFFFF is none)
		fd.add_ushort (1); // number of features
		fd.add_ushort (0); // feature index
		
		// feature table
		fd.add_ushort (1); // number of features
		
		fd.add_tag ("clig"); // feature tag
		fd.add_ushort (8); // offset to feature
		// FIXME: Should it be liga and clig?

		Lookups lookups = new Lookups ();
		lookups.append (clig_feature.get_lookups ());
		
		// FIXME: refactor clig_feature 
		uint16 feature_lookups = 1;
		
		if (clig_feature.contextual.has_ligatures ()) {
			feature_lookups++;
		}
		
		fd.add_ushort (0); // feature prameters (null)
		fd.add_ushort (feature_lookups); // number of lookups
		
		if (clig_feature.contextual.has_ligatures ()) {
			// The chained context tables are listed here but the actual
			// ligature table is only referenced in the context table
			fd.add_ushort (lookups.find (Lookups.CHAINED_CONTEXT));
			fd.add_ushort (lookups.find (Lookups.LIGATURES)); 
		} else {
			fd.add_ushort (lookups.find (Lookups.LIGATURES)); // lookup clig_subtable
		}
		
		// lookup list
		fd.append (lookups.genrate_lookup_list ());
		
		// subtables
		foreach (Lookup lookup in lookups.tables) {
			foreach (FontData subtable in lookup.subtables) {
				fd.append (subtable);
			}
		}
		
		fd.pad ();
		
		this.font_data = fd;
	}
}

}

