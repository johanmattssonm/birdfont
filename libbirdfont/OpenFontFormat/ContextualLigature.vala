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

public class ContextualLigature : GLib.Object {
	
	public string backtrack = "";
	public string input = "";
	public string lookahead = "";
	public string ligatures = "";

	/** All arguments are list of glyph names separated by space. */
	public ContextualLigature (string ligatures, string backtrack, string input, string lookahead) {
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
	
	public FontData get_data (GlyfTable glyf_table, uint16 ligature_lookup_index) {
		FontData fd = new FontData ();
		
		Gee.ArrayList<string> backtrack = GsubTable.get_names (backtrack);
		Gee.ArrayList<string> input = GsubTable.get_names (input);
		Gee.ArrayList<string> lookahead = GsubTable.get_names (lookahead);
		
		// FIXME: add ligatures
		
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
			fd.add_ushort ((uint16) backtrack.size); // coverage array length
			fd.add_ushort ((uint16) glyf_table.get_gid (glyph_name));
		}
				
		// input coverage table1
		if (fd.length_with_padding () != input_offset) {
			warning (@"Wrong input offset: $input_offset != $(fd.length_with_padding ())");
		}
		
		// gid array 
		foreach (string glyph_name in input) {
			fd.add_ushort (1); // format
			fd.add_ushort ((uint16) input.size); // coverage array length
			fd.add_ushort ((uint16) glyf_table.get_gid (glyph_name));
		}

		// lookahead coverage table1
		if (fd.length_with_padding () != lookahead_offset) {
			warning (@"Wrong lookahead offset: $lookahead_offset != $(fd.length_with_padding ())");
		}	

		// gid array 
		foreach (string glyph_name in lookahead) {
			fd.add_ushort (1); // format
			fd.add_ushort ((uint16) lookahead.size); // coverage array length
			fd.add_ushort ((uint16) glyf_table.get_gid (glyph_name));
		}
		
		return fd;
	}
}

}
