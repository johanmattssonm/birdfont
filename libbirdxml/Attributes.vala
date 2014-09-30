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

/** Iterator for XML attributes. */
public class Attributes : GLib.Object {
	
	Tag tag;
			
	internal Attributes (Tag t) {
		tag = t;
	}
	
	public Iterator iterator () {
		return new Iterator (tag);
	}
	
	public class Iterator {
		Tag tag;
		Attribute? next_attribute;
		
		internal Iterator (Tag t) {
			tag = t;
			next_attribute = null;
			tag.reparse_attributes ();
		}

		public bool next () {
			if (tag.has_more_attributes ()) {
				next_attribute = tag.get_next_attribute ();
			} else {
				next_attribute = null;
			}
			
			return next_attribute != null;
		}

		public Attribute get () {
			if (unlikely (next_attribute == null)) {
				warning ("No attribute is parsed yet.");
				return new Attribute.empty ();
			}
			
			return (!) next_attribute;
		}
	}
}

}
