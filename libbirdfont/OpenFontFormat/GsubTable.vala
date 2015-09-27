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

		Lookups lookups = new Lookups ();
		FeatureList features = new FeatureList ();

		bool has_clig = clig_feature.contextual.has_ligatures ()
			|| clig_feature.has_regular_ligatures ();
			
		if (has_clig) {
			Lookups clig_lookups = clig_feature.get_lookups ();
			Feature clig_feature_lookup = new Feature ("clig", lookups);
			
			if (clig_feature.contextual.has_ligatures ()) {
				clig_feature_lookup.add_feature_lookup ("chained");
			}
				
			if (clig_feature.has_regular_ligatures ()) {
				clig_feature_lookup.add_feature_lookup ("ligatures");
			}
			
			features.add (clig_feature_lookup);
			lookups.append (clig_lookups);
		}
		
		add_alternate_table (features, lookups, "swsh");
		add_alternate_table (features, lookups, "salt");
		add_alternate_table (features, lookups, "c2sc");
		add_alternate_table (features, lookups, "smcp");
	
		FontData feature_tags = features.generate_feature_tags ();

		uint feature_list_offset = 28 + 2 * features.features.size;
		uint lookup_list_offset = feature_list_offset + feature_tags.length_with_padding ();
		
		fd.add_ulong (0x00010000); // table version
		fd.add_ushort (10); // offset to script list
		fd.add_ushort ((uint16) feature_list_offset); // offset to feature list
		fd.add_ushort ((uint16) lookup_list_offset); // offset to lookup list
		
		// script list
		fd.add_ushort (1); // number of items in script list
		fd.add_tag ("DFLT"); // default script
		fd.add_ushort (8); // offset to script table from script list
		
		// script table
		fd.add_ushort (4); // offset to default language system
		fd.add_ushort (0); // number of languages
		
		// LangSys table 
		fd.add_ushort (0); // reserved
		fd.add_ushort (0xFFFF); // required features (0xFFFF is none)
		fd.add_ushort ((uint16) features.features.size); // number of features

		// FIXME: double check this
		for (int i = 0; i < features.features.size; i++) {
			fd.add_ushort ((uint16) i); // feature index
		}

		// feature lookups with references to the lookup list
		fd.append (feature_tags);

		if (lookup_list_offset != fd.length_with_padding ()) {
			warning (@"Bad offset to lookup list: $(lookup_list_offset) != $(fd.length_with_padding ())");
		}

		// lookup list
		fd.append (lookups.generate_lookup_list ());	

		// subtable data
		foreach (Lookup lookup in lookups.tables) {
			foreach (FontData subtable in lookup.subtables) {
				fd.append (subtable);
			}
		}
		
		fd.pad ();
		
		this.font_data = fd;
	}

	/** Add alterate substitutions to lookups and features. */
	public void add_alternate_table (FeatureList features, Lookups lookups, string tag) 
	throws GLib.Error {
		AlternateFeature alt = new AlternateFeature (glyf_table, tag);
		if (alt.has_alternates ()) {			
			Lookups alt_lookup = alt.get_lookups ();
			Feature alt_feature_lookup = new Feature (tag, lookups);
			alt_feature_lookup.add_feature_lookup (tag);
			features.add (alt_feature_lookup);	
			lookups.append (alt_lookup);
		}
	}

}

}
