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

namespace BirdFont {

public class AlternateSets : GLib.Object {
	
	public Gee.ArrayList<Alternate> alternates;
	
	public AlternateSets () {
		alternates = new Gee.ArrayList<Alternate> ();
	}
	
	public Gee.ArrayList<string> get_all_tags () {
		Gee.ArrayList<string> tags;
		tags = new Gee.ArrayList<string> ();
		
		foreach (Alternate a in alternates) {
			if (tags.index_of (a.tag) == -1) {
				tags.add (a.tag);
			}
		}
		
		return tags;
	}

	public Gee.ArrayList<Alternate> get_alt (string tag) {	
		Gee.ArrayList<Alternate> alt;
		alt = new Gee.ArrayList<Alternate> ();
		
		foreach (Alternate a in alternates) {
			if (a.tag == tag) {
				alt.add (a);
			}
		}
		
		return alt;
	}
	
	public void add (Alternate alternate) {
		alternates.add (alternate);
	}
}

}
