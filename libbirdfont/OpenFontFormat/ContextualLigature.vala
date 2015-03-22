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
}

}
