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

public class KernList : GLib.Object {
	public List<PairFormat1> pairs;

	public delegate void KernIterator (Kern k);
	public delegate void PairFormat1Iterator (PairFormat1 k);

	GlyfTable glyf_table;
	uint num_pairs;
	
	public KernList (GlyfTable glyf_table) {
		this.glyf_table = glyf_table;
		num_pairs = 0;
	}
	
	/** @return number of pairs. */
	public uint fetch_all_pairs () {
		PairFormat1 current_pairs = new PairFormat1 ();
		
		if (pairs.length () > 0 || num_pairs > 0) {
			warning ("Pairs already loaded.");
		}
		
		num_pairs = 0;
		while (pairs.length () > 0) {
			pairs.remove_link (pairs.first ());
		}
		
		KerningClasses.get_instance ().all_pairs ((kp) => {
			uint16 gid_left, gid_right;
			unowned List<Kerning> kerning;
			KerningPair kerning_pair = kp;
			
			if (unlikely (kerning_pair.character.get_name () == "")) {
				warning ("No name for glyph");
			}

			current_pairs = new PairFormat1 ();
			gid_left = (uint16) glyf_table.get_gid (kerning_pair.character.get_name ());
			current_pairs.left = gid_left;
			pairs.append (current_pairs);
			
			kerning = kerning_pair.kerning.first ();
			
			if (unlikely (is_null (kerning))) {
				warning ("No kerning");
			}
			
			if (unlikely (kerning_pair.kerning.length () == 0)) {
				warning ("No pairs.");
			}
			
			num_pairs += kerning_pair.kerning.length ();
			foreach (Kerning k in kerning_pair.kerning) {
				gid_right = (uint16) glyf_table.get_gid (k.get_glyph ().get_name ());
				current_pairs.pairs.append (new Kern (gid_left, gid_right, (int16) (kerning.data.val * HeadTable.UNITS)));
				kerning = kerning.next;
			}
		});
		
		return num_pairs;
	}

	/** @return the number of glyphs that is kerned on the left side in 
	 * pair pos format 1.
	 */
	public uint get_length_left () {
		return pairs.length ();
	}
		
	/** @return the total number of pairs. */
	public uint get_length () {
		return num_pairs;
	}
	
	public void all_kern (KernIterator iter, int limit) {
		int i = 0;
		foreach (PairFormat1 p in pairs) {
			foreach (Kern k in p.pairs) {
				if (unlikely (i >= limit)) {
					warning (@"Too many pairs. Limit: $limit");
					return;
				}
				
				iter (k);
				i++;
			}
		}
	}

	public void all_pairs_format1 (PairFormat1Iterator iter, int limit = -1) {
		uint i = 0;
		
		foreach (PairFormat1 p in pairs) {
			if (unlikely (i >= limit && limit != -1)) {
				warning (@"Too many pairs. Limit: $limit");
				return;
			}
			
			iter (p);
			
			i++;
		}
	}
}

}
