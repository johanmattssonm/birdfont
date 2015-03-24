/*
    Copyright (C) 2013 2015 Johan Mattsson

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

public class GlyphSequence : GLib.Object {
	
	/** A list of all glyphs */
	public Gee.ArrayList<Glyph?> glyph;

	/** A list of corresponding glyph ranges if applicable. */ 
	public Gee.ArrayList<GlyphRange?> ranges;

	public GlyphSequence () {
		glyph = new Gee.ArrayList<Glyph?> ();
		ranges = new Gee.ArrayList<GlyphRange?> ();
	}
	
	public int length () {
		return glyph.size;
	}
	
	public void add (Glyph? g) {
		glyph.add (g);
		ranges.add (null);
	}
	
	public void append (GlyphSequence c) {
		foreach (Glyph? g in c.glyph) {
			glyph.add (g);
		}

		foreach (GlyphRange? r in c.ranges) {
			ranges.add (r);
		}
	}
	
	/** Do ligature substitution.
	 * @return a new sequence with ligatures
	 */
	public GlyphSequence process_ligatures (Font font) {
		// FIXME add range to ligature
		GlyphSequence ligature_sequence = new GlyphSequence ();
		bool has_range = false;
		Ligatures ligatures;
		
		foreach (Glyph? g in glyph) {
			ligature_sequence.glyph.add (g);
		}
				
		foreach (GlyphRange? r in ranges) { 
			ligature_sequence.ranges.add (r);
			if (r != null) {
				has_range = true;
			}
		}
		
		// skip ligature substitution if this sequence contains ranges
		if (has_range) {
			return ligature_sequence;
		}
		
		ligatures = font.get_ligatures ();
		ligatures.get_single_substitution_ligatures ((substitute, ligature) => {
			ligature_sequence.replace (substitute, ligature);
		});
		
		foreach (ContextualLigature c in  ligatures.contextual_ligatures) {
			ligature_sequence.replace_contextual (c.get_backtrack (),
				c.get_input (), c.get_lookahead (), c.get_ligature_sequence ());	
		}
		
		ligature_sequence.ranges.clear ();
		for (int i = 0; i < ligature_sequence.glyph.size; i++) {
			ligature_sequence.ranges.add (null);
		}
		
		return ligature_sequence;
	}
	
	void replace (GlyphSequence old, GlyphSequence replacement) {
		int i = 0;
		while (i < glyph.size) {
			if (starts_with (old, i)) {
				substitute (i, old.glyph.size, replacement);
				i += replacement.length ();
			} else {
				i++;
			}
		}
	}

	void replace_contextual (GlyphSequence backtrack, GlyphSequence input, GlyphSequence lookahead, GlyphSequence replacement) {
		bool start, middle, end;
		int i = 0;
		while (i < glyph.size) {
			start = starts_with (backtrack, i);
			middle = starts_with (input, i + backtrack.length ());
			end = starts_with (lookahead, i + backtrack.length () + input.length ());
			
			if (start && middle && end) {
				substitute (i + backtrack.length (), input.length (), replacement);
				i += i + backtrack.length () + input.length ();
			} else {
				i++;
			}
		}
	}
		
	bool starts_with (GlyphSequence old, uint index) {
		Glyph? gl;

		foreach (Glyph? g in old.glyph) {
			if (index >= glyph.size) {
				return false;
			}
			
			gl = glyph.get ((int) index);
		
			if (g != gl) {
				return false;
			}
			
			index++;
		}
		
		return true;
	}
	
	void substitute (uint index, uint length, GlyphSequence substitute) {
		Gee.ArrayList<Glyph?> new_list = new Gee.ArrayList<Glyph?> ();
		int i = 0;
		
		foreach (Glyph? g in glyph) {
			if (i == index) {
				foreach (Glyph? gn in substitute.glyph) {
					new_list.add (gn);
				}
			}

			if (!(i >= index && i < index + length)) {
				new_list.add (g);
			}

			i++;
		}
		
		glyph = new_list;		
	}
}

}
