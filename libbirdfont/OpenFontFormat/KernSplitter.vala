/*
	Copyright (C) 2017 Johan Mattsson

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

public class KernSplitter : GLib.Object {
	public Gee.ArrayList<PairFormat1> pairs;
	private KernList source_list;
	
	public KernSplitter (KernList kerning_list) {
		source_list = kerning_list;
		pairs = new Gee.ArrayList<PairFormat1> (); 
		
		kerning_list.all_single_kern((pair) => {
			pairs.add (pair);
		});
	}
	
	/** Prevent integer overflow in coverage table of the PairPos1 subtable. */
	public bool is_full (KernList kerning_pairs) {
		uint length = 10;
		length += GposTable.pairs_offset_length (kerning_pairs);
		length += GposTable.pairs_set_length (kerning_pairs);
		
		return length > (uint16.MAX - 10);
	}
	
	public KernList get_subset (uint offset) {
		int count = 0;
		KernList result = new KernList (source_list.glyf_table);
		
		PairFormat1 current = new PairFormat1 ();
		current.left = 0xFFFF;
		
		for (uint i = offset; i < pairs.size; i++) {
			PairFormat1 next = pairs.get ((int) i);
			
			if (is_full (result)) {
				break;
			}
			
			if (next.left != current.left) {
				current = new PairFormat1 ();
				current.left = next.left;
				result.pairs.add (current);
			}
			
			if (unlikely (next.pairs.size != 1)) {
				warning ("Splitting kerning pairs failed. "
					+ @"next.pairs.size: != $(next.pairs.size)");
			}
			
			current.pairs.add (next.pairs.get (0));
			count++;
		}

		foreach (PairFormat1 kerning in result.pairs) {
 			result.num_pairs += kerning.pairs.size;
 		}
		
		return result;
	}
}

}
