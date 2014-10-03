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

public class Ligature : GLib.Object {
	public string ligature = "";
	public string substitution = "";
	
	public Ligature (string ligature, string substitution) {
		this.ligature = ligature;
		this.substitution = substitution;
	}
	
	public unichar get_first_char () {
		return substitution.get (0);
	}
}

}
