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
using Math;

namespace BirdFont {

public class ContextualLigatureCollection : GLib.Object {

	public Gee.ArrayList<ContextualLigature> ligature_context;
	public Gee.ArrayList<LigatureCollection> ligatures;
	
	public ContextualLigatureCollection (GlyfTable glyf_table) {
		ligature_context = new Gee.ArrayList<ContextualLigature> ();	
		ligatures = new Gee.ArrayList<LigatureCollection> ();
		add_contextual_ligatures (glyf_table);
	}
	
	public int16 get_size () {
		if (ligatures.size != ligature_context.size) {
			warning ("Expecting one substitution table per contextual ligature");
		}
		
		return (int16) ligature_context.size;
	}
	
	public bool has_ligatures () {
		return ligature_context.size > 0;
	}
	
	void add_contextual_ligatures (GlyfTable glyf_table) {
		Font font = BirdFont.get_current_font ();
		
		foreach (ContextualLigature c in font.ligature_substitution.contextual_ligatures) {
			ligature_context.add (c);
			ligatures.add (new LigatureCollection.contextual (glyf_table, c));
		}
	}
}

}
