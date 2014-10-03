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

using Cairo;
using Math;

namespace BirdFont {

public class Ligatures : GLib.Object {
	
	public delegate void LigatureIterator (string substitution, string ligature);
	public delegate void SingleLigatureIterator (GlyphSequence substitution, GlyphCollection ligature);

	public Ligatures () {
	}
	
	// FIXME: keep ligatures sorted, long strings first
	public void get_ligatures (LigatureIterator iter) {
		iter ("a f", "af");
		iter ("f f i", "ffi");
		iter ("f i", "fi");		
	}

	public void get_single_substitution_ligatures (SingleLigatureIterator iter) {
		get_ligatures ((substitution, ligature) => {
			Font font = BirdFont.get_current_font ();
			GlyphCollection? gc;
			GlyphCollection li;
			GlyphSequence gs;
			string[] subst_names = substitution.split (" ");
			
			gc = font.get_glyph_collection_by_name (ligature);
			
			if (gc == null) {
				return;
			}
			
			li = (!) gc;
			
			gs = new GlyphSequence ();
			foreach (string s in subst_names) {
				gc = font.get_glyph_collection_by_name (s);
				
				if (gc == null) {
					return;
				}
				
				gs.glyph.add (((!) gc).get_current ());
			}
			
			iter (gs, li);
		});
	}
		
	public int count () {
		return 1;
	}
	
	
}

}
