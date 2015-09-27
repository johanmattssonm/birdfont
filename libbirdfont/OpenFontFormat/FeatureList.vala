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

public class FeatureList : GLib.Object {
	
	public Gee.ArrayList<Feature> features = new Gee.ArrayList<Feature> ();
	
	public FeatureList () {
	}
		
	public void add (Feature f) {
		features.add (f);
	}
	
	public FontData generate_feature_tags () throws GLib.Error {
		FontData fd = new FontData ();

		fd.add_ushort ((uint16) features.size); // number of features
		
		uint offset = 2 + 6 * features.size;
		foreach (Feature feature in features) {
			fd.add_tag (feature.tag); // feature tag: aalt, clig etc.
			fd.add_ushort ((uint16) offset); // offset to feature
			
			offset += 4 + 2 * feature.get_public_lookups ();
		}

		foreach (Feature feature in features) {
			// feature prameters (null)
			fd.add_ushort (0);
			
			// number of lookups
			fd.add_ushort ((uint16) feature.public_lookups.size); 
			
			foreach (int p in feature.public_lookups) {
				// reference to a lookup table (lookup index)
				fd.add_ushort (feature.lookups.find (p));
			}
		}
				
		return fd;
	}
}

}
