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

public class ContextList : GLib.Object {

	public Gee.ArrayList<ContextualLigature> ligature_context;
	public Gee.ArrayList<LigatureList> ligatures;
	
	public ContextList (GlyfTable glyf_table) {
		ligature_context = new Gee.ArrayList<ContextualLigature> ();	
		ligatures = new Gee.ArrayList<LigatureList> ();
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
	
	void add_contextual_ligatures () {
		Font font = BirdFont.get_current_font ();
		Ligatures ligatures = font.ligature_substitution;
		
		foreach (ContextualLigature c in ligatures.contextual_ligatures) {
			ligature_context.add (c);
			ligatures.add (new LigatureList.contextual (glyf_table, c));
		}
	}
}

}
