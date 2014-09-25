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
namespace Bird {

/** A small xml parser originally written for the BirdFont project. */
public class Xml : GLib.Object {
	
	Tag root;
	string data;

	public Xml (string data) {
		this.data = data;
		reparse ();
	}
	
	/** Reset the parser and start from the beginning of the XML document. */
	public void reparse () {
		int root_index;
		
		root_index = find_root_tag ();
		if (root_index == -1) {
			warning ("No root tag found.");
		}
		
		root = new Tag ("", "", data.substring (root_index));
	}
	
	/** @return the next tag. **/
	public Tag get_next_tag () {
		return root.get_next_tag ();
	}
	
	/** @return true if there is one more tags left */
	public bool has_more_tags () {
		return root.has_more_tags ();
	}
		
	int find_root_tag () {
		int index = 0;
		int prev_index = 0;
		int modifier = 0;
		unichar c;
		
		while (true) {
			prev_index = index;
			if (!data.get_next_char (ref index, out c)) {
				break;
			}
			
			if (c == '<') {
				modifier = index;
				data.get_next_char (ref modifier, out c);
				if (c != '?' && c != '[') {
					return prev_index;
				} 
			}
		}
		
		return -1;
	}	
}

}
