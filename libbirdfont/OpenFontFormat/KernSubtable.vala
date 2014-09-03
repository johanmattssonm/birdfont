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

public class KernSubtable : GLib.Object {
	
	public delegate void KernIterator (Kern k);
	public delegate void PairFormat1Iterator (PairFormat1 k);
	
	public Gee.ArrayList<PairFormat1> pairs;
	public uint num_pairs;
	
	public KernSubtable () {
		pairs = new Gee.ArrayList<PairFormat1> ();
		num_pairs = 0;
	}
	
	public void add (PairFormat1 kerning_pair) {
		num_pairs += kerning_pair.pairs.size;
		pairs.add (kerning_pair);
	}

	/** @return the number of glyphs that is kerned on the left side in 
	 * pair pos format 1.
	 */
	public uint get_length_left () {
		return pairs.size;
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
	
	public uint get_pairs_set_length () {
		uint len = 0;
		
		all_pairs_format1 ((p) => {
			len += 2 + 4 * p.pairs.size;
		});
		
		return len;
	}
	
	public uint get_pairs_offset_length () {
		return 2 * pairs.size;
	}
	
	public uint get_bytes_used () {
		return get_pairs_set_length () + get_pairs_offset_length ();
	}
	
	public void remove_last () {
		return_if_fail (pairs.size > 0);
		pairs.remove_at (pairs.size - 1);
	}
}

}
