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
 * Representation of one XML attribute.
 */
[Compact]
[CCode (ref_function = "bird_attribute_ref", unref_function = "bird_attribute_unref")]
public class Attribute {
	
	public string ns;
	public string name;
	public string content;

	public int refcount = 1;
	
	internal Attribute (string ns, string name, string content) {
		this.ns = ns;
		this.name = name;
		this.content = content;
	}

	internal Attribute.empty () {
		this.ns = "";
		this.name = "";
		this.content = "";
	}
	
	/** Increment the reference count.
	 * @return a pointer to this object
	 */
	public unowned Attribute @ref () {
		refcount++;
		return this;
	}
	
	/** Decrement the reference count and free the object when zero object are holding references to it.*/
	public void unref () {
		if (--refcount == 0) {
			this.free ();
		}
	}
	
	/** 
	 * @return name space part for this attribute.
	 */
	public string get_namespace () {
		return ns;
	}
	
	/**
	 * @return the name of this attribute. 
	 */
	public string get_name () {
		return name;
	}

	/** 
	 * @return the value of this attribute.
	 */
	public string get_content () {
		return content;
	}
	
	private extern void free ();
}

}
