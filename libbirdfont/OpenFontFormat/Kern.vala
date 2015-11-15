/*
	Copyright (C) 2012, 2013 Johan Mattsson

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

public class Kern : GLib.Object {
	public uint16 left;
	public uint16 right;
	public int16 kerning;
	
	public Kern (uint16 l, uint16 r, int16 k) {
		left = l;
		right = r;
		kerning = k;
	}
}

}
