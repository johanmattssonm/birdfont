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

/** 
 * Iterator for XML attributes. 
 */
[Compact]
[CCode (ref_function = "bird_attributes_ref", unref_function = "bird_attributes_unref")]
public class Attributes {
	
	public Tag tag;
	public int refcount = 1;
			
	internal Attributes (Tag t) {
		tag = t;
	}
	
	public Iterator iterator () {
		return new Iterator (tag);
	}

	/** Increment the reference count.
	 * @return a pointer to this object
	 */
	public unowned Attributes @ref () {
		refcount++;
		return this;
	}
	
	/** Decrement the reference count and free the object when zero object are holding references to it.*/
	public void unref () {
		if (--refcount == 0) {
			this.finalize ();
		}
	}
	
	[Compact]
	[CCode (ref_function = "bird_attributes_iterator_ref", unref_function = "bird_attributes_iterator_unref")]
	public class Iterator {
		public Tag tag;
		public Attribute? next_attribute;
		public int iterator_refcount = 1;
		
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
			if (next_attribute == null) {
				XmlParser.warning ("No attribute is parsed yet.");
				return new Attribute.empty ();
			}
			
			return (!) next_attribute;
		}
		
		/** Increment the reference count.
		 * @return a pointer to this object
		 */
		public unowned Iterator @ref () {
			iterator_refcount++;
			return this;
		}
		
		/** Decrement the reference count and free the object when zero object are holding references to it.*/
		public void unref () {
			if (--iterator_refcount == 0) {
				this.finalize ();
			}
		}
		
		private extern void finalize ();
	}
	
	private extern void finalize ();
}

}
