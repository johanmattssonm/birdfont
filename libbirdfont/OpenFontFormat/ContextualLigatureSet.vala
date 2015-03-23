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

public class ContextualLigatureSet : GLib.Object {

	public Gee.ArrayList<ContextualLigature> ligature_context;
	public LigatureSetList ligatures;
	
	public ContextualLigatureSet (GlyfTable glyf_table) {
		ligature_context = new Gee.ArrayList<ContextualLigature> ();	
		add_contextual_ligatures ();
		ligatures = new LigatureSetList.contextual (glyf_table, this);
	}
	
	public bool has_ligatures () {
		return ligature_context.size > 0;
	}
	
	void add_contextual_ligatures () {
		Font font = BirdFont.get_current_font ();
		Ligatures ligatures = font.ligature_substitution;
		
		foreach (ContextualLigature c in ligatures.contextual_ligatures) {
			ligature_context.add (c);
		}
	}
}

}
