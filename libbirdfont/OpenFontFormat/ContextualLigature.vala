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

	public Gee.ArrayList<Ligature> ligatures;

	public ContextualLigature (string backtrack, string input, string lookahead) {
		this.backtrack = backtrack;
		this.input = input;
		this.lookahead = lookahead;
		
		ligatures = new Gee.ArrayList<Ligature> ();
	}

	public void remove_ligature_at (int i) {
		return_if_fail (0 <= i < ligatures.size);
		ligatures.remove_at (i);
	}

	public void add_ligature () {
		Ligature l = new Ligature (t_("ligature"), t_("glyph sequence"));
		ligatures.add (l);		
	}
	
	public void set_ligature (int i) {
		return_if_fail (0 <= i < ligatures.size);
		ligatures.get (i).set_ligature ();
	}

	public void set_substitution (int i) {
		return_if_fail (0 <= i < ligatures.size);
		ligatures.get (i).set_substitution (this);
	}
	
	public void sort () {
		ligatures.sort ((a, b) => {
			Ligature first, next;
			int chars_first, chars_next;
			
			first = (Ligature) a;
			next = (Ligature) b;
			
			chars_first = first.substitution.split (" ").length;
			chars_next = next.substitution.split (" ").length;
							
			return chars_next - chars_first;
		});	
	}
}

}
