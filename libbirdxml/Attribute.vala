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
public class Attribute : GLib.Object {
	
	public string ns;
	public string name;
	public string content;
	
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
}

}
