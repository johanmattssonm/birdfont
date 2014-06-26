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

using Cairo;
using Math;

namespace BirdFont {

public class Ligatures : GLib.Object {
	
	public delegate void LigatureIterator (string substitution, string ligature);

	public Ligatures () {
	}

	public void get_ligatures (LigatureIterator iter) {
		iter ("f i", "fi");
	}
	
	public int count () {
		return 1;
	}
}

}
