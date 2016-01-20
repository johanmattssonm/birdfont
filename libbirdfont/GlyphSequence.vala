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

	OtfTags otf_tags;

	public GlyphSequence () {
		glyph = new Gee.ArrayList<Glyph?> ();
		ranges = new Gee.ArrayList<GlyphRange?> ();
		otf_tags = new OtfTags ();
	}
	
	public void set_otf_tags (OtfTags tags) {
		this.otf_tags = tags;
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
	
	/** Perform glyph substitution.
	 * @param tags enable otf features
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

		foreach (ContextualLigature c in  ligatures.contextual_ligatures) {
			if (c.is_valid ()) {
				ligature_sequence.replace_contextual (c.get_backtrack (),
					c.get_input (),
					c.get_lookahead (),
					c.get_ligature_sequence ());	
			}
		}
		
		ligatures.get_single_substitution_ligatures ((substitute, ligature) => {
			ligature_sequence.replace (substitute, ligature);
		});
		
		// salt and similar tags
		foreach (string tag in otf_tags.elements) {
			Gee.ArrayList<Alternate> alternates;
			alternates = font.alternates.get_alt (tag);

			foreach (Alternate a in alternates) {
				GlyphSequence old = new GlyphSequence ();
				string name;
				Glyph? g;
				
				name = a.glyph_name;
				
				if (name == "space") {
					name = " ";
				}
				
				g = font.get_glyph_by_name (name);

				if (likely (g != null)) {
					old.add (g);
						
					if (a.alternates.size > 0) {
						// FIXME: pick one of several alternates
						string alt_name = a.alternates.get (0);
						Glyph? alt = font.get_glyph_by_name (alt_name);
						
						if (likely (alt != null)) {
							GlyphSequence replacement = new GlyphSequence ();
							replacement.add (alt);
							ligature_sequence.replace (old, replacement);
						} else {
							warning (@"Alternate does not exist: $(alt_name)");
						}
					}
				} else {
					warning (@"Alternative for a missing glyph: $(a.glyph_name)");
				}
			}
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
				glyph = substitute (i, old.glyph.size, replacement);
				i += replacement.length ();
			} else {
				i++;
			}
		}
	}

	void replace_contextual (GlyphSequence backtrack, GlyphSequence input, GlyphSequence lookahead, 
		GlyphSequence replacement) {
			
		bool start, middle, end;
		int i = 0;
		int advance = 0;

		while (i < glyph.size) {
			start = starts_with (backtrack, i);
			middle = starts_with (input, i + backtrack.length ());
			end = starts_with (lookahead, i + backtrack.length () + input.length ());
			
			if (start && middle && end) {
				glyph = substitute (i + backtrack.length (), input.length (), replacement);
				
				advance = backtrack.length () + replacement.length ();
				i += advance + 1;
				
				if (advance <= 0) {
					warning ("No advancement.");
					return;
				}
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
	
	Gee.ArrayList<Glyph?> substitute (uint index, uint length, GlyphSequence substitute) {
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
		
		return new_list;
	}
}

}
