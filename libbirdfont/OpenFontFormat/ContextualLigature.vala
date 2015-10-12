/*
    Copyright (C) 2014 2015 Johan Mattsson

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

public class ContextualLigature : GLib.Object {
	
	public string backtrack = "";
	public string input = "";
	public string lookahead = "";
	public string ligatures = "";

	Font font;

	/** All arguments are list of glyph names separated by space. */
	public ContextualLigature (Font font, string ligatures, string backtrack, string input, string lookahead) {
		this.font = font;
		this.backtrack = backtrack;
		this.input = input;
		this.lookahead = lookahead;
		this.ligatures = ligatures;
	}

	public Gee.ArrayList<Ligature> get_ligatures () {
		Gee.ArrayList<Ligature> ligature_list = new Gee.ArrayList<Ligature> ();
		string[] ligatures = ligatures.split (" ");
		
		foreach (string ligature_name in ligatures) {
			ligature_list.add (new Ligature (ligature_name)); 
		}
		
		return ligature_list;
	}
	
	public FontData get_font_data (GlyfTable glyf_table, uint16 ligature_lookup_index) 
		throws GLib.Error {
		FontData fd = new FontData ();
		Font font = BirdFont.get_current_font (); // FIXME: thread safety?
		
		// FIXME: it looks like get_names is the right function
		// but harfbuzz assumes that glyphs appear in the other 
		// order for latin scripts, get_names_in_reverse_order
		// creates an array of glyphs in reverse order.
		//
		// I have not found out why yet.
		
		Gee.ArrayList<string> backtrack = font.get_names_in_reverse_order (backtrack);
		Gee.ArrayList<string> input = font.get_names (input);
		Gee.ArrayList<string> lookahead = font.get_names (lookahead);
		
		uint16 lookahead_offset, input_offset, backtrack_offset;

		fd.add_ushort (3); // format identifier
		
		backtrack_offset = 14 + (uint16) (lookahead.size * 2) + (uint16) (input.size * 2) + (uint16) (backtrack.size * 2);
		fd.add_ushort ((uint16) backtrack.size); // backtrack glyph count
		for (uint16 i = 0; i < backtrack.size; i++) {
			fd.add_ushort (backtrack_offset + 6 * i); // array of offsets to coverage table
		}
		
		input_offset = 14 + (uint16) (lookahead.size * 2) + (uint16) (input.size * 2)  + (uint16) (backtrack.size * (2 + 6));
		fd.add_ushort ((uint16) input.size); // input glyph count (middle)
		for (uint16 i = 0; i < input.size; i++) {
			fd.add_ushort (input_offset + 6 * i); // array of offsets to coverage table
		}
		
		lookahead_offset = 14 + (uint16) (lookahead.size * 2) + (uint16) (input.size * (2 + 6)) + (uint16) (backtrack.size * (2 + 6));
		fd.add_ushort ((uint16) lookahead.size); // lookahead glyph count
		for (uint16 i = 0; i < lookahead.size; i++) {
			fd.add_ushort (lookahead_offset + 6 * i); // array of offsets to coverage table
		}
		
		fd.add_ushort (1); // substitute count
		
		// substitution lookup records
		fd.add_ushort (0); // glyph sequence index for the character that will be substituted 
		fd.add_ushort (ligature_lookup_index); // go to the ligature substitution via lookup table

		// backtrack coverage table1
		if (fd.length_with_padding () != backtrack_offset) {
			warning (@"Wrong backtrack offset: $backtrack_offset != $(fd.length_with_padding ())");
		}
		
		// gid array 
		foreach (string glyph_name in backtrack) {
			fd.add_ushort (1); // format
			fd.add_ushort (1); // coverage array length
			fd.add_ushort ((uint16) glyf_table.get_gid (glyph_name));
		}
				
		// input coverage table1
		if (fd.length_with_padding () != input_offset) {
			warning (@"Wrong input offset: $input_offset != $(fd.length_with_padding ())");
		}
		
		// gid array 
		foreach (string glyph_name in input) {
			fd.add_ushort (1); // format
			fd.add_ushort (1); // coverage array length
			fd.add_ushort ((uint16) glyf_table.get_gid (glyph_name));
		}

		// lookahead coverage table1
		if (fd.length_with_padding () != lookahead_offset) {
			warning (@"Wrong lookahead offset: $lookahead_offset != $(fd.length_with_padding ())");
		}

		// gid array 
		foreach (string glyph_name in lookahead) {
			fd.add_ushort (1); // format
			fd.add_ushort (1); // coverage array length
			fd.add_ushort ((uint16) glyf_table.get_gid (glyph_name));
		}
		
		return fd;
	}
	
	public GlyphSequence get_backtrack () {
		return get_sequence (backtrack);
	}

	public GlyphSequence get_input () {
		return get_sequence (input);
	}
	
	public GlyphSequence get_lookahead () {
		return get_sequence (lookahead);
	}
	
	public GlyphSequence get_ligature_sequence () {
		return get_sequence (ligatures);
	}
	
	public bool is_valid () {
		foreach (string s in font.get_names (backtrack)) {
			if (font.get_glyph_collection_by_name (s) == null) {
				return false;
			}
		}
		
		foreach (string s in font.get_names (input)) {
			if (font.get_glyph_collection_by_name (s) == null) {
				return false;
			}
		}

		foreach (string s in font.get_names (lookahead)) {
			if (font.get_glyph_collection_by_name (s) == null) {
				return false;
			}
		}

		foreach (string s in font.get_names (ligatures)) {
			if (font.get_glyph_collection_by_name (s) == null) {
				return false;
			}
		}
						
		return true;
	}
	
	GlyphSequence get_sequence (string context) {
		GlyphCollection? gc;
		GlyphSequence gs;
		
		gs = new GlyphSequence ();
		foreach (string s in font.get_names (context)) {
			gc = font.get_glyph_collection_by_name (s);
			
			if (gc == null) {
				warning (@"No glyph found for $s");
				return new GlyphSequence ();
			}
			
			gs.glyph.add (((!) gc).get_current ());
		}
		
		return gs;
	}
}

}
